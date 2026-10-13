--!strict
--[[
	LinkedDeque — 노드를 양방향으로 이은 양끝 큐(2026-10-13).

	## 왜 따로 있는가

	`CircularDeque`(링 버퍼)는 양끝만 O(1) 입니다. 이쪽은 **위치가 노드**라, 노드를 쥐고 있으면 **가운데도
	O(1)** 로 넣고 뺍니다 — LRU 목록(쓰인 항목을 떼어 맨 뒤로), 순회하며 떼어 내기, 작업 취소. 양끝만 쓸
	거면 `CircularDeque` 가 낫습니다(원소마다 노드 하나를 할당하지 않음 — perf 35절).
	종류를 모르는 코드는 `Deque` 트레이트로 둘을 같게 다룹니다(`Deque.PushBack(d, v)`).

	## 표현

	```lua
	{ head: Node<T>?, tail: Node<T>?, size: number }
	```

	노드는 컨테이너 밖의 조각 `Node`(`src/Node.luau`) — `{ value, [1] = 앞 노드, [2] = 뒤 노드 }`. 양끝은
	`nil` 로 끝납니다(고리로 잇지 않음 — 리스트 계약의 "다음이 없으면 `nil`" 이 그대로 나옴).

	## 위치(노드)를 다루는 규칙

	- 밖으로 내주는 위치는 **읽기 노드**(`NodeRead<T>`)입니다 — 값과 이웃을 읽을 수 있지만 연결을 고치는
	  것은 이 모듈의 함수로만(`InsertAfter`·`InsertBefore`·`Remove`).
	- 떼어 낸 노드는 **연결이 끊깁니다**(두 칸이 `nil`). 쥐고 있던 위치로 다시 `Remove`·`Insert*` 하면
	  에러입니다(끝 쪽 칸이 `nil` 인데 그 덱의 머리·꼬리가 아닌 노드 — 두 번 지우기와 떼어 낸 노드를
	  잡습니다. 비교 둘이라 비용이 없습니다).
	- ⚠️ **다른 덱의 가운데 노드**를 넘기는 것은 잡지 못합니다(정의되지 않은 동작 — 두 덱이 다 깨집니다).
	  노드에 주인을 적으면 잡을 수 있지만 노드마다 칸 하나가 듭니다(conventions "위치 저장 — 문서 규약").
	- `Iter` 는 **도는 동안 지금 노드를 `Remove` 해도 됩니다**(다음 노드를 미리 읽어 둠). 그 밖의 변경
	  (다른 노드 지우기, 넣기)은 다른 컨테이너처럼 정의되지 않은 동작입니다.

	## 구멍

	`nil` 원소를 담을 수 있고 타입에 `T?` 로 드러납니다(`LinkedDeque.New<<number?>>()`). `PopFront`·`Front`
	가 `nil` 을 돌려주면 비었는지 구멍인지는 `Len` 으로 가르세요.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")
local Node = require("../Node")
local List = require("../Traits/List")
local Deque = require("../Traits/Deque")
local Collection = require("../Traits/Collection")
local Arr = require("./Arr")

type Node<T> = Node.Node<T>
type NodeRead<T> = Node.NodeRead<T>
type Arr<T> = Arr.Arr<T>

export type LinkedDequeData<T> = {
	head: Node<T>?,
	tail: Node<T>?,
	size: number,
	read __type: Trait.Token<"LinkedDeque">,
	-- 리스트 트레이트 마커(타입에만 있음) — 위치는 **읽기 노드**
	read __list: T,
	read __listIndex: NodeRead<T>,
	read __listMut: (T, NodeRead<T>) -> (T, NodeRead<T>),
	-- 덱 트레이트 마커와 불변 팬텀(`Deque.MarkerMut`) — 타입에만 있습니다.
	read __dequeItem: T,
	read __dequeMut: (T) -> T,
	-- 바꾸는 컬렉션 알고리즘용 팬텀(`Collection.MarkerMut`) — 타입에만 있습니다.
	read __collectionMut: true,
}
export type LinkedDeque<T> = LinkedDequeData<T>

-- 읽기만 하는 함수의 첫 인자(`ArrRead`·`CircularDequeRead` 와 같은 규칙). 원소에 공변이고, 팬텀이 없어
-- 쓰는 제네릭·꺼내기·비우기에 못 들어갑니다.
export type LinkedDequeRead<T> = {
	read head: NodeRead<T>?,
	read tail: NodeRead<T>?,
	read size: number,
	read __type: Trait.Token<"LinkedDeque">,
	read __list: T,
	read __listIndex: NodeRead<T>,
	read __dequeItem: T,
}

-- 리터럴로 둡니다 — `Trait.TYPE_KEY` 를 받아 쓰면 상수 접기가 안 돼 생성이 느려졌습니다(perf 21절).
const TYPE_KEY = "__type"
const TOKEN = Trait.NewType("LinkedDeque") :: Trait.Token<"LinkedDeque">

-- 노드의 연결 칸. 지역 상수라 접힙니다.
const PREV, NEXT = 1, 2

--#region ----------- 계약 구현 (List.Ops) — 위치는 노드 -----------

const function Get<T>(_self: LinkedDequeRead<T>, node: NodeRead<T>): T?
	return node.value
end

const function FirstIndex<T>(self: LinkedDequeRead<T>): NodeRead<T>?
	return self.head
end

const function LastIndex<T>(self: LinkedDequeRead<T>): NodeRead<T>?
	return self.tail
end

const function NextIndex<T>(_self: LinkedDequeRead<T>, node: NodeRead<T>): NodeRead<T>?
	return node[NEXT]
end

const function PrevIndex<T>(_self: LinkedDequeRead<T>, node: NodeRead<T>): NodeRead<T>?
	return node[PREV]
end

--#endregion

--#region ----------- 넣기·꺼내기 (Deque.Ops) -----------

-- 맨 뒤에 넣습니다. O(1). 자기 자신을 돌려줍니다(`Arr.PushBack` 과 같음) — 새 노드가 필요하면 `LastIndex`.
const function PushBack<T>(self: LinkedDequeData<T>, item: T): LinkedDeque<T>
	const tail = self.tail
	-- 연결 칸을 생성자에 같이 적습니다(나중에 대입하면 배열 부분을 다시 잡아 3배 — perf 34절)
	const node: Node<T> = { tail, nil, value = item } :: any
	if tail then
		tail[NEXT] = node
	else
		self.head = node
	end
	self.tail = node
	self.size += 1
	return self :: any
end

-- 맨 앞에 넣습니다. O(1).
const function PushFront<T>(self: LinkedDequeData<T>, item: T): LinkedDeque<T>
	const head = self.head
	const node: Node<T> = { nil, head, value = item } :: any
	if head then
		head[PREV] = node
	else
		self.tail = node
	end
	self.head = node
	self.size += 1
	return self :: any
end

-- 맨 앞을 꺼냅니다. 비었으면 `nil`. O(1). 꺼낸 노드는 연결이 끊깁니다.
const function PopFront<T>(self: LinkedDequeData<T>): T?
	const head = self.head
	if head == nil then
		return nil
	end
	const after = head[NEXT]
	if after then
		after[PREV] = nil
		head[NEXT] = nil
	else
		self.tail = nil
	end
	self.head = after
	self.size -= 1
	return head.value
end

-- 맨 뒤를 꺼냅니다. 비었으면 `nil`. O(1).
const function PopBack<T>(self: LinkedDequeData<T>): T?
	const tail = self.tail
	if tail == nil then
		return nil
	end
	const before = tail[PREV]
	if before then
		before[NEXT] = nil
		tail[PREV] = nil
	else
		self.head = nil
	end
	self.tail = before
	self.size -= 1
	return tail.value
end

-- 맨 앞을 봅니다(꺼내지 않음). 비었으면 `nil`.
const function Front<T>(self: LinkedDequeRead<T>): T?
	const head = self.head
	return if head then head.value else nil
end

-- 맨 뒤를 봅니다. 비었으면 `nil`.
const function Back<T>(self: LinkedDequeRead<T>): T?
	const tail = self.tail
	return if tail then tail.value else nil
end

--#endregion

--#region ----------- 위치(노드)로 넣기·빼기 -----------

-- `node` 가 이 덱에 이어져 있지 않으면 에러. 끝 쪽 칸이 `nil` 인 노드만 가릴 수 있습니다(머리·꼬리와 견줌) —
-- 떼어 낸 노드, 두 번 지우기, 다른 덱의 머리·꼬리·외톨이 노드가 걸립니다(머리 주석).
const function checkLinked<T>(self: LinkedDequeRead<T>, node: NodeRead<T>, who: string)
	if (node[PREV] == nil and self.head ~= node) or (node[NEXT] == nil and self.tail ~= node) then
		Common.raise(
			`LinkedDeque: {who} got a node that is not in this deque (removed already, or from another deque?)`
		)
	end
end

-- `node` 바로 뒤에 넣고 **새 노드**를 돌려줍니다. O(1).
const function InsertAfter<T>(self: LinkedDequeData<T>, node: NodeRead<T>, item: T): NodeRead<T>
	checkLinked(self, node, "InsertAfter")
	const at = node :: any
	const after: Node<T>? = at[NEXT]
	const fresh: Node<T> = { at, after, value = item } :: any
	at[NEXT] = fresh
	if after then
		after[PREV] = fresh
	else
		self.tail = fresh
	end
	self.size += 1
	return fresh
end

-- `node` 바로 앞에 넣고 새 노드를 돌려줍니다. O(1).
const function InsertBefore<T>(self: LinkedDequeData<T>, node: NodeRead<T>, item: T): NodeRead<T>
	checkLinked(self, node, "InsertBefore")
	const at = node :: any
	const before: Node<T>? = at[PREV]
	const fresh: Node<T> = { before, at, value = item } :: any
	at[PREV] = fresh
	if before then
		before[NEXT] = fresh
	else
		self.head = fresh
	end
	self.size += 1
	return fresh
end

-- `node` 를 떼어 내고 그 값을 돌려줍니다. O(1). 떼어 낸 노드는 연결이 끊깁니다 — 같은 노드를 다시 넘기면 에러.
const function Remove<T>(self: LinkedDequeData<T>, node: NodeRead<T>): T
	checkLinked(self, node, "Remove")
	const at = node :: any
	const before: Node<T>? = at[PREV]
	const after: Node<T>? = at[NEXT]
	if before then
		before[NEXT] = after
	else
		self.head = after
	end
	if after then
		after[PREV] = before
	else
		self.tail = before
	end
	at[PREV] = nil
	at[NEXT] = nil
	self.size -= 1
	return at.value
end

--#endregion

--#region ----------- 조회·순회 -----------

const function Len<T>(self: LinkedDequeRead<T>): number
	return self.size
end

const function Empty<T>(self: LinkedDequeRead<T>): boolean
	return self.size == 0
end

-- 앞에서부터 `(노드, 값)`: `for node, value in LinkedDeque.Iter(d) do`. 구멍(`nil` 값)에서도 멈추지 않습니다
-- (첫 변수가 노드). 다음 노드를 미리 읽어 두므로 **지금 노드를 `Remove` 해도** 이어서 돕니다.
const function Iter<T>(self: LinkedDequeRead<T>): () -> (NodeRead<T>, T)
	local cursor = self.head
	return function(): (NodeRead<T>, T)
		const node = cursor
		if node == nil then
			return nil :: any, nil :: any
		end
		cursor = node[NEXT]
		return node, node.value
	end
end

-- 앞에서부터 담은 새 `Arr`. 구멍은 구멍 그대로.
const function ToArr<T>(self: LinkedDequeRead<T>): Arr<T>
	const size = self.size
	const raw = table.create(size) :: any
	local at, node = 0, self.head
	while node ~= nil do
		at += 1
		raw[at] = node.value
		node = node[NEXT]
	end
	raw.n = size
	return Arr.FromTable(raw)
end

--#endregion

--#region ----------- 변형 -----------

-- 비웁니다. O(1) — 노드들은 서로 이어진 채 버려집니다(쥐고 있던 위치는 더는 이 덱의 것이 아닙니다 —
-- 넘기면 대부분 에러, 가운데 노드는 정의되지 않은 동작).
const function Clear<T>(self: LinkedDequeData<T>): LinkedDeque<T>
	self.head = nil
	self.tail = nil
	self.size = 0
	return self :: any
end

const function newEmpty<T>(): LinkedDeque<T>
	return { head = nil, tail = nil, size = 0, [TYPE_KEY] = TOKEN } :: any
end

-- 얕은 복사(노드는 새로 만들고 값은 같은 것).
const function Clone<T>(self: LinkedDequeRead<T>): LinkedDeque<T>
	const copy = newEmpty() :: LinkedDeque<T>
	local node = self.head
	while node ~= nil do
		PushBack(copy, node.value)
		node = node[NEXT]
	end
	return copy
end

--#endregion

--#region ----------- 생성자 -----------

-- ⚠️ 빈 덱은 원소 타입을 직접 알려줘야 합니다: `LinkedDeque.New<<number>>()`.
const function New<T>(): LinkedDeque<T>
	return newEmpty()
end

-- 리스트에서(`Common.listLength` 규약 — `n` 이 있으면 그것, 없으면 `#`). 구멍은 구멍 그대로 담습니다.
const function FromList<T>(list: { T }): LinkedDeque<T>
	const out = newEmpty() :: LinkedDeque<T>
	for idx = 1, Common.listLength(list) do
		PushBack(out, list[idx])
	end
	return out
end

-- 인자들로. `nil` 인자는 구멍으로 담깁니다(`Arr.Of` 와 같음).
const function Of<T>(...: T): LinkedDeque<T>
	const out = newEmpty() :: LinkedDeque<T>
	for idx = 1, select("#", ...) do
		PushBack(out, (select(idx, ...)))
	end
	return out
end

--#endregion

const function isLinkedDeque(value: any): boolean
	return type(value) == "table" and rawget(value, TYPE_KEY) == TOKEN
end

-- stylua: ignore
const LinkedDequeModule = {
	New = New, FromList = FromList, Of = Of, isLinkedDeque = isLinkedDeque,
	-- 이 종류의 타입 토큰(값의 `__type`) — 바깥 트레이트를 이 종류에 붙일 때: `Trait.Impl(MyTrait, LinkedDeque.Token, impl)`
	Token = TOKEN,

	Get = Get, FirstIndex = FirstIndex, LastIndex = LastIndex, NextIndex = NextIndex, PrevIndex = PrevIndex,
	PushBack = PushBack, PushFront = PushFront, PopFront = PopFront, PopBack = PopBack,
	Front = Front, Back = Back,
	InsertAfter = InsertAfter, InsertBefore = InsertBefore, Remove = Remove,
	Len = Len, Empty = Empty, Iter = Iter, ToArr = ToArr, Clear = Clear, Clone = Clone,
}

Trait.Impl(List, TOKEN, LinkedDequeModule)
Trait.Impl(Deque, TOKEN, LinkedDequeModule)
Trait.Impl(Collection, TOKEN, LinkedDequeModule)
-- 구현이 계약을 만족하는지 여기서 정적으로 확인합니다(`Trait.Impl` 호출만으로는 서명 불일치가 안 잡힘).
const _list: List.Impl<LinkedDeque<any>, any, NodeRead<any>> = LinkedDequeModule
const _deque: Deque.Ops<LinkedDeque<any>, any> = LinkedDequeModule
const _collection: Collection.Ops<LinkedDeque<any>> = LinkedDequeModule

return LinkedDequeModule

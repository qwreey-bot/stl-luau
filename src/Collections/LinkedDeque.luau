--!strict
--[[
	LinkedDeque — 노드를 양방향으로 이은 양끝 큐(2026-10-13).

	## 왜 따로 있는가

	`CircularDeque`(링 버퍼)는 양끝만 O(1) 입니다. 이쪽은 **위치가 노드**라, 노드를 쥐고 있으면 **가운데도
	O(1)** 로 넣고 뺍니다 — LRU 목록(쓰인 항목을 떼어 맨 뒤로), 순회하며 떼어 내기, 작업 취소. 양끝만 쓸
	거면 `CircularDeque` 가 낫습니다(원소마다 노드 하나를 할당하지 않음 — 1.13~1.41배, perf 38-3절).
	종류를 모르는 코드는 `Deque` 트레이트로 둘을 같게 다룹니다(`Deque.PushBack(d, v)`).

	## 표현

	```lua
	{ head: Node<T>?, tail: Node<T>?, size: number }
	```

	노드는 컨테이너 밖의 조각 `Node.Double`(`src/Node/Double.luau`) — `{ [1] = 값, [2] = 앞 노드, [3] = 뒤 노드 }`.
	양끝은 `nil` 로 끝납니다(고리로 잇지 않음 — 리스트 계약의 "다음이 없으면 `nil`" 이 그대로 나옴).

	## 위치(노드)를 다루는 규칙

	- 밖으로 내주는 위치는 **읽기 노드**(`Node.Double.NodeRead<T>` — 불투명 핸들)입니다. 값은 `LinkedDeque.Get(d,
	  node)` 나 `Node.Double.Value(node)`, 이웃은 `NextIndex`·`PrevIndex`(또는 `Node.Double.Next`·`Prev`)로 읽고,
	  연결을 고치는 것은 이 모듈의 함수로만(`InsertAfter`·`InsertBefore`·`Remove`).
	- 떼어 낸 노드는 **연결이 끊깁니다**(두 칸이 `nil`). 쥐고 있던 위치로 다시 `Remove`·`Insert*` 하면
	  에러입니다(끝 쪽 칸이 `nil` 인데 그 덱의 머리·꼬리가 아닌 노드 — 두 번 지우기와 떼어 낸 노드를
	  잡습니다. 비교 둘이라 비용이 없습니다).
	- ⚠️ **다른 덱의 가운데 노드**를 넘기는 것은 잡지 못합니다(정의되지 않은 동작 — 두 덱이 다 깨집니다).
	  노드에 주인을 적으면 잡을 수 있지만 노드마다 칸 하나가 듭니다(위치 저장은 문서 규약 — 질문 D).
	- `Iter` 는 **도는 동안 지금 노드를 `Remove` 해도 됩니다**(다음 노드를 미리 읽어 둠). 그 밖의 변경
	  (다른 노드 지우기, 넣기)은 다른 컨테이너처럼 정의되지 않은 동작입니다.

	## 구멍

	`nil` 원소를 담을 수 있고 타입에 `T?` 로 드러납니다(`LinkedDeque.New<<number?>>()`). `PopFront`·`Front`
	가 `nil` 을 돌려주면 비었는지 구멍인지는 `Len` 으로 가르세요.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")
type A = Trait.A
local Double = require("../Node/Double")
local List = require("../Traits/List")
local Deque = require("../Traits/Deque")
local Collection = require("../Traits/Collection")
local Arr = require("./Arr")

type Node<T> = Double.Node<T>
type NodeRead<T> = Double.NodeRead<T>
type Arr<T> = Arr.Arr<T>

export type LinkedDequeData<T> = {
	head: Node<T>?,
	tail: Node<T>?,
	size: number,
	read __type: Trait.Token<"Stl.LinkedDeque">,
	-- 이 종류가 구현하는 트레이트와 그 인자(질문 BA — 타입에만 있음, 읽으면 nil)
	read __traits: {
		read List: List.Assoc<T, NodeRead<T>>,
		read Deque: Deque.Assoc<T>,
		read Collection: Collection.Assoc,
	},
}
export type LinkedDeque<T> = LinkedDequeData<T>

-- 읽기만 하는 함수의 첫 인자(`ArrRead`·`CircularDequeRead` 와 같은 규칙). 원소에 공변이고, 팬텀이 없어
-- 쓰는 제네릭·꺼내기·비우기에 못 들어갑니다.
export type LinkedDequeRead<T> = {
	read head: NodeRead<T>?,
	read tail: NodeRead<T>?,
	read size: number,
	read __type: Trait.Token<"Stl.LinkedDeque">,
	-- 이 종류가 구현하는 트레이트와 그 인자(질문 BA — 타입에만 있음, 읽으면 nil)
	read __traits: { read List: List.AssocRead<T, NodeRead<T>>, read Deque: Deque.AssocRead<T> },
}

-- 리터럴로 둡니다 — `Trait.TYPE_KEY` 를 받아 쓰면 상수 접기가 안 돼 생성이 느려졌습니다(perf 21절).
const TYPE_KEY = "__type"
const TOKEN = Trait.NewToken("Stl.LinkedDeque") :: Trait.Token<"Stl.LinkedDeque">

-- 노드의 칸 배치(`Node.Double` 의 계약 — `1` = 값, `2` = 앞, `3` = 뒤). 지역 상수로 다시 적어 접히게 합니다.
-- 이 모듈 안에서는 노드를 칸으로 직접 읽고 씁니다(불투명 핸들 타입은 밖을 위한 것 — 안에서는 `any` 로).
const VALUE, PREV, NEXT = 1, 2, 3

--#region ----------- 계약 구현 (List.Core) — 위치는 노드 -----------

const function Get<T>(_self: LinkedDequeRead<T>, node: NodeRead<T>): T?
	return (node :: any)[VALUE]
end

const function FirstIndex<T>(self: LinkedDequeRead<T>): NodeRead<T>?
	return self.head
end

const function LastIndex<T>(self: LinkedDequeRead<T>): NodeRead<T>?
	return self.tail
end

const function NextIndex<T>(_self: LinkedDequeRead<T>, node: NodeRead<T>): NodeRead<T>?
	return (node :: any)[NEXT]
end

const function PrevIndex<T>(_self: LinkedDequeRead<T>, node: NodeRead<T>): NodeRead<T>?
	return (node :: any)[PREV]
end

--#endregion

--#region ----------- 넣기·꺼내기 (Deque.Core) -----------

-- 맨 뒤에 넣습니다. O(1). 자기 자신을 돌려줍니다(`Arr.PushBack` 과 같음) — 새 노드가 필요하면 `LastIndex`.
const function PushBack<T>(self: LinkedDequeData<T>, item: T): LinkedDeque<T>
	const deque: any = self
	const tail = deque.tail
	-- 칸을 생성자에 다 적습니다(나중에 대입하면 배열 부분을 다시 잡아 3배 — perf 34절)
	const node = { item, tail, nil }
	if tail then
		tail[NEXT] = node
	else
		deque.head = node
	end
	deque.tail = node
	deque.size += 1
	return self :: any
end

-- 맨 앞에 넣습니다. O(1).
const function PushFront<T>(self: LinkedDequeData<T>, item: T): LinkedDeque<T>
	const deque: any = self
	const head = deque.head
	const node = { item, nil, head }
	if head then
		head[PREV] = node
	else
		deque.tail = node
	end
	deque.head = node
	deque.size += 1
	return self :: any
end

-- 맨 앞을 꺼냅니다. 비었으면 `nil`. O(1). 꺼낸 노드는 연결이 끊깁니다.
const function PopFront<T>(self: LinkedDequeData<T>): T?
	const deque: any = self
	const head = deque.head
	if head == nil then
		return nil
	end
	const after = head[NEXT]
	if after then
		after[PREV] = nil
		head[NEXT] = nil
	else
		deque.tail = nil
	end
	deque.head = after
	deque.size -= 1
	return head[VALUE]
end

-- 맨 뒤를 꺼냅니다. 비었으면 `nil`. O(1).
const function PopBack<T>(self: LinkedDequeData<T>): T?
	const deque: any = self
	const tail = deque.tail
	if tail == nil then
		return nil
	end
	const before = tail[PREV]
	if before then
		before[NEXT] = nil
		tail[PREV] = nil
	else
		deque.head = nil
	end
	deque.tail = before
	deque.size -= 1
	return tail[VALUE]
end

-- 맨 앞을 봅니다(꺼내지 않음). 비었으면 `nil`.
const function Front<T>(self: LinkedDequeRead<T>): T?
	const head: any = self.head
	return if head then head[VALUE] else nil
end

-- 맨 뒤를 봅니다. 비었으면 `nil`.
const function Back<T>(self: LinkedDequeRead<T>): T?
	const tail: any = self.tail
	return if tail then tail[VALUE] else nil
end

--#endregion

--#region ----------- 위치(노드)로 넣기·빼기 -----------

-- `node` 가 이 덱에 이어져 있지 않으면 에러. 끝 쪽 칸이 `nil` 인 노드만 가릴 수 있습니다(머리·꼬리와 견줌) —
-- 떼어 낸 노드, 두 번 지우기, 다른 덱의 머리·꼬리·외톨이 노드가 걸립니다(머리 주석).
const function checkLinked(self: any, node: any, who: string)
	-- 위치를 돌려주는 함수가 전부 옵셔널이라(`List.IndexOf` 가 못 찾음, 빈 덱의 `LastIndex`) 타입 없는 코드에서
	-- 가장 흔한 비노드 값이 `nil` 입니다 — 라이브러리 줄의 `attempt to index nil` 이었습니다(리뷰).
	if type(node) ~= "table" then
		Common.raise(`LinkedDeque: {who} needs a node, got {typeof(node)}`)
	end
	if (node[PREV] == nil and self.head ~= node) or (node[NEXT] == nil and self.tail ~= node) then
		Common.raise(
			`LinkedDeque: {who} got a node that is not in this deque (removed already, or from another deque?)`
		)
	end
end

-- `node` 바로 뒤에 넣고 **새 노드**를 돌려줍니다. O(1).
const function InsertAfter<T>(self: LinkedDequeData<T>, node: NodeRead<T>, item: T): NodeRead<T>
	checkLinked(self, node, "InsertAfter")
	const deque: any, at: any = self, node
	const after = at[NEXT]
	const fresh = { item, at, after }
	at[NEXT] = fresh
	if after then
		after[PREV] = fresh
	else
		deque.tail = fresh
	end
	deque.size += 1
	return fresh :: any
end

-- `node` 바로 앞에 넣고 새 노드를 돌려줍니다. O(1).
const function InsertBefore<T>(self: LinkedDequeData<T>, node: NodeRead<T>, item: T): NodeRead<T>
	checkLinked(self, node, "InsertBefore")
	const deque: any, at: any = self, node
	const before = at[PREV]
	const fresh = { item, before, at }
	at[PREV] = fresh
	if before then
		before[NEXT] = fresh
	else
		deque.head = fresh
	end
	deque.size += 1
	return fresh :: any
end

-- `node` 를 떼어 내고 그 값을 돌려줍니다. O(1). 떼어 낸 노드는 연결이 끊깁니다 — 같은 노드를 다시 넘기면 에러.
const function Remove<T>(self: LinkedDequeData<T>, node: NodeRead<T>): T
	checkLinked(self, node, "Remove")
	const deque: any, at: any = self, node
	const before = at[PREV]
	const after = at[NEXT]
	if before then
		before[NEXT] = after
	else
		deque.head = after
	end
	if after then
		after[PREV] = before
	else
		deque.tail = before
	end
	at[PREV] = nil
	at[NEXT] = nil
	deque.size -= 1
	return at[VALUE]
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
	local cursor: any = self.head
	return function(): (NodeRead<T>, T)
		const node = cursor
		if node == nil then
			return nil :: any, nil :: any
		end
		cursor = node[NEXT]
		return node, node[VALUE]
	end
end

-- 앞에서부터 담은 새 `Arr`. 구멍은 구멍 그대로.
const function ToArr<T>(self: LinkedDequeRead<T>): Arr<T>
	const size = self.size
	const raw = table.create(size) :: any
	local at, node: any = 0, self.head
	while node ~= nil do
		at += 1
		raw[at] = node[VALUE]
		node = node[NEXT]
	end
	raw.n = size
	return Arr.Adopt(raw)
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
	local node: any = self.head
	while node ~= nil do
		PushBack(copy, node[VALUE])
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
	-- 이 종류의 타입 토큰(값의 `__type`) — 바깥 트레이트를 이 종류에 붙일 때: `MyTrait.ImplFor(LinkedDeque.Token, impl)`
	Token = TOKEN,

	Get = Get, FirstIndex = FirstIndex, LastIndex = LastIndex, NextIndex = NextIndex, PrevIndex = PrevIndex,
	PushBack = PushBack, PushFront = PushFront, PopFront = PopFront, PopBack = PopBack,
	Front = Front, Back = Back,
	InsertAfter = InsertAfter, InsertBefore = InsertBefore, Remove = Remove,
	Len = Len, Empty = Empty, Iter = Iter, ToArr = ToArr, Clear = Clear, Clone = Clone,
}

-- ⭐ **트레이트에는 넘길 것만 든 표를 등록합니다**(2026-10-13 사용자 결정, 질문 AS) — 모듈 테이블을 통째로 넘기지
-- 않습니다(같은 이름이 전부 그 트레이트의 구현이 되어, 뜻이 다른 같은 이름이 조용히 먹었음. 이제 모르는 이름은
-- `ImplFor` 가 에러로 알림). 표의 타입 주석(`X.Provided<…>` — 등록 표 타입, 기본 구현 칸은 선택)이 "구현이 계약을 만족하는가" 의
-- 정적 확인입니다 — **탐침 타입**(`Trait.A`·`Trait.B` — 서로 다른 불투명 타입)으로 적습니다: `any` 로 적으면 인자 수·인자 타입이
-- 검사되지 않았고(2라운드 리뷰), 구체 타입(`string`)으로 적으면 원소를 못박은 함수가 샙니다(2026-10-14 탐색 — 질문 AY).
-- 표는 이렇게 **주석 단 지역 변수**에 적어 넘깁니다 — `ImplFor(토큰, { … })` 처럼 표 리터럴을 바로 넘기면 검사가 안 됩니다.
const listImpl: List.Provided<LinkedDeque<A>, A, NodeRead<A>> = {
	Get = LinkedDequeModule.Get,
	FirstIndex = LinkedDequeModule.FirstIndex,
	LastIndex = LinkedDequeModule.LastIndex,
	NextIndex = LinkedDequeModule.NextIndex,
	PrevIndex = LinkedDequeModule.PrevIndex,
}
const dequeImpl: Deque.Provided<LinkedDeque<A>, A> = {
	PushFront = LinkedDequeModule.PushFront,
	PushBack = LinkedDequeModule.PushBack,
	PopFront = LinkedDequeModule.PopFront,
	PopBack = LinkedDequeModule.PopBack,
	Front = LinkedDequeModule.Front,
	Back = LinkedDequeModule.Back,
}
const collectionImpl: Collection.Provided<LinkedDeque<A>> =
	{ Len = LinkedDequeModule.Len, Clear = LinkedDequeModule.Clear }
List.ImplFor(TOKEN, listImpl)
Deque.ImplFor(TOKEN, dequeImpl)
Collection.ImplFor(TOKEN, collectionImpl)

return LinkedDequeModule

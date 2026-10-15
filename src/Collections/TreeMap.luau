--!strict
--[[
	TreeMap — 키 순서를 유지하는 맵. **자가 균형 이진 트리**(기본 레드블랙)로 조립합니다(2026-10-13).

	## 층 (`papers/07` 9-4)

	이 모듈은 3층(조립)입니다: 노드는 1층 `Node`, 구조 제어는 2층 `src/Trees/`(`RedBlack` — 뿌리 노드를 받아
	고치고 새 뿌리를 돌려주는 함수들). 여기에는 **크기·타입 토큰·키 검사·맵의 표면**만 있습니다.
	균형 방식은 고를 수 있습니다(사용자: *"default 가 있고, 직접 선택도 가능한 구조"*):

	```lua
	local m = TreeMap.New<<string, number>>(Common.compareString)        -- 레드블랙(기본)
	local a = TreeMap.New<<string, number>>(Common.compareString, stl.Avl)  -- AVL
	```

	## `FlatMap` 과 무엇이 다른가 (perf 37절)

	표면은 같습니다(같은 `Map` 트레이트, 같은 함수 이름과 뜻). `FlatMap` 은 정렬 배열(예전 `TreeMap`)이고
	이쪽은 노드 트리입니다:
	- **넣고 빼기가 섞이면 이쪽**: 넣기·지우기가 O(log n) — 정렬 배열은 뒤를 밀어 O(n)(지우고 넣기가 1만 개에서
	  4.5배, 10만 개에서 19배 차이 — perf 38-3절). `PopFirst` 도 O(log n).
	- 조회는 이쪽이 빠릅니다(약 0.5배).
	- `Keys`·`Values`(3배쯤)와 "이미 정렬된 순서로 넣기", 메모리는 `FlatMap` 이 낫습니다 — 작거나, 한 번에 지어
	  읽기만 하는 쓰임이면 `FlatMap`.

	## 표현

	```lua
	{ root: 노드?, size: number, compare: Comparator<K>, balance: 균형 방식 }
	```

	## 키

	NaN·`nil` 키는 받지 않습니다(넣기는 에러, 조회·삭제는 "없음" — `FlatMap` 과 같은 정책, conventions).
	값이 `nil` 이면 삭제입니다(`Set(m, k, nil)` — `HashMap` 과 같은 규칙).

	## 콜백·순회 중 변경

	`Retain` 의 콜백이나 `Iter` 로 도는 동안 이 맵을 바꾸면 정의되지 않은 동작입니다(conventions — 검사 없음).
]]
local Types = require("../Types")
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")
type A = Trait.A
type B = Trait.B
local Node = require("../Node")
local Search = require("../Trees/Search")
local Balance = require("../Trees/Balance")
local RedBlack = require("../Trees/RedBlack")
local Map = require("../Traits/Map")
local Collection = require("../Traits/Collection")

type Record<K, V> = Types.Record<K, V>
type Comparator<K> = Types.Comparator<K>
type Scheme = Balance.Scheme
type KeyNode<K, V> = Search.KeyNodeRead<K, V>

export type TreeMapData<K, V> = {
	-- 뿌리 노드(읽기 타입 — 연결을 고치는 것은 균형 방식만). 비었으면 `nil`.
	root: KeyNode<K, V>?,
	size: number,
	compare: Comparator<K>,
	-- 자가 균형(`Balance.Scheme` — `RedBlack`·`Avl` 모듈이 그 모양). 노드를 만든 방식과 같아야 합니다.
	balance: Scheme,
	read __type: Trait.Token<"Stl.TreeMap">,
	-- 이 종류가 구현하는 트레이트와 그 인자(질문 BA — 타입에만 있음, 읽으면 nil)
	read __traits: { read Map: Map.Assoc<K, V>, read Collection: Collection.Assoc },
}
-- 함수가 타입 바깥(네임스페이스)에 있으니 전체형은 데이터부 그 자체입니다(질문 AB).
export type TreeMap<K, V> = TreeMapData<K, V>

-- 리터럴로 둡니다 — `Trait.TYPE_KEY` 를 받아 쓰면 상수 접기가 안 돼 생성이 느려졌습니다(perf 21절).
const TYPE_KEY = "__type"
const TOKEN = Trait.NewToken("Stl.TreeMap") :: Trait.Token<"Stl.TreeMap">

-- 노드의 칸 배치(`Trees/Search` 머리 — `1` = 값, `2` = 왼쪽, `3` = 오른쪽, `5` = 키. 지역 상수라 접힘)와 도구.
-- 이 모듈 안에서는 노드를 칸으로 직접 읽으니 도구를 느슨한 타입으로 받습니다.
const VALUE, LEFT, RIGHT, KEY = 1, 2, 3, 5
const binary: any, search: any = Node.Binary, Search
const firstOf: (any) -> any, lastOf: (any) -> any = binary.First, binary.Last
const nextOf: (any) -> any, prevOf: (any) -> any = binary.Next, binary.Prev
const lowerBound: (any, any, any) -> any, upperBound: (any, any, any) -> any = search.LowerBound, search.UpperBound

const function unusable(key: any): boolean
	return key == nil or key ~= key
end

const function rejectKey(key: any): never
	return Common.raise(if key == nil then "TreeMap: nil key" else "TreeMap: NaN key")
end

--#region ----------- 계약 구현 (Map.Core) -----------
-- 이 모듈 테이블이 그대로 `Map.Core` 구현체입니다(질문 AB).

-- 키의 노드. 없으면 `nil`. 뜨거운 길이라 `Search.Find` 를 거치지 않고 여기서 따라갑니다(호출 하나).
const function nodeOf<K, V>(self: TreeMapData<K, V>, key: K): any
	const compare = self.compare
	local cursor: any = self.root
	while cursor ~= nil do
		const order = compare(key, cursor[KEY])
		if order == 0 then
			return cursor
		end
		cursor = if order < 0 then cursor[LEFT] else cursor[RIGHT]
	end
	return nil
end

const function Get<K, V>(self: TreeMapData<K, V>, key: K): V?
	if unusable(key) then
		return nil
	end
	const node = nodeOf(self, key)
	return if node ~= nil then node[VALUE] else nil
end

-- 지우고 값을 돌려줍니다(키 검사는 부른 쪽이).
const function removeNode<K, V>(self: TreeMapData<K, V>, node: any): V
	self.root = (self.balance :: any).Remove(self.root, node)
	self.size -= 1
	return node[VALUE]
end

-- 값을 넣습니다. 이미 있으면 덮어씁니다. O(log n).
-- ⭐ **값이 `nil` 이면 삭제입니다** — `HashMap`·`FlatMap` 과 같은 규칙이고 Lua 의 `t[k] = nil` 과 같습니다.
const function Set<K, V>(self: TreeMapData<K, V>, key: K, value: V): ()
	if unusable(key) then
		rejectKey(key)
	end
	if value == nil then
		const node = nodeOf(self, key)
		if node ~= nil then
			removeNode(self, node)
		end
		return
	end
	const root, _, isNew = (self.balance :: any).Insert(self.root, key, value, self.compare)
	self.root = root
	if isNew then
		self.size += 1
	end
end

const function Has<K, V>(self: TreeMapData<K, V>, key: K): boolean
	return not unusable(key) and nodeOf(self, key) ~= nil
end

-- 키를 지우고 **지워진 값**을 돌려줍니다. 없었으면 `nil`. O(log n).
const function Remove<K, V>(self: TreeMapData<K, V>, key: K): V?
	if unusable(key) then
		return nil
	end
	const node = nodeOf(self, key)
	if node == nil then
		return nil
	end
	return removeNode(self, node)
end

-- 키 순서로 `(key, value)`: `for key, value in TreeMap.Iter(m) do`. 상태는 클로저에 담습니다(`Iter()` 한 번에
-- 클로저 하나). `(K, V)` 비옵셔널 선언인 것은 `ipairs` 와 같은 이유입니다.
const function Iter<K, V>(self: TreeMapData<K, V>): () -> (K, V)
	const root = self.root
	local cursor = if root ~= nil then firstOf(root :: any) :: any else nil
	return function(): (K, V)
		const node = cursor
		if node == nil then
			return nil :: any, nil :: any
		end
		cursor = nextOf(node)
		return node[KEY], node[VALUE]
	end
end

--#endregion

--#region ----------- 조회 -----------

const function GetOr<K, V>(self: TreeMapData<K, V>, key: K, fallback: V): V
	const value = Get(self, key)
	-- (`if … then fallback else value` 는 0.742 의 솔버가 `(V & ~nil) | V` 를 V 로 줄이지 못했음)
	if value ~= nil then
		return value
	end
	return fallback
end

const function Len<K, V>(self: TreeMapData<K, V>): number
	return self.size
end

const function Empty<K, V>(self: TreeMapData<K, V>): boolean
	return self.size == 0
end

-- 키-값 쌍의 목록. **키 순서이고, 레코드는 새로 만든 것**입니다(받은 쪽이 고쳐도 맵은 그대로).
const function Records<K, V>(self: TreeMapData<K, V>): { Record<K, V> }
	const out = table.create(self.size) :: { Record<K, V> }
	const root = self.root
	local at, node: any = 0, if root ~= nil then firstOf(root :: any) else nil
	while node ~= nil do
		at += 1
		out[at] = { key = node[KEY], value = node[VALUE] }
		node = nextOf(node)
	end
	return out
end

-- 키만, **키 순서로**.
const function Keys<K, V>(self: TreeMapData<K, V>): { K }
	const out = table.create(self.size) :: { K }
	const root = self.root
	local at, node: any = 0, if root ~= nil then firstOf(root :: any) else nil
	while node ~= nil do
		at += 1
		out[at] = node[KEY]
		node = nextOf(node)
	end
	return out
end

-- 값만, 키 순서로.
const function Values<K, V>(self: TreeMapData<K, V>): { V }
	const out = table.create(self.size) :: { V }
	const root = self.root
	local at, node: any = 0, if root ~= nil then firstOf(root :: any) else nil
	while node ~= nil do
		at += 1
		out[at] = node[VALUE]
		node = nextOf(node)
	end
	return out
end

-- 가장 작은 키의 쌍(새 레코드). 비어 있으면 `nil`.
const function First<K, V>(self: TreeMapData<K, V>): Record<K, V>?
	const root = self.root
	if root == nil then
		return nil
	end
	const node: any = firstOf(root :: any)
	return { key = node[KEY], value = node[VALUE] }
end

-- 가장 큰 키의 쌍. 비어 있으면 `nil`.
const function Last<K, V>(self: TreeMapData<K, V>): Record<K, V>?
	const root = self.root
	if root == nil then
		return nil
	end
	const node: any = lastOf(root :: any)
	return { key = node[KEY], value = node[VALUE] }
end

-- `key` **이상**인 키 중 가장 작은 것. 없으면 `nil`.
const function CeilingKey<K, V>(self: TreeMapData<K, V>, key: K): K?
	if unusable(key) then
		return nil
	end
	const node = lowerBound(self.root, key, self.compare)
	return if node ~= nil then node[KEY] else nil
end

-- `key` 보다 **큰** 키 중 가장 작은 것(엄격). 없으면 `nil`.
const function HigherKey<K, V>(self: TreeMapData<K, V>, key: K): K?
	if unusable(key) then
		return nil
	end
	const node = upperBound(self.root, key, self.compare)
	return if node ~= nil then node[KEY] else nil
end

-- `bound`(어떤 경계의 첫 노드 — 없으면 끝을 넘은 것)의 바로 앞 노드의 키.
const function keyBefore<K, V>(self: TreeMapData<K, V>, bound: any): K?
	const root = self.root
	if root == nil then
		return nil
	end
	const node: any = if bound ~= nil then prevOf(bound :: any) else lastOf(root :: any)
	return if node ~= nil then node[KEY] else nil
end

-- `key` **이하**인 키 중 가장 큰 것. 없으면 `nil`.
const function FloorKey<K, V>(self: TreeMapData<K, V>, key: K): K?
	if unusable(key) then
		return nil
	end
	return keyBefore(self, upperBound(self.root, key, self.compare))
end

-- `key` 보다 **작은** 키 중 가장 큰 것(엄격). 없으면 `nil`.
-- ⚠️ Java `NavigableMap` 의 어휘입니다(`Floor`·`Ceiling`·`Lower`·`Higher`) — 트리부·`BSearch` 의 `LowerBound`(C++ 어휘:
-- **이상**인 첫 것)와 `Lower` 가 반대 뜻입니다.
const function LowerKey<K, V>(self: TreeMapData<K, V>, key: K): K?
	if unusable(key) then
		return nil
	end
	return keyBefore(self, lowerBound(self.root, key, self.compare))
end

-- 키 구간 `[fromKey, toKey]` 의 쌍들. **양끝 포함**이고 키 순서입니다. 구간이 뒤집혀 있으면 빈 목록
-- (이 저장소의 구간 규약). O(log n + 결과 수).
const function RangeRecords<K, V>(self: TreeMapData<K, V>, fromKey: K, toKey: K): { Record<K, V> }
	const out: { Record<K, V> } = {}
	if unusable(fromKey) or unusable(toKey) then
		return out
	end
	const compare = self.compare
	local at, node: any = 0, lowerBound(self.root, fromKey, compare)
	while node ~= nil and compare(node[KEY], toKey) <= 0 do
		at += 1
		out[at] = { key = node[KEY], value = node[VALUE] }
		node = nextOf(node)
	end
	return out
end

--#endregion

--#region ----------- 변형 -----------

-- 가장 작은 키의 쌍을 **꺼냅니다**. 비었으면 `nil`. O(log n).
const function PopFirst<K, V>(self: TreeMapData<K, V>): Record<K, V>?
	const root = self.root
	if root == nil then
		return nil
	end
	const node: any = firstOf(root :: any)
	const record = { key = node[KEY], value = node[VALUE] }
	removeNode(self, node)
	return record
end

-- 가장 큰 키의 쌍을 꺼냅니다. O(log n).
const function PopLast<K, V>(self: TreeMapData<K, V>): Record<K, V>?
	const root = self.root
	if root == nil then
		return nil
	end
	const node: any = lastOf(root :: any)
	const record = { key = node[KEY], value = node[VALUE] }
	removeNode(self, node)
	return record
end

-- 조건을 만족하는 쌍만 **남깁니다**(제자리, 키 순서로 부름). 콜백은 `(key, value)`. 자기 자신을 돌려줍니다.
-- ⚠️ Java `retainAll` 과 달리 술어를 받습니다(질문 W).
-- ⚠️ 콜백 안에서 이 맵을 바꾸면 정의되지 않은 동작입니다(질문 AL 1). 지울 것은 `false` 로 돌려주세요.
const function Retain<K, V>(self: TreeMapData<K, V>, fn: (key: K, value: V) -> boolean): TreeMap<K, V>
	const root = self.root
	local node: any = if root ~= nil then firstOf(root :: any) else nil
	while node ~= nil do
		-- 지우기가 회전으로 길을 바꾸니 다음 노드를 먼저 읽습니다(다음 노드 자체는 남음)
		const after = nextOf(node)
		if not fn(node[KEY], node[VALUE]) then
			removeNode(self, node)
		end
		node = after
	end
	return self
end

-- 비우고 **자기 자신을 돌려줍니다**. O(1).
const function Clear<K, V>(self: TreeMapData<K, V>): TreeMap<K, V>
	self.root = nil
	self.size = 0
	return self
end

const function newMap<K, V>(root: any, size: number, compare: Comparator<K>, balance: Scheme): TreeMap<K, V>
	return { root = root, size = size, compare = compare, balance = balance, [TYPE_KEY] = TOKEN } :: any
end

-- 얕은 복사(노드는 새로, 키·값은 같은 것 — 구조째 베껴 O(n)). 비교자와 균형 방식은 같은 것.
const function Clone<K, V>(self: TreeMapData<K, V>): TreeMap<K, V>
	return newMap((self.balance :: any).Clone(self.root), self.size, self.compare, self.balance)
end

--#region ----------- 가르기·잇기 -----------
-- 균형 방식의 `Join` 과 그 위의 `Balance.Split`(2층)을 조립합니다 — 노드를 새로 만들지 않고 다시 잇습니다.

-- 두 트리를 **번갈아 한 걸음씩** 세다가 먼저 끝나는 쪽으로 `high` 의 노드 수를 정합니다(전체 `total` 을 알고 있음).
-- 노드에 부분 크기를 두지 않아(넣기 1.1~1.3배·지우기 1.5~2배 — perf 45절) 세어야 하는데, 작은 쪽만큼만 셉니다.
const function countHigh(low: any, high: any, total: number): number
	local lowAt: any = if low ~= nil then firstOf(low) else nil
	local highAt: any = if high ~= nil then firstOf(high) else nil
	local counted = 0
	while true do
		if lowAt == nil then
			return total - counted
		elseif highAt == nil then
			return counted
		end
		counted += 1
		lowAt = nextOf(lowAt)
		highAt = nextOf(highAt)
	end
end

-- **`key` 이상인 키들을 떼어 새 맵으로** 돌려줍니다. 이 맵에는 `key` 미만만 남습니다(Rust `split_off`).
-- O(log n + 작은 쪽의 크기) — 노드를 새로 만들지 않고 다시 잇습니다(쥐고 있던 노드는 둘 중 한 맵에 살아 있음).
-- 새 맵은 같은 비교자·균형 방식. `key` 가 맵에 없어도 됩니다(그 자리에서 가름). `nil`·NaN 키는 에러.
-- 비교자가 도중에 던지면 이 맵은 그대로입니다(관측 — 계약은 아님: 비교를 다 한 뒤에 고치기 시작함).
const function SplitOff<K, V>(self: TreeMapData<K, V>, key: K): TreeMap<K, V>
	if unusable(key) then
		rejectKey(key)
	end
	const scheme: any = self.balance
	const low, found, rest = Balance.Split(scheme, self.root :: any, key, self.compare)
	const high = if found ~= nil then scheme.Join(nil, found, rest) else rest
	const total = self.size
	const moved = countHigh(low, high, total)
	self.root = low
	self.size = total - moved
	return newMap(high, moved, self.compare, self.balance)
end

-- **`other` 의 전부를 이 맵 뒤에 잇고** 이 맵을 돌려줍니다 — `other` 의 모든 키가 이 맵의 모든 키보다 커야 합니다
-- (아니면 에러: 겹치는 맵을 합치는 것은 `Merge`). `other` 는 빈 맵이 됩니다(노드가 이쪽으로 옮겨 옴).
-- O(log n) — 원소를 하나씩 옮기지 않습니다. 두 맵은 같은 비교자·같은 균형 방식이어야 합니다.
const function Join<K, V>(self: TreeMapData<K, V>, other: TreeMapData<K, V>): TreeMap<K, V>
	-- 첫 인자도 봅니다(표면이 같은 Tree/Flat 을 섞기 쉬움 — 예전엔 라이브러리 줄의 원시 에러이거나 엉뚱한 메시지, 5라운드 리뷰)
	const mine: any = self
	if type(mine) ~= "table" or rawget(mine, TYPE_KEY) ~= TOKEN then
		const kind = Trait.TokenOf(mine)
		Common.raise(`TreeMap: Join needs a TreeMap, got {if kind then kind.name else typeof(mine)}`)
	end
	const rest: any = other
	if type(rest) ~= "table" or rawget(rest, TYPE_KEY) ~= TOKEN then
		const kind = Trait.TokenOf(rest)
		Common.raise(`TreeMap: Join needs another TreeMap, got {if kind then kind.name else typeof(rest)}`)
	end
	if rest == self then
		Common.raise("TreeMap: Join needs two different maps")
	end
	if self.compare ~= rest.compare then
		Common.raise("TreeMap: maps use different comparators")
	end
	if self.balance ~= rest.balance then
		Common.raise("TreeMap: maps use different balance schemes")
	end
	const high: any = rest.root
	if high == nil then
		return self :: any
	end
	const low: any = self.root
	const scheme: any = self.balance
	if low == nil then
		self.root = high
	else
		const first = firstOf(high)
		if self.compare(lastOf(low)[KEY], first[KEY]) >= 0 then
			Common.raise("TreeMap: Join needs every key of the second map to be greater than every key of the first")
		end
		-- 뒤쪽의 가장 작은 노드를 떼어 가운데 노드로 씁니다
		self.root = scheme.Join(low, first, scheme.Remove(high, first))
	end
	self.size += rest.size
	rest.root = nil
	rest.size = 0
	return self :: any
end

--#endregion

--#endregion

--#region ----------- 생성자 -----------

-- ⚠️ **값 타입을 직접 알려줘야 합니다**(비교자에서 `K` 는 뽑히지만 `V` 는 나올 자리가 없음):
--
--     local m = TreeMap.New<<number, string>>(Common.compareNumber)
--
-- `balance` 는 자가 균형 방식(선택 — 기본 레드블랙). `stl.Avl` 이나 `Balance.Scheme` 모양의 바깥 구현.
const function New<K, V>(compare: Comparator<K>, balance: Scheme?): TreeMap<K, V>
	Common.expectComparator(compare, "TreeMap: New")
	return newMap(nil, 0, compare, Balance.Expect(balance, RedBlack, "TreeMap: New"))
end

-- 키-값 쌍 목록에서 만듭니다. **정렬해서 한 번에 짓고(O(n log n) 정렬 + O(n) 짓기) 중복 키는 뒤엣것이
-- 이깁니다.** 마지막 값이 `nil` 인 키는 없는 것으로 봅니다(`Set` 과 같은 규칙).
-- 동점(비교자가 0 을 돌려주는 두 키)에서 뒤엣것이 이기도록 원래 위치를 타이브레이커로 씁니다(`table.sort`
-- 는 안정 정렬이 아님).
const function FromRecords<K, V>(source: { Record<K, V> }, compare: Comparator<K>, balance: Scheme?): TreeMap<K, V>
	Common.expectComparator(compare, "TreeMap: FromRecords")
	const scheme = Balance.Expect(balance, RedBlack, "TreeMap: FromRecords")
	-- 길이는 `Common.listLength` 규약(`n` 우선, 구멍은 건너뜀).
	const records, count = Common.denseList(source)
	if count == 0 then
		return newMap(nil, 0, compare, scheme)
	end
	const order = table.create(count) :: { number }
	for idx = 1, count do
		if unusable(records[idx].key) then
			rejectKey(records[idx].key)
		end
		order[idx] = idx
	end
	table.sort(order, function(x: number, y: number): boolean
		const diff = compare(records[x].key, records[y].key)
		if diff ~= 0 then
			return diff < 0
		end
		return x < y
	end)
	const keys = table.create(count) :: { K }
	const values = table.create(count) :: { V }
	local size = 0
	for pos = 1, count do
		const rec = records[order[pos]]
		-- 같은 키가 이어지면 뒤엣것으로 덮어씁니다.
		if size == 0 or compare(keys[size], rec.key) ~= 0 then
			size += 1
		end
		keys[size] = rec.key
		values[size] = rec.value
	end
	-- 마지막 값이 nil 인 키는 뺍니다.
	local kept = 0
	for pos = 1, size do
		if values[pos] ~= nil then
			kept += 1
			keys[kept] = keys[pos]
			values[kept] = values[pos]
		end
	end
	return newMap((scheme :: any).FromSorted(keys, values, kept), kept, compare, scheme)
end

-- ⚠️ **검사 없이 짓기**: 이미 **키 순서로 정렬돼 있고 중복·NaN·`nil` 키가 없는** 목록(`keys[i]`·`values[i]`,
-- `1..count`)에서 O(n) 으로 짓습니다. **검사하지 않습니다** — 호출자 책임입니다. `FlatMap.Adopt`·`HashMap.Adopt` 와
-- 닮은 것은 "전제를 믿는다" 까지입니다: 저쪽은 넘긴 테이블을 **그대로 가집니다**(입양), 여기는 목록을 읽어 노드를
-- **새로 만듭니다**(넘긴 목록은 그대로 호출자의 것).
-- `TreeSet` 의 집합 연산처럼 병합 결과가 이미 정렬된 자리를 위한 문이고, 일반 사용자는 `FromRecords` 를 쓰세요.
const function FromSorted<K, V>(
	keys: { K },
	values: { V },
	count: number,
	compare: Comparator<K>,
	balance: Scheme?
): TreeMap<K, V>
	Common.expectComparator(compare, "TreeMap: FromSorted")
	const scheme = Balance.Expect(balance, RedBlack, "TreeMap: FromSorted")
	return newMap((scheme :: any).FromSorted(keys, values, count), count, compare, scheme)
end

const function isTreeMap(value: any): boolean
	return type(value) == "table" and rawget(value, TYPE_KEY) == TOKEN
end

--#endregion

-- stylua: ignore
const TreeMapModule = {
	New = New,
	FromRecords = FromRecords,
	FromSorted = FromSorted,
	isTreeMap = isTreeMap,
	-- 이 종류의 타입 토큰(값의 `__type`) — 바깥 트레이트를 이 종류에 붙일 때: `MyTrait.ImplFor(TreeMap.Token, impl)`
	Token = TOKEN,

	Has = Has, GetOr = GetOr, Len = Len, Empty = Empty, Keys = Keys, Values = Values, Iter = Iter,
	First = First, Last = Last, FloorKey = FloorKey, CeilingKey = CeilingKey,
	RangeRecords = RangeRecords, Remove = Remove, Clear = Clear, Clone = Clone, Get = Get, Set = Set,
	Records = Records,
	LowerKey = LowerKey, HigherKey = HigherKey, PopFirst = PopFirst, PopLast = PopLast, Retain = Retain,
	SplitOff = SplitOff, Join = Join,
}

-- ⭐ **트레이트에는 넘길 것만 든 표를 등록합니다**(2026-10-13 사용자 결정, 질문 AS) — 모듈 테이블을 통째로 넘기지
-- 않습니다(같은 이름이 전부 그 트레이트의 구현이 되어, 뜻이 다른 같은 이름이 조용히 먹었음. 이제 모르는 이름은
-- `ImplFor` 가 에러로 알림). 표의 타입 주석(`X.Provided<…>` — 등록 표 타입, 기본 구현 칸은 선택)이 "구현이 계약을 만족하는가" 의
-- 정적 확인입니다 — **탐침 타입**(`Trait.A`·`Trait.B` — 서로 다른 불투명 타입)으로 적습니다: `any` 로 적으면 인자 수·인자 타입이
-- 검사되지 않았고(2라운드 리뷰), 구체 타입(`string`)으로 적으면 원소를 못박은 함수가 샙니다(2026-10-14 탐색 — 질문 AY).
-- 표는 이렇게 **주석 단 지역 변수**에 적어 넘깁니다 — `ImplFor(토큰, { … })` 처럼 표 리터럴을 바로 넘기면 검사가 안 됩니다.
const mapImpl: Map.Provided<TreeMap<A, B>, A, B> = {
	Get = TreeMapModule.Get,
	Set = TreeMapModule.Set,
	Has = TreeMapModule.Has,
	Remove = TreeMapModule.Remove,
	Iter = TreeMapModule.Iter,
}
const collectionImpl: Collection.Provided<TreeMap<A, B>> = { Len = TreeMapModule.Len, Clear = TreeMapModule.Clear }
Map.ImplFor(TOKEN, mapImpl)
Collection.ImplFor(TOKEN, collectionImpl)

return TreeMapModule

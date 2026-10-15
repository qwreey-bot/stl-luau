--!strict
--[[
	TreeSet — 원소 순서를 유지하는 셋. **노드 기반 `TreeMap` 위에 얹습니다**(2026-10-13 — 기본 레드블랙).

	`FlatSet`(정렬 배열 — 예전 `TreeSet`)과 **같은 표면**입니다(같은 `Set` 트레이트, 같은 함수 이름과 뜻).
	넣고 빼기가 섞이면 이쪽(O(log n)), 작거나 한 번에 지어 읽기만 하면 `FlatSet` — `TreeMap`/`FlatMap` 과
	같은 기준입니다(perf 37절). 의존은 **TreeSet → TreeMap 한 방향**이고, 이 모듈이 자기 맵의 주인이라
	노드를 바로 따라갑니다(순회·집합 연산에서 중간 배열을 만들지 않음).

	```lua
	local s = TreeSet.New<<number>>(Common.compareNumber)             -- 레드블랙(기본)
	local a = TreeSet.FromList({ 3, 1, 2 }, Common.compareNumber, stl.Avl)
	```

	NaN·`nil` 원소는 받지 않습니다(넣기는 에러, 조회·삭제는 "없음"). 집합 연산은 **두 셋의 비교자가 같은
	함수**여야 합니다(다르면 병합이 뜻을 잃어 에러) — `Common.compareNumber` 처럼 같은 함수를 나눠 쓰세요.
	콜백(`Retain`)이나 순회 중에 이 셋을 바꾸면 정의되지 않은 동작입니다(conventions).
]]
local Types = require("../Types")
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")
type A = Trait.A
local Node = require("../Node")
local Search = require("../Trees/Search")
local Balance = require("../Trees/Balance")
local Set = require("../Traits/Set")
local Collection = require("../Traits/Collection")
local RedBlack = require("../Trees/RedBlack")
local TreeMap = require("./TreeMap")

type Comparator<T> = Types.Comparator<T>
type Scheme = Balance.Scheme
type TreeMapType<K, V> = TreeMap.TreeMap<K, V>

export type TreeSetData<T> = {
	map: TreeMapType<T, true>,
	read __type: Trait.Token<"Stl.TreeSet">,
	-- 이 종류가 구현하는 트레이트와 그 인자(질문 BA — 타입에만 있음, 읽으면 nil)
	read __traits: { read Set: Set.Assoc<T>, read Collection: Collection.Assoc },
}
-- 함수가 타입 바깥(네임스페이스)에 있으니 전체형은 데이터부 그 자체입니다(질문 AB).
export type TreeSet<T> = TreeSetData<T>

-- 리터럴로 둡니다 — `Trait.TYPE_KEY` 를 받아 쓰면 상수 접기가 안 돼 생성이 느려졌습니다(perf 21절).
const TYPE_KEY = "__type"
-- 이 종류 = 닫힌 트레이트(질문 BB): 맨 위에서 만들고 맨 끝에서 모듈 표를 봉인 — 그 표가 곧 `stl.TreeSet`(종류의 정체).
const Kind = Trait.Struct("Stl.TreeSet")
const TOKEN = Kind.Token -- 안쪽에서만(생성자가 `__type` 에 찍는 상수)

-- 노드의 칸 배치(`Trees/Search` 머리 — `5` = 키. 지역 상수라 접힘)와 도구(이 모듈 안에서는 칸으로 직접 읽음).
const KEY = 5
const binary: any, search: any = Node.Binary, Search
const firstOf: (any) -> any, lastOf: (any) -> any, nextOf: (any) -> any = binary.First, binary.Last, binary.Next
const lowerBound: (any, any, any) -> any = search.LowerBound

const function wrap<T>(map: TreeMapType<T, true>): TreeSet<T>
	return { map = map, [TYPE_KEY] = TOKEN } :: any
end

-- 맵의 첫 노드(없으면 `nil`). 순회·집합 연산이 여기서 `Node.Binary.Next` 로 따라갑니다.
const function firstNode(map: any): any
	const root = map.root
	return if root ~= nil then firstOf(root) else nil
end

--#region ----------- 계약 구현 (Set.Core) -----------
-- 이 모듈 테이블이 그대로 `Set.Core` 구현체입니다(질문 AB).

-- 원소를 넣습니다. **새로 들어갔으면 `true`**, 이미 있었으면 `false`. O(log n).
-- NaN·`nil` 은 받지 않습니다. 여기서 먼저 봅니다 — 맡기면 메시지가 `TreeMap: NaN key` 로 나와, 사용자가 부른
-- 적 없는 모듈 이름이 나옵니다.
const function Add<T>(self: TreeSetData<T>, item: T): boolean
	if item == nil or item ~= item then
		Common.raise(if item == nil then "TreeSet: nil item" else "TreeSet: NaN item")
	end
	const map = self.map
	const before = map.size
	TreeMap.Set(map, item, true :: true)
	return map.size > before
end

const function Has<T>(self: TreeSetData<T>, item: T): boolean
	return TreeMap.Has(self.map, item)
end

const function Remove<T>(self: TreeSetData<T>, item: T): boolean
	return TreeMap.Remove(self.map, item) ~= nil
end

-- 원소를 모은 배열. **정렬 순서입니다.**
const function Items<T>(self: TreeSetData<T>): { T }
	return TreeMap.Keys(self.map)
end

--#endregion

--#region ----------- 조회 -----------

const function Len<T>(self: TreeSetData<T>): number
	return self.map.size
end

const function Empty<T>(self: TreeSetData<T>): boolean
	return self.map.size == 0
end

-- `for item in TreeSet.Iter(set) do … end` 또는 `for _, item in …` — **정렬 순서로**. 원소를 두 자리 모두에
-- 돌려주고 상태는 클로저에 담습니다(`HashSet`·`FlatSet` 과 바꿔 끼울 수 있음).
const function Iter<T>(self: TreeSetData<T>): () -> (T, T)
	local cursor: any = firstNode(self.map)
	return function(): (T, T)
		const node = cursor
		if node == nil then
			return nil :: any, nil :: any
		end
		cursor = nextOf(node)
		return node[KEY], node[KEY]
	end
end

-- 가장 작은 원소. 비어 있으면 `nil`.
const function First<T>(self: TreeSetData<T>): T?
	const node = firstNode(self.map)
	return if node ~= nil then node[KEY] else nil
end

-- 가장 큰 원소. 비어 있으면 `nil`.
const function Last<T>(self: TreeSetData<T>): T?
	const root: any = self.map.root
	if root == nil then
		return nil
	end
	const node: any = lastOf(root)
	return node[KEY]
end

-- `item` **이하**인 원소 중 가장 큰 것.
const function FloorItem<T>(self: TreeSetData<T>, item: T): T?
	return TreeMap.FloorKey(self.map, item)
end

-- `item` **이상**인 원소 중 가장 작은 것.
const function CeilingItem<T>(self: TreeSetData<T>, item: T): T?
	return TreeMap.CeilingKey(self.map, item)
end

-- `item` 보다 **작은** 원소 중 가장 큰 것(엄격 — `FloorItem` 은 같은 원소도 줌).
const function LowerItem<T>(self: TreeSetData<T>, item: T): T?
	return TreeMap.LowerKey(self.map, item)
end

-- `item` 보다 **큰** 원소 중 가장 작은 것(엄격 — `CeilingItem` 은 같은 원소도 줌).
const function HigherItem<T>(self: TreeSetData<T>, item: T): T?
	return TreeMap.HigherKey(self.map, item)
end

-- 구간 `[from, to]` 의 원소들. **양끝 포함**, 정렬 순서. 뒤집히면 빈 목록. O(log n + 결과 수).
const function RangeItems<T>(self: TreeSetData<T>, from: T, to: T): { T }
	const out: { T } = {}
	-- 비교에는 걸러 내기 전의 이름으로(0.742 의 솔버가 `~= nil`·`~= to` 로 좁힌 `to` 를 T 로 안 받았음)
	const upper: T = to
	if from == nil or from ~= from or to == nil or to ~= to then
		return out
	end
	const map = self.map
	const compare = map.compare
	local at, node: any = 0, lowerBound(map.root, from, compare)
	while node ~= nil and compare(node[KEY], upper) <= 0 do
		at += 1
		out[at] = node[KEY]
		node = nextOf(node)
	end
	return out
end

--#endregion

--#region ----------- 변형 -----------

-- 비우고 **자기 자신을 돌려줍니다**. O(1).
const function Clear<T>(self: TreeSetData<T>): TreeSet<T>
	TreeMap.Clear(self.map)
	return self
end

-- 가장 작은 원소를 **꺼냅니다**. 비었으면 `nil`. O(log n).
const function PopFirst<T>(self: TreeSetData<T>): T?
	const record = TreeMap.PopFirst(self.map)
	return if record ~= nil then record.key else nil
end

-- 가장 큰 원소를 꺼냅니다. O(log n).
const function PopLast<T>(self: TreeSetData<T>): T?
	const record = TreeMap.PopLast(self.map)
	return if record ~= nil then record.key else nil
end

-- 조건을 만족하는 원소만 **남깁니다**(제자리, 정렬 순서로 부름). ⚠️ Java `retainAll` 과 달리 술어를 받습니다
-- (질문 W). 콜백 안에서 이 셋을 바꾸면 정의되지 않은 동작입니다(질문 AL 1). 자기 맵의 노드를 직접 훑습니다
-- (`TreeMap.Retain` 에 클로저 한 겹을 끼우지 않으려고).
const function Retain<T>(self: TreeSetData<T>, fn: (item: T) -> boolean): TreeSet<T>
	const map: any = self.map
	local node: any = firstNode(map)
	while node ~= nil do
		-- 지우기가 회전으로 길을 바꾸니 다음 노드를 먼저 읽습니다
		const after = nextOf(node)
		if not fn(node[KEY]) then
			map.root = (map.balance :: any).Remove(map.root, node)
			map.size -= 1
		end
		node = after
	end
	return self
end

const function Clone<T>(self: TreeSetData<T>): TreeSet<T>
	return wrap(TreeMap.Clone(self.map))
end

-- **`item` 이상인 원소들을 떼어 새 셋으로** 돌려줍니다(이 셋에는 미만만 남음). O(log n + 작은 쪽) — `TreeMap.SplitOff`.
const function SplitOff<T>(self: TreeSetData<T>, item: T): TreeSet<T>
	if item == nil or item ~= item then
		Common.raise(if item == nil then "TreeSet: nil item" else "TreeSet: NaN item")
	end
	return wrap(TreeMap.SplitOff(self.map, item))
end

-- **`other` 의 전부를 이 셋 뒤에 잇고** 이 셋을 돌려줍니다 — `other` 의 모든 원소가 이 셋의 모든 원소보다 커야 합니다.
-- `other` 는 빈 셋이 됩니다. O(log n). 같은 비교자·같은 균형 방식.
const function Join<T>(self: TreeSetData<T>, other: TreeSetData<T>): TreeSet<T>
	-- 첫 인자도 봅니다(표면이 같은 Tree/Flat 을 섞기 쉬움 — 예전엔 라이브러리 줄의 원시 에러이거나 엉뚱한 메시지, 5라운드 리뷰)
	const mine: any = self
	if type(mine) ~= "table" or rawget(mine, TYPE_KEY) ~= TOKEN then
		const kind = Trait.TokenOf(mine)
		Common.raise(`TreeSet: Join needs a TreeSet, got {if kind then kind.name else typeof(mine)}`)
	end
	const rest: any = other
	if type(rest) ~= "table" or rawget(rest, TYPE_KEY) ~= TOKEN then
		const kind = Trait.TokenOf(rest)
		Common.raise(`TreeSet: Join needs another TreeSet, got {if kind then kind.name else typeof(rest)}`)
	end
	const selfMap: any, restMap: any = self.map, rest.map
	if rest == self then
		Common.raise("TreeSet: Join needs two different sets")
	end
	if selfMap.compare ~= restMap.compare then
		Common.raise("TreeSet: sets use different comparators")
	end
	if selfMap.balance ~= restMap.balance then
		Common.raise("TreeSet: sets use different balance schemes")
	end
	const low: any, high: any = selfMap.root, restMap.root
	if low ~= nil and high ~= nil and selfMap.compare(search.Last(low)[KEY], search.First(high)[KEY]) >= 0 then
		Common.raise("TreeSet: Join needs every item of the second set to be greater than every item of the first")
	end
	TreeMap.Join(selfMap, restMap)
	return self :: any
end

--#endregion

--#region ----------- 집합 연산 — 두 트리를 순서대로 나란히 훑는 병합 -----------
-- 두 셋의 노드를 중위 순서로 한 번씩 따라가 **정렬된 결과**를 모으고, 그것으로 새 트리를 O(n) 에 짓습니다
-- (`TreeMap.FromSorted`). 그래서 전부 O(n + m) 이고 결과는 완전히 균형 잡힌 트리입니다.
--
-- ⭐ **두 셋의 비교자가 같은 함수여야 합니다.** 다르면 병합이 뜻을 잃고 결과가 불변식이 깨진 셋이 됩니다.
-- 같은지 한 번 보는 값은 거의 0 이라 막습니다 — 뜻이 같은 비교자라도 **다른 함수 값**이면 에러입니다.
const function sameOrder<T>(a: TreeSetData<T>, b: TreeSetData<T>)
	-- 상대가 같은 종류인지 먼저(타입 없는 코드 — 표면이 같은 `FlatSet` 을 섞으면 `map.root` 가 없어 **빈 셋으로
	-- 읽혀** `Union` 이 한쪽만 돌려주고 `IsDisjointFrom` 이 참이었습니다, 리뷰)
	-- **첫 인자도** 봅니다(2라운드 리뷰 — 둘째만 보던 때는 섞인 쪽이 첫 인자면 그대로 통과했음. 다른 함수들은
	-- 첫 인자의 종류를 검사하지 않지만, 여기는 두 인자가 대칭이고 검사가 이미 도는 자리입니다)
	if type(a) ~= "table" or rawget(a :: any, TYPE_KEY) ~= TOKEN then
		const kind = Trait.TokenOf(a)
		Common.raise(`TreeSet: set operations need a TreeSet, got {if kind then kind.name else typeof(a)}`)
	end
	if type(b) ~= "table" or rawget(b :: any, TYPE_KEY) ~= TOKEN then
		const kind = Trait.TokenOf(b)
		Common.raise(`TreeSet: set operations need another TreeSet, got {if kind then kind.name else typeof(b)}`)
	end
	if a.map.compare ~= b.map.compare then
		Common.raise("TreeSet: sets use different comparators")
	end
end

-- 정렬된 원소 목록에서 셋을(`self` 의 비교자·균형 방식을 물려받음).
const function fromSortedItems<T>(self: TreeSetData<T>, items: { T }, count: number): TreeSet<T>
	const map = self.map
	return wrap(TreeMap.FromSorted(items, table.create(count, true :: true), count, map.compare, map.balance))
end

-- 합집합. O(n + m).
const function Union<T>(self: TreeSetData<T>, other: TreeSetData<T>): TreeSet<T>
	sameOrder(self, other)
	const compare = self.map.compare
	const out = table.create(self.map.size + other.map.size) :: { T }
	local count, a: any, b: any = 0, firstNode(self.map), firstNode(other.map)
	while a ~= nil and b ~= nil do
		const diff = compare(a[KEY], b[KEY])
		count += 1
		if diff < 0 then
			out[count] = a[KEY]
			a = nextOf(a)
		elseif diff > 0 then
			out[count] = b[KEY]
			b = nextOf(b)
		else
			out[count] = a[KEY]
			a = nextOf(a)
			b = nextOf(b)
		end
	end
	while a ~= nil do
		count += 1
		out[count] = a[KEY]
		a = nextOf(a)
	end
	while b ~= nil do
		count += 1
		out[count] = b[KEY]
		b = nextOf(b)
	end
	return fromSortedItems(self, out, count)
end

-- 교집합. O(n + m).
const function Intersect<T>(self: TreeSetData<T>, other: TreeSetData<T>): TreeSet<T>
	sameOrder(self, other)
	const compare = self.map.compare
	const out: { T } = {}
	local count, a: any, b: any = 0, firstNode(self.map), firstNode(other.map)
	while a ~= nil and b ~= nil do
		const diff = compare(a[KEY], b[KEY])
		if diff < 0 then
			a = nextOf(a)
		elseif diff > 0 then
			b = nextOf(b)
		else
			count += 1
			out[count] = a[KEY]
			a = nextOf(a)
			b = nextOf(b)
		end
	end
	return fromSortedItems(self, out, count)
end

-- 차집합. 이쪽에는 있고 저쪽에는 없는 것. O(n + m).
const function Difference<T>(self: TreeSetData<T>, other: TreeSetData<T>): TreeSet<T>
	sameOrder(self, other)
	const compare = self.map.compare
	const out: { T } = {}
	local count, a: any, b: any = 0, firstNode(self.map), firstNode(other.map)
	while a ~= nil do
		if b == nil then
			count += 1
			out[count] = a[KEY]
			a = nextOf(a)
		else
			const diff = compare(a[KEY], b[KEY])
			if diff < 0 then
				count += 1
				out[count] = a[KEY]
				a = nextOf(a)
			elseif diff > 0 then
				b = nextOf(b)
			else
				a = nextOf(a)
				b = nextOf(b)
			end
		end
	end
	return fromSortedItems(self, out, count)
end

-- 대칭차. 한쪽에만 있는 것. O(n + m).
const function SymmetricDifference<T>(self: TreeSetData<T>, other: TreeSetData<T>): TreeSet<T>
	sameOrder(self, other)
	const compare = self.map.compare
	const out: { T } = {}
	local count, a: any, b: any = 0, firstNode(self.map), firstNode(other.map)
	while a ~= nil and b ~= nil do
		const diff = compare(a[KEY], b[KEY])
		if diff < 0 then
			count += 1
			out[count] = a[KEY]
			a = nextOf(a)
		elseif diff > 0 then
			count += 1
			out[count] = b[KEY]
			b = nextOf(b)
		else
			a = nextOf(a)
			b = nextOf(b)
		end
	end
	while a ~= nil do
		count += 1
		out[count] = a[KEY]
		a = nextOf(a)
	end
	while b ~= nil do
		count += 1
		out[count] = b[KEY]
		b = nextOf(b)
	end
	return fromSortedItems(self, out, count)
end

-- 이쪽이 저쪽에 통째로 들어가는가. 크기를 먼저 보고 걸러냅니다.
const function IsSubsetOf<T>(self: TreeSetData<T>, other: TreeSetData<T>): boolean
	sameOrder(self, other)
	if self.map.size > other.map.size then
		return false
	end
	const compare = self.map.compare
	local a: any, b: any = firstNode(self.map), firstNode(other.map)
	while a ~= nil do
		if b == nil then
			return false
		end
		const diff = compare(a[KEY], b[KEY])
		if diff < 0 then
			return false -- a 의 이 원소는 b 에 없다
		elseif diff > 0 then
			b = nextOf(b)
		else
			a = nextOf(a)
			b = nextOf(b)
		end
	end
	return true
end

-- 겹치는 원소가 하나도 없는가.
const function IsDisjointFrom<T>(self: TreeSetData<T>, other: TreeSetData<T>): boolean
	sameOrder(self, other)
	const compare = self.map.compare
	local a: any, b: any = firstNode(self.map), firstNode(other.map)
	while a ~= nil and b ~= nil do
		const diff = compare(a[KEY], b[KEY])
		if diff < 0 then
			a = nextOf(a)
		elseif diff > 0 then
			b = nextOf(b)
		else
			return false
		end
	end
	return true
end

-- 원소가 완전히 같은가. 둘 다 정렬 순서로 나오니 **나란히 대조**하면 됩니다.
const function Equal<T>(self: TreeSetData<T>, other: TreeSetData<T>): boolean
	sameOrder(self, other)
	if self.map.size ~= other.map.size then
		return false
	end
	const compare = self.map.compare
	local a: any, b: any = firstNode(self.map), firstNode(other.map)
	while a ~= nil do
		if compare(a[KEY], b[KEY]) ~= 0 then
			return false
		end
		a = nextOf(a)
		b = nextOf(b)
	end
	return true
end

--#endregion

--#region ----------- 생성자 -----------

-- `balance` 는 자가 균형 방식(선택 — 기본 레드블랙, `TreeMap.New` 와 같음).
const function New<T>(compare: Comparator<T>, balance: Scheme?): TreeSet<T>
	-- 여기서 먼저 봅니다 — 맡기면 메시지 머리가 `TreeMap:` 으로 나옵니다(사용자가 부른 적 없는 모듈).
	Common.expectComparator(compare, "TreeSet: New")
	Balance.Expect(balance, RedBlack, "TreeSet: New")
	return wrap(TreeMap.New<<T, true>>(compare, balance))
end

-- 평범한 Lua 배열의 원소로 만듭니다. 정렬해서 한 번에 짓고(O(n log n) 정렬 + O(n) 짓기) 중복은 하나로
-- 접힙니다. 길이는 `Common.listLength` 규약(`n` 우선, 구멍은 건너뜀), NaN 은 에러.
const function FromList<T>(source: { T }, compare: Comparator<T>, balance: Scheme?): TreeSet<T>
	Common.expectComparator(compare, "TreeSet: FromList")
	Balance.Expect(balance, RedBlack, "TreeSet: FromList")
	const list, count = Common.denseList(source)
	for idx = 1, count do
		const item = list[idx]
		if item ~= item then
			Common.raise("TreeSet: NaN item")
		end
	end
	const sorted = table.create(count) :: { T }
	table.move(list, 1, count, 1, sorted)
	table.sort(sorted, function(a: T, b: T): boolean
		return compare(a, b) < 0
	end)
	local size = 0
	for idx = 1, count do
		const item = sorted[idx]
		if size == 0 or compare(sorted[size], item) ~= 0 then
			size += 1
			sorted[size] = item
		end
	end
	return wrap(TreeMap.FromSorted(sorted, table.create(size, true :: true), size, compare, balance))
end

const function isTreeSet(value: any): boolean
	return type(value) == "table" and rawget(value, TYPE_KEY) == TOKEN
end

--#endregion

-- stylua: ignore
const TreeSetModule = Kind.Seal({
	New = New,
	FromList = FromList,
	isTreeSet = isTreeSet,

	Add = Add, Has = Has, Remove = Remove, Items = Items,
	Len = Len, Empty = Empty, Iter = Iter, First = First, Last = Last,
	FloorItem = FloorItem, CeilingItem = CeilingItem, LowerItem = LowerItem, HigherItem = HigherItem,
	RangeItems = RangeItems, Clear = Clear, PopFirst = PopFirst, PopLast = PopLast, Retain = Retain, Clone = Clone,
	SplitOff = SplitOff, Join = Join,
	Union = Union, Intersect = Intersect, Difference = Difference, SymmetricDifference = SymmetricDifference,
	IsSubsetOf = IsSubsetOf, IsDisjointFrom = IsDisjointFrom, Equal = Equal,
})

-- ⭐ **트레이트에는 넘길 것만 든 표를 등록합니다**(2026-10-13 사용자 결정, 질문 AS) — 모듈 테이블을 통째로 넘기지
-- 않습니다(같은 이름이 전부 그 트레이트의 구현이 되어, 뜻이 다른 같은 이름이 조용히 먹었음. 이제 모르는 이름은
-- `ImplFor` 가 에러로 알림). 표의 타입 주석(`X.Provided<…>` — 등록 표 타입, 기본 구현 칸은 선택)이 "구현이 계약을 만족하는가" 의
-- 정적 확인입니다 — **탐침 타입**(`Trait.A`·`Trait.B` — 서로 다른 불투명 타입)으로 적습니다: `any` 로 적으면 인자 수·인자 타입이
-- 검사되지 않았고(2라운드 리뷰), 구체 타입(`string`)으로 적으면 원소를 못박은 함수가 샙니다(2026-10-14 탐색 — 질문 AY).
-- 표는 이렇게 **주석 단 지역 변수**에 적어 넘깁니다 — `ImplFor(토큰, { … })` 처럼 표 리터럴을 바로 넘기면 검사가 안 됩니다.
const setImpl: Set.Provided<TreeSet<A>, A> =
	{ Add = TreeSetModule.Add, Has = TreeSetModule.Has, Remove = TreeSetModule.Remove, Items = TreeSetModule.Items }
const collectionImpl: Collection.Provided<TreeSet<A>> = { Len = TreeSetModule.Len, Clear = TreeSetModule.Clear }
Set.ImplFor(TreeSetModule, setImpl)
Collection.ImplFor(TreeSetModule, collectionImpl)

return TreeSetModule

--!strict
--[[
	TreeSet — **정렬을 유지하는** 셋.

	## TreeMap 위에 단방향으로 얹혀 있습니다

	```lua
	{ map: TreeMap<T, true> }
	```

	`HashSet` 이 `HashMap` 을 감싸는 것과 같은 구조이고, 어휘도 같습니다 —
	**셋은 `Add`/`Has`/`Remove`, 맵은 `Set`/`Get`.** 바꿔 끼울 수 있어야 하므로
	`HashSet` 과 같은 이름을 씁니다.

	## `HashSet` 대신 이걸 쓰는 이유

	**`Items()`/`Iter()` 가 정렬 순서를 보장합니다.** 그리고 정렬이 있어야만
	되는 것들이 있습니다 — `First`/`Last`, `FloorItem`/`CeilingItem`,
	`RangeItems`.

	순서가 필요 없으면 `HashSet` 이 낫습니다. 조회가 `HashSet` 은 O(1),
	여기는 O(log n) 이고 삽입은 뒤를 미는 O(n) 입니다.

	⚠️ **많이 담을 때는 `Add` 를 반복하지 말고 `FromList` 를 쓰세요.**
	삽입마다 뒤를 미는 O(n^2) 이라 원소 2만 개에서 이미 7.5배 차이가 납니다.

	## ⭐ 집합 연산은 병합인데, **그게 해싱보다 빠르지 않습니다**

	양쪽이 이미 정렬돼 있으므로 한 번씩 훑으며 맞춰 나갑니다 — 해시를 한 번도
	계산하지 않는 O(n + m) 입니다. 교과서대로라면 이겨야 하는데, **실측은
	반대입니다**(원소 10만, `.claude/base/perf-measurements.md` 9절):

	| | HashSet | TreeSet | |
	|---|---|---|---|
	| `Union` | 0.0028s | 0.0163s | **5.9배 느림** |
	| `Intersect` | 0.0043s | 0.0049s | 1.2배 |
	| `Has` × 10만 | 0.0030s | 0.0696s | **23.4배 느림** |
	| `FromList` | 0.0010s | 0.0495s | **50배 느림** |

	이유는 단순합니다. **Luau 의 테이블 해싱은 C 안에서 돌고, 우리 병합은
	Lua 클로저로 비교자를 부릅니다.** 알고리즘 차수가 아니라 상수가 이깁니다.

	**그러니 `TreeSet` 은 순서를 위한 것이지 속도를 위한 게 아닙니다.**
	순서가 필요 없으면 `HashSet` 을 쓰세요 — 모든 축에서 빠릅니다.

	⚠️ **두 셋의 비교자가 같아야 합니다.** 다르면 병합이 뜻을 잃습니다 —
	검사하지 않으니 호출자가 맞춰 주세요.
]]
local Types = require("./Types")
local TreeMap = require("./TreeMap")

type Record<K, V> = Types.Record<K, V>
type Comparator<T> = Types.Comparator<T>
type TreeMapType<K, V> = TreeMap.TreeMap<K, V>

export type TreeSetData<T> = { map: TreeMapType<T, true>, read __treeset__: true }

-- 인스턴스 판별용 태그. **메타테이블은 없습니다**(질문 AB) — 데이터는 평범한
-- 테이블(엔티티), 연산은 이 모듈의 네임스페이스 함수(서비스)입니다.
const TAG = "__treeset__"

-- 날 테이블에 태그를 붙입니다. 생성자들이 공유합니다.
const function tagged(raw: any): any
	raw[TAG] = true
	return raw
end

const function adopt<T>(records: { Record<T, true> }, size: number, compare: Comparator<T>): TreeSet<T>
	const map: TreeMapType<T, true> = TreeMap.Adopt(records, size, compare)
	return tagged({ map = map })
end

--#region ----------- 계약 구현 (Types.SetOps) -----------
-- 이 모듈 테이블이 그대로 `Types.SetOps` 구현체입니다(질문 AB).

-- 원소를 넣습니다. **새로 들어갔으면 `true`**, 이미 있었으면 `false`.
const function Add<T>(self: TreeSetData<T>, item: T): boolean
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

-- `for item in TreeSet.Iter(set) do … end` 또는 `for _, item in …` — **정렬 순서로**.
--
-- ⭐ **원소를 두 자리 모두에 돌려주고, 상태는 클로저에 담습니다.** 그래서 두
-- 형태가 다 되고 `HashSet` 과 바꿔 끼울 수 있습니다. 예전엔 `(인덱스, 원소)` 를
-- 돌려줘서 `for item in` 이 **인덱스**를 받았고(주석과 반대, 2026-09-30 리뷰),
-- 원소 타입이 number 면 타입 검사도 그걸 못 잡았습니다.
const function Iter<T>(self: TreeSetData<T>): () -> (T, T)
	const map = self.map
	local idx = 0
	return function(): (T, T)
		idx += 1
		if idx > map.size then
			return nil :: any, nil :: any
		end
		const item = map.records[idx].key
		return item, item
	end
end

--#endregion

--#region ----------- 정렬이 있어야만 되는 것들 -----------

const function First<T>(self: TreeSetData<T>): T?
	const rec = TreeMap.First(self.map)
	if rec == nil then
		return nil
	end
	return rec.key
end

const function Last<T>(self: TreeSetData<T>): T?
	const rec = TreeMap.Last(self.map)
	if rec == nil then
		return nil
	end
	return rec.key
end

-- `item` **이하**인 원소 중 가장 큰 것.
const function FloorItem<T>(self: TreeSetData<T>, item: T): T?
	return TreeMap.FloorKey(self.map, item)
end

-- `item` **이상**인 원소 중 가장 작은 것.
const function CeilingItem<T>(self: TreeSetData<T>, item: T): T?
	return TreeMap.CeilingKey(self.map, item)
end

-- 구간 `[from, to]` 의 원소들. **양끝 포함**, 정렬 순서. 뒤집히면 빈 목록.
const function RangeItems<T>(self: TreeSetData<T>, from: T, to: T): { T }
	const recs = TreeMap.RangeRecords(self.map, from, to)
	const out = table.create(#recs) :: { T }
	for idx, rec in recs do
		out[idx] = rec.key
	end
	return out
end

--#endregion

--#region ----------- 변형 -----------

const function Clear<T>(self: TreeSetData<T>): ()
	TreeMap.Clear(self.map)
end

const function Clone<T>(self: TreeSetData<T>): TreeSet<T>
	return tagged({ map = TreeMap.Clone(self.map) })
end

--#endregion

--#region ----------- 집합 연산 (병합) -----------
-- 양쪽 레코드 배열을 한 번씩 훑습니다. 이 모듈이 자기 맵의 주인이라 안쪽
-- 배열을 바로 읽는 것이고, 계층을 넘는 게 아닙니다.
--
-- 결과 레코드는 **새로 만듭니다.** 원본 레코드를 그대로 꽂으면 두 셋이 같은
-- 테이블을 공유하게 되는데, 셋에서는 값이 항상 `true` 라 지금은 안전하지만
-- 나중에 값에 뭔가를 담게 되면 조용히 깨집니다.

-- ⭐ **두 셋의 비교자가 같은 함수여야 합니다.** 다르면 병합이 뜻을 잃고,
-- 결과가 **불변식이 깨진 셋**(중복·정렬 깨짐)으로 조용히 퍼졌습니다
-- (2026-09-30 리뷰). 같은지 한 번 보는 값은 거의 0 이라 막습니다 — 뜻이 같은
-- 비교자라도 **다른 함수 값**이면 에러이니 `Common.compareNumber` 처럼 같은
-- 함수를 나눠 쓰세요.
const function sameOrder<T>(a: TreeSetData<T>, b: TreeSetData<T>)
	if a.map.compare ~= b.map.compare then
		error("TreeSet: sets use different comparators", 3)
	end
end

const function rec<T>(key: T): Record<T, true>
	return { key = key, value = true }
end

-- 합집합. O(n + m).
const function Union<T>(self: TreeSetData<T>, other: TreeSetData<T>): TreeSet<T>
	sameOrder(self, other)
	const a, b = self.map, other.map
	const compare = a.compare
	const out = table.create(a.size + b.size) :: { Record<T, true> }
	local i, j, k = 1, 1, 0
	while i <= a.size and j <= b.size do
		const diff = compare(a.records[i].key, b.records[j].key)
		k += 1
		if diff < 0 then
			out[k] = rec(a.records[i].key)
			i += 1
		elseif diff > 0 then
			out[k] = rec(b.records[j].key)
			j += 1
		else
			out[k] = rec(a.records[i].key)
			i += 1
			j += 1
		end
	end
	-- 남은 꼬리는 이미 정렬돼 있으니 그대로 이어붙입니다.
	for idx = i, a.size do
		k += 1
		out[k] = rec(a.records[idx].key)
	end
	for idx = j, b.size do
		k += 1
		out[k] = rec(b.records[idx].key)
	end
	return adopt(out, k, compare)
end

-- 교집합. O(n + m).
const function Intersect<T>(self: TreeSetData<T>, other: TreeSetData<T>): TreeSet<T>
	sameOrder(self, other)
	const a, b = self.map, other.map
	const compare = a.compare
	const out = table.create(math.min(a.size, b.size)) :: { Record<T, true> }
	local i, j, k = 1, 1, 0
	while i <= a.size and j <= b.size do
		const diff = compare(a.records[i].key, b.records[j].key)
		if diff < 0 then
			i += 1
		elseif diff > 0 then
			j += 1
		else
			k += 1
			out[k] = rec(a.records[i].key)
			i += 1
			j += 1
		end
	end
	return adopt(out, k, compare)
end

-- 차집합. 이쪽에는 있고 저쪽에는 없는 것. O(n + m).
const function Difference<T>(self: TreeSetData<T>, other: TreeSetData<T>): TreeSet<T>
	sameOrder(self, other)
	const a, b = self.map, other.map
	const compare = a.compare
	const out = table.create(a.size) :: { Record<T, true> }
	local i, j, k = 1, 1, 0
	while i <= a.size and j <= b.size do
		const diff = compare(a.records[i].key, b.records[j].key)
		if diff < 0 then
			k += 1
			out[k] = rec(a.records[i].key)
			i += 1
		elseif diff > 0 then
			j += 1
		else
			i += 1
			j += 1
		end
	end
	for idx = i, a.size do
		k += 1
		out[k] = rec(a.records[idx].key)
	end
	return adopt(out, k, compare)
end

-- 대칭차. 한쪽에만 있는 것. O(n + m).
const function SymmetricDifference<T>(self: TreeSetData<T>, other: TreeSetData<T>): TreeSet<T>
	sameOrder(self, other)
	const a, b = self.map, other.map
	const compare = a.compare
	const out = table.create(a.size + b.size) :: { Record<T, true> }
	local i, j, k = 1, 1, 0
	while i <= a.size and j <= b.size do
		const diff = compare(a.records[i].key, b.records[j].key)
		if diff < 0 then
			k += 1
			out[k] = rec(a.records[i].key)
			i += 1
		elseif diff > 0 then
			k += 1
			out[k] = rec(b.records[j].key)
			j += 1
		else
			i += 1
			j += 1
		end
	end
	for idx = i, a.size do
		k += 1
		out[k] = rec(a.records[idx].key)
	end
	for idx = j, b.size do
		k += 1
		out[k] = rec(b.records[idx].key)
	end
	return adopt(out, k, compare)
end

-- 이쪽이 저쪽에 통째로 들어가는가. 크기를 먼저 보고 걸러냅니다.
const function IsSubsetOf<T>(self: TreeSetData<T>, other: TreeSetData<T>): boolean
	sameOrder(self, other)
	const a, b = self.map, other.map
	if a.size > b.size then
		return false
	end
	const compare = a.compare
	local i, j = 1, 1
	while i <= a.size do
		if j > b.size then
			return false
		end
		const diff = compare(a.records[i].key, b.records[j].key)
		if diff < 0 then
			return false -- a 의 이 원소는 b 에 없다
		elseif diff > 0 then
			j += 1
		else
			i += 1
			j += 1
		end
	end
	return true
end

const function IsDisjointFrom<T>(self: TreeSetData<T>, other: TreeSetData<T>): boolean
	sameOrder(self, other)
	const a, b = self.map, other.map
	const compare = a.compare
	local i, j = 1, 1
	while i <= a.size and j <= b.size do
		const diff = compare(a.records[i].key, b.records[j].key)
		if diff < 0 then
			i += 1
		elseif diff > 0 then
			j += 1
		else
			return false
		end
	end
	return true
end

-- 원소가 완전히 같은가. 정렬돼 있으니 **나란히 대조**하면 됩니다.
const function Equal<T>(self: TreeSetData<T>, other: TreeSetData<T>): boolean
	sameOrder(self, other)
	const a, b = self.map, other.map
	if a.size ~= b.size then
		return false
	end
	const compare = a.compare
	for idx = 1, a.size do
		if compare(a.records[idx].key, b.records[idx].key) ~= 0 then
			return false
		end
	end
	return true
end

--#endregion

--#region ----------- 타입 -----------
-- 함수가 타입 바깥(네임스페이스)에 있으니 전체형은 데이터부 그 자체입니다(질문 AB).
export type TreeSet<T> = TreeSetData<T>

--#endregion

--#region ----------- 생성자 -----------

const function New<T>(compare: Comparator<T>): TreeSet<T>
	return adopt({} :: { Record<T, true> }, 0, compare)
end

-- 평범한 Lua 배열의 원소로 만듭니다. 정렬해서 담고 중복은 하나로 접힙니다.
--
-- ⚠️ 한 번에 정렬해서 담습니다(O(n log n)). `Add` 를 n 번 부르면 삽입마다
-- 뒤를 밀어 **O(n^2)** 이 됩니다.
const function FromList<T>(list: { T }, compare: Comparator<T>): TreeSet<T>
	const count = #list
	if count == 0 then
		return adopt({} :: { Record<T, true> }, 0, compare)
	end
	for idx = 1, count do
		const item = list[idx]
		if item ~= item then
			error("TreeSet: NaN item", 2)
		end
	end
	const sorted = table.create(count) :: { T }
	table.move(list, 1, count, 1, sorted)
	table.sort(sorted, function(a: T, b: T): boolean
		return compare(a, b) < 0
	end)
	const out = table.create(count) :: { Record<T, true> }
	local size = 0
	for idx = 1, count do
		const item = sorted[idx]
		if size == 0 or compare(out[size].key, item) ~= 0 then
			size += 1
			out[size] = { key = item, value = true }
		end
	end
	return adopt(out, size, compare)
end

const function isTreeSet(value: any): boolean
	return type(value) == "table" and rawget(value, TAG) == true and type(rawget(value, "map")) == "table"
end

--#endregion

-- stylua: ignore
return {
	New = New,
	FromList = FromList,
	isTreeSet = isTreeSet,

	-- ⭐ 모든 연산은 여기 네임스페이스 함수입니다(`TreeSet.X(v, …)`) — 콜론 호출은
	-- 없습니다(질문 AB). `local` 로 받아 부르면 더 빠릅니다(perf 14·16절).
	Len = Len, Empty = Empty, Iter = Iter, First = First, Last = Last, FloorItem = FloorItem,
	CeilingItem = CeilingItem, RangeItems = RangeItems, Clear = Clear, Clone = Clone, Union = Union,
	Intersect = Intersect, Difference = Difference, SymmetricDifference = SymmetricDifference,
	IsSubsetOf = IsSubsetOf, IsDisjointFrom = IsDisjointFrom, Equal = Equal, Add = Add, Has = Has,
	Remove = Remove, Items = Items,
}

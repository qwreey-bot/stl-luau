--!strict
--[[
	FlatSet — **정렬을 유지하는** 셋.

	## FlatMap 위에 단방향으로 얹혀 있습니다

	```lua
	{ map: FlatMap<T, true> }
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

	| | HashSet | FlatSet | |
	|---|---|---|---|
	| `Union` | 0.0028s | 0.0163s | **5.9배 느림** |
	| `Intersect` | 0.0043s | 0.0049s | 1.2배 |
	| `Has` × 10만 | 0.0030s | 0.0696s | **23.4배 느림** |
	| `FromList` | 0.0010s | 0.0495s | **50배 느림** |

	이유는 단순합니다. **Luau 의 테이블 해싱은 C 안에서 돌고, 우리 병합은
	Lua 클로저로 비교자를 부릅니다.** 알고리즘 차수가 아니라 상수가 이깁니다.

	**그러니 `FlatSet` 은 순서를 위한 것이지 속도를 위한 게 아닙니다.**
	순서가 필요 없으면 `HashSet` 을 쓰세요 — 모든 축에서 빠릅니다.

	⚠️ **두 셋의 비교자가 같아야 합니다.** 다르면 병합이 뜻을 잃습니다 —
	검사하지 않으니 호출자가 맞춰 주세요.
]]
local Types = require("../Types")
local FlatMap = require("./FlatMap")
local Common = require("../Common")
local Trait = require("../Trait")
type A = Trait.A
local Set = require("../Traits/Set")
local Collection = require("../Traits/Collection")
Common.registerSource(debug.info(1, "s"))

type Record<K, V> = Types.Record<K, V>
type Comparator<T> = Types.Comparator<T>
type FlatMapType<K, V> = FlatMap.FlatMap<K, V>

export type FlatSetData<T> = {
	map: FlatMapType<T, true>,
	read __type: Trait.Token<"Stl.FlatSet">,
	-- 이 종류가 구현하는 트레이트와 그 인자(질문 BA — 타입에만 있음, 읽으면 nil)
	read __traits: { read Set: Set.Assoc<T>, read Collection: Collection.Assoc },
}

-- 인스턴스 판별용 태그. **메타테이블은 없습니다**(질문 AB) — 데이터는 평범한
-- 테이블(엔티티), 연산은 이 모듈의 네임스페이스 함수(서비스)입니다.
-- 리터럴로 둡니다 — `Trait.TYPE_KEY` 를 받아 쓰면 상수 접기가 안 돼 생성이 7~11% 느려졌습니다(perf 21절).
const TYPE_KEY = "__type"
-- 이 종류 = 닫힌 트레이트(질문 BB): 맨 위에서 만들고 맨 끝에서 모듈 표를 봉인 — 그 표가 곧 `stl.FlatSet`(종류의 정체).
const Kind = Trait.Struct("Stl.FlatSet")
const TOKEN = Kind.Token -- 안쪽에서만(생성자가 `__type` 에 찍는 상수)

-- 날 테이블에 태그를 붙입니다. 생성자들이 공유합니다.
const function tagged(raw: any): any
	raw[TYPE_KEY] = TOKEN
	return raw
end

const function adopt<T>(records: { Record<T, true> }, size: number, compare: Comparator<T>): FlatSet<T>
	const map: FlatMapType<T, true> = FlatMap.Adopt(records, size, compare)
	return tagged({ map = map })
end

--#region ----------- 계약 구현 (Set.Core) -----------
-- 이 모듈 테이블이 그대로 `Set.Core` 구현체입니다(질문 AB).

-- 원소를 넣습니다. **새로 들어갔으면 `true`**, 이미 있었으면 `false`.
--
-- NaN·`nil` 은 받지 않습니다(`FlatMap` 의 키와 같은 이유). 여기서 먼저 봅니다 — 맡기면 메시지가
-- `FlatMap: NaN key` 로 나와, 사용자가 부른 적 없는 모듈 이름이 나왔습니다(2026-10-12).
const function Add<T>(self: FlatSetData<T>, item: T): boolean
	if item == nil or item ~= item then
		Common.raise(if item == nil then "FlatSet: nil item" else "FlatSet: NaN item")
	end
	const map = self.map
	const before = map.size
	FlatMap.Set(map, item, true :: true)
	return map.size > before
end

const function Has<T>(self: FlatSetData<T>, item: T): boolean
	return FlatMap.Has(self.map, item)
end

const function Remove<T>(self: FlatSetData<T>, item: T): boolean
	return FlatMap.Remove(self.map, item) ~= nil
end

-- 원소를 모은 배열. **정렬 순서입니다.**
const function Items<T>(self: FlatSetData<T>): { T }
	return FlatMap.Keys(self.map)
end

--#endregion

--#region ----------- 조회 -----------

const function Len<T>(self: FlatSetData<T>): number
	return self.map.size
end

const function Empty<T>(self: FlatSetData<T>): boolean
	return self.map.size == 0
end

-- `for item in FlatSet.Iter(set) do … end` 또는 `for _, item in …` — **정렬 순서로**.
--
-- ⭐ **원소를 두 자리 모두에 돌려주고, 상태는 클로저에 담습니다.** 그래서 두
-- 형태가 다 되고 `HashSet` 과 바꿔 끼울 수 있습니다. 예전엔 `(인덱스, 원소)` 를
-- 돌려줘서 `for item in` 이 **인덱스**를 받았고(주석과 반대, 2026-09-30 리뷰),
-- 원소 타입이 number 면 타입 검사도 그걸 못 잡았습니다.
const function Iter<T>(self: FlatSetData<T>): () -> (T, T)
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

const function First<T>(self: FlatSetData<T>): T?
	const rec = FlatMap.First(self.map)
	if rec == nil then
		return nil
	end
	return rec.key
end

const function Last<T>(self: FlatSetData<T>): T?
	const rec = FlatMap.Last(self.map)
	if rec == nil then
		return nil
	end
	return rec.key
end

-- `item` **이하**인 원소 중 가장 큰 것.
const function FloorItem<T>(self: FlatSetData<T>, item: T): T?
	return FlatMap.FloorKey(self.map, item)
end

-- `item` **이상**인 원소 중 가장 작은 것.
const function CeilingItem<T>(self: FlatSetData<T>, item: T): T?
	return FlatMap.CeilingKey(self.map, item)
end

-- `item` 보다 **작은** 원소 중 가장 큰 것(엄격 — `FloorItem` 은 같은 원소도 줌).
const function LowerItem<T>(self: FlatSetData<T>, item: T): T?
	return FlatMap.LowerKey(self.map, item)
end

-- `item` 보다 **큰** 원소 중 가장 작은 것(엄격 — `CeilingItem` 은 같은 원소도 줌).
const function HigherItem<T>(self: FlatSetData<T>, item: T): T?
	return FlatMap.HigherKey(self.map, item)
end

-- 구간 `[from, to]` 의 원소들. **양끝 포함**, 정렬 순서. 뒤집히면 빈 목록.
const function RangeItems<T>(self: FlatSetData<T>, from: T, to: T): { T }
	const recs = FlatMap.RangeRecords(self.map, from, to)
	const out = table.create(#recs) :: { T }
	for idx, rec in recs do
		out[idx] = rec.key
	end
	return out
end

--#endregion

--#region ----------- 변형 -----------

-- 비우고 **자기 자신을 돌려줍니다**(2026-10-12 사용자 결정, 질문 AM — 일곱 컨테이너가 같게. 반환은 공짜였음).
const function Clear<T>(self: FlatSetData<T>): FlatSet<T>
	FlatMap.Clear(self.map)
	return self
end

-- 가장 작은 원소를 **꺼냅니다**. 비었으면 `nil`. O(n) 입니다(`FlatMap.PopFirst`).
const function PopFirst<T>(self: FlatSetData<T>): T?
	const rec = FlatMap.PopFirst(self.map)
	return if rec == nil then nil else rec.key
end

-- 가장 큰 원소를 꺼냅니다. O(1).
const function PopLast<T>(self: FlatSetData<T>): T?
	const rec = FlatMap.PopLast(self.map)
	return if rec == nil then nil else rec.key
end

-- 조건을 만족하는 원소만 **남깁니다**(제자리, 정렬 순서로 부름). ⚠️ Java `retainAll` 과 달리
-- 술어를 받습니다(질문 W). 콜백 안에서 이 셋을 바꾸면 정의되지 않은 동작입니다(`FlatMap.Retain`
-- 과 같음, 질문 AL 1). 자기 맵의 레코드 배열을 직접 훑습니다(집합 연산처럼 — 클로저 한 겹을 아낌).
const function Retain<T>(self: FlatSetData<T>, fn: (item: T) -> boolean): FlatSet<T>
	const map = self.map
	const records = map.records
	const size = map.size
	local kept = 0
	for idx = 1, size do
		const rec = records[idx]
		if fn(rec.key) then
			kept += 1
			records[kept] = rec
		end
	end
	for idx = kept + 1, size do
		records[idx] = nil :: any
	end
	map.size = kept
	return self
end

const function Clone<T>(self: FlatSetData<T>): FlatSet<T>
	return tagged({ map = FlatMap.Clone(self.map) })
end

-- **`item` 이상인 원소들을 떼어 새 셋으로** 돌려줍니다(이 셋에는 미만만 남음) — `FlatMap.SplitOff`.
const function SplitOff<T>(self: FlatSetData<T>, item: T): FlatSet<T>
	if item == nil or item ~= item then
		Common.raise(if item == nil then "FlatSet: nil item" else "FlatSet: NaN item")
	end
	return tagged({ map = FlatMap.SplitOff(self.map, item) })
end

-- **`other` 의 전부를 이 셋 뒤에 잇고** 이 셋을 돌려줍니다 — `other` 의 모든 원소가 이 셋의 모든 원소보다 커야 합니다.
-- `other` 는 빈 셋이 됩니다. 같은 비교자.
const function Join<T>(self: FlatSetData<T>, other: FlatSetData<T>): FlatSet<T>
	-- 첫 인자도 봅니다(표면이 같은 Tree/Flat 을 섞기 쉬움 — 예전엔 라이브러리 줄의 원시 에러이거나 엉뚱한 메시지, 5라운드 리뷰)
	const mine: any = self
	if type(mine) ~= "table" or rawget(mine, TYPE_KEY) ~= TOKEN then
		const kind = Trait.TokenOf(mine)
		Common.raise(`FlatSet: Join needs a FlatSet, got {if kind then kind.name else typeof(mine)}`)
	end
	const rest: any = other
	if type(rest) ~= "table" or rawget(rest, TYPE_KEY) ~= TOKEN then
		const kind = Trait.TokenOf(rest)
		Common.raise(`FlatSet: Join needs another FlatSet, got {if kind then kind.name else typeof(rest)}`)
	end
	const selfMap: any, restMap: any = self.map, rest.map
	if rest == self then
		Common.raise("FlatSet: Join needs two different sets")
	end
	if selfMap.compare ~= restMap.compare then
		Common.raise("FlatSet: sets use different comparators")
	end
	if
		selfMap.size > 0
		and restMap.size > 0
		and selfMap.compare(selfMap.records[selfMap.size].key, restMap.records[1].key) >= 0
	then
		Common.raise("FlatSet: Join needs every item of the second set to be greater than every item of the first")
	end
	FlatMap.Join(selfMap, restMap)
	return self :: any
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
const function sameOrder<T>(a: FlatSetData<T>, b: FlatSetData<T>)
	-- 상대가 같은 종류인지 먼저(타입 없는 코드가 표면이 같은 `TreeSet` 을 섞으면 라이브러리 줄에서 죽었음, 리뷰)
	-- **첫 인자도** 봅니다(2라운드 리뷰 — 둘째만 보던 때는 섞인 쪽이 첫 인자면 그대로 통과했음. 다른 함수들은
	-- 첫 인자의 종류를 검사하지 않지만, 여기는 두 인자가 대칭이고 검사가 이미 도는 자리입니다)
	if type(a) ~= "table" or rawget(a :: any, TYPE_KEY) ~= TOKEN then
		const kind = Trait.TokenOf(a)
		Common.raise(`FlatSet: set operations need a FlatSet, got {if kind then kind.name else typeof(a)}`)
	end
	if type(b) ~= "table" or rawget(b :: any, TYPE_KEY) ~= TOKEN then
		const kind = Trait.TokenOf(b)
		Common.raise(`FlatSet: set operations need another FlatSet, got {if kind then kind.name else typeof(b)}`)
	end
	if a.map.compare ~= b.map.compare then
		Common.raise("FlatSet: sets use different comparators")
	end
end

const function rec<T>(key: T): Record<T, true>
	return { key = key, value = true }
end

-- 합집합. O(n + m).
const function Union<T>(self: FlatSetData<T>, other: FlatSetData<T>): FlatSet<T>
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
const function Intersect<T>(self: FlatSetData<T>, other: FlatSetData<T>): FlatSet<T>
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
const function Difference<T>(self: FlatSetData<T>, other: FlatSetData<T>): FlatSet<T>
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
const function SymmetricDifference<T>(self: FlatSetData<T>, other: FlatSetData<T>): FlatSet<T>
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
const function IsSubsetOf<T>(self: FlatSetData<T>, other: FlatSetData<T>): boolean
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

const function IsDisjointFrom<T>(self: FlatSetData<T>, other: FlatSetData<T>): boolean
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
const function Equal<T>(self: FlatSetData<T>, other: FlatSetData<T>): boolean
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
export type FlatSet<T> = FlatSetData<T>

--#endregion

--#region ----------- 생성자 -----------

const function New<T>(compare: Comparator<T>): FlatSet<T>
	Common.expectComparator(compare, "FlatSet: New")
	return adopt({} :: { Record<T, true> }, 0, compare)
end

-- 평범한 Lua 배열의 원소로 만듭니다. 정렬해서 담고 중복은 하나로 접힙니다.
--
-- ⚠️ 한 번에 정렬해서 담습니다(O(n log n)). `Add` 를 n 번 부르면 삽입마다
-- 뒤를 밀어 **O(n^2)** 이 됩니다.
const function FromList<T>(source: { read [number]: T }, compare: Comparator<T>): FlatSet<T>
	Common.expectComparator(compare, "FlatSet: FromList")
	-- 길이는 `Common.listLength` 규약(`n` 우선, 구멍은 건너뜀, M0 3라운드).
	const list, count = Common.denseList(source)
	if count == 0 then
		return adopt({} :: { Record<T, true> }, 0, compare)
	end
	for idx = 1, count do
		const item = list[idx]
		if item ~= item then
			Common.raise("FlatSet: NaN item")
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

const function isFlatSet(value: any): boolean
	return type(value) == "table" and rawget(value, TYPE_KEY) == TOKEN
end

--#endregion

-- stylua: ignore
const FlatSetModule = Kind.Seal({
	New = New,
	FromList = FromList,
	isFlatSet = isFlatSet,

	-- ⭐ 모든 연산은 여기 네임스페이스 함수입니다(`FlatSet.X(v, …)`) — 콜론 호출은
	-- 없습니다(질문 AB). `local` 로 받아 부르면 더 빠릅니다(perf 14·16절).
	Len = Len, Empty = Empty, Iter = Iter, First = First, Last = Last, FloorItem = FloorItem,
	CeilingItem = CeilingItem, RangeItems = RangeItems, Clear = Clear, Clone = Clone, Union = Union,
	Intersect = Intersect, Difference = Difference, SymmetricDifference = SymmetricDifference,
	IsSubsetOf = IsSubsetOf, IsDisjointFrom = IsDisjointFrom, Equal = Equal, Add = Add, Has = Has,
	Remove = Remove, Items = Items,
	LowerItem = LowerItem, HigherItem = HigherItem, PopFirst = PopFirst, PopLast = PopLast, Retain = Retain,
	SplitOff = SplitOff, Join = Join,
})

-- ⭐ **트레이트에는 넘길 것만 든 표를 등록합니다**(2026-10-13 사용자 결정, 질문 AS) — 모듈 테이블을 통째로 넘기지
-- 않습니다(같은 이름이 전부 그 트레이트의 구현이 되어, 뜻이 다른 같은 이름이 조용히 먹었음. 이제 모르는 이름은
-- `ImplFor` 가 에러로 알림). 표의 타입 주석(`X.Provided<…>` — 등록 표 타입, 기본 구현 칸은 선택)이 "구현이 계약을 만족하는가" 의
-- 정적 확인입니다 — **탐침 타입**(`Trait.A`·`Trait.B` — 서로 다른 불투명 타입)으로 적습니다: `any` 로 적으면 인자 수·인자 타입이
-- 검사되지 않았고(2라운드 리뷰), 구체 타입(`string`)으로 적으면 원소를 못박은 함수가 샙니다(2026-10-14 탐색 — 질문 AY).
-- 표는 이렇게 **주석 단 지역 변수**에 적어 넘깁니다 — `ImplFor(토큰, { … })` 처럼 표 리터럴을 바로 넘기면 검사가 안 됩니다.
const setImpl: Set.Provided<FlatSet<A>, A> =
	{ Add = FlatSetModule.Add, Has = FlatSetModule.Has, Remove = FlatSetModule.Remove, Items = FlatSetModule.Items }
const collectionImpl: Collection.Provided<FlatSet<A>> = { Len = FlatSetModule.Len, Clear = FlatSetModule.Clear }
Set.ImplFor(FlatSetModule, setImpl)
Collection.ImplFor(FlatSetModule, collectionImpl)

return FlatSetModule

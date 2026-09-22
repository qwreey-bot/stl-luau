--!strict
--[[
	TreeMap — **정렬을 유지하는** 맵.

	## 표현 — 트리가 아니라 정렬 배열입니다

	```lua
	{ records: { Record<K, V> }, size: number, compare: Comparator<K>, probe: … }
	```

	이름은 `TreeMap` 이지만 안은 **정렬된 레코드 배열 + 이분 탐색**입니다.
	Luau 에서 붉은검은나무를 굴리면 노드마다 테이블이 하나씩 생기는데, 그
	테이블 하나하나가 메타테이블 없이도 96바이트짜리이고 GC 압력이 됩니다.
	정렬 배열은 조회가 같은 O(log n) 이고 메모리가 훨씬 촘촘합니다.

	**대가는 삽입/삭제가 O(n)** 입니다 — 뒤를 밀어야 하니까요. 다만 그 밀기가
	`table.move` 라 C 안에서 돌아, 원소 루프로 미는 것보다 14배 빠릅니다
	(`.claude/base/perf-measurements.md` 2절). 쓰기가 아주 잦고 크기가 큰
	용도라면 나중에 진짜 트리 백엔드를 재볼 만합니다 — 그때 이 주석을 지우세요.

	## 왜 `HashMap` 이 있는데 이게 또 있는가

	**`Records()`/`Keys()`/`Values()`/`Iter()` 가 정렬 순서를 보장합니다.**
	`HashMap` 은 해시 순서라 보장이 없습니다. 그게 이 모듈의 존재 이유이고,
	순서가 필요 없으면 `HashMap` 이 모든 면에서 낫습니다.

	더해서 정렬이 있어야만 되는 것들이 있습니다 — `First`/`Last`,
	`FloorKey`/`CeilingKey`(주어진 키의 아래/위로 가장 가까운 키),
	`RangeRecords`(키 구간 잘라내기).

	## 비교자를 주입받습니다

	`Comparator<K>`(3방향)입니다. **탐색이 주된 일이라 3방향이 맞습니다** —
	불리언이면 같은지 알려고 두 번 물어야 합니다(`src/Common.luau` 상단).
	`Common.compareNumber` / `Common.compareString` 이 기본 제공됩니다.
]]
local Types = require("./Types")
local BSearch = require("./BSearch")

type Record<K, V> = Types.Record<K, V>
type Comparator<K> = Types.Comparator<K>
type KeyProbe<K, V> = BSearch.Probe<Record<K, V>, K>

export type TreeMapData<K, V> = {
	records: { Record<K, V> },
	size: number,
	compare: Comparator<K>,
	-- 레코드의 키와 찾는 키를 비교하는 어댑터. **생성 때 한 번만 만듭니다** —
	-- 조회마다 클로저를 새로 만들면 조회 하나에 할당이 하나씩 붙습니다.
	probe: KeyProbe<K, V>,
}

local Ifce: TreeMapIfce & Types.MapCore<any, any>

--#region ----------- 계약 구현 (Types.MapCore) -----------
-- ⚠️ 이 셋은 `TreeMapIfce` 에 **다시 쓰지 않습니다.** 계약이 이미 줍니다.

const function Get<K, V>(self: TreeMapData<K, V>, key: K): V?
	const pos = BSearch.Find(self.records, self.size, key, self.probe)
	if pos == nil then
		return nil
	end
	return self.records[pos].value
end

-- 값을 넣습니다. 이미 있으면 덮어쓰고, 없으면 **정렬 위치에 끼워넣습니다**.
-- 끼워넣기는 뒤를 미는 O(n) 이지만 `table.move` 라 C 안에서 돕니다.
const function Set<K, V>(self: TreeMapData<K, V>, key: K, value: V): ()
	const records = self.records
	const size = self.size
	const pos = BSearch.LowerBound(records, size, key, self.probe)
	if pos <= size and self.probe(records[pos], key) == 0 then
		records[pos].value = value
		return
	end
	if pos <= size then
		table.move(records, pos, size, pos + 1)
	end
	records[pos] = { key = key, value = value }
	self.size = size + 1
end

-- 키-값 쌍의 목록. **정렬 순서입니다.**
-- 내부 배열을 그대로 주지 않고 **복사합니다** — 받은 쪽이 건드려도 정렬과
-- `size` 가 깨지지 않게 하려는 것입니다.
const function Records<K, V>(self: TreeMapData<K, V>): { Record<K, V> }
	const out = table.create(self.size) :: { Record<K, V> }
	table.move(self.records, 1, self.size, 1, out)
	return out
end

--#endregion

--#region ----------- 조회 -----------

const function Has<K, V>(self: TreeMapData<K, V>, key: K): boolean
	return BSearch.Find(self.records, self.size, key, self.probe) ~= nil
end

const function GetOr<K, V>(self: TreeMapData<K, V>, key: K, fallback: V): V
	const pos = BSearch.Find(self.records, self.size, key, self.probe)
	if pos == nil then
		return fallback
	end
	return self.records[pos].value
end

const function Len<K, V>(self: TreeMapData<K, V>): number
	return self.size
end

const function Empty<K, V>(self: TreeMapData<K, V>): boolean
	return self.size == 0
end

-- 키만, **정렬 순서로**.
const function Keys<K, V>(self: TreeMapData<K, V>): { K }
	const out = table.create(self.size) :: { K }
	const records = self.records
	for idx = 1, self.size do
		out[idx] = records[idx].key
	end
	return out
end

const function Values<K, V>(self: TreeMapData<K, V>): { V }
	const out = table.create(self.size) :: { V }
	const records = self.records
	for idx = 1, self.size do
		out[idx] = records[idx].value
	end
	return out
end

-- `for key, value in map:Iter() do … end` — **정렬 순서로** 돕니다.
-- ⭐ `(K, V)` 로 비옵셔널 선언입니다(`ipairs` 와 같은 방식).
const function iterStep<K, V>(self: TreeMapData<K, V>, idx: number): (K, V)
	const nextIdx = idx + 1
	if nextIdx > self.size then
		return nil :: any, nil :: any
	end
	const rec = self.records[nextIdx]
	return rec.key, rec.value
end

const function Iter<K, V>(self: TreeMapData<K, V>): (typeof(iterStep), TreeMapData<K, V>, number)
	return iterStep, self, 0
end

--#endregion

--#region ----------- 정렬이 있어야만 되는 것들 -----------

-- 가장 작은 키의 쌍. 비어 있으면 `nil`.
const function First<K, V>(self: TreeMapData<K, V>): Record<K, V>?
	if self.size == 0 then
		return nil
	end
	return self.records[1]
end

const function Last<K, V>(self: TreeMapData<K, V>): Record<K, V>?
	if self.size == 0 then
		return nil
	end
	return self.records[self.size]
end

-- `key` **이하**인 키 중 가장 큰 것. 없으면 `nil`.
const function FloorKey<K, V>(self: TreeMapData<K, V>, key: K): K?
	const pos = BSearch.UpperBound(self.records, self.size, key, self.probe)
	if pos == 1 then
		return nil
	end
	return self.records[pos - 1].key
end

-- `key` **이상**인 키 중 가장 작은 것. 없으면 `nil`.
const function CeilingKey<K, V>(self: TreeMapData<K, V>, key: K): K?
	const pos = BSearch.LowerBound(self.records, self.size, key, self.probe)
	if pos > self.size then
		return nil
	end
	return self.records[pos].key
end

-- 키 구간 `[fromKey, toKey]` 의 쌍들. **양끝 포함**이고 정렬 순서입니다.
-- 구간이 뒤집혀 있으면 빈 목록입니다(이 저장소의 구간 규약).
const function RangeRecords<K, V>(self: TreeMapData<K, V>, fromKey: K, toKey: K): { Record<K, V> }
	const records = self.records
	const size = self.size
	const first = BSearch.LowerBound(records, size, fromKey, self.probe)
	const last = BSearch.UpperBound(records, size, toKey, self.probe) - 1
	if last < first then
		return {}
	end
	const out = table.create(last - first + 1) :: { Record<K, V> }
	table.move(records, first, last, 1, out)
	return out
end

--#endregion

--#region ----------- 변형 -----------

-- 키를 지우고 **지워진 값**을 돌려줍니다. 없었으면 `nil`.
const function Remove<K, V>(self: TreeMapData<K, V>, key: K): V?
	const records = self.records
	const size = self.size
	const pos = BSearch.Find(records, size, key, self.probe)
	if pos == nil then
		return nil
	end
	const removed = records[pos].value
	table.move(records, pos + 1, size, pos)
	records[size] = nil :: any
	self.size = size - 1
	return removed
end

const function Clear<K, V>(self: TreeMapData<K, V>): ()
	table.clear(self.records)
	self.size = 0
end

-- 얕은 복사. **레코드도 새로 만듭니다** — 같은 레코드 테이블을 공유하면
-- 한쪽에서 `Set` 으로 값을 덮어쓸 때 다른 쪽까지 바뀝니다.
const function Clone<K, V>(self: TreeMapData<K, V>): TreeMap<K, V>
	const records = table.create(self.size) :: { Record<K, V> }
	const source = self.records
	for idx = 1, self.size do
		const rec = source[idx]
		records[idx] = { key = rec.key, value = rec.value }
	end
	return setmetatable(
		{
			records = records,
			size = self.size,
			compare = self.compare,
			probe = self.probe,
		} :: any,
		Ifce :: any
	) :: any
end

--#endregion

--#region ----------- 타입 조립 -----------
-- ⭐ `Get`/`Set`/`Records` 는 **여기 없습니다.** `Types.MapCore` 가 줍니다.

type TreeMapIfce = {
	Has: typeof(Has),
	GetOr: typeof(GetOr),
	Len: typeof(Len),
	Empty: typeof(Empty),
	Keys: typeof(Keys),
	Values: typeof(Values),
	Iter: typeof(Iter),
	First: typeof(First),
	Last: typeof(Last),
	FloorKey: typeof(FloorKey),
	CeilingKey: typeof(CeilingKey),
	RangeRecords: typeof(RangeRecords),
	Remove: typeof(Remove),
	Clear: typeof(Clear),
	Clone: typeof(Clone),
}

export type TreeMap<K, V> = TreeMapData<K, V> & TreeMapIfce & Types.MapCore<K, V>

-- 범주별로 묶어 두는 편이 읽기 좋은 디스패치 테이블입니다. 한 줄에 하나씩
-- 펼치면 배로 길어지고 그룹 주석과의 대응이 흩어집니다.
-- stylua: ignore
Ifce = {
	Has = Has, GetOr = GetOr, Len = Len, Empty = Empty,
	Keys = Keys, Values = Values, Iter = Iter,
	First = First, Last = Last, FloorKey = FloorKey, CeilingKey = CeilingKey,
	RangeRecords = RangeRecords,
	Remove = Remove, Clear = Clear, Clone = Clone,
	-- 계약이 주는 것들.
	Get = Get, Set = Set, Records = Records,
} :: any
(Ifce :: any).__index = Ifce

--#endregion

--#region ----------- 생성자 -----------

const function makeProbe<K, V>(compare: Comparator<K>): KeyProbe<K, V>
	return function(element: Record<K, V>, target: K): number
		return compare(element.key, target)
	end
end

const function adopt<K, V>(records: { Record<K, V> }, size: number, compare: Comparator<K>): TreeMap<K, V>
	return setmetatable(
		{
			records = records,
			size = size,
			compare = compare,
			probe = makeProbe(compare),
		} :: any,
		Ifce :: any
	) :: any
end

-- ⚠️ **값 타입은 캐스트로 적어야 합니다.** 비교자에서 `K` 는 뽑히지만 `V` 는
-- 나올 자리가 없고, Luau 는 기대 타입을 제네릭 호출 안으로 전파하지 않습니다.
--
--     local m = TreeMap.New(Common.compareNumber) :: TreeMap<number, string>
const function New<K, V>(compare: Comparator<K>): TreeMap<K, V>
	return adopt({} :: { Record<K, V> }, 0, compare)
end

-- 키-값 쌍 목록에서 만듭니다. **정렬해서 담고 중복 키는 뒤엣것이 이깁니다.**
--
-- ⚠️ 한 번에 정렬해서 담습니다(O(n log n)). `Set` 을 n 번 부르면 삽입마다
-- 뒤를 밀어 **O(n^2)** 이 됩니다 — 큰 입력에서 그 차이가 큽니다.
--
-- 동점(비교자가 0 을 돌려주는 두 키)에서 어느 쪽이 이길지를 정해두려고
-- 원래 위치를 타이브레이커로 씁니다. `table.sort` 는 안정 정렬이 아니라서
-- 이걸 안 하면 "뒤엣것이 이긴다" 가 보장되지 않습니다.
const function FromRecords<K, V>(records: { Record<K, V> }, compare: Comparator<K>): TreeMap<K, V>
	const count = #records
	if count == 0 then
		return adopt({} :: { Record<K, V> }, 0, compare)
	end
	const order = table.create(count) :: { number }
	for idx = 1, count do
		order[idx] = idx
	end
	table.sort(order, function(x: number, y: number): boolean
		const diff = compare(records[x].key, records[y].key)
		if diff ~= 0 then
			return diff < 0
		end
		return x < y
	end)
	const out = table.create(count) :: { Record<K, V> }
	local size = 0
	for pos = 1, count do
		const source = records[order[pos]]
		if size > 0 and compare(out[size].key, source.key) == 0 then
			-- 같은 키가 이어지면 뒤엣것으로 덮어씁니다.
			out[size] = { key = source.key, value = source.value }
		else
			size += 1
			out[size] = { key = source.key, value = source.value }
		end
	end
	return adopt(out, size, compare)
end

const function isTreeMap(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Ifce
end

--#endregion

return {
	New = New,
	FromRecords = FromRecords,
	Adopt = adopt,
	isTreeMap = isTreeMap,
}

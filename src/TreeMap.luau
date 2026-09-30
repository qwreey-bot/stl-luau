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

-- ⭐ **NaN 키는 받지 않습니다.** NaN 은 자기 자신과도 같지 않아 어떤 3방향
-- 비교자로도 순서가 서지 않고, 조용히 넣으면 **다른 키까지** 못 찾게 되고
-- 같은 키가 중복으로 들어갔습니다(2026-09-30 리뷰). `HashMap` 은 Lua 가 이미
-- `table index is NaN` 으로 시끄럽게 거절하므로 같은 태도입니다.
-- 조회·삭제에 NaN 을 주면 "없음" 입니다.
const function isNaN(key: any): boolean
	return key ~= key
end

-- `pos` 의 레코드를 빼고 뒤를 당깁니다. `Set(k, nil)` 과 `Remove` 가 같이 씁니다.
const function removeAt<K, V>(self: TreeMapData<K, V>, pos: number): V
	const records = self.records
	const size = self.size
	const removed = records[pos].value
	table.move(records, pos + 1, size, pos)
	records[size] = nil :: any
	self.size = size - 1
	return removed
end

const function Get<K, V>(self: TreeMapData<K, V>, key: K): V?
	if isNaN(key) then
		return nil
	end
	const pos = BSearch.Find(self.records, self.size, key, self.probe)
	if pos == nil then
		return nil
	end
	return self.records[pos].value
end

-- 값을 넣습니다. 이미 있으면 덮어쓰고, 없으면 **정렬 위치에 끼워넣습니다**.
-- 끼워넣기는 뒤를 미는 O(n) 이지만 `table.move` 라 C 안에서 돕니다.
--
-- ⭐ **값이 `nil` 이면 삭제입니다** — `HashMap` 과 같은 규칙이고 Lua 의
-- `t[k] = nil` 과 같습니다. 예전엔 `nil` 값을 레코드로 저장해서 같은 `MapCore`
-- 인데 두 맵의 뜻이 달랐습니다(2026-09-30 리뷰).
const function Set<K, V>(self: TreeMapData<K, V>, key: K, value: V): ()
	if isNaN(key) then
		error("TreeMap: NaN key", 2)
	end
	const records = self.records
	const size = self.size
	const pos = BSearch.LowerBound(records, size, key, self.probe)
	const found = pos <= size and self.probe(records[pos], key) == 0
	if value == nil then
		if found then
			removeAt(self, pos)
		end
		return
	end
	if found then
		(records[pos] :: any).value = value
		return
	end
	if pos <= size then
		table.move(records, pos, size, pos + 1)
	end
	records[pos] = { key = key, value = value }
	self.size = size + 1
end

-- 받은 쪽에 내줄 레코드. **새로 만듭니다** — 내부 레코드를 그대로 주면
-- 받은 쪽이 `rec.key = 99` 로 고쳤을 때 정렬이 깨져 **다른 키까지** 못 찾게
-- 됐습니다(2026-09-30 리뷰). `HashMap.Records` 도 원래 새로 만들어 주므로 비용
-- 모양이 같습니다. 할당 없이 돌려면 `Iter` 를 쓰세요.
const function copyRecord<K, V>(rec: Record<K, V>): Record<K, V>
	return { key = rec.key, value = rec.value }
end

-- 키-값 쌍의 목록. **정렬 순서이고, 레코드까지 복사본입니다.**
const function Records<K, V>(self: TreeMapData<K, V>): { Record<K, V> }
	const size = self.size
	const records = self.records
	const out = table.create(size) :: { Record<K, V> }
	for idx = 1, size do
		out[idx] = copyRecord(records[idx])
	end
	return out
end

--#endregion

--#region ----------- 조회 -----------

const function Has<K, V>(self: TreeMapData<K, V>, key: K): boolean
	if isNaN(key) then
		return false
	end
	return BSearch.Find(self.records, self.size, key, self.probe) ~= nil
end

const function GetOr<K, V>(self: TreeMapData<K, V>, key: K, fallback: V): V
	if isNaN(key) then
		return fallback
	end
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
--
-- ⭐ **상태를 클로저에 담습니다.** 예전엔 인덱스를 제어 변수로 쓰면서 첫
-- 반환값으로 **키**를 돌려줘서, generic for 가 키를 다음 인덱스로 넘겼습니다.
-- 키가 우연히 `1, 2, 3` 인 테스트만 통과했고, 키가 `10, 20` 이면 첫 원소에서
-- 멈추고 문자열이면 크래시했습니다(2026-09-30 발견). `Iter()` 한 번에 클로저
-- 하나가 들고 원소마다 드는 비용은 없습니다.
-- `(K, V)` 비옵셔널 선언인 것은 `ipairs` 와 같은 이유입니다.
const function Iter<K, V>(self: TreeMapData<K, V>): () -> (K, V)
	local idx = 0
	return function(): (K, V)
		idx += 1
		if idx > self.size then
			return nil :: any, nil :: any
		end
		const rec = self.records[idx]
		return rec.key, rec.value
	end
end

--#endregion

--#region ----------- 정렬이 있어야만 되는 것들 -----------

-- 가장 작은 키의 쌍. 비어 있으면 `nil`.
const function First<K, V>(self: TreeMapData<K, V>): Record<K, V>?
	if self.size == 0 then
		return nil
	end
	return copyRecord(self.records[1])
end

const function Last<K, V>(self: TreeMapData<K, V>): Record<K, V>?
	if self.size == 0 then
		return nil
	end
	return copyRecord(self.records[self.size])
end

-- `key` **이하**인 키 중 가장 큰 것. 없으면 `nil`.
const function FloorKey<K, V>(self: TreeMapData<K, V>, key: K): K?
	if isNaN(key) then
		return nil
	end
	const pos = BSearch.UpperBound(self.records, self.size, key, self.probe)
	if pos == 1 then
		return nil
	end
	return self.records[pos - 1].key
end

-- `key` **이상**인 키 중 가장 작은 것. 없으면 `nil`.
const function CeilingKey<K, V>(self: TreeMapData<K, V>, key: K): K?
	if isNaN(key) then
		return nil
	end
	const pos = BSearch.LowerBound(self.records, self.size, key, self.probe)
	if pos > self.size then
		return nil
	end
	return self.records[pos].key
end

-- 키 구간 `[fromKey, toKey]` 의 쌍들. **양끝 포함**이고 정렬 순서입니다.
-- 구간이 뒤집혀 있으면 빈 목록입니다(이 저장소의 구간 규약).
const function RangeRecords<K, V>(self: TreeMapData<K, V>, fromKey: K, toKey: K): { Record<K, V> }
	if isNaN(fromKey) or isNaN(toKey) then
		return {}
	end
	const records = self.records
	const size = self.size
	const first = BSearch.LowerBound(records, size, fromKey, self.probe)
	const last = BSearch.UpperBound(records, size, toKey, self.probe) - 1
	if last < first then
		return {}
	end
	const out = table.create(last - first + 1) :: { Record<K, V> }
	for idx = first, last do
		out[idx - first + 1] = copyRecord(records[idx])
	end
	return out
end

--#endregion

--#region ----------- 변형 -----------

-- 키를 지우고 **지워진 값**을 돌려줍니다. 없었으면 `nil`.
const function Remove<K, V>(self: TreeMapData<K, V>, key: K): V?
	if isNaN(key) then
		return nil
	end
	const pos = BSearch.Find(self.records, self.size, key, self.probe)
	if pos == nil then
		return nil
	end
	return removeAt(self, pos)
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

-- ⚠️ **값 타입을 직접 알려줘야 합니다.** 비교자에서 `K` 는 뽑히지만 `V` 는
-- 나올 자리가 없습니다.
--
--     local m = TreeMap.New<<number, string>>(Common.compareNumber)   -- 권장
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
		if isNaN(records[idx].key) then
			error("TreeMap: NaN key", 2)
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
	-- `Set` 과 같은 규칙: 마지막 값이 nil 인 키는 삭제된 것으로 봅니다.
	local kept = 0
	for pos = 1, size do
		const rec = out[pos]
		if rec.value ~= nil then
			kept += 1
			out[kept] = rec
		end
	end
	for pos = kept + 1, size do
		out[pos] = nil :: any
	end
	return adopt(out, kept, compare)
end

const function isTreeMap(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Ifce
end

--#endregion

-- stylua: ignore
return {
	New = New,
	FromRecords = FromRecords,
	Adopt = adopt,
	isTreeMap = isTreeMap,

	-- ⭐ 메소드를 **네임스페이스 함수로도** 노출합니다 — 절차적 호출이 이
	-- 라이브러리의 정식 모양입니다(`TreeMap.X(v, …)`). 콜론 호출과 같은 함수이고,
	-- 메타테이블을 안 거쳐 18% 빠르며 `local` 로 받아 부르면 36% 빠릅니다
	-- (`.claude/base/perf-measurements.md` 14절).
	Has = Has, GetOr = GetOr, Len = Len, Empty = Empty, Keys = Keys, Values = Values, Iter = Iter,
	First = First, Last = Last, FloorKey = FloorKey, CeilingKey = CeilingKey,
	RangeRecords = RangeRecords, Remove = Remove, Clear = Clear, Clone = Clone, Get = Get, Set = Set,
	Records = Records,
}

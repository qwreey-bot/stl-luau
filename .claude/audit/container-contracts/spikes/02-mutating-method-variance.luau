--!strict
-- 계약에 "K 를 입력으로 받는 변경 연산"이 있으면 공용 알고리즘의 제네릭이 깨지는가?
export type MapRecord<K, V> = { key: K, value: V }

-- R: 읽기 전용 계약
export type ReadMap<K, V> = {
	Get: (self: ReadMap<K, V>, k: K) -> V?,
	Records: (self: ReadMap<K, V>) -> { MapRecord<K, V> },
}
-- W: 변경 연산 포함 (K, V 둘 다 입력 자리)
export type RWMap<K, V> = {
	Get: (self: RWMap<K, V>, k: K) -> V?,
	Set: (self: RWMap<K, V>, k: K, v: V) -> (),
	Records: (self: RWMap<K, V>) -> { MapRecord<K, V> },
}

local function KeysR<K, V>(m: ReadMap<K, V>): { K }
	local recs = m:Records()
	local out: { K } = table.create(#recs)
	for i, r in recs do out[i] = r.key end
	return out
end
local function KeysW<K, V>(m: RWMap<K, V>): { K }
	local recs = m:Records()
	local out: { K } = table.create(#recs)
	for i, r in recs do out[i] = r.key end
	return out
end

local r = (nil :: any) :: ReadMap<string, number>
local w = (nil :: any) :: RWMap<string, number>
type RWTree<K, V> = RWMap<K, V> & { Ordered: (self: RWTree<K, V>) -> { MapRecord<K, V> } }
local wt = (nil :: any) :: RWTree<string, number>

local k1: { string } = KeysR(r)   -- 읽기 계약
local k2: { string } = KeysW(w)   -- 변경 계약, 확장 없음
local k3: { string } = KeysW(wt)  -- 변경 계약 + 교집합 확장  ← 의심 지점

-- 읽기 계약으로 받으면? (변경 구현체를 읽기 알고리즘에 넘기기)
local k4: { string } = KeysR(w :: any)

local canary: string = 42
return { k1, k2, k3, k4, canary }

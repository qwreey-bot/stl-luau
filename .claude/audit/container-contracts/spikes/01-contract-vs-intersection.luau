--!strict
-- 공용 알고리즘에 "계약을 확장한 구현체"를 넘기면 제네릭이 제대로 풀리는가?
-- 확장 방식 3가지를 비교한다.
export type MapRecord<K, V> = { key: K, value: V }
export type MapCore<K, V> = {
	Get: (self: MapCore<K, V>, k: K) -> V?,
	Records: (self: MapCore<K, V>) -> { MapRecord<K, V> },
}
local function Keys<K, V>(m: MapCore<K, V>): { K }
	local recs = m:Records()
	local out: { K } = table.create(#recs)
	for i, r in recs do
		out[i] = r.key
	end
	return out
end

-- A: 계약 그대로 (확장 없음)
local a = (nil :: any) :: MapCore<string, number>
local ka: { string } = Keys(a)

-- B: 교집합으로 확장
type MapB<K, V> = MapCore<K, V> & { Ordered: (self: MapB<K, V>) -> { MapRecord<K, V> } }
local b = (nil :: any) :: MapB<string, number>
local kb: { string } = Keys(b)

-- C: 계약 필드를 펼쳐 쓴 단일 테이블 (교집합 아님)
type MapC<K, V> = {
	Get: (self: MapCore<K, V>, k: K) -> V?,
	Records: (self: MapCore<K, V>) -> { MapRecord<K, V> },
	Ordered: (self: MapC<K, V>) -> { MapRecord<K, V> },
}
local c = (nil :: any) :: MapC<string, number>
local kc: { string } = Keys(c)

-- D: 계약을 필드로 품음 (컴포지션)
type MapD<K, V> = { core: MapCore<K, V>, Ordered: (self: MapD<K, V>) -> { MapRecord<K, V> } }
local d = (nil :: any) :: MapD<string, number>
local kd: { string } = Keys(d.core)

local canary: string = 42
return { ka, kb, kc, kd, canary }

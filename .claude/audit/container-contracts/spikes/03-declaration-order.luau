--!strict
-- ⚠️ 선언 순서 의존 재현. Tree 절이 Map 절보다 **앞**이라 Keys(tm) 이
-- `{K & string}` 로 샙니다(기대: `{string}`). 04 는 순서만 바꾼 것이고 통과합니다.
-- quad typing-limits §8.21 과 같은 계열 — 거기엔 Luau 솔버 소스까지 파고든
-- 원인 분석이 있습니다(무한 확장 가드가 아직 안 풀린 참조를 오판).
-- 기대 진단: 2건 (누수 1 + canary 1)
export type TreeCore<K, V> = {
	Root: (self: TreeCore<K, V>) -> K?,
	Left: (self: TreeCore<K, V>, key: K) -> K?,
}
-- 재귀 제네릭 함수
local function Height<K, V>(tree: TreeCore<K, V>, key: K?): number
	if key == nil then return 0 end
	return 1 + Height(tree, tree:Left(key))
end
export type MapRecord<K, V> = { key: K, value: V }
export type MapCore<K, V> = { Records: (self: MapCore<K, V>) -> { MapRecord<K, V> } }
local function Keys<K, V>(m: MapCore<K, V>): { K }
	local recs = m:Records()
	local out: { K } = table.create(#recs)
	for i, r in recs do out[i] = r.key end
	return out
end
type TreeMap<K, V> = MapCore<K, V> & { Ordered: (self: TreeMap<K, V>) -> { MapRecord<K, V> } }
local tm = (nil :: any) :: TreeMap<string, number>
local k1: { string } = Keys(tm)
local canary: string = 42
return { k1, canary }

--!strict
-- 03 에서 **선언 순서만** 바꾼 것(Map 절을 Tree 절보다 앞으로). 통과합니다.
-- 기대 진단: 1건 (canary 만)
export type MapRecord<K, V> = { key: K, value: V }
export type MapCore<K, V> = { Records: (self: MapCore<K, V>) -> { MapRecord<K, V> } }
local function Keys<K, V>(m: MapCore<K, V>): { K }
	local recs = m:Records()
	local out: { K } = table.create(#recs)
	for i, r in recs do out[i] = r.key end
	return out
end
export type TreeCore<K, V> = {
	Root: (self: TreeCore<K, V>) -> K?,
	Left: (self: TreeCore<K, V>, key: K) -> K?,
}
-- 재귀 제네릭 함수
local function Height<K, V>(tree: TreeCore<K, V>, key: K?): number
	if key == nil then return 0 end
	return 1 + Height(tree, tree:Left(key))
end
type TreeMap<K, V> = MapCore<K, V> & { Ordered: (self: TreeMap<K, V>) -> { MapRecord<K, V> } }
local tm = (nil :: any) :: TreeMap<string, number>
local k1: { string } = Keys(tm)
local canary: string = 42
return { k1, canary }

--!strict
-- 예전 Assignment9 Utils 의 계약 3종이 Luau 타입에서 서는가?
--   (1) 위치 타입을 파라미터로 뺀 트리 — 배열 기반과 연결 기반이 같은 알고리즘 공유
--   (2) 해시 전략 주입 (Hasher 인터페이스)
--   (3) Map 계약에 레코드 타입까지 포함 (Assignment8 의 이름 갈림을 막은 것)

--#region (1) 트리: Key 가 위치 타입
export type TreeCore<K, V> = {
	Root: (self: TreeCore<K, V>) -> K?,
	Value: (self: TreeCore<K, V>, key: K) -> V?,
	Left: (self: TreeCore<K, V>, key: K) -> K?,
	Right: (self: TreeCore<K, V>, key: K) -> K?,
}
-- 알고리즘은 한 번만 — 구현을 모른다
local function Height<K, V>(tree: TreeCore<K, V>, key: K?): number
	if key == nil then return 0 end
	local l = Height(tree, tree:Left(key))
	local r = Height(tree, tree:Right(key))
	return 1 + (if l > r then l else r)
end
type Node<V> = { value: V, left: Node<V>?, right: Node<V>? }
type ArrayTree<V> = TreeCore<number, V>   -- 배열 기반: 위치 = 인덱스
type LinkedTree<V> = TreeCore<Node<V>, V> -- 연결 기반: 위치 = 노드
--#endregion

--#region (2) 해시 전략 주입
export type Hasher<T> = { Hash: (self: Hasher<T>, value: T, maxHash: number) -> number }
local function NewHashMap<K, V>(hasher: Hasher<K>): HashMap<K, V>
	return nil :: any
end
export type HashMap<K, V> = {
	Set: (self: HashMap<K, V>, k: K, v: V) -> (),
	Get: (self: HashMap<K, V>, k: K) -> V?,
}
--#endregion

--#region (3) Map 계약 — 레코드 타입까지 포함
export type MapRecord<K, V> = { key: K, value: V }
export type MapCore<K, V> = {
	Set: (self: MapCore<K, V>, k: K, v: V) -> (),
	Get: (self: MapCore<K, V>, k: K) -> V?,
	Records: (self: MapCore<K, V>) -> { MapRecord<K, V> },
}
-- 같은 계약 위의 공용 알고리즘 — 해시맵이든 트리맵이든 동일
local function Keys<K, V>(m: MapCore<K, V>): { K }
	local records = m:Records()
	local out: { K } = table.create(#records)
	for idx, rec in records do
		out[idx] = rec.key
	end
	return out
end
type TreeMap<K, V> = MapCore<K, V> & { Ordered: (self: TreeMap<K, V>) -> { MapRecord<K, V> } }
--#endregion

local at = (nil :: any) :: ArrayTree<string>
local lt = (nil :: any) :: LinkedTree<string>
local hm = (nil :: any) :: HashMap<string, number>
local tm = (nil :: any) :: TreeMap<string, number>

-- POS: 같은 알고리즘이 두 트리 구현에
local h1: number = Height(at, at:Root())
local h2: number = Height(lt, lt:Root())
-- POS: 같은 Keys 가 해시맵/트리맵에
local k1: { string } = Keys(tm)
local intHasher = (nil :: any) :: Hasher<number>
local m2 = NewHashMap(intHasher)

-- NEG: 전부 에러여야 함
local n1 = Height(at, lt:Root())          -- 배열트리에 연결트리의 위치
local n2: Node<string>? = at:Left(1)      -- 배열트리의 위치는 number
local n3: string = hm:Get("k")            -- V 는 number
local n4: HashMap<number, boolean> = NewHashMap((nil :: any) :: Hasher<string>) -- 해셔 키 불일치
local n5: number = Keys(tm)[1]            -- K 는 string
local canary: string = 42
return { h1, h2, k1, m2, n1, n2, n3, n4, n5, canary }

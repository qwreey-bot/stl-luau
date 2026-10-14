--!strict
-- 맵: 타입 인자 순서 <K, V>. 트레이트 연관 타입 별칭은 <E(값), I(키)> 순서 — 어긋남
type MyMap<K, V> = { read __generics: { read Item: (V) -> V, read Index: (K) -> K }, data: { [K]: V } }
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
local function getOf<Self, E, I>(m: Self & ItemIndex<E, I>, key: I): E? return nil end
local m: MyMap<string, number> = nil :: any
const v: number? = getOf(m, "k")
const NEG_v: string? = getOf(m, "k") -- NEG
const NEG_k = getOf(m, 5) -- NEG: 키는 string
-- 인라인으로 적으면
local function getOf2<Self, E, I>(m: Self & { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }, key: I): E? return nil end
const v2: number? = getOf2(m, "k")
const NEG_v2: string? = getOf2(m, "k") -- NEG
const NEG_k2 = getOf2(m, 5) -- NEG
local canary: string = 1

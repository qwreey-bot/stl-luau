--!strict
-- 상류 결함 후보(2026-10-15, luau 0.742): 교집합 `A & B` 를 `C & X` 자리에 넘기면 `C` 가 `A | B`(유니온)로 풀림 — 그래서 바깥 컨테이너 타입은
-- 트레이트를 교집합(`{ … } & stl.Map<K, V>`)이 아니라 **필드**(`read __traits: { read Map: stl.MapAssoc<K, V> }`)로 적습니다. (1) 은 에러, (2) 는 됨.
type Rec<K, V> = { read Key: () -> K, read Value: () -> V, read Mut: (K, V) -> (K, V) }
type MapV<K, V> = { read __traits: { read Map: Rec<K, V> } }
local function into<C, K, V>(c: C & MapV<K, V>, _k: K, _v: V): C
	return c
end
-- (1) 교집합으로 적은 바깥 타입
type BagI<V> = { slots: { [string]: V } } & MapV<string, V>
local bi: BagI<number> = nil :: any
local r1 = into(bi, "a", 1)
local s1 = r1.slots -- 교집합이면 되어야 함
-- (2) 필드로 적은 바깥 타입
type BagF<V> = { slots: { [string]: V }, read __traits: { read Map: Rec<string, V> } }
local bf: BagF<number> = nil :: any
local r2 = into(bf, "a", 1)
local s2 = r2.slots
return { s1, s2 }

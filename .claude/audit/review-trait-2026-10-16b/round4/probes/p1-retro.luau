--!strict
-- 맨 인자가 있는 칸의 **반환** 인덱서가 읽기 전용을 잃는가(T2 와 같은 메커니즘이 반환 쪽에)
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<K, V> = { read Item: () -> (K, V) }
type Assoc<K, V> = { read Item: () -> (K, V), read Mut: (K, V) -> (K, V) }
type ValueRead<K, V> = { read __type: stl.TraitToken<any>, read __traits: { read Multi: AssocRead<K, V> } }
type Value<K, V> = { read __type: stl.TraitToken<any>, read __traits: { read Multi: Assoc<K, V> } }
local Multi
do
	Multi = Trait.Trait("P1.Multi", function<Self, K, V>(of: (Self & ValueRead<K, V>) | AnyToken, ofMut: (Self & Value<K, V>) | AnyToken)
		return table.freeze({
			All = Trait.Fn<<(m: Self) -> { read [K]: { read [number]: V } }>>(), -- 인덱서 칸(유지)
			GetAll = Trait.Fn<<(m: Self, key: K) -> { read [number]: V }>>(), -- 맨 K + 반환 인덱서
			GetAllOpt = Trait.Fn<<(m: Self, key: K?) -> { read [number]: V }>>(), -- K? (유니온, 유지)
		})
	end)
end
type MyMulti<K, V> = { read __type: stl.TraitToken<"P1">, read __traits: { read Multi: Assoc<K, V> } }
local m: MyMulti<string, number> = nil :: any
local all = Multi.All(m)
local inner = all.x
local l = Multi.GetAll(m, "x") -- POS
local v: number? = l[1] -- POS
l[1] = 5 -- NEG: 맵 안쪽 리스트에 쓰기 (읽기 전용 약속)
local l2 = Multi.GetAllOpt(m, "x") -- POS
l2[1] = 5 -- NEG
Multi.GetAll(m, 1) -- NEG: 키
return { inner, v }

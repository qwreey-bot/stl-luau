--!strict
-- 정의 제네릭 셋 <Self, K, V> — 유지 칸이 서로 다른 부분집합을 씀, of/ofMut 조건이 다름
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<K, V> = { read Key: () -> K, read Value: () -> V }
type Assoc<K, V> = { read Key: () -> K, read Value: () -> V, read Mut: (K, V) -> (K, V) }
type ValueRead<K, V> = { read __type: stl.TraitToken<any>, read __traits: { read Tbl: AssocRead<K, V> } }
type Value<K, V> = { read __type: stl.TraitToken<any>, read __traits: { read Tbl: Assoc<K, V> } }
local Tbl
do
	Tbl = Trait.Trait("P5.Tbl", function<Self, K, V>(of: (Self & ValueRead<K, V>) | AnyToken, ofMut: (Self & Value<K, V>) | AnyToken)
		return table.freeze({
			Keys = Trait.Fn<<(t: Self) -> { read [number]: K }>>(), -- K 만
			Vals = Trait.Fn<<(t: Self) -> { read [number]: V }>>(), -- V 만
			PutAll = Trait.FnMut<<(t: Self, src: { read [K]: V }) -> ()>>(), -- K, V
			GetMany = Trait.Fn<<(t: Self, keys: { read [number]: K }) -> { read [number]: V? }>>(), -- K 인자, V 반환
			Put = Trait.FnMut<<(t: Self, k: K, v: V) -> ()>>(), -- 인덱서 없음(다시 지음)
			PutVals = Trait.FnMut<<(t: Self, k: K, vs: { read [number]: V }) -> ()>>(), -- 맨 K + 인덱서(다시 지음)
			OnlyV = Trait.Fn<<(t: Self, vs: { read [number]: V }, f: (V) -> boolean) -> boolean>>(), -- V 만 + 콜백
		})
	end)
end
type MyTbl<K, V> = { read __type: stl.TraitToken<"P5">, read __traits: { read Tbl: Assoc<K, V> } }
local t: MyTbl<string, number> = nil :: any
local arrN = stl.Arr.Of(1, 2)
local arrS = stl.Arr.Of("a", "b")
local k1 = Tbl.Keys(t) -- POS
local k2: string? = k1[1] -- POS
local k3: number? = k1[1] -- NEG
k1[1] = "z" -- NEG
local v1 = Tbl.Vals(t) -- POS
local v2: number? = v1[1] -- POS
local v3: string? = v1[1] -- NEG
Tbl.PutAll(t, { a = 1 }) -- POS
Tbl.PutAll(t, { a = "s" }) -- NEG
local g1 = Tbl.GetMany(t, { "a" }) -- POS
local g1b = Tbl.GetMany(t, arrS) -- POS
local g2: number? = g1[1] -- POS
local g3: string? = g1[1] -- NEG
g1[1] = 3 -- NEG
Tbl.Put(t, "a", 1) -- POS
Tbl.Put(t, "a", "s") -- NEG
Tbl.PutVals(t, "a", { 1 }) -- POS
Tbl.PutVals(t, "a", { "s" }) -- NEG
Tbl.PutVals(t, "a", arrN) -- BND
local o1: boolean = Tbl.OnlyV(t, { 1 }, function(x: number): boolean return true end) -- POS
local o1b: boolean = Tbl.OnlyV(t, arrN, function(x: number): boolean return true end) -- POS
local o2 = Tbl.OnlyV(t, { 1 }, function(x: string): boolean return true end) -- NEG
return { k2, k3, v2, v3, g1b, g2, g3, o1, o1b, o2 }

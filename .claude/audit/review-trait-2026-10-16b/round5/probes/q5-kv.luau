--!strict
-- <Self, K, V> 맵 모양, <Self> 만, 별칭으로 감싼 맨 제네릭
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<K, V> = { read Key: () -> K, read Value: () -> V }
type Assoc<K, V> = { read Key: () -> K, read Value: () -> V, read Mut: (K, V) -> (K, V) }
type ValueRead<K, V> = { read __type: stl.TraitToken<any>, read __traits: { read Q5: AssocRead<K, V> } }
type Value<K, V> = { read __type: stl.TraitToken<any>, read __traits: { read Q5: Assoc<K, V> } }
type Elem<X> = X
type Q5S = { read __type: stl.TraitToken<any>, read __traits: { read Q5S: { read Mut: true } } }
local Tbl, Solo
do
	Tbl = Trait.Trait("Q5.Tbl", function<Self, K, V>(of: (Self & ValueRead<K, V>) | AnyToken, ofMut: (Self & Value<K, V>) | AnyToken)
		return table.freeze({
			Keys = Trait.Fn<<(t: Self) -> { read [number]: K }>>(),
			FirstOf = Trait.FnMut<<(t: Self, keys: { read [number]: K }) -> V?>>(),
			PairOf = Trait.FnMut<<(t: Self, keys: { read [number]: K }) -> (K?, V?)>>(),
			EachKV = Trait.FnMut<<(t: Self, keys: { read [number]: K }, f: (K, V) -> ()) -> ()>>(),
			PutAlias = Trait.FnMut<<(t: Self, k: Elem<K>, vs: { read [number]: V }) -> ()>>(),
			GetOrMany = Trait.FnMut<<(t: Self, keys: { read [number]: K }, fallback: V?) -> { V }>>(),
		})
	end)
	Solo = Trait.Trait("Q5.Solo", function<Self>(of: (Self & Q5S) | AnyToken)
		return table.freeze({
			MergeAll = Trait.FnMut<<(s: Self, others: { read [number]: Self }) -> ()>>(),
			ByName = Trait.Fn<<(s: Self, named: { read [string]: Self }) -> Self?>>(),
			Tag = Trait.FnMut<<(s: Self, names: { read [number]: string }) -> Self>>(),
		})
	end)
end
type MyTbl<K, V> = { read __type: stl.TraitToken<"Q5">, read __traits: { read Q5: Assoc<K, V> } }
type MyS = { read __type: stl.TraitToken<"Q5s">, read __traits: { read Q5S: { read Mut: true } } }
type OtherS = { read __type: stl.TraitToken<"Q5o">, read __traits: { read Q5S: { read Mut: true } } }
local t: MyTbl<string, number> = nil :: any
local arrS = stl.Arr.Of("a")
local k = Tbl.Keys(t) -- POS
local f1: number? = Tbl.FirstOf(t, { "a" }) -- POS
local f2: number? = Tbl.FirstOf(t, arrS) -- POS
local f3: string? = Tbl.FirstOf(t, { "a" }) -- NEG
Tbl.FirstOf(t, { 1 }) -- NEG
local p1: string?, p2: number? = Tbl.PairOf(t, { "a" }) -- POS
local p3: string?, p4: string? = Tbl.PairOf(t, { "a" }) -- NEG
Tbl.EachKV(t, { "a" }, function(kk: string, v: number) end) -- POS
Tbl.EachKV(t, arrS, function(kk: string, v: number) end) -- POS
Tbl.EachKV(t, { "a" }, function(kk: string, v: string) end) -- NEG
Tbl.PutAlias(t, "a", { 1 }) -- POS
Tbl.PutAlias(t, 1, { 1 }) -- NEG
Tbl.PutAlias(t, "a", { "s" }) -- NEG
local g1: { number } = Tbl.GetOrMany(t, { "a" }, 0) -- POS
local g2: { number } = Tbl.GetOrMany(t, arrS, nil) -- POS
Tbl.GetOrMany(t, { "a" }, "s") -- NEG
local s: MyS = nil :: any
local o: OtherS = nil :: any
Solo.MergeAll(s, { s }) -- POS
local bn: MyS? = Solo.ByName(s, { x = s }) -- POS
local bn2: OtherS? = Solo.ByName(s, { x = s }) -- NEG
local tg: MyS = Solo.Tag(s, { "a" }) -- POS
local tg2: OtherS = Solo.Tag(s, { "a" }) -- NEG
return { k, f1, f2, f3, p1, p2, p3, p4, g1, g2, bn, bn2, tg, tg2, o }

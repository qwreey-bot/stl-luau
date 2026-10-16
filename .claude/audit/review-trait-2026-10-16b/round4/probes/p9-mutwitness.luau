--!strict
-- 살아남은 돌연변이(Y02·Y10·Y12·Y13)를 잡는 줄 후보
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag9: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag9: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("P9.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
			Log = Trait.Fn<<(bag: Self, pool: { read [number]: T }, ...any) -> ()>>(),
			FoldIn = Trait.Fn<<<U>(bag: Self, init: U, f: (U, T) -> U, pool: { read [number]: T }) -> U>>(),
			AddAllS = Trait.FnMut<<(bag: Self, items: { read [number]: T }) -> Self>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"P9">, read __traits: { read Bag9: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
Bag.Log(b, arr, "x", 1) -- POS (Y02)
local f1: number = Bag.FoldIn(b, 0, function(a: number, x: number): number return a end, arr) -- POS (Y10)
local s1: MyBag<number> = Bag.AddAllS(b, arr) -- POS (Y12)
local l = Bag.ToList(b)
return { f1, s1, l }

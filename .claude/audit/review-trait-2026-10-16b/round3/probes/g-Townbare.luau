--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Townbare: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Townbare: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Townbare", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			FoldL = Trait.Fn<<<U>(bag: Self, init: U, f: (U, T) -> U, pool: { read [number]: T }) -> U>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Townbarex">, read __traits: { read Townbare: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
local f1: number = Bag.FoldL(b, 0, function(a: number, x: number): number return a end, { 1 }) -- POS
local f2: number = Bag.FoldL(b, 0, function(a: number, x: string): number return a end, { 1 }) -- NEG
return nil

--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Otwo: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Otwo: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Otwo", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			Zip = Trait.Fn<<(bag: Self, a: { read [number]: T }, c: { read [number]: T }) -> ()>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Otwox">, read __traits: { read Otwo: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
Bag.Zip(b, { 1 }, { 2 }) -- POS
Bag.Zip(b, arr, arr) -- POS
Bag.Zip(b, { 1 }, { "s" }) -- NEG
return nil

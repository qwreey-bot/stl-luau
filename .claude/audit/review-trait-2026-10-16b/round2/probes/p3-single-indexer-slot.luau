--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag3: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag3: Assoc<T> } }

local Bag
do
	Bag = Trait.Trait("P3.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			Push = Trait.FnMut<<(bag: Self, item: T) -> ()>>(),
			PushWithRest = Trait.FnMut<<(bag: Self, first: T, rest: { read [number]: T }) -> ()>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"P3">, read __traits: { read Bag3: Assoc<T> } }
local b: MyBag<number> = nil :: any
Bag.Push(b, 1)
Bag.PushWithRest(b, 1, { 2, 3 }) -- POS (only indexer slot in the trait)
Bag.PushWithRest(b, "x", { 2 }) -- NEG
return nil

--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Ointer2: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Ointer2: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Ointer2", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			PushI = Trait.FnMut<<(bag: Self, x: T & number, rest: { read [number]: T }) -> ()>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Ointer2x">, read __traits: { read Ointer2: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
Bag.PushI(b, 1, { 2 }) -- POS
return nil

--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Ofnparam: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Ofnparam: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Ofnparam", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			Apply = Trait.FnMut<<(bag: Self, f: (T) -> T, pool: { read [number]: T }) -> ()>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Ofnparamx">, read __traits: { read Ofnparam: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
Bag.Apply(b, function(x: number): number return x end, { 1 }) -- POS
Bag.Apply(b, function(x: string): string return x end, { 1 }) -- NEG
return nil

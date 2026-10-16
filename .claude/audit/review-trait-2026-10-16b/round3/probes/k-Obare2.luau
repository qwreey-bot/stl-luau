--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Obare2: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Obare2: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Obare2", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			PushA = Trait.FnMut<<(bag: Self, x: T, rest: { read [number]: T }) -> ()>>(),
			PushB = Trait.FnMut<<(bag: Self, x: T?, rest: { T }) -> ()>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Obare2x">, read __traits: { read Obare2: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
Bag.PushA(b, 1, { 2 }) -- POS
Bag.PushB(b, 1, { 2 }) -- POS
Bag.PushA(b, "s", { 2 }) -- NEG
Bag.PushB(b, "s", { 2 }) -- NEG
return nil

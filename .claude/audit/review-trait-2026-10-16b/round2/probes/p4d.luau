--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bp4d: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("p4d", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			PushWithRest = Trait.Fn<<(bag: Self, first: T, rest: { read [number]: T }) -> ()>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"p4dx">, read __traits: { read Bp4d: Assoc<T> } }
local b: MyBag<number> = nil :: any
Bag.PushWithRest(b, 1, { 2 }) -- POS
local f = Bag.PushWithRest
f(b, 1, {2}) -- POS
return nil

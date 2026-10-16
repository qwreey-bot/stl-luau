--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bp4a: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("p4a", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			PushWithRest = Trait.Fn<<(bag: Self, first: T, rest: { read [number]: T }) -> ()>>(),
			ToList = Trait.Fn<<(bag: Self) -> { T }>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"p4ax">, read __traits: { read Bp4a: Assoc<T> } }
local b: MyBag<number> = nil :: any
Bag.PushWithRest(b, 1, { 2 }) -- POS
local l: { number } = Bag.ToList(b) -- POS
return nil

--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bp4c: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("p4c", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { T }>>(),
			View = Trait.Fn<<(bag: Self) -> { read [string]: T }>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"p4cx">, read __traits: { read Bp4c: Assoc<T> } }
local b: MyBag<number> = nil :: any
local l: { number } = Bag.ToList(b) -- POS
local v = Bag.View(b)
local x: number? = v.a -- POS
local nx: string? = v.a -- NEG
return nil

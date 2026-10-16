--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bp4f: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("p4f", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			Drain = Trait.Fn<<(bag: Self, into: { T }) -> T?>>(),
			ToList = Trait.Fn<<(bag: Self) -> { T }>>(),
			Each = Trait.Fn<<(bag: Self, fn: (T) -> ()) -> { T }>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"p4fx">, read __traits: { read Bp4f: Assoc<T> } }
local b: MyBag<number> = nil :: any
local into: { number } = {}
local d: number? = Bag.Drain(b, into) -- POS
local nd: string? = Bag.Drain(b, into) -- NEG
local e = Bag.Each(b, function(x: number) end) -- POS
local ne = Bag.Each(b, function(x: string) end) -- NEG
return { d, nd, e, ne }

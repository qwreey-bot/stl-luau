--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q1b: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q1b: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Q1b.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
			FindOpt = Trait.Fn<<(bag: Self, pool: { read [number]: T }) -> T?>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Q1b">, read __traits: { read Q1b: Assoc<T> } }
local b: MyBag<number> = nil :: any
Bag.FindOpt(b, { "s" }) -- NEG
local h1 = Bag.FindOpt(b, { "s" }) -- NEG
local h2: number? = Bag.FindOpt(b, { "s" }) -- NEG
local h3: typeof(Bag.FindOpt) = nil :: any
local h4: nil = Bag.FindOpt -- dump
return { h1, h2, h3 }

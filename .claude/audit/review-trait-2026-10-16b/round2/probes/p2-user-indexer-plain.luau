--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag: Assoc<T> } }

local Bag
do
	Bag = Trait.Trait("P2.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			Push = Trait.FnMut<<(bag: Self, item: T) -> ()>>(),
			PushWithRest = Trait.FnMut<<(bag: Self, first: T, rest: { read [number]: T }) -> ()>>(),
			IndexIn = Trait.Fn<<(bag: Self, item: T, pool: { T }) -> number?>>(),
			ToList = Trait.Fn<<(bag: Self) -> { T }>>(),
			Has = Trait.Fn<<(bag: Self, item: T) -> boolean>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"P2">, read __traits: { read Bag: Assoc<T> } }
local b: MyBag<number> = nil :: any

-- POS (should be 0 errors)
Bag.Push(b, 1)
Bag.PushWithRest(b, 1, { 2, 3 }) -- POS-A
local i: number? = Bag.IndexIn(b, 1, { 1, 2 }) -- POS-B
local l: { number } = Bag.ToList(b) -- POS-C
local h: boolean = Bag.Has(b, 1)
-- NEG
Bag.Push(b, "x") -- NEG
Bag.PushWithRest(b, "x", { 2 }) -- NEG-A
Bag.PushWithRest(b, 1, { "y" }) -- NEG-A2
local nl: { string } = Bag.ToList(b) -- NEG-C
return { i, l, h, nl }

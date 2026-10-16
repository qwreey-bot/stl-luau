--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Okeyset: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Okeyset: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Okeyset", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			HasAll = Trait.Fn<<(bag: Self, keys: { read [T]: boolean }) -> boolean>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Okeysetx">, read __traits: { read Okeyset: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
local h1: boolean = Bag.HasAll(b, { [1] = true }) -- POS
local h2 = Bag.HasAll(b, { s = true }) -- NEG
return nil

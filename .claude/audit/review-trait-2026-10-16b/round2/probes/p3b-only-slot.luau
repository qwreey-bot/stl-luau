--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag4: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("P3b.Bag", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			Has = Trait.Fn<<(bag: Self, item: T, among: { T }) -> boolean>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"P3b">, read __traits: { read Bag4: Assoc<T> } }
local b: MyBag<number> = nil :: any
local h: boolean = Bag.Has(b, 1, { 1 }) -- POS
local h2 = Bag.Has(b, "x", { 1 }) -- NEG
return { h, h2 }

--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
export type AssocRead<T> = { read Item: () -> T }
export type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
export type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag: AssocRead<T> } }
export type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag: Assoc<T> } }
type Box<T> = { read v: T }
local Bag
do
	Bag = Trait.Trait("P2.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			Base = Trait.Fn<<(bag: Self) -> T?>>(),
			Make = Trait.Fn<<() -> Self>>(),
		})
	end)
end
local _x: nil = Bag.Make
local _y: nil = Bag.Base
return nil

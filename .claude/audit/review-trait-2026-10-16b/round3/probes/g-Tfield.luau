--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Tfield: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Tfield: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Tfield", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			Conf = Trait.Fn<<(bag: Self, opts: { read x: T, read list: { read [number]: T } }) -> ()>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Tfieldx">, read __traits: { read Tfield: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
Bag.Conf(b, { x = 1, list = { 2 } }) -- POS
Bag.Conf(b, { x = 1, list = arr }) -- POS
Bag.Conf(b, { x = "s", list = { 2 } }) -- NEG
Bag.Conf(b, { x = 1, list = { "s" } }) -- NEG
return nil

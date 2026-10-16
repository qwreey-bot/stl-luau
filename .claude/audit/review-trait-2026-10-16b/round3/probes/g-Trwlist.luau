--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Trwlist: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Trwlist: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Trwlist", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			Drain = Trait.FnMut<<(bag: Self, into: { T }) -> ()>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Trwlistx">, read __traits: { read Trwlist: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
local into: { number } = {}; Bag.Drain(b, into) -- POS
local into2: { string } = {}; Bag.Drain(b, into2) -- NEG
return nil

--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Tcb: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Tcb: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Tcb", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			Each = Trait.Fn<<(bag: Self, fn: (T) -> (), pool: { read [number]: T }) -> ()>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Tcbx">, read __traits: { read Tcb: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
Bag.Each(b, function(x: number) end, { 1 }) -- POS
Bag.Each(b, function(x: number) end, arr) -- POS
Bag.Each(b, function(x: string) end, { 1 }) -- NEG
Bag.Each(b, function(x: number) end, { "s" }) -- NEG
return nil

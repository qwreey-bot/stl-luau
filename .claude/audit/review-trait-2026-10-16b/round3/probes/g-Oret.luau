--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Oret: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Oret: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Oret", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			Pop2 = Trait.FnMut<<(bag: Self) -> (T?, { read [number]: T })>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Oretx">, read __traits: { read Oret: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
local r1: number?, r2 = Bag.Pop2(b) -- POS
local r3: string? = Bag.Pop2(b) -- NEG
return nil

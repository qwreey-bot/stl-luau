--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Otail: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Otail: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Otail", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			PushMany = Trait.FnMut<<(bag: Self, pool: { read [number]: T }, ...T) -> ()>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Otailx">, read __traits: { read Otail: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
Bag.PushMany(b, { 1 }, 2, 3) -- POS
Bag.PushMany(b, arr, 2) -- POS
Bag.PushMany(b, { 1 }, "s") -- NEG
Bag.PushMany(b, { "s" }, 2) -- NEG
return nil

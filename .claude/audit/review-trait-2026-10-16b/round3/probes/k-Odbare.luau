--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Odbare: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Odbare: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Odbare", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			PushE = Trait.Default(function(_ops: any): (bag: Self, x: T, pool: { read [number]: T }) -> ()
				return function(_bag: Self, _x: T, _pool: { read [number]: T }) end
			end),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Odbarex">, read __traits: { read Odbare: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
Bag.PushE(b, 1, { 1 }) -- POS
Bag.PushE(b, "s", { 1 }) -- NEG
return nil

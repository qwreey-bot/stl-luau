--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Odmutbare: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Odmutbare: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Odmutbare", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			PushD = Trait.DefaultMut(function(_ops: any): (bag: Self, x: T, pool: { read [number]: T }) -> ()
				return function(_bag: Self, _x: T, _pool: { read [number]: T }) end
			end, Trait.Sig<<(bag: Self, x: T, pool: { read [number]: T }) -> ()>>()),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Odmutbarex">, read __traits: { read Odmutbare: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
Bag.PushD(b, 1, { 1 }) -- POS
Bag.PushD(b, "s", { 1 }) -- NEG
Bag.PushD(b, 1, arr) -- BND
return nil

--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Tdsigtail: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Tdsigtail: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Tdsigtail", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			PushManyD = Trait.Default(function(_ops: any): (bag: Self, pool: { read [number]: T }, ...T) -> ()
				return function(_bag: Self, _pool: { read [number]: T }, ...: T) end
			end, Trait.Sig<<(bag: Self, pool: { read [number]: T }, ...T) -> ()>>()),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Tdsigtailx">, read __traits: { read Tdsigtail: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
Bag.PushManyD(b, { 1 }, 2) -- POS
Bag.PushManyD(b, { 1 }, "s") -- NEG
return nil

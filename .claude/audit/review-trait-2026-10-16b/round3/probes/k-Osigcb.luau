--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Osigcb: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Osigcb: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Osigcb", function<Self, T>(of: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			SomeIn = Trait.Default(function(_ops: any): (bag: Self, pool: { read [number]: T }, pred: (T, ...any) -> boolean) -> boolean
				return function(_bag: Self, _pool: { read [number]: T }, _pred: (T, ...any) -> boolean): boolean return false end
			end, Trait.Sig<<(bag: Self, pool: { read [number]: T }, pred: (T) -> boolean) -> boolean>>()),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Osigcbx">, read __traits: { read Osigcb: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
local so1: boolean = Bag.SomeIn(b, { 1 }, function(x: number): boolean return true end) -- POS
local so2: boolean = Bag.SomeIn(b, arr, function(x: number): boolean return true end) -- POS
local so3: boolean = Bag.SomeIn(b, { 1 }, function(x: string): boolean return true end) -- NEG
return nil

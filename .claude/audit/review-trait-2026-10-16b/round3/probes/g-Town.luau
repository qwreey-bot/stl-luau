--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Town: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Town: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Town", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			MapInto = Trait.Fn<<<U>(bag: Self, f: (T) -> U, into: { U }) -> { U }>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Townx">, read __traits: { read Town: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
local into3: { string } = {}; local m1: { string } = Bag.MapInto(b, function(x: number): string return "" end, into3) -- POS
local into4: { string } = {}; local m2 = Bag.MapInto(b, function(x: string): string return "" end, into4) -- NEG
return nil

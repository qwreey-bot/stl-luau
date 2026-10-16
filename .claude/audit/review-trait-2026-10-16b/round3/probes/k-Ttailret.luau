--!strict
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Ttailret: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Ttailret: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Ttailret", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(), -- 다른 인덱서 칸(유지되는 칸)
			PushRet = Trait.FnMut<<(bag: Self, ...T) -> { read [number]: T }>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Ttailretx">, read __traits: { read Ttailret: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local tl = Bag.ToList(b) -- POS
local pr = Bag.PushRet(b, 1, 2) -- POS
Bag.PushRet(b, "s") -- NEG
local pr2: number? = pr[1] -- POS
return nil

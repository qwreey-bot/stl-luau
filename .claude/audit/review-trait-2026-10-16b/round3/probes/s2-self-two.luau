--!strict
-- 맨 Self 를 받는 인덱서 칸이 둘 + 맨 T 칸 + 다른 인덱서 칸 (vB 의 기준이 Self 를 건너뛰어도 되는가)
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read S2: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read S2: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("S2", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
			Merge = Trait.FnMut<<(bag: Self, other: Self, pool: { read [number]: T }) -> ()>>(),
			Pair = Trait.Fn<<(bag: Self, other: Self, pool: { read [number]: T }) -> boolean>>(),
			PushWithRest = Trait.FnMut<<(bag: Self, first: T, rest: { read [number]: T }) -> ()>>(),
			Swap = Trait.FnMut<<(bag: Self, ...Self) -> { read [number]: Self }>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"S2x">, read __traits: { read S2: Assoc<T> } }
type Other<T> = { read __type: stl.TraitToken<"S2o">, read __traits: { read S2: Assoc<T> } }
local b: MyBag<number> = nil :: any
local o: Other<number> = nil :: any
local bs: MyBag<string> = nil :: any
local arr = stl.Arr.Of(1, 2)
Bag.Merge(b, b, { 1 }) -- POS
Bag.Merge(b, b, arr) -- POS
local pp: boolean = Bag.Pair(b, b, arr) -- POS
Bag.PushWithRest(b, 1, { 2 }) -- POS
local sw = Bag.Swap(b, b, b) -- POS
Bag.Merge(b, b, { "s" }) -- NEG
Bag.Merge(b, bs, { 1 }) -- NEG
Bag.Merge(b, o, { 1 }) -- NEG
return { pp, sw }

--!strict
-- 둘째 반환·반환 꼬리의 맨 제네릭(돌연변이 R02·R06·R07 판별)
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q7: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q7: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Q7.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
			TryPick = Trait.FnMut<<(bag: Self, pool: { read [number]: T }) -> (boolean, T)>>(),
			Unpack = Trait.Fn<<(bag: Self, w: { read [number]: number }) -> ...T>>(),
			Dump = Trait.Fn<<(bag: Self, pool: { read [number]: T }) -> ...any>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Q7">, read __traits: { read Q7: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local ok1: boolean, v1: number = Bag.TryPick(b, { 1 }) -- POS
local ok2: boolean, v2: string = Bag.TryPick(b, { 1 }) -- NEG
local u1: number = Bag.Unpack(b, { 1 }) -- POS
local u2: string = Bag.Unpack(b, { 1 }) -- NEG
Bag.Dump(b, arr) -- POS
return { ok1, v1, ok2, v2, u1, u2 }

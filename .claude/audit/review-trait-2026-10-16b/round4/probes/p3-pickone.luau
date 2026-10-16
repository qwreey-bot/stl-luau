--!strict
-- 맨 T 반환 칸 — 인덱서 칸이 하나뿐일 때
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag3: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag3: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("P3.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			Peek = Trait.Fn<<(bag: Self) -> T?>>(),
			Pick = Trait.Fn<<(bag: Self, pool: { read [number]: T }) -> T>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"P3">, read __traits: { read Bag3: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local p1: number = Bag.Pick(b, { 1 }) -- POS
local p2: number = Bag.Pick(b, arr) -- POS
local p3: string = Bag.Pick(b, { 1 }) -- NEG
Bag.Pick(b, { "s" }) -- NEG
local function hand<Self, T>(bag: Self & ValueRead<T>, pool: { read [number]: T }): T return nil :: any end
local h1: number = hand(b, { 1 }) -- POS
local h2: number = hand(b, arr) -- POS
hand(b, { "s" }) -- NEG
return { p1, p2, p3, h1, h2 }

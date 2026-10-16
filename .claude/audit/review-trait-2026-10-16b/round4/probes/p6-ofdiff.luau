--!strict
-- of 와 ofMut 의 조건이 다름(쓰기 칸은 더 넓은 조건) + 인덱서 칸 여럿
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag6: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag6: Assoc<T> }, read size: number }
local Bag
do
	Bag = Trait.Trait("P6.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
			AddAll = Trait.FnMut<<(bag: Self, items: { read [number]: T }) -> Self>>(),
			Push = Trait.FnMut<<(bag: Self, x: T, more: { read [number]: T }) -> Self>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"P6">, read __traits: { read Bag6: Assoc<T> }, read size: number }
type RoBag<T> = { read __type: stl.TraitToken<"P6">, read __traits: { read Bag6: AssocRead<T> } }
local b: MyBag<number> = nil :: any
local r: RoBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local l = Bag.ToList(r) -- POS
local a1: MyBag<number> = Bag.AddAll(b, arr) -- POS
Bag.AddAll(r, { 1 }) -- NEG: 읽기 참조로 쓰기
Bag.AddAll(b, { "s" }) -- NEG
local p1: MyBag<number> = Bag.Push(b, 1, { 2 }) -- POS
Bag.Push(r, 1, { 2 }) -- NEG: 읽기 참조
Bag.Push(b, "s", { 2 }) -- NEG
l[1] = 3 -- NEG
return { a1, p1 }

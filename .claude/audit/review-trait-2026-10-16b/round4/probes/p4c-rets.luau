--!strict
-- 반환 쪽 맨 제네릭의 여러 꼴 (인덱서 칸 여럿)
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag4: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag4: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("P4.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
			Choose = Trait.Fn<<(bag: Self, weights: { read [number]: number }) -> T>>(),
			Both = Trait.Fn<<(bag: Self, weights: { read [number]: number }) -> (T, T)>>(),
			Tail = Trait.Fn<<(bag: Self, weights: { read [number]: number }) -> ...T>>(),
			ChainS = Trait.FnMut<<(bag: Self, weights: { read [number]: number }) -> Self>>(),
			NoIdx = Trait.Fn<<(bag: Self, i: number) -> T>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"P4">, read __traits: { read Bag4: Assoc<T> } }
local b: MyBag<number> = nil :: any
local w = { 1, 2 }
local c1: number = Bag.Choose(b, w) -- POS
local c2: string = Bag.Choose(b, w) -- NEG
local d1: number, d2: number = Bag.Both(b, w) -- POS
local e1: number = Bag.Tail(b, w) -- POS
local e2: string = Bag.Tail(b, w) -- NEG
local s1: MyBag<number> = Bag.ChainS(b, w) -- POS
local n1: number = Bag.NoIdx(b, 1) -- POS
local n2: string = Bag.NoIdx(b, 1) -- NEG
local wa = stl.Arr.Of(1, 2)
local c9: number = Bag.Choose(b, wa) -- POS: T 없는 읽기 리스트에 Arr
return { c9, c1, c2, d1, d2, e1, e2, s1, n1, n2 }

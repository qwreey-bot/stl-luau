--!strict
-- 5라운드: 인덱서 칸 여럿 + 아직 안 본 현실적인 모양
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q1: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q1: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Q1.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
			AddAll = Trait.FnMut<<(bag: Self, items: { read [number]: T }) -> ()>>(),
			FindOpt = Trait.Fn<<(bag: Self, pool: { read [number]: T }) -> T?>>(),
			ChooseOpt = Trait.Fn<<(bag: Self, w: { read [number]: number }) -> T?>>(),
			RetRec = Trait.Fn<<(bag: Self, w: { read [number]: number }) -> { read first: T }>>(),
			RetSelfOpt = Trait.Fn<<(bag: Self, w: { read [number]: number }) -> Self?>>(),
			RetTupOpt = Trait.Fn<<(bag: Self, w: { read [number]: number }) -> (number, T?)>>(),
			EachS = Trait.Fn<<(bag: Self, pool: { read [number]: T }, f: (Self, T) -> ()) -> ()>>(),
			AddArr = Trait.FnMut<<(bag: Self, a: stl.ArrRead<T>) -> ()>>(),
			ToArr = Trait.Fn<<(bag: Self) -> stl.Arr<T>>>(),
			AddOptList = Trait.FnMut<<(bag: Self, pool: { read [number]: T }?) -> ()>>(),
			RetRw = Trait.Fn<<(bag: Self) -> { T }>>(),
			RetGetter = Trait.Fn<<(bag: Self, w: { read [number]: number }) -> () -> T?>>(),
			RetMap = Trait.Fn<<(bag: Self, keys: { read [number]: string }) -> { read [string]: T }>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Q1">, read __traits: { read Q1: Assoc<T> } }
type OtherBag<T> = { read __type: stl.TraitToken<"Q1o">, read __traits: { read Q1: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local arrS = stl.Arr.Of("a")
local w = { 1, 2 }
local t1 = Bag.ToList(b) -- POS
Bag.AddAll(b, arr) -- POS
local a1: number? = Bag.FindOpt(b, { 1 }) -- POS
local a2: number? = Bag.FindOpt(b, arr) -- POS
local a3: string? = Bag.FindOpt(b, { 1 }) -- NEG
Bag.FindOpt(b, { "s" }) -- NEG
local c1: number? = Bag.ChooseOpt(b, w) -- POS
local c2: string? = Bag.ChooseOpt(b, w) -- NEG
local r1: number = Bag.RetRec(b, w).first -- POS
local r2: string = Bag.RetRec(b, w).first -- NEG
local s1: MyBag<number>? = Bag.RetSelfOpt(b, w) -- POS
local s2: OtherBag<number>? = Bag.RetSelfOpt(b, w) -- NEG
local u1: number, u2: number? = Bag.RetTupOpt(b, w) -- POS
local u3: number, u4: string? = Bag.RetTupOpt(b, w) -- NEG
Bag.EachS(b, { 1 }, function(x: MyBag<number>, v: number) end) -- POS
Bag.EachS(b, arr, function(x: MyBag<number>, v: number) end) -- POS
Bag.EachS(b, { 1 }, function(x: MyBag<number>, v: string) end) -- NEG
Bag.EachS(b, { 1 }, function(x: OtherBag<number>, v: number) end) -- NEG
Bag.AddArr(b, arr) -- POS
Bag.AddArr(b, arrS) -- NEG
local x1: stl.Arr<number> = Bag.ToArr(b) -- POS
local x2: stl.Arr<string> = Bag.ToArr(b) -- NEG
Bag.AddOptList(b, nil) -- POS
Bag.AddOptList(b, { 1 }) -- POS
Bag.AddOptList(b, arr) -- POS
Bag.AddOptList(b, { "s" }) -- NEG
local rw = Bag.RetRw(b) -- POS
local rw1: number? = rw[1] -- POS
local rw2: string? = rw[1] -- NEG
local gt1: number? = Bag.RetGetter(b, w)() -- POS
local gt2: string? = Bag.RetGetter(b, w)() -- NEG
local m = Bag.RetMap(b, { "a" }) -- POS
local m1: number? = m.a -- POS
local m2: string? = m.a -- NEG
m.a = 3 -- NEG
return { t1, a1, a2, a3, c1, c2, r1, r2, s1, s2, u1, u2, u3, u4, x1, x2, rw1, rw2, gt1, gt2, m1, m2 }

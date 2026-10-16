--!strict
-- 유니온·교집합 안의 정의 제네릭(맨 제네릭이 아님)을 받는 인덱서 칸이 여럿 — 그대로 둬도(다시 짓지 않아도) 맞는 호출이 통과하는가
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read U1: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read U1: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("U1", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
			PushOpt = Trait.FnMut<<(bag: Self, x: T?, rest: { read [number]: T }) -> ()>>(),
			PushOpt2 = Trait.FnMut<<(bag: Self, x: T?, rest: { read [number]: T }) -> ()>>(),
			PushOr = Trait.FnMut<<(bag: Self, x: T | string, rest: { read [number]: T }) -> ()>>(),
			MergeOpt = Trait.FnMut<<(bag: Self, other: Self?, rest: { read [number]: T }) -> ()>>(),
			MergeOpt2 = Trait.FnMut<<(bag: Self, other: Self?, rest: { read [number]: T }) -> ()>>(),
			PushAnd = Trait.FnMut<<(bag: Self, x: T & number, rest: { read [number]: T }) -> ()>>(),
			PushAnd2 = Trait.FnMut<<(bag: Self, x: T & number, rest: { read [number]: T }) -> ()>>(),
			PushTailOpt = Trait.FnMut<<(bag: Self, rest: { read [number]: T }, ...T?) -> ()>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"U1x">, read __traits: { read U1: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
Bag.PushOpt(b, 1, arr) -- POS
Bag.PushOpt2(b, nil, { 1 }) -- POS
Bag.PushOr(b, "s", arr) -- POS
Bag.PushOr(b, 1, { 1 }) -- POS
Bag.MergeOpt(b, b, arr) -- POS
Bag.MergeOpt2(b, nil, { 1 }) -- POS
Bag.PushAnd(b, 1, arr) -- POS
Bag.PushAnd2(b, 1, { 1 }) -- POS
Bag.PushTailOpt(b, arr, 1, nil) -- POS
Bag.PushOpt(b, "s", { 1 }) -- NEG
Bag.PushOr(b, true, { 1 }) -- NEG
Bag.PushOpt2(b, 1, { "s" }) -- NEG
Bag.PushTailOpt(b, arr, "s") -- NEG
return nil

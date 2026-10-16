--!strict
-- 유니온 갈래의 맨 제네릭이 여러 유지 칸에
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q6: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q6: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Q6.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			PushOptA = Trait.FnMut<<(bag: Self, x: T?, rest: { read [number]: T }) -> ()>>(),
			PushOptB = Trait.FnMut<<(bag: Self, rest: { read [number]: T }, x: T?) -> T?>>(),
			SwapOpt = Trait.FnMut<<(bag: Self, x: T?, pool: { read [number]: T }) -> T?>>(),
			Replace = Trait.FnMut<<(bag: Self, pool: { read [number]: T }, old: T?, new: T?) -> boolean>>(),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Q6">, read __traits: { read Q6: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
Bag.PushOptA(b, 1, { 2 }) -- POS
Bag.PushOptA(b, 1, arr) -- POS
Bag.PushOptA(b, "s", { 2 }) -- NEG
local x1: number? = Bag.PushOptB(b, { 2 }, 1) -- POS
local x2: number? = Bag.PushOptB(b, arr, nil) -- POS
Bag.PushOptB(b, { 2 }, "s") -- NEG
local x3: string? = Bag.PushOptB(b, { 2 }, 1) -- NEG
local y1: number? = Bag.SwapOpt(b, 1, arr) -- POS
local y2: number? = Bag.SwapOpt(b, nil, { 1 }) -- POS
Bag.SwapOpt(b, "s", { 1 }) -- NEG
local z1: boolean = Bag.Replace(b, arr, 1, 2) -- POS
local z2: boolean = Bag.Replace(b, { 1 }, nil, 2) -- POS
Bag.Replace(b, { 1 }, 1, "s") -- NEG
return { x1, x2, x3, y1, y2, z1, z2 }

--!strict
-- 쓰기 칸(불변 조건) + 기본 구현·Sig + 맨 람다
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q3: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q3: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("Q3.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
			TakeOpt = Trait.FnMut<<(bag: Self, pool: { read [number]: T }) -> T?>>(),
			EachM = Trait.FnMut<<(bag: Self, pool: { read [number]: T }, f: (T) -> ()) -> ()>>(),
			RetainM = Trait.FnMut<<(bag: Self, keep: (T, number) -> boolean, extra: { read [number]: T }) -> number>>(),
			AddOrList = Trait.FnMut<<(bag: Self, x: T | { read [number]: T }) -> ()>>(),
			FindD = Trait.Default(function(_ops: any): (bag: Self, pool: { read [number]: T }) -> T?
				return function(_bag: Self, _pool: { read [number]: T }): T?
					return nil
				end
			end),
			TakeD = Trait.DefaultMut(function(_ops: any): (bag: Self, pool: { read [number]: T }) -> (boolean, T?)
				return function(_bag: Self, _pool: { read [number]: T }): (boolean, T?)
					return false, nil
				end
			end),
			FindSig = Trait.Default(function(_ops: any): (bag: Self, pool: { read [number]: T }, ...any) -> T?
				return function(_bag: Self, _pool: { read [number]: T }, ...: any): T?
					return nil
				end
			end, Trait.Sig<<(bag: Self, pool: { read [number]: T }) -> T?>>()),
			PickSig = Trait.Default(function(_ops: any): (bag: Self, pool: { read [number]: T }, ...any) -> T
				return function(_bag: Self, pool: { read [number]: T }, ...: any): T
					return pool[1]
				end
			end, Trait.Sig<<(bag: Self, pool: { read [number]: T }) -> T>>()),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"Q3">, read __traits: { read Q3: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local t1 = Bag.ToList(b) -- POS
local a1: number? = Bag.TakeOpt(b, { 1 }) -- POS
local a2: number? = Bag.TakeOpt(b, arr) -- POS
local a3: string? = Bag.TakeOpt(b, { 1 }) -- NEG
Bag.TakeOpt(b, { "s" }) -- NEG
Bag.EachM(b, { 1 }, function(x: number) end) -- POS
Bag.EachM(b, arr, function(x) local y: number = x + 1 end) -- POS
Bag.EachM(b, { 1 }, function(x) local y: string = x end) -- NEG
Bag.EachM(b, { 1 }, function(x: string) end) -- NEG
local n1: number = Bag.RetainM(b, function(x: number, i: number): boolean return x > i end, { 1 }) -- POS
local n2: number = Bag.RetainM(b, function(x, i) return x > i end, arr) -- POS
Bag.RetainM(b, function(x: string, i: number): boolean return true end, { 1 }) -- NEG
Bag.AddOrList(b, 1) -- POS
Bag.AddOrList(b, { 1 }) -- POS
Bag.AddOrList(b, arr) -- POS
Bag.AddOrList(b, "s") -- NEG
local d1: number? = Bag.FindD(b, { 1 }) -- POS
local d2: number? = Bag.FindD(b, arr) -- POS
local d3: string? = Bag.FindD(b, { 1 }) -- NEG
local e1: boolean, e2: number? = Bag.TakeD(b, { 1 }) -- POS
local e3: boolean, e4: number? = Bag.TakeD(b, arr) -- POS
local e5: boolean, e6: string? = Bag.TakeD(b, { 1 }) -- NEG
Bag.TakeD(b, { "s" }) -- NEG
local g1: number? = Bag.FindSig(b, { 1 }) -- POS
local g2: number? = Bag.FindSig(b, arr) -- POS
local g3: string? = Bag.FindSig(b, { 1 }) -- NEG
local h1: number = Bag.PickSig(b, { 1 }) -- POS
local h2: number = Bag.PickSig(b, arr) -- BND (맨 반환 → 다시 지음)
local h3: string = Bag.PickSig(b, { 1 }) -- NEG
return { t1, a1, a2, a3, n1, n2, d1, d2, d3, e1, e2, e3, e4, e5, e6, g1, g2, g3, h1, h2, h3 }

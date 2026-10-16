--!strict
-- 맨 람다(주석 없음) — 진입점 대 손 서명, 칸 하나 대 둘
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q4: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Q4: Assoc<T> } }
local Two, One
do
	Two = Trait.Trait("Q4.Two", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
			EachM = Trait.FnMut<<(bag: Self, pool: { read [number]: T }, f: (T) -> ()) -> ()>>(),
			Each0 = Trait.FnMut<<(bag: Self, f: (T) -> ()) -> ()>>(),
		})
	end)
	One = Trait.Trait("Q4.One", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			EachM = Trait.FnMut<<(bag: Self, pool: { read [number]: T }, f: (T) -> ()) -> ()>>(),
		})
	end)
end
local EachH: <T>(bag: Value<T>, pool: { read [number]: T }, f: (T) -> ()) -> () = nil :: any
type MyBag<T> = { read __type: stl.TraitToken<"Q4">, read __traits: { read Q4: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
Two.EachM(b, arr, function(x) local y: number = x + 1 end) -- POS two/arr
Two.EachM(b, { 1 }, function(x) local y: number = x + 1 end) -- POS two/lit
Two.EachM(b, arr, function(x) local y: number = x end) -- POS two/arr assign
Two.Each0(b, function(x) local y: number = x + 1 end) -- POS two/no-pool (rebuilt? no indexer)
One.EachM(b, arr, function(x) local y: number = x + 1 end) -- POS one/arr
One.EachM(b, { 1 }, function(x) local y: number = x + 1 end) -- POS one/lit
EachH(b, arr, function(x) local y: number = x + 1 end) -- POS hand/arr
EachH(b, { 1 }, function(x) local y: number = x + 1 end) -- POS hand/lit
local d: nil = Two.EachM -- dump
local d1: nil = One.EachM -- dump
return nil

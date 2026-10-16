--!strict
-- 인덱서 칸 여럿 + 여러 모양(맨 반환, 맨 Self 반환, 반환 함수만, 콜백 안 맨 T, 필드 표, Default+Sig)
local stl = require("../src")
local Trait = stl.Trait
type AnyToken = stl.TraitToken<string>
type AssocRead<T> = { read Item: () -> T }
type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
type ValueRead<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag2: AssocRead<T> } }
type Value<T> = { read __type: stl.TraitToken<any>, read __traits: { read Bag2: Assoc<T> } }
local Bag
do
	Bag = Trait.Trait("P2.Bag", function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
		return table.freeze({
			ToList = Trait.Fn<<(bag: Self) -> { read [number]: T }>>(),
			AddAll = Trait.FnMut<<(bag: Self, items: { read [number]: T }) -> ()>>(),
			-- 맨 T 반환(인자엔 인덱서만)
			Pick = Trait.Fn<<(bag: Self, pool: { read [number]: T }) -> T>>(),
			-- 맨 Self 반환
			Chain = Trait.FnMut<<(bag: Self, items: { read [number]: T }) -> Self>>(),
			-- 반환 함수 안의 맨 T 만(인자엔 인덱서 원소가 number 고정)
			Getter = Trait.Fn<<(bag: Self, idx: { read [number]: number }) -> (number) -> T>>(),
			-- 콜백 인자 (T) -> T
			Apply = Trait.FnMut<<(bag: Self, f: (T) -> T, pool: { read [number]: T }) -> ()>>(),
			-- 필드 표 { read x: T } 와 인덱서
			Conf = Trait.FnMut<<(bag: Self, opts: { read x: T }, pool: { read [number]: T }) -> ()>>(),
			-- 맨 T 둘
			Two = Trait.FnMut<<(bag: Self, a: T, c: T, pool: { read [number]: T }) -> ()>>(),
			-- Default + Sig: Sig 에 맨 T
			PushD = Trait.DefaultMut(function(_ops: any): (bag: Self, x: any, pool: { read [number]: T }) -> ()
				return function(_bag: Self, _x: any, _pool: { read [number]: T }) end
			end, Trait.Sig<<(bag: Self, x: T, pool: { read [number]: T }) -> ()>>()),
			-- Default + Sig: 칸 타입엔 맨 T, Sig 엔 없음
			PushE = Trait.DefaultMut(function(_ops: any): (bag: Self, x: T, pool: { read [number]: T }) -> ()
				return function(_bag: Self, _x: T, _pool: { read [number]: T }) end
			end, Trait.Sig<<(bag: Self, x: T?, pool: { read [number]: T }) -> ()>>()),
		})
	end)
end
type MyBag<T> = { read __type: stl.TraitToken<"P2">, read __traits: { read Bag2: Assoc<T> } }
type OtherBag<T> = { read __type: stl.TraitToken<"P2o">, read __traits: { read Bag2: Assoc<T> } }
local b: MyBag<number> = nil :: any
local arr = stl.Arr.Of(1, 2)
local t1 = Bag.ToList(b) -- POS
Bag.AddAll(b, arr) -- POS
local p1: number = Bag.Pick(b, { 1 }) -- POS
local p2: number = Bag.Pick(b, arr) -- POS
local p3: string = Bag.Pick(b, { 1 }) -- NEG
Bag.Pick(b, { "s" }) -- NEG
local c1: MyBag<number> = Bag.Chain(b, { 1 }) -- POS
local c2: MyBag<number> = Bag.Chain(b, arr) -- POS
local c3: OtherBag<number> = Bag.Chain(b, { 1 }) -- NEG
local g1: number = Bag.Getter(b, { 1 })(1) -- POS
local g2: string = Bag.Getter(b, { 1 })(1) -- NEG
Bag.Apply(b, function(x: number): number return x end, { 1 }) -- POS
Bag.Apply(b, function(x: number): number return x end, arr) -- POS
Bag.Apply(b, function(x: string): string return x end, { 1 }) -- NEG
Bag.Conf(b, { x = 1 }, { 1 }) -- POS
Bag.Conf(b, { x = 1 }, arr) -- POS
Bag.Conf(b, { x = 1 }, { "s" }) -- NEG
Bag.Two(b, 1, 2, { 1 }) -- POS
Bag.Two(b, 1, "s", { 1 }) -- NEG
Bag.Two(b, 1, 2, arr) -- BND
Bag.PushD(b, 1, { 1 }) -- POS
Bag.PushD(b, "s", { 1 }) -- NEG
Bag.PushE(b, 1, { 1 }) -- POS
Bag.PushE(b, nil, { 1 }) -- POS
Bag.PushE(b, 1, arr) -- POS
Bag.PushE(b, "s", { 1 }) -- NEG
return { t1, p1, p2, p3, c1, c2, c3, g1, g2 }

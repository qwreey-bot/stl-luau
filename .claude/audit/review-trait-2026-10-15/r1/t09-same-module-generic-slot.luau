--!strict
-- 타입 프로브 t09: 같은 모듈에서 정의한 트레이트의 **제네릭 기본 구현 칸**(`<U>`)이 등록 표에서 얼마나 검사되나.
-- (다른 모듈에서 정의하면 전부 잡힘 — t08 (1)~(4).) 대조로 필수 칸에 제네릭을 둔 경우도.
local stl = require("../../../../src")
local Trait = stl.Trait
type Tok = stl.TraitToken<string>
type A = { read __probeA: true }
type Bag<T> = { read __type: Tok, read __generics: { read Item: (T) -> T }, items: { T } }
local F = Trait.Trait("T09.F", function<Self, T>(of: (Self & stl.TraitItem<T>) | Tok)
	return table.freeze({
		Each = Trait.Fn<<(bag: Self, fn: (T) -> ()) -> ()>>(),
		Map = Trait.Fn<<<U>(bag: Self, fn: (T) -> U) -> { U }>>(), -- 필수 칸에 제네릭
		Fold = Trait.Default(function(ops: any): <U>(bag: Self, init: U, fn: (U, T) -> U) -> U
			return function<U>(bag: Self, init: U, fn: (U, T) -> U): U
				return init
			end
		end),
		Count = Trait.Default(function(ops: any): (bag: Self) -> number -- 비제네릭 기본 구현(대조)
			return function(bag: Self): number
				return 0
			end
		end),
	})
end)
type P = typeof(F.ImplOf<<Bag<A>, A>>(nil :: any))
local function each(_b: Bag<A>, _fn: (A) -> ()) end
local function map<U>(_b: Bag<A>, _fn: (A) -> U): { U } return {} end
local okAll: P = { Each = each, Map = map }
local negPinU: P = { Each = each, Map = map,
	Fold = function(_b: Bag<A>, init: number, _fn: (number, A) -> number): number return init end } -- NEG 1
local negElem: P = { Each = each, Map = map,
	Fold = function<U>(_b: Bag<A>, init: U, _fn: (U, string) -> U): U return init end } -- NEG 2
local negRet: P = { Each = each, Map = map,
	Fold = function<U>(_b: Bag<A>, _init: U, _fn: (U, A) -> U): string return "" end } -- NEG 3
local negLen: P = { Each = each, Map = map,
	Fold = function(_b: Bag<A>): number return 0 end } -- NEG 4 (인자 수/반환)
local negNotFn: P = { Each = each, Map = map, Fold = 5 } -- NEG 5
local negCount: P = { Each = each, Map = map, Count = function(_b: Bag<A>): string return "" end } -- NEG 6 (대조)
local negMapPin: P = { Each = each,
	Map = function(_b: Bag<A>, _fn: (A) -> number): { number } return {} end } -- NEG 7 필수 칸의 U 못박음
-- 쓰는 쪽(완성 표)
local b: Bag<number> = nil :: any
local full = F.Of(b)
local u1: number = full.Fold(b, "", function(acc: string, _x: number): string return acc end) -- NEG 8
local canary: string = 1
return { okAll, negPinU, negElem, negRet, negLen, negNotFn, negCount, negMapPin, u1, canary }

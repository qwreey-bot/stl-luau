--!strict
local Trait = require("./Trait")
local function qdef<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
	return {
		Get = Trait.Fn<<(l: Self, i: I) -> E?>>(),
		First = Trait.Fn<<(l: Self) -> I?>>(),
		Contains = Trait.Default(mode, function(ops: Q<Self, E, I>)
			return function(l: Self, x: E): boolean
				return ops.Get(l, ops.First(l) :: I) ~= nil
			end
		end),
	}
end end
const L = Trait.Trait("Q", qdef<<"full">>, qdef<<"impl">>)
export type Q<Self, E, I> = typeof(L.Of<<Self, E, I>>(nil :: any))
export type QI<Self, E, I> = typeof(L.ImplOf<<Self, E, I>>(nil :: any))
local x: Q<string, number, number> = nil :: any
local r: boolean = x.Contains("a", 1)
local r2: string = x.Contains("a", 1) -- NEG
local r3 = x.Contains("a", 1); local r4: number = r3 + 1 -- NEG
local function g(s: string, i: number): number? return nil end
local function f1(s: string): number? return nil end
const ok: QI<string, number, number> = { Get = g, First = f1 }
const okov: QI<string, number, number> = { Get = g, First = f1, Contains = function(l: string, x: number): boolean return true end }
const NEG_ov: QI<string, number, number> = { Get = g, First = f1, Contains = g } -- NEG
const typo: QI<string, number, number> = { Get = g, First = f1, Contans = function(l: string, x: number): boolean return true end } -- typo
const NEG_miss: QI<string, number, number> = { Get = g } -- NEG
local canary: string = 1
return { r, r2, r4, ok, okov, NEG_ov, typo, NEG_miss, canary }

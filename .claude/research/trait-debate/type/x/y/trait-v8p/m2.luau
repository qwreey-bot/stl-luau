--!strict
local Trait = require("./Trait")
local function d2<M>(mode: M) return function<Self, T>(of: (Self & Trait.Item<T>) | Trait.AnyToken)
	return { Get = Trait.Fn<<(s: Self) -> T>>(), D = Trait.Default(mode, function(ops: any) return function(s: Self): T return "x" :: any end end) }
end end
const L4 = Trait.Trait("M4", d2<<"full">>) -- impl 생략
export type I4<Self, T> = typeof(L4.ImplOf<<Self, T>>(nil :: any))
const bad: I4<string, number> = { Get = 5, Zzz = 1 } -- NEG(생략 시 검사 없음?)
local canary: string = 1
return { bad, canary }

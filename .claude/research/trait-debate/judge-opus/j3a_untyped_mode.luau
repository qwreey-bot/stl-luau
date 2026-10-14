--!strict
local Trait = require("../trait-v9/Trait")
local stl = require("../../../src")
type Arr<T> = stl.Arr<T>
type Item<T> = Trait.Item<T>
type A = Trait.A
const Fn, Default = Trait.Fn, Trait.Default
-- J3a: 정의 함수에 <M> 도 주석도 없음
local function def(mode)
	return function<Self, T>(of: (Self & Item<T>) | Trait.AnyToken)
		return {
			Pop = Fn<<(stack: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: any)
				return function(s: Self): boolean
					return false
				end
			end),
		}
	end
end
const X = Trait.Trait("J3a", def(Trait.FULL), def(Trait.IMPL))
export type S<Self, T> = typeof(X.Of<<Self, T>>(nil :: any))
export type SImpl<Self, T> = typeof(X.ImplOf<<Self, T>>(nil :: any))
const a: Arr<number> = stl.Arr.Of(1)
const ok: boolean = X.Of<<Arr<number>, number>>(a).IsEmpty(a)
const NEG_ret: string = X.Of<<Arr<number>, number>>(a).IsEmpty(a) -- NEG
const reg: SImpl<Arr<A>, A> = { Pop = stl.Arr.PopBack }
local canary: string = 1
return { ok, NEG_ret, reg, canary }

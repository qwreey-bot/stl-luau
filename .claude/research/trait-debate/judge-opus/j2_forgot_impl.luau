--!strict
local Trait = require("../trait-v9/Trait")
local stl = require("../../../src")
type Arr<T> = stl.Arr<T>
type Item<T> = Trait.Item<T>
type A = Trait.A
const Fn, Default = Trait.Fn, Trait.Default
-- J2: IMPL 보기를 빠뜨림 (정의 함수를 FULL 로 부른 것 하나만)
local function def<M>(mode: M)
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
const X = Trait.Trait("J2", def(Trait.FULL))
export type S<Self, T> = typeof(X.Of<<Self, T>>(nil :: any))
export type SImpl<Self, T> = typeof(X.ImplOf<<Self, T>>(nil :: any))
const a: Arr<number> = stl.Arr.Of(1)
const ok: boolean = X.Of<<Arr<number>, number>>(a).IsEmpty(a)
const NEG_ret: string = X.Of<<Arr<number>, number>>(a).IsEmpty(a) -- NEG
const reg: SImpl<Arr<A>, A> = { Pop = stl.Arr.PopBack }
local canary: string = 1
return { ok, NEG_ret, reg, canary }

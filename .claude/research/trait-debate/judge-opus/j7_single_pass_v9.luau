--!strict
-- J7: D3(v9) 의 Trait 에 정의 함수를 부르지 않고 하나만 넘김(사용자가 바란 "한 번" 모양) — 시끄러워야
local Trait = require("../trait-v9/Trait")
local stl = require("../../../src")
type Arr<T> = stl.Arr<T>
type Item<T> = Trait.Item<T>
type A = Trait.A
const Fn, Default = Trait.Fn, Trait.Default
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
const X = Trait.Trait("J5", def)
export type S<Self, T> = typeof(X.Of<<Self, T>>(nil :: any))
export type SImpl<Self, T> = typeof(X.ImplOf<<Self, T>>(nil :: any))
const a: Arr<number> = stl.Arr.Of(1)
const ok: boolean = X.Of<<Arr<number>, number>>(a).IsEmpty(a)
const NEG_ret: string = X.Of<<Arr<number>, number>>(a).IsEmpty(a) -- NEG
const reg: SImpl<Arr<A>, A> = { Pop = stl.Arr.PopBack }
const NEG_over: SImpl<Arr<A>, A> = { Pop = stl.Arr.PopBack, IsEmpty = stl.Arr.Len } -- NEG
local canary: string = 1
return { ok, NEG_ret, reg, NEG_over, canary }

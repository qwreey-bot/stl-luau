--!strict
-- B(v8): 바깥 사람이 트레이트를 정의할 때의 실수들
local Trait = require("./trait-v8/Trait")
const Fn, Default = Trait.Fn, Trait.Default
type Item<T> = Trait.Item<T>
type AnyToken = Trait.AnyToken

-- (a) A 모양 그대로(모드 겹을 잊음)
const Size1 = Trait.Trait("Size1", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return { Len = Fn<<(s: Self) -> number>>() }
end)

-- (b) Default 에 mode 를 잊음
const Size2 = Trait.Trait("Size2", function<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | AnyToken)
		return {
			Len = Fn<<(s: Self) -> number>>(),
			IsEmpty = Default(function(ops: any)
				return function(s: Self): boolean return true end
			end),
		}
	end
end)

-- (c) mode 자리에 다른 것(문자열)
const Size3 = Trait.Trait("Size3", function<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | AnyToken)
		return {
			Len = Fn<<(s: Self) -> number>>(),
			IsEmpty = Default("full", function(ops: any)
				return function(s: Self): boolean return true end
			end),
		}
	end
end)
export type Size3Impl<Self, T> = typeof(Size3.ImplOf<<Self, T>>(nil :: any))
const s3: Size3Impl<{ read __generics: { read Item: (number) -> number } }, number> = { Len = function(_s) return 0 end }

-- (d) 바깥 겹에 : M 을 잊음
const Size4 = Trait.Trait("Size4", function(mode)
	return function<Self, T>(of: (Self & Item<T>) | AnyToken)
		return {
			Len = Fn<<(s: Self) -> number>>(),
			IsEmpty = Default(mode, function(ops: any)
				return function(s: Self): boolean return true end
			end),
		}
	end
end)
export type Size4<Self, T> = typeof(Size4.Of<<Self, T>>(nil :: any))
export type Size4Impl<Self, T> = typeof(Size4.ImplOf<<Self, T>>(nil :: any))
local s4full: Size4<{ n: number }, number> = nil :: any
const b4: boolean = s4full.IsEmpty({ n = 1 })
const s4: Size4Impl<{ n: number }, number> = { Len = function(_s) return 0 end }
return { Size1, Size2, Size3, s3, b4, s4 }

--!strict
local Trait = require("./Trait")
const L = Trait.Trait("Q", function<M>(mode: M) return function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
	return {
		Get = Trait.Fn<<(l: Self, i: I) -> E?>>(),
		First = Trait.Fn<<(l: Self) -> I?>>(),
		Contains = Trait.Default(mode, function(ops: Q<Self, E, I>)
			return function(l: Self, x: E): boolean
				return ops.Get(l, ops.First(l) :: I) ~= nil
			end
		end),
	}
end end)
export type Q<Self, E, I> = typeof(L.Of<<Self, E, I>>(nil :: any))
local x: Q<string, number, number> = nil :: any
local r: boolean = x.Contains("a", 1)
local r2 = x.Contains("a", 1); local z = r2.foo.bar; local y: number = r2 + 1
local canary: string = 1
return { r, r2, canary }

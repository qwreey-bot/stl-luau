--!strict
local Trait = require("./Trait")
const L = Trait.Trait("P2", function<M>(mode: M) return function<Self, E>(of: (Self & Trait.ItemRead<E>) | Trait.AnyToken)
	return {
		Get = Trait.Fn<<(s: Self, i: number) -> E?>>(),
		Has = Trait.Default(mode, function(ops: P2<Self, E>)
			const get = ops.Get
			return function(s: Self, x: E): boolean
				return get(s, 1) == x
			end
		end),
		Count = Trait.Default(mode, function(ops: P2<Self, E>)
			return function(s: Self): number return 1 end
		end),
	}
end end)
export type P2<Self, E> = typeof(L.Of<<Self, E>>(nil :: any))
export type P2Impl<Self, E> = typeof(L.ImplOf<<Self, E>>(nil :: any))
return { L = L }

--!strict
local Trait = require("../.claude/research/trait-v4/Trait")
type ItemIndex<E, I> = Trait.ItemIndex<E, I>
type AnyToken = Trait.AnyToken
type A = Trait.A
type B = Trait.B

const Fn, Default = Trait.Fn, Trait.Default

const MyList = Trait.Trait("MyList", function<Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken)
	return {
		Get = Fn<<(list: Self, idx: I) -> E?>>(),
		-- Mistake: element pinned to string inside trait definition!
		IndexOf = Default(function(ops: MyList<Self, E, I>)
			return function(list: Self, item: string): I?
				return nil
			end
		end),
	}
end)
export type MyList<Self, E, I> = typeof(MyList.Of<<Self, E, I>>(nil :: any))

-- Now let's see what happens at implementation site!
type Arr<T> = { n: number, [number]: T, __generics: { Item: (T) -> T, Index: (number) -> number } }
local myArrToken = Trait.Token("MyArr")

-- When implementer provides full type:
-- Look at IndexOf: does it require string or A?
local impl1: MyList<Arr<A>, A, number> = {
	Get = function(l: Arr<A>, idx: number): A? return l[idx] end,
	IndexOf = Trait.Inherit,
}

local impl2: MyList<Arr<A>, A, number> = {
	Get = function(l: Arr<A>, idx: number): A? return l[idx] end,
	-- If implementer overrides IndexOf with correct generic signature:
	IndexOf = function(l: Arr<A>, item: A): number? return nil end,
}

local canary: string = 1
return { impl1, impl2, canary }

--!strict
local Trait = require("../.claude/research/trait-v4/Trait")
type ItemIndex<E, I> = Trait.ItemIndex<E, I>
type Item<T> = Trait.Item<T>
type AnyToken = Trait.AnyToken

const Fn, Default = Trait.Fn, Trait.Default

-- Trait definition testing Default builder leaks
const TraitDef = Trait.Trait("TraitDef", function<Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken)
	return {
		Get = Fn<<(list: Self, idx: I) -> E?>>(),
		FirstIndex = Fn<<(list: Self) -> I?>>(),
		NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),

		-- D1: element pinned to string in parameter
		D1_pinnedParam = Default(function(ops: TraitDef<Self, E, I>)
			return function(list: Self, item: string): I?
				return nil
			end
		end),

		-- D2: index pinned to number in parameter
		D2_pinnedIndex = Default(function(ops: TraitDef<Self, E, I>)
			return function(list: Self, idx: number): E?
				return nil
			end
		end),

		-- D3: Self pinned to table
		D3_pinnedSelf = Default(function(ops: TraitDef<Self, E, I>)
			return function(list: { n: number }, idx: I): E?
				return nil
			end
		end),

		-- D4: returning concrete type into I?
		D4_returnConcreteOpt = Default(function(ops: TraitDef<Self, E, I>)
			return function(list: Self): I?
				return 123 -- number literal into I?
			end
		end),

		-- D5: returning concrete type into non-optional boolean
		D5_returnWrongNonOpt = Default(function(ops: TraitDef<Self, E, I>)
			return function(list: Self): boolean
				return "not_boolean" -- string literal into boolean
			end
		end),

		-- D6: assigning generic I? to concrete local
		D6_assignGenericToConcrete = Default(function(ops: TraitDef<Self, E, I>)
			const firstIndex = ops.FirstIndex
			return function(list: Self): I?
				local idx: number? = firstIndex(list) -- I? to number?
				return idx
			end
		end),

		-- D7: passing generic E to concrete function (math.abs)
		D7_passGenericToConcrete = Default(function(ops: TraitDef<Self, E, I>)
			return function(list: Self, item: E): boolean
				local _ = math.abs(item) -- passing generic E to number
				return true
			end
		end),

		-- D8: calling 1-arg sibling with 2 args
		D8_siblingWrongArgCount = Default(function(ops: TraitDef<Self, E, I>)
			const firstIndex = ops.FirstIndex -- (Self) -> I?
			return function(list: Self, item: E): I?
				return firstIndex(list, item) -- 2 args to 1-arg function
			end
		end),

		-- D9: Fold higher-order function passing literal to generic parameter of callback
		D9_foldLiteralArg = Default(function(ops: TraitDef<Self, E, I>)
			const firstIndex = ops.FirstIndex
			return function<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I) -> U): U
				local idx = firstIndex(list)
				if idx ~= nil then
					return fn(init, "not_an_E", idx) -- literal string to generic E
				end
				return init
			end
		end),

		-- D10: Fold higher-order function returning wrong acc
		D10_foldWrongAcc = Default(function(ops: TraitDef<Self, E, I>)
			return function<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I) -> U): U
				return "not_a_U" -- string literal to generic U
			end
		end),
	}
end)
export type TraitDef<Self, E, I> = typeof(TraitDef.Of<<Self, E, I>>(nil :: any))

local canary: string = 1
return { TraitDef, canary }

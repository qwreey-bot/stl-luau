--!strict
local Trait = require("../.claude/research/trait-v4/Trait")
type ItemIndex<E, I> = Trait.ItemIndex<E, I>
type AnyToken = Trait.AnyToken

const Fn, Default = Trait.Fn, Trait.Default

-- Trait with Default builders
const List = Trait.Trait("List", function<Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken)
	return {
		Get = Fn<<(list: Self, idx: I) -> E?>>(),
		FirstIndex = Fn<<(list: Self) -> I?>>(),
		NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),

		-- Normal
		IndexOf = Default(function(ops: List<Self, E, I>)
			const get, firstIndex, nextIndex = ops.Get, ops.FirstIndex, ops.NextIndex
			return function(list: Self, item: E): I?
				local idx = firstIndex(list)
				while idx ~= nil do
					if get(list, idx) == item then
						return idx
					end
					idx = nextIndex(list, idx)
				end
				return nil
			end
		end),

		-- Mistake 1: item pinned to string
		IndexOfPinnedItem = Default(function(ops: List<Self, E, I>)
			const get, firstIndex, nextIndex = ops.Get, ops.FirstIndex, ops.NextIndex
			return function(list: Self, item: string): I? -- MISTAKE: item: string instead of E
				local idx = firstIndex(list)
				while idx ~= nil do
					if get(list, idx) == item then -- comparing E? with string
						return idx
					end
					idx = nextIndex(list, idx)
				end
				return nil
			end
		end),

		-- Mistake 2: return type pinned to number? instead of I?
		IndexOfPinnedIndex = Default(function(ops: List<Self, E, I>)
			const firstIndex = ops.FirstIndex
			return function(list: Self, item: E): number? -- MISTAKE: return number? instead of I?
				local idx = firstIndex(list)
				return idx -- returning I? as number?
			end
		end),

		-- Mistake 3: inside body, assigning generic I to string
		IndexOfBadVar = Default(function(ops: List<Self, E, I>)
			const firstIndex = ops.FirstIndex
			return function(list: Self, item: E): I?
				local idx: string? = firstIndex(list) -- MISTAKE: I? assigned to string?
				return nil
			end
		end),

		-- Mistake 4: wrong sibling captured
		ContainsWrongSibling = Default(function(ops: List<Self, E, I>)
			const wrong = ops.Get -- ops.Get is (Self, I) -> E?, but we treat it as IndexOf: (Self, E) -> I?
			return function(list: Self, item: E): boolean
				return wrong(list, item) ~= nil -- passing item (E) where idx (I) is expected
			end
		end),

		-- Mistake 5: calling concrete function with generic E
		CallsConcrete = Default(function(ops: List<Self, E, I>)
			local function needNumber(x: number) end
			return function(list: Self, item: E): boolean
				needNumber(item) -- MISTAKE: passing generic E to number
				return true
			end
		end),

		-- Mistake 6: literal return value
		LiteralReturn = Default(function(ops: List<Self, E, I>)
			return function(list: Self): E
				return "literal" -- MISTAKE: returning literal string as E
			end
		end),
	}
end)
export type List<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))

local canary: string = 1
return { List = List, canary = canary }

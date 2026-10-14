--!strict
local Traits = require("../.claude/research/trait-v4/Traits")
type Stack<Self, T> = Traits.Stack<Self, T>
type List<Self, E, I> = Traits.List<Self, E, I>

-- Baseline
local function drain<C, T>(st: Stack<C, T>, c: C): { T }
	local out = {}
	local x = st.Pop(c)
	while x ~= nil do
		table.insert(out, x)
		x = st.Pop(c)
	end
	return out
end

-- U1a: Passing literal string to st.Push(c, item) where item is T
local function u1a_pushLiteral<C, T>(st: Stack<C, T>, c: C): C
	return st.Push(c, "literal_string")
end

-- U1b: Passing variable string to st.Push(c, item) where item is T
local function u1b_pushVar<C, T>(st: Stack<C, T>, c: C): C
	local str: string = "variable_string"
	return st.Push(c, str)
end

-- U2: Assigning st.Pop(c) (which is T?) to string?
local function u2_popAssignConcrete<C, T>(st: Stack<C, T>, c: C): string?
	local val: string? = st.Pop(c) -- T? to string?
	return val
end

-- U3a: Returning literal table { "not_T" } where { T } is expected
local function u3a_returnLiteralTable<C, T>(st: Stack<C, T>, c: C): { T }
	return { "not_T" }
end

-- U3b: Returning typed concrete table where { T } is expected
local function u3b_returnTypedConcreteTable<C, T>(st: Stack<C, T>, c: C): { T }
	local strs: { string } = { "a", "b" }
	return strs
end

-- U4: Passing generic x to concrete helper
local function u4_passToConcreteHelper<C, T>(st: Stack<C, T>, c: C)
	local function needNumber(n: number) end
	local x = st.Pop(c)
	if x ~= nil then
		needNumber(x) -- passing T to number
	end
end

-- U5: Calling unrelated trait function on c
local function u5_unrelatedTrait<C, T>(st: Stack<C, T>, list: List<C, T, number>, c: C)
	return list.Get(c, 1) -- valid: list is passed explicitly
end

local function u5_badTraitCall<C, T>(st: Stack<C, T>, c: C)
	return Traits.List.Get(c, 1) -- c passed to entrypoint
end

local canary: string = 1
return {
	drain,
	u1a_pushLiteral,
	u1b_pushVar,
	u2_popAssignConcrete,
	u3a_returnLiteralTable,
	u3b_returnTypedConcreteTable,
	u4_passToConcreteHelper,
	u5_unrelatedTrait,
	u5_badTraitCall,
	canary,
}

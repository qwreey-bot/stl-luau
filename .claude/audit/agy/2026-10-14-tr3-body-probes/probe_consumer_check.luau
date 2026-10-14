--!strict
local Traits = require("../.claude/research/trait-v4/Traits")
local Trait = require("../.claude/research/trait-v4/Trait")
type Stack<Self, T> = Traits.Stack<Self, T>
type A = Trait.A
type B = Trait.B

-- Generic consumer function
local function drain<C, T>(st: Stack<C, T>, c: C): { T }
	local out: { T } = {}
	local x = st.Pop(c)
	while x ~= nil do
		table.insert(out, x)
		x = st.Pop(c)
	end
	return out
end

-- Monomorphic verification of the consumer algorithm using probe types!
local function test_drain_mono(st: Stack<A, B>, c: A): { B }
	local out: { B } = {}
	local x = st.Pop(c)
	while x ~= nil do
		table.insert(out, x)
		x = st.Pop(c)
	end
	return out
end

-- What if someone made the mistakes in the monomorphic version?
local function bad_drain_assign(st: Stack<A, B>, c: A)
	local val: string? = st.Pop(c) -- NEG: B? to string?
	return val
end

local function bad_drain_return(st: Stack<A, B>, c: A): { B }
	return { "not_B" } -- NEG: { string } to { B }
end

local function bad_drain_call(st: Stack<A, B>, c: A)
	local function needNumber(n: number) end
	local x = st.Pop(c)
	if x ~= nil then
		needNumber(x) -- NEG: passing B to number
	end
end

local canary: string = 1
return {
	drain,
	test_drain_mono,
	bad_drain_assign,
	bad_drain_return,
	bad_drain_call,
	canary,
}

--!strict
local Traits = require("../.claude/research/trait-v4/Traits")
local Trait = require("../.claude/research/trait-v4/Trait")
local stl = require("../src")
type Arr<T> = stl.Arr<T>
type ArrRead<T> = stl.ArrRead<T>
type Stack<Self, T> = Traits.Stack<Self, T>
type A = Trait.A

-- Writing arrPeek monomorphically using probe type A:
local function arrPeek_mono(self: ArrRead<A>): A?
	return self[self.n]
end

-- What if someone puts a mistake in arrPeek_mono?
local function bad_peek_str(self: ArrRead<A>): A?
	return "hello" -- NEG: string vs A?
end

local function bad_peek_num(self: ArrRead<A>): A?
	local x: number? = self[self.n] -- NEG: A? into number?
	return x
end

-- Plugging into arrStack:
const arrStack: Stack<Arr<A>, A> = {
	Push = stl.Arr.PushBack,
	Pop = stl.Arr.PopBack,
	Peek = arrPeek_mono,
}

local canary: string = 1
return { arrPeek_mono, bad_peek_str, bad_peek_num, arrStack, canary }

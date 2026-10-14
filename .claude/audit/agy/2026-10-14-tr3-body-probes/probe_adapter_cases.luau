--!strict
local Traits = require("../.claude/research/trait-v4/Traits")
local Trait = require("../.claude/research/trait-v4/Trait")
local stl = require("../src")
type Arr<T> = stl.Arr<T>
type ArrRead<T> = stl.ArrRead<T>
type CircularDeque<T> = stl.CircularDeque<T>
type Stack<Self, T> = Traits.Stack<Self, T>
type A = Trait.A

-- 1. Inside adapter generic body: returning concrete string into T?
const function a1_bodyReturnOpt<T>(self: ArrRead<T>): T?
	return "hello" -- string literal into T?
end

-- 2. Inside adapter generic body: assigning T to number
const function a2_bodyAssign<T>(self: ArrRead<T>): T?
	local val: number? = self[self.n] -- T? into number?
	return val
end

-- 3. Inside adapter generic body: calling math.abs with T
const function a3_bodyCall<T>(self: ArrRead<T>): T?
	if self.n > 0 then
		math.abs(self[1]) -- passing T to number
	end
	return self[self.n]
end

-- 4. Pinned return type in adapter signature, plugged into probe-typed table
const function a4_pinnedReturn<T>(self: ArrRead<T>): string?
	return nil
end

const reg_a4: Stack<Arr<A>, A> = {
	Push = stl.Arr.PushBack,
	Pop = stl.Arr.PopBack,
	Peek = a4_pinnedReturn, -- Expected: (Arr<A>) -> A?, Got: (ArrRead<A>) -> string?
}

-- 5. Pinned parameter in adapter signature, plugged into probe-typed table
const function a5_pinnedParam<T>(self: ArrRead<string>): T?
	return nil
end

const reg_a5: Stack<Arr<A>, A> = {
	Push = stl.Arr.PushBack,
	Pop = stl.Arr.PopBack,
	Peek = a5_pinnedParam, -- Expected: Arr<A>, Got: ArrRead<string>
}

-- 6. Wrong container in adapter signature, plugged into probe-typed table
const function a6_wrongContainer<T>(self: CircularDeque<T>): T?
	return nil
end

const reg_a6: Stack<Arr<A>, A> = {
	Push = stl.Arr.PushBack,
	Pop = stl.Arr.PopBack,
	Peek = a6_wrongContainer, -- Expected: Arr<A>, Got: CircularDeque<T>
}

local canary: string = 1
return {
	a1_bodyReturnOpt,
	a2_bodyAssign,
	a3_bodyCall,
	reg_a4,
	reg_a5,
	reg_a6,
	canary,
}

--!strict
local Traits = require("../.claude/research/trait-v4/Traits")
local stl = require("../src")
type Arr<T> = stl.Arr<T>
type CircularDeque<T> = stl.CircularDeque<T>
type Stack<Self, T> = Traits.Stack<Self, T>
const Stack = Traits.Stack

-- Option A: as in v4 Traits.luau, using `:: any`
const goodIntoA: <T>(a: Arr<T>) -> Stack<Arr<T>, T> = Stack.Of :: any
const badIntoA1: <T>(a: Arr<T>) -> Stack<Arr<T>, string> = Stack.Of :: any -- MISTAKE: string instead of T
const badIntoA2: <T>(a: Arr<T>) -> Stack<CircularDeque<T>, T> = Stack.Of :: any -- MISTAKE: CircularDeque instead of Arr

-- Option B: without `:: any`, as a generic helper function
local function goodIntoB<T>(a: Arr<T>): Stack<Arr<T>, T>
	return Stack.Of(a)
end

local function badIntoB1_element<T>(a: Arr<T>): Stack<Arr<T>, string>
	return Stack.Of(a) -- MISTAKE: Stack.Of(a) is Stack<Arr<T>, T>, but return type claims string
end

local function badIntoB2_container<T>(a: Arr<T>): Stack<CircularDeque<T>, T>
	return Stack.Of(a) -- MISTAKE: container type is CircularDeque instead of Arr
end

local function badIntoB3_wrongArg<T>(a: Arr<T>): Stack<Arr<T>, T>
	return Stack.Of("not_an_arr") -- MISTAKE: passing string literal to Stack.Of
end

local canary: string = 1
return {
	goodIntoA,
	badIntoA1,
	badIntoA2,
	goodIntoB,
	badIntoB1_element,
	badIntoB2_container,
	badIntoB3_wrongArg,
	canary,
}

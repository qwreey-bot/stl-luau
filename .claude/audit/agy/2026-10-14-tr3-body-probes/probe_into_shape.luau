--!strict
local Traits = require("../.claude/research/trait-v4/Traits")
local Trait = require("../.claude/research/trait-v4/Trait")
local stl = require("../src")
type Arr<T> = stl.Arr<T>
type CircularDeque<T> = stl.CircularDeque<T>
type Stack<Self, T> = Traits.Stack<Self, T>
const Stack = Traits.Stack

type ProbeT = { read __probeT: true }

-- Suppose Into is written in 3 ways:
-- Case 1: correctly typed
const arrIntoStack_good: <T>(a: Arr<T>) -> Stack<Arr<T>, T> = Stack.Of :: any

-- Case 2: element type pinned to string
const arrIntoStack_badElem: <T>(a: Arr<T>) -> Stack<Arr<T>, string> = Stack.Of :: any

-- Case 3: container type wrong
const arrIntoStack_badContainer: <T>(a: Arr<T>) -> Stack<CircularDeque<T>, T> = Stack.Of :: any

-- Now, can a top-level probe assertion catch Cases 2 and 3?
-- Let's test checking `arrIntoStack` against the expected probe function type:
type ExpectedInto = (a: Arr<ProbeT>) -> Stack<Arr<ProbeT>, ProbeT>

-- Good check
local _check_good: ExpectedInto = arrIntoStack_good

-- Bad checks:
local _check_badElem: ExpectedInto = arrIntoStack_badElem
local _check_badContainer: ExpectedInto = arrIntoStack_badContainer

-- Also, what if Into is implemented as a monomorphic function with probe type?
local function arrInto_mono(a: Arr<ProbeT>): Stack<Arr<ProbeT>, ProbeT>
	return Stack.Of(a)
end

-- What if arrInto_mono has a mistake?
local function arrInto_mono_bad(a: Arr<ProbeT>): Stack<Arr<ProbeT>, string>
	return Stack.Of(a) -- Can Stack.Of(a) return string when a is Arr<ProbeT>?
end

local canary: string = 1
return {
	_check_good,
	_check_badElem,
	_check_badContainer,
	arrInto_mono,
	arrInto_mono_bad,
	canary,
}

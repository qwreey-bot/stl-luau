--!strict
local Trait = require("../.claude/research/trait-v4/Trait")
local stl = require("../src")

type Deque<Self, T> = {
	PushFront: (deque: Self, item: T) -> Self,
	PushBack: (deque: Self, item: T) -> Self,
	PopFront: (deque: Self) -> T?,
	PopBack: (deque: Self) -> T?,
	Front: (deque: Self) -> T?,
	Back: (deque: Self) -> T?,
}

type Stack<Self, T> = {
	Push: (stack: Self, item: T) -> Self,
	Pop: (stack: Self) -> T?,
	Peek: (stack: Self) -> T?,
}

const DequeTrait = Trait.Trait("TestDeque", function<Self, T>(of: (Self & Trait.Item<T>) | Trait.AnyToken)
	return {
		PushFront = Trait.Fn<<(d: Self, item: T) -> Self>>(),
		PushBack = Trait.Fn<<(d: Self, item: T) -> Self>>(),
		PopFront = Trait.Fn<<(d: Self) -> T?>>(),
		PopBack = Trait.Fn<<(d: Self) -> T?>>(),
		Front = Trait.Fn<<(d: Self) -> T?>>(),
		Back = Trait.Fn<<(d: Self) -> T?>>(),
	}
end)
type TestDeque<Self, T> = typeof(DequeTrait.Of<<Self, T>>(nil :: any))

const StackTrait = Trait.Trait("TestStack", function<Self, T>(of: (Self & Trait.Item<T>) | Trait.AnyToken)
	return {
		Push = Trait.Fn<<(s: Self, item: T) -> Self>>(),
		Pop = Trait.Fn<<(s: Self) -> T?>>(),
		Peek = Trait.Fn<<(s: Self) -> T?>>(),
	}
end)
type TestStack<Self, T> = typeof(StackTrait.Of<<Self, T>>(nil :: any))

type ProbeC = { read __probeC: true }
type ProbeT = { read __probeT: true }

-- Monomorphic blanket body typed with probe types!
local function stackFromDeque(deque: TestDeque<ProbeC, ProbeT>): TestStack<ProbeC, ProbeT>
	return {
		Push = deque.PushBack,
		Pop = deque.PopBack,
		Peek = deque.Back,
	}
end

Trait.Blanket(StackTrait, { DequeTrait }, function(deps)
	return stackFromDeque(deps[DequeTrait])
end)

-- Register CircularDeque implementation of DequeTrait
const CD_TOKEN = Trait.Token("Test.CD")
type CircularDeque<T> = stl.CircularDeque<T>
type A = Trait.A
const cdImpl: TestDeque<CircularDeque<A>, A> = {
	PushFront = stl.CircularDeque.PushFront,
	PushBack = stl.CircularDeque.PushBack,
	PopFront = stl.CircularDeque.PopFront,
	PopBack = stl.CircularDeque.PopBack,
	Front = stl.CircularDeque.Front,
	Back = stl.CircularDeque.Back,
}
Trait.Impl(DequeTrait, CD_TOKEN, cdImpl)

-- Verify runtime behavior
local d = stl.CircularDeque.Of(10, 20)
;(d :: any).__type = CD_TOKEN

const fullStack = StackTrait.Of<<CircularDeque<number>, number>>(CD_TOKEN)
assert(fullStack.Push == stl.CircularDeque.PushBack)
assert(fullStack.Pop == stl.CircularDeque.PopBack)
assert(fullStack.Peek == stl.CircularDeque.Back)

local popped = fullStack.Pop(d)
assert(popped == 20)

print("PASS runtime test of monomorphic blanket body")
return {}

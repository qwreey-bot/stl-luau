--!strict
type Deque<Self, T> = {
	PushFront: (deque: Self, item: T) -> Self,
	PushBack: (deque: Self, item: T) -> Self,
	PopFront: (deque: Self) -> T?,
	PopBack: (deque: Self) -> T?,
	Front: (deque: Self) -> T?,
	Back: (deque: Self) -> T?,
	IsEmpty: (deque: Self) -> boolean,
}

type Stack<Self, T> = {
	Push: (stack: Self, item: T) -> Self,
	Pop: (stack: Self) -> T?,
	Peek: (stack: Self) -> T?,
}

-- Baseline: correct implementation
local function stackFromDeque<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = d.PushBack, Pop = d.PopBack, Peek = d.Back }
end

-- Case 1: Pinned element type (Pop returns string?)
local function b1_pinnedPop<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = d.PushBack, Pop = function(c: C): string? return nil end, Peek = d.Back }
end

-- Case 2: Pinned element type (Push accepts number)
local function b2_pinnedPush<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = function(c: C, x: number): C return c end, Pop = d.PopBack, Peek = d.Back }
end

-- Case 3: Pinned container type (Push expects { n: number })
local function b3_pinnedSelf<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = function(c: { n: number }, x: T): { n: number } return c end, Pop = d.PopBack, Peek = d.Back }
end

-- Case 4: Miswiring sibling with different arity (Pop = PushBack)
local function b4_siblingArity<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = d.PushBack, Pop = d.PushBack, Peek = d.Back }
end

-- Case 5: Miswiring sibling with same arity but different return type (Pop = IsEmpty)
local function b5_siblingReturnType<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = d.PushBack, Pop = d.IsEmpty, Peek = d.Back }
end

-- Case 6: Missing field (omitted Peek)
local function b6_missingField<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = d.PushBack, Pop = d.PopBack }
end

-- Case 7: Misspelled field (Peek spelled as Pick)
local function b7_misspelledField<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = d.PushBack, Pop = d.PopBack, Pick = d.Back }
end

-- Case 8: Direct call inside body passing concrete type to generic method
local function b8_callWithConcrete<C, T>(d: Deque<C, T>): Stack<C, T>
	local function customPush(c: C, x: T): C
		d.PushBack(c, "not_T") -- passing string to T
		return c
	end
	return { Push = customPush, Pop = d.PopBack, Peek = d.Back }
end

-- Case 9: Assigning generic return value to concrete local variable
local function b9_assignToConcrete<C, T>(d: Deque<C, T>): Stack<C, T>
	local function customPop(c: C): T?
		local item: string? = d.PopBack(c) -- assigning T? to string?
		return item
	end
	return { Push = d.PushBack, Pop = customPop, Peek = d.Back }
end

-- Case 10: Returning concrete literal where T is expected
local function b10_literalReturn<C, T>(d: Deque<C, T>): Stack<C, T>
	local function customPop(c: C): T?
		return 123 -- returning number literal
	end
	return { Push = d.PushBack, Pop = customPop, Peek = d.Back }
end

local canary: string = 1
return {
	stackFromDeque,
	b1_pinnedPop,
	b2_pinnedPush,
	b3_pinnedSelf,
	b4_siblingArity,
	b5_siblingReturnType,
	b6_missingField,
	b7_misspelledField,
	b8_callWithConcrete,
	b9_assignToConcrete,
	b10_literalReturn,
	canary,
}

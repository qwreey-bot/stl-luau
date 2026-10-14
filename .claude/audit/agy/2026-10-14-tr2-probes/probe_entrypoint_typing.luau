--!strict
-- probe_entrypoint_typing.luau: 편한 진입점(Stack.Push)에 타입을 줄 수 있는가?

type Item<T> = { read __generics: { read Item: (T) -> T } }
type Arr<T> = {
	n: number,
	read __generics: { read Item: (T) -> T },
	[number]: T,
}

type StackTrait = {
	Push: <Self, T>(stack: Self & Item<T>, item: T) -> Self,
	Pop: <Self, T>(stack: Self & Item<T>) -> T?,
	Peek: <Self, T>(stack: Self & Item<T>) -> T?,
}

local Stack: StackTrait = {
	Push = function(s: any, item: any): any
		return s
	end,
	Pop = function(s: any): any
		return nil
	end,
	Peek = function(s: any): any
		return nil
	end,
}

local a: Arr<number> = {
	n = 2,
	__generics = { Item = function(x: number) return x end },
	[1] = 10,
	[2] = 20,
}

-- 1. 올바른 호출
local ok_push = Stack.Push(a, 30)
local ok_pop: number? = Stack.Pop(a)

-- 2. 틀린 호출 (원소 타입 불일치)
local NEG_wrong_item = Stack.Push(a, "not a number") -- NEG
local NEG_wrong_pop: string? = Stack.Pop(a) -- NEG

local canary: string = 1

return {
	ok_push,
	ok_pop,
	NEG_wrong_item,
	NEG_wrong_pop,
	canary,
}

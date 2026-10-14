--!strict
local stl = require("../src")
type CircularDeque<T> = stl.CircularDeque<T>
type Arr<T> = stl.Arr<T>

type Item<T> = { read __generics: { read Item: (T) -> T } }
type AnyToken = { read name: string }

local function Fn<T>(): T
	return nil :: any
end

local function Default<T>(build: any): T
	return nil :: any
end

--[[ 트레이트 정의: 진입점을 단일 원천으로 ]]
const StackEntries = {
	Push = Fn<< <Self, T>(stack: Self & Item<T>, item: T) -> Self >>(),
	Pop = Fn<< <Self, T>(stack: Self & Item<T>) -> T? >>(),
	Peek = Default<< <Self, T>(stack: Self & Item<T>) -> T? >>(function(ops: any)
		return nil
	end),
}

export type Stack<Self, T> = {
	Push: typeof(StackEntries.Push<<Self, T>>),
	Pop: typeof(StackEntries.Pop<<Self, T>>),
	Peek: typeof(StackEntries.Peek<<Self, T>>),
}

type StackObject = typeof(StackEntries) & {
	Of: (<Self, T>(of: Self & Item<T>) -> Stack<Self, T>)
		& (<Self, T>(token: AnyToken) -> Stack<Self, T>),
}

local Stack: StackObject = nil :: any

--[[ 사용 테스트 ]]
local d: CircularDeque<number> = stl.CircularDeque.Of(1, 2, 3) :: any
(d :: any).__generics = { Item = function(x: number) return x end }

-- 1. 진입점 사용: Stack.Push
local pushed = Stack.Push(d, 4)
local popped: number? = Stack.Pop(d)

-- NEG 테스트
local NEG_push = Stack.Push(d, "x") -- NEG
local NEG_pop: string? = Stack.Pop(d) -- NEG

-- 2. Of 사용: Stack.Of(d)
local s = Stack.Of(d)
local s_pushed = s.Push(d, 4)
local s_popped: number? = s.Pop(d)

local NEG_s_push = s.Push(d, "x") -- NEG
local NEG_s_pop: string? = s.Pop(d) -- NEG

local canary: string = 1

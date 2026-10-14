--!strict
-- 중개자가 이미 있는 찾기 함수(Stack.Of)에 정확한 제네릭 타입만 다시 붙임 — 감싸는 함수 없음
local stl = require("../../../src")
local Arr, CircularDeque = stl.Arr, stl.CircularDeque
type Arr<T> = stl.Arr<T>
type CircularDeque<T> = stl.CircularDeque<T>
local function Fn<T>(): T
	return nil :: any
end
local function stackDef<Self, T>()
	return { Push = Fn<<(s: Self, item: T) -> Self>>(), Pop = Fn<<(s: Self) -> T?>>(), Peek = Fn<<(s: Self) -> T?>>() }
end
type Stack<Self, T> = typeof(stackDef<<Self, T>>())
local Stack: { Of: (value: any) -> any } = { Of = function(v: any): any return nil end }

-- 중개자(Arr 와 Stack 을 둘 다 아는 제3의 모듈): 등록하고, 이 줄 하나를 내보냄
const ArrIntoStack: <T>(a: Arr<T>) -> Stack<Arr<T>, T> = Stack.Of :: any
const DequeIntoStack: <T>(d: CircularDeque<T>) -> Stack<CircularDeque<T>, T> = Stack.Of :: any

local function drain<C, T>(s: Stack<C, T>, c: C): { T }
	const out = {}
	local x = s.Pop(c)
	while x ~= nil do
		table.insert(out, x)
		x = s.Pop(c)
	end
	return out
end
local a = Arr.Of("x", "y")
local d = CircularDeque.Of(1, 2)
const sa = ArrIntoStack(a) -- 원소 타입은 값에서(주장 없음)
const s1: { string } = drain(sa, a)
const s2: { number } = drain(DequeIntoStack(d), d)
sa.Push(a, "z")
const NEG1 = sa.Push(a, 1) -- NEG
const NEG2: { number } = drain(sa, a) -- NEG
const NEG3 = ArrIntoStack(d) -- NEG: 덱은 Arr 가 아님
const NEG4 = drain(sa, d) -- NEG: 표와 값이 엇갈림
local canary: string = 1
return { s1, s2, NEG1, NEG2, NEG3, NEG4, canary }

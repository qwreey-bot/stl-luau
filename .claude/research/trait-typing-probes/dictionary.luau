--!strict
-- 구현 표를 "사전" 값으로: 각 필드가 제네릭 함수라 모든 T 에 대해 Stack<Arr<T>, T> 로 쓰임
local stl = require("../../../src")
local Arr, CircularDeque = stl.Arr, stl.CircularDeque
type Arr<T> = stl.Arr<T>
type ArrRead<T> = stl.ArrRead<T>
local function Fn<T>(): T
	return nil :: any
end
local function stackDef<Self, T>()
	return { Push = Fn<<(s: Self, item: T) -> Self>>(), Pop = Fn<<(s: Self) -> T?>>(), Peek = Fn<<(s: Self) -> T?>>() }
end
type Stack<Self, T> = typeof(stackDef<<Self, T>>())

-- 중개자(Arr 와 Stack 을 둘 다 아는 곳): 주석 없이 표를 만듦
local function arrPeek<T>(self: ArrRead<T>): T?
	return self[self.n]
end
const ArrStack = { Push = Arr.PushBack, Pop = Arr.PopBack, Peek = arrPeek }
const DequeStack = { Push = CircularDeque.PushBack, Pop = CircularDeque.PopBack, Peek = CircularDeque.Back }

-- 종류를 모르는 제네릭 알고리즘
local function drain<C, T>(s: Stack<C, T>, c: C): { T }
	const out = {}
	local x = s.Pop(c)
	while x ~= nil do
		table.insert(out, x)
		x = s.Pop(c)
	end
	return out
end
local function pushAll<C, T>(s: Stack<C, T>, c: C, items: { T }): C
	for _, it in items do
		s.Push(c, it)
	end
	return c
end

local a = Arr.Of("x", "y")
local d = CircularDeque.Of(1, 2)
-- (1) 표 + 값을 넘기면 T 가 값에서 추론되나
const fromArr: { string } = drain(ArrStack, a)
const fromDeque: { number } = drain(DequeStack, d)
const back: Arr<string> = pushAll(ArrStack, a, { "z" })
-- (2) 틀린 것
const NEG1: { number } = drain(ArrStack, a) -- NEG: 원소 타입
const NEG2 = pushAll(ArrStack, a, { 1 }) -- NEG: 넣는 원소
const NEG3 = drain(ArrStack, d) -- NEG: 표와 값의 종류가 엇갈림
-- (3) 등록 검사: 같은 표를 구체 타입에 대입(타입 함수 없음)
const _checkArr: Stack<Arr<string>, string> = ArrStack
const BadStack = { Push = Arr.PushBack, Pop = Arr.Len, Peek = arrPeek }
const NEG4: Stack<Arr<string>, string> = BadStack -- NEG: Pop 자리에 Len
local canary: string = 1
return { fromArr, fromDeque, back, NEG1, NEG2, NEG3, NEG4, canary }

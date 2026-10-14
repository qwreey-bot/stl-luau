--!strict
local stl = require("../../../src")
local CircularDeque = stl.CircularDeque
type CircularDeque<T> = stl.CircularDeque<T>
local function Fn<T>(): T
	return true :: any
end

--[[ 트레이트 = 제네릭 타입(Self, T). 정의는 한 곳(팩토리) — 런타임엔 이름 목록, 타입은 typeof ]]
local function dequeDef<Self, T>()
	return {
		PushBack = Fn<<(deque: Self, item: T) -> Self>>(),
		PopBack = Fn<<(deque: Self) -> T?>>(),
		Back = Fn<<(deque: Self) -> T?>>(),
	}
end
export type Deque<Self, T> = typeof(dequeDef<<Self, T>>())
local function stackDef<Self, T>()
	return {
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
		Peek = Fn<<(stack: Self) -> T?>>(),
	}
end
export type Stack<Self, T> = typeof(stackDef<<Self, T>>())

--[[ (2) 등록 검사 — 구체 타입으로 ]]
local okReg: Stack<CircularDeque<string>, string> = {
	Push = CircularDeque.PushBack,
	Pop = CircularDeque.PopBack,
	Peek = CircularDeque.Back,
}
local negReg: Stack<CircularDeque<string>, string> = {
	Push = CircularDeque.PushBack,
	Pop = CircularDeque.Len, -- NEG
	Peek = CircularDeque.Back,
}

--[[ (3) 자바 식: 받는 함수가 Stack<C, T> 를 적음 ]]
local function drain<C, T>(s: Stack<C, T>, c: C): { T }
	local out = {}
	local x = s.Pop(c)
	while x ~= nil do
		table.insert(out, x)
		x = s.Pop(c)
	end
	return out
end
-- 동적 경로로 얻기: 트레이트마다 자기 타입으로 꺼내는 함수(시스템이 만들고, 타입은 별칭으로)
local function stackOf<C, T>(value: C): Stack<C, T>
	return nil :: any
end
local d = CircularDeque.Of(1, 2, 3)
local s = stackOf<<CircularDeque<number>, number>>(d) -- 받는 쪽이 T 를 밝힘(자바의 List<Integer>)
local all: { number } = drain(s, d)
s.Push(d, 4)
local negPush = s.Push(d, "x") -- NEG
local negDrain: { string } = drain(s, d) -- NEG

--[[ (4) 뭉텅이 구현: 덱이면 스택 — 제네릭 함수로 타입 검사 ]]
local function stackFromDeque<C, T>(deque: Deque<C, T>): Stack<C, T>
	return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
end
local function badStackFromDeque<C, T>(deque: Deque<C, T>): Stack<C, T>
	return { Push = deque.PushBack, Pop = deque.Back, Peek = deque.PushBack } -- NEG(Peek 자리)
end

local canary: string = 1
return { okReg, negReg, all, negPush, negDrain, stackFromDeque, badStackFromDeque, canary }

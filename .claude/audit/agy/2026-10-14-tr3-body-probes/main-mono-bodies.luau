--!strict
type A = { read __probeA: true }
type B = { read __probeB: true }
type Stack<Self, T> = { Push: (Self, T) -> Self, Pop: (Self) -> T?, Peek: (Self) -> T? }
type Deque<Self, T> = { PushBack: (Self, T) -> Self, PopBack: (Self) -> T?, Back: (Self) -> T?, IsEmpty: (Self) -> boolean }
local function ok(d: Deque<A, B>): Stack<A, B>
	return { Push = d.PushBack, Pop = d.PopBack, Peek = d.Back }
end
local function bad1(d: Deque<A, B>): Stack<A, B>
	return { Push = d.PushBack, Pop = function(c: A): string? return nil end, Peek = d.Back } -- NEG
end
local function bad2(d: Deque<A, B>): Stack<A, B>
	return { Push = function(c: A, x: number): A return c end, Pop = d.PopBack, Peek = d.Back } -- NEG
end
local function bad3(d: Deque<A, B>): Stack<A, B>
	return { Push = d.PushBack, Pop = d.IsEmpty, Peek = d.Back } -- NEG
end
local function bad4(d: Deque<A, B>): Stack<A, B>
	return { Push = d.PushBack, Pop = d.PopBack, Peek = function(c: A): B? return 123 end } -- NEG
end
-- 기본 구현 몸통도 탐침으로
local function indexOf(get: (A, number) -> B?, n: (A) -> number): (A, B) -> number?
	return function(list: A, item: B): number?
		for i = 1, n(list) do
			if get(list, i) == item then return i end
		end
		return "x" -- NEG
	end
end
local canary: string = 1
return { ok, bad1, bad2, bad3, bad4, indexOf }

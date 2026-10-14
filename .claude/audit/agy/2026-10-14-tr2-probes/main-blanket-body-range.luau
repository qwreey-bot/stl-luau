--!strict
type Stack<Self, T> = { Push: (Self, T) -> Self, Pop: (Self) -> T? }
type Deque<Self, T> = { PushBack: (Self, T) -> Self, PopBack: (Self) -> T?, Back: (Self) -> T? }
local function r5<T>(): T
	return 5 -- NEG? 구체 값
end
local function r6<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = d.PushBack } -- NEG? 빠진 필드
end
local function r7<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = d.PushBack, Pop = d.PushBack } -- NEG? 서명 다른 형제
end
local function r8<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = d.PushBack, Pop = function(c: C): string? return nil end } -- NEG?
end
local function r9<C, T>(d: Deque<C, T>, x: T): string
	return x -- NEG?
end
local function strPop(c: any): string? return nil end
local function r10<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = d.PushBack, Pop = strPop } -- NEG? (any 인자)
end
local function pinned(a: { n: number }, x: string): { n: number } return a end
local function r11<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = pinned, Pop = d.PopBack } -- NEG? Self 도 다름
end
local canary: string = 1
return { r5, r6, r7, r8, r9, r10, r11 }

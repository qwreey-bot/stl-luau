--!strict
type Stack<Self, T> = { Push: (Self, T) -> Self, Pop: (Self) -> T? }
type Arr<T> = { n: number, [number]: T }
local function strPush(a: Arr<string>, x: string): Arr<string> return a end
local function arrPop<T>(a: Arr<T>): T? return a[a.n] end
local function numPop(a: Arr<number>): number? return nil end
-- 1. 반환 표에서 바로
local function r1<T>(): Stack<Arr<T>, T>
	return { Push = strPush, Pop = arrPop } -- NEG?
end
-- 2. 안에서 주석 단 지역
local function r2<T>(): Stack<Arr<T>, T>
	const s: Stack<Arr<T>, T> = { Push = strPush, Pop = arrPop } -- NEG?
	return s
end
-- 3. 필드 하나 대입
local function r3<T>(): (Arr<string>, string) -> Arr<string>
	return strPush
end
local function r4<T>(): (Arr<T>, T) -> Arr<T>
	return strPush -- NEG?
end
-- 5. v4 Blanket 몸통 모양: 받은 표에서 꺼내 넣기
type Deque<Self, T> = { PushBack: (Self, T) -> Self, PopBack: (Self) -> T?, PopFront: (Self) -> T? }
local function fromDeque<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = d.PushBack, Pop = d.PopBack }
end
local function fromDequeBad<C, T>(d: Deque<C, T>): Stack<C, T>
	return { Push = d.PushBack, Pop = numPop } -- NEG? (원소를 못박은 함수)
end
local function fromDequeBad2<C, T>(d: Deque<C, T>, other: (C, number) -> C): Stack<C, T>
	return { Push = other, Pop = d.PopBack } -- NEG?
end
local canary: string = 1
return { r1, r2, r3, r4, fromDeque, fromDequeBad, fromDequeBad2 }

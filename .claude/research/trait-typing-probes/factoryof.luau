--!strict
-- Opus ① 의 주장: Trait<F>(name, factory: F) 가 { read Of: F } 를 돌려주면 팩토리가 곧 Of 의 타입
local stl = require("../../../src")
local CircularDeque, Arr = stl.CircularDeque, stl.Arr
type CircularDeque<T> = stl.CircularDeque<T>
type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
type Object<F> = { read Of: F, read FnTok: { [string]: number }, read [string]: any }
local function Fn<T>(): T
	return nil :: any
end
local function Trait<F>(name: string, factory: F): Object<F>
	return nil :: any
end
const Stack = Trait("Stack", function<Self, T>(of: (Self & Item<T>) | Token)
	return {
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
	}
end)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))

local d = CircularDeque.Of(1, 2)
local s = Stack.Of(d) -- Self·T 를 값에서
const back: CircularDeque<number> = s.Push(d, 3)
const p: number? = s.Pop(d)
const NEG1 = s.Push(d, "x") -- NEG
const NEG2: string? = s.Pop(d) -- NEG
const NEG3 = Stack.Of<<CircularDeque<number>, string>>(d) -- NEG: 밝힌 T 가 값과 어긋남
-- 토큰으로(밝히기)
const t = Stack.Of<<CircularDeque<number>, number>>(CircularDeque.Token :: any)
const p2: number? = t.Pop(d)
-- 별칭으로 받는 제네릭 알고리즘
local function drain<C, T>(st: Stack<C, T>, c: C): { T }
	const out = {}
	local x = st.Pop(c)
	while x ~= nil do
		table.insert(out, x)
		x = st.Pop(c)
	end
	return out
end
const all: { number } = drain(s, d)
const NEG4: { string } = drain(s, d) -- NEG
-- 등록 검사(탐침)
type A = { read __probeA: true }
const ok: Stack<stl.Arr<A>, A> = { Push = Arr.PushBack, Pop = Arr.PopBack }
const NEG5: Stack<stl.Arr<A>, A> = { Push = Arr.PushBack, Pop = Arr.Len } -- NEG
local canary: string = 1
return { back, p, NEG1, NEG2, NEG3, p2, all, NEG4, ok, NEG5, canary }

--!strict
-- 등록 검사를 "구체 타입(string)" 대신 "탐침 타입(A — 어떤 실제 타입과도 다른 불투명 타입)" 으로
local stl = require("../../../src")
local Arr = stl.Arr
type Arr<T> = stl.Arr<T>
type ArrRead<T> = stl.ArrRead<T>
local function Fn<T>(): T
	return nil :: any
end
local function stackDef<Self, T>()
	return { Push = Fn<<(s: Self, item: T) -> Self>>(), Pop = Fn<<(s: Self) -> T?>>(), Peek = Fn<<(s: Self) -> T?>>() }
end
type Stack<Self, T> = typeof(stackDef<<Self, T>>())
type A = { read __probeA: true }
local function arrPeek<T>(self: ArrRead<T>): T?
	return self[self.n]
end
-- 원소를 string 으로 못박은 함수(제네릭 컨테이너의 구현으로는 틀림)
local function strPush(self: Arr<string>, item: string): Arr<string>
	return self
end
-- 구체 타입으로 검사: 못박은 함수도 통과(구멍)
const concreteOk: Stack<Arr<string>, string> = { Push = Arr.PushBack, Pop = Arr.PopBack, Peek = arrPeek }
const concreteHole: Stack<Arr<string>, string> = { Push = strPush, Pop = Arr.PopBack, Peek = arrPeek } -- 0건이면 구멍
-- 탐침으로 검사
const probeOk: Stack<Arr<A>, A> = { Push = Arr.PushBack, Pop = Arr.PopBack, Peek = arrPeek }
const NEG_probePinned: Stack<Arr<A>, A> = { Push = strPush, Pop = Arr.PopBack, Peek = arrPeek } -- NEG
const NEG_probeLen: Stack<Arr<A>, A> = { Push = Arr.PushBack, Pop = Arr.Len, Peek = arrPeek } -- NEG
local canary: string = 1
return { concreteOk, concreteHole, probeOk, NEG_probePinned, NEG_probeLen, canary }

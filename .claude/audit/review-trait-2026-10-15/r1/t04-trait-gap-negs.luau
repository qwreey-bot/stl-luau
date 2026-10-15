--!strict
-- 타입 프로브 t04: 돌연변이 TM11·TM16·TM19·TM21·TM22·TM25 가 살아남은 자리의 NEG. 원본 src 에서는 전부 에러여야 하고
-- (아래 기대), 각 돌연변이 사본에서는 해당 줄이 0건이 됨(= 배터리의 빈 곳).
local stl = require("../../../../src")
type A = { read __probeA: true }
type Arr<T> = stl.Arr<T>
type CD<T> = stl.CircularDeque<T>
local d = stl.CircularDeque.Of(1, 2, 3)
local borrowed: stl.CircularDequeRead<number> = d
local q1 = stl.Queue.Of(borrowed) -- NEG(TM11): 읽기로 빌린 참조는 큐를 못 얻음
local q2 = stl.Queue.Push(d, "x") -- NEG(TM16): 원소 타입
local s1 = stl.Stack.Pop(borrowed) -- NEG(TM19): 빌린 참조에서 꺼냄
local function noRet(_s: CD<A>, _x: A) end
local dq: stl.DequeProvided<CD<A>, A> = {
	PushFront = stl.CircularDeque.PushFront,
	PushBack = noRet, -- NEG(TM21): 자기 자신을 안 돌려줌
	PopFront = stl.CircularDeque.PopFront,
	PopBack = stl.CircularDeque.PopBack,
	Front = stl.CircularDeque.Front,
	Back = stl.CircularDeque.Back,
}
local function clearNoRet(_s: CD<A>) end
local col: stl.CollectionProvided<CD<A>> = { Len = stl.CircularDeque.Len, Clear = clearNoRet } -- NEG(TM22)
local function strGet(_s: Arr<A>, _i: string): A? return nil end
local li: stl.ListProvided<Arr<A>, A, number> = {
	Get = strGet, -- NEG(TM25): 위치 타입
	FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex,
}
local canary: string = 1
return { q1, q2, s1, dq, col, li, canary }

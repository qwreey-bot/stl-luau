--!strict
-- 시제품 v2 의 타입 — 진입점(시그니처 그대로)과 등록 검사(For 별칭). 음성 대조군은 NEG.
local P = require("./Traits")
local stl = require("../../../src")
type CircularDeque<T> = stl.CircularDeque<T>
local d = P.Kinds.tag(stl.CircularDeque.Of(1, 2, 3), P.Kinds.CD)

-- 진입점
const pushed: CircularDeque<number> = P.Stack.Push(d, 4)
const popped: number? = P.Stack.Pop(d)
const NEG_push = P.Stack.Push(d, "x") -- NEG: 원소 타입(불변 마커)
const NEG_pop: string? = P.Queue.Pop(d) -- NEG: 반환 타입
const NEG_borrow = P.Stack.Pop(d :: stl.CircularDequeRead<number>) -- NEG: 빌린 참조는 꺼내기 못 함
const peekBorrow: number? = P.Stack.Peek(d :: stl.CircularDequeRead<number>)
const where: number? = P.List.IndexOf(d, 2)
const total: number = P.List.Fold(d, 0, function(acc: number, x: number): number
	return acc + x
end)
-- 타입을 적은 콜백 변수(예전 `...unknown` 꼬리가 거절하던 모양)
const add: (acc: number, item: number, idx: number) -> number = function(acc, x, _i)
	return acc + x
end
const total2: number = P.List.Fold(d, 0, add)
const NEG_fold: string = P.List.Fold(d, 0, add) -- NEG: 누적 타입
-- 종류를 아는 경로
const direct = P.Stack[P.Kinds.CD]

local canary: string = 1
return { pushed, popped, NEG_push, NEG_pop, NEG_borrow, peekBorrow, where, total, total2, NEG_fold, direct, canary }

--!strict
-- 시제품 v2 의 타입 — 진입점(표식을 바꿔 끼운 시그니처)과 등록 검사(ImplFor). 음성 대조군은 NEG.
local P = require("./Traits")
local stl = require("../../../src")
type CircularDeque<T> = stl.CircularDeque<T>
type Arr<T> = stl.Arr<T>
local d = P.Kinds.tag(stl.CircularDeque.Of(1, 2, 3), P.Kinds.CD)
local a = P.Kinds.tag(stl.Arr.Of("x", "y"), P.Kinds.ARR)

-- 진입점: 덱
const pushed: CircularDeque<number> = P.Stack.Push(d, 4)
const popped: number? = P.Stack.Pop(d)
const NEG_push = P.Stack.Push(d, "x") -- NEG: 원소 타입
const NEG_pop: string? = P.Queue.Pop(d) -- NEG: 반환 타입
-- 진입점: Arr — 덱이 아니어도 For 로 스택(예전엔 타입에서 거절됐음)
const arrPushed: Arr<string> = P.Stack.Push(a, "z")
const arrPeek: string? = P.Stack.Peek(a)
const NEG_arrPush = P.Stack.Push(a, 1) -- NEG: 원소 타입
-- 리스트: 위치 타입은 종류마다(덱은 숫자)
const where: number? = P.List.IndexOf(d, 2)
const total: number = P.List.Fold(d, 0, function(acc: number, x: number, _i: number): number
	return acc + x
end)
const add: (acc: number, item: number, idx: number) -> number = function(acc, x, _i)
	return acc + x
end
const total2: number = P.List.Fold(d, 0, add)
const NEG_fold: string = P.List.Fold(d, 0, add) -- NEG: 누적 타입
const NEG_where: string? = P.List.IndexOf(d, 2) -- NEG: 위치 타입

local canary: string = 1
return {
	pushed,
	popped,
	NEG_push,
	NEG_pop,
	arrPushed,
	arrPeek,
	NEG_arrPush,
	where,
	total,
	total2,
	NEG_fold,
	NEG_where,
	impl,
	canary,
}

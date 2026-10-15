--!strict
--[[
	바깥에서 트레이트를 덧붙이기(질문 BA, 2026-10-15 — 사용자: "<T>(Arr<T>) -> Stack<T> 를 주는 뭔가", "traits 나열 같은 경우 바깥에서 못할 이유를
	잘 모르겠는"): 등록(런타임)은 타입을 못 바꾸니, 원래 타입에 `__traits` 레코드를 교집합으로 덧붙인 별칭과 그것을 돌려주는 **중간자 함수**
	(`<T>(Arr<T>) -> StackArr<T>` — 런타임은 그대로 돌려줌)로 씁니다. 원소 타입이 이어지는지, 변환 안 한 값·빌린 참조는 막히는지.
	⚠️ 여기서는 런타임 등록을 하지 않습니다(타입만 봄) — 실제로 쓰려면 `Stack.ImplFor(Arr.Token, …)` 같은 등록이 짝입니다.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 줄마다 + CANARY 1).
]]
local stl = require("../../../../src")
type Arr<T> = stl.Arr<T>

-- 1. 바깥에서 트레이트를 나열: 원래 타입에 `__traits` 레코드를 교집합으로 덧붙임
type StackArr<T> = Arr<T> & { read __traits: { read Deque: stl.DequeAssoc<T> } }
-- 2. 중간자: 토큰·구조를 아는 쪽과 트레이트를 아는 쪽을 둘 다 아는 자리(등록하는 자리)가 쓰는 제네릭 함수 값.
--    런타임은 그대로 돌려줌(데이터는 엔티티 — 감싸지 않음). 타입만 "이 값은 스택이기도 함" 을 더함.
local function asStack<T>(a: Arr<T>): StackArr<T>
	return a :: any
end

local a = stl.Arr.Of(1, 2, 3)
local s = asStack(a)
stl.Stack.Push(s, 4)
local top: number? = stl.Stack.Pop(s)
local still: number = stl.Arr.Len(s) -- 원래 모듈 함수도 그대로(교집합이라 Arr 이기도 함)
local negPush = stl.Stack.Push(s, "x") -- NEG: 원소 타입이 이어짐
local negTop: string? = stl.Stack.Peek(s) -- NEG
local negRaw = stl.Stack.Push(a, 4) -- NEG: 변환하지 않은 Arr 은 스택이 아님(타입이 안 바뀜 — 뿌리)
local r: stl.ArrRead<number> = a
local negBorrow = asStack(r) -- NEG: 빌린 읽기 참조는 변환 못 함(Arr<T> 를 요구)
-- 읽기만 하는 중간자는 빌린 참조도
type PeekArr<T> = stl.ArrRead<T> & { read __traits: { read Deque: stl.DequeAssocRead<T> } }
local function asPeek<T>(x: stl.ArrRead<T>): PeekArr<T>
	return x :: any
end
local p: number? = stl.Stack.Peek(asPeek(r))
local negPeekPush = stl.Stack.Push(asPeek(r), 1) -- NEG: 읽기 레코드만이라 쓰기 진입점은 못 받음
local canary: string = 1
return { top, still, negPush, negTop, negRaw, negBorrow, p, negPeekPush, canary }

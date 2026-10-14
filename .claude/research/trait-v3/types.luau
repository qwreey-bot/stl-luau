--!strict
-- 시제품 v3 의 타입 — 트레이트가 제네릭 타입. 음성 대조군은 NEG.
local P = require("./Traits")
local stl = require("../../../src")
type CircularDeque<T> = stl.CircularDeque<T>
type Arr<T> = stl.Arr<T>
type Stack<Self, T> = P.Stack<Self, T>
local d = P.Kinds.tag(stl.CircularDeque.Of(1, 2, 3), P.Kinds.CD)
local a = P.Kinds.tag(stl.Arr.Of("x", "y"), P.Kinds.ARR)

-- 동적 경로: 받는 쪽이 T 를 밝힘
const s = P.Stack.Of<<CircularDeque<number>, number>>(d)
const pushed: CircularDeque<number> = s.Push(d, 4)
const popped: number? = s.Pop(d)
const NEG_push = s.Push(d, "x") -- NEG: 원소 타입
const NEG_pop: string? = s.Pop(d) -- NEG: 반환 타입
const sa = P.Stack.Of<<Arr<string>, string>>(a) -- Arr 스택
const arrPeek: string? = sa.Peek(a)
const NEG_arr = sa.Push(a, 1) -- NEG
-- 토큰으로
const sf = P.Stack.For<<CircularDeque<number>, number>>(P.Kinds.CD)
const viaToken: number? = sf.Pop(d)
-- 자바 식: 받는 함수가 Stack<C, T> 를 적음
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
const NEG_drain: { string } = drain(s, d) -- NEG
-- 리스트(위치·기본 구현)
const l = P.List.Of<<CircularDeque<number>, number, number>>(d)
const where: number? = l.IndexOf(d, 2)
const total: number = l.Fold(d, 0, function(acc: number, x: number, _i: number): number
	return acc + x
end)
const NEG_where: string? = l.IndexOf(d, 2) -- NEG
-- ⚠️ 알려진 경계(0건이어야 함): 밝힌 T 는 주장 — 숫자 덱을 문자열 스택으로 꺼내도 타입이 못 막음
const claimed = P.Stack.Of<<CircularDeque<number>, string>>(d)
-- 편한 진입점(원소 검사 없음 — any 경로)
P.Stack.Push(d, "any")

local canary: string = 1
return {
	pushed,
	popped,
	NEG_push,
	NEG_pop,
	arrPeek,
	NEG_arr,
	viaToken,
	all,
	NEG_drain,
	where,
	total,
	NEG_where,
	claimed,
	canary,
}

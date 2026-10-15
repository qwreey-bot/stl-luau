--!strict
-- 메인: Gemini 가 결정적이라 한 장면(제네릭 알고리즘이 완성 표를 받음)을 Sonnet 의 레코드 안(정의 함수에 타입 함수)에서
local stl = require("../src")
type A = { read __probeA: true }
local function drain<C, T>(st: stl.StackFull<C, T>, c: C): { T }
	local out = {}
	local x = st.Pop(c)
	while x ~= nil do
		table.insert(out, x)
		x = st.Pop(c)
	end
	return out
end
local d = stl.CircularDeque.Of(1, 2, 3)
const all: { number } = drain(stl.Stack.Of(d), d)
const negAll: { string } = drain(stl.Stack.Of(d), d) -- NEG
-- 인라인 주석 단 등록에서 Fold 의 U 를 못박음 / Fold = Len
const negPinU: stl.ListProvided<stl.Arr<A>, A, number> = {
	Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex,
	Fold = function(_l: stl.Arr<A>, init: number, _fn: (number, A, number, ...any) -> number): number -- NEG
		return init
	end,
}
const negLen: stl.ListProvided<stl.Arr<A>, A, number> = {
	Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex,
	Fold = stl.Arr.Len, -- NEG
}
local canary: string = 1
return { all, negAll, negPinU, negLen, canary }

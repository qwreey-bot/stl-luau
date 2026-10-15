--!strict
-- 타입 프로브 01: ImplWhere 의 첫 인자 타입(`{ any } | EveryKind`)이 무엇을 받고 무엇을 거절하나
local stl = require("../../../../src")
local T = stl.Trait
local build = function(_deps: { [any]: any }): any
	return {}
end
stl.Stack.ImplWhere(T.Every, build) -- POS: 표식
stl.Stack.ImplWhere({ stl.Deque }, build) -- POS: 목록
stl.Stack.ImplWhere({}, build) -- ? 빈 목록 리터럴 (런타임 에러)
stl.Stack.ImplWhere(table.freeze({}), build) -- ? 얼린 빈 목록 (런타임 에러)
stl.Stack.ImplWhere(stl.Deque, build) -- ? 목록 없이 트레이트 (런타임 에러)
stl.Stack.ImplWhere({ T.Every }, build) -- ? 목록 안의 표식 (런타임 에러)
stl.Stack.ImplWhere("Deque", build) -- NEG? 문자열
const traits = { Deque = stl.Deque }
stl.Stack.ImplWhere({ traits.Dequ }, build) -- NEG? 오타(strict)
const e: stl.TraitEveryKind = T.Every -- POS: 배럴 타입
const fake: stl.TraitEveryKind = { __everyKind = true } -- ? 표식을 흉내(런타임 에러)
stl.Stack.ImplWhere(fake, build)
local canary: string = 1
return { e, canary }

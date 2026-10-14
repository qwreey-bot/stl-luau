--!strict
-- probe 3: D3 (v9) 의 동일 모듈 내 안전성(soundness) 전수 실측
-- 한 파일에서 정의, 등록, 호출을 모두 수행할 때 기본 구현 반환 및 시그니처가 정확히 잡히는지 검증
local TraitV9 = require("../.claude/research/trait-v9/Trait")

-- 1. 트레이트 정의 (기본 구현 2개 포함)
local function testDef<M>(mode: M)
	return function<Self, E>(of: Self)
		return {
			Get = TraitV9.Fn<<(Self, number) -> E?>>(),
			Contains = TraitV9.Default(mode, function(ops: any)
				return function(s: Self, e: E): boolean return false end
			end),
			IndexOf = TraitV9.Default(mode, function(ops: any)
				return function(s: Self, e: E): number? return 1 end
			end),
		}
	end
end

const TestTrait = TraitV9.Trait("TestTrait", testDef(TraitV9.FULL), testDef(TraitV9.IMPL))
type TestTrait<Self, E> = typeof(TestTrait.Of<<Self, E>>(nil :: any))
type TestTraitImpl<Self, E> = typeof(TestTrait.ImplOf<<Self, E>>(nil :: any))

-- 2. 동일 파일에서 구현체 등록 (Contains, IndexOf는 생략)
type Container = { n: number }
const containerImpl: TestTraitImpl<Container, number> = {
	Get = function(s: Container, i: number): number? return 42 end,
}

-- 3. 동일 파일에서 호출 및 반환값 검증
local obj: Container = { n = 1 }
const ops = TestTrait.Of(obj)

-- 정상 호출
local b: boolean = ops.Contains(obj, 10)
local idx: number? = ops.IndexOf(obj, 10)

-- [NEG 테스트]: B(v8 인라인)에서 never로 추락해 침묵 통과했던 바로 그 줄들!
const NEG_contains_to_string: string = ops.Contains(obj, 10) -- NEG: boolean -> string
const NEG_indexof_to_boolean: boolean = ops.IndexOf(obj, 10) -- NEG: number? -> boolean
const NEG_contains_bad_arg = ops.Contains(obj, "not_number") -- NEG: number -> string 인자 불일치
const NEG_missing_get: TestTraitImpl<Container, number> = {} -- NEG: 필수 Get 누락

local canary: string = 1
return { b, idx, NEG_contains_to_string, NEG_indexof_to_boolean, NEG_contains_bad_arg, NEG_missing_get, canary }

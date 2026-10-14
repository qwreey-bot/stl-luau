--!strict
-- probe 3b: D3에서 ItemRead 팬텀 마커가 있을 때의 E 추론 및 인자 검사 실측
local TraitV9 = require("../.claude/research/trait-v9/Trait")
type ItemRead<E> = TraitV9.ItemRead<E>

-- 트레이트 정의: of에 ItemRead<E> 요구
local function testDef<M>(mode: M)
	return function<Self, E>(of: (Self & ItemRead<E>) | TraitV9.AnyToken)
		return {
			Get = TraitV9.Fn<<(Self, number) -> E?>>(),
			Contains = TraitV9.Default(mode, function(ops: any)
				return function(s: Self, e: E): boolean return false end
			end),
		}
	end
end

const TestTrait = TraitV9.Trait("TestTrait", testDef(TraitV9.FULL), testDef(TraitV9.IMPL))
type TestTrait<Self, E> = typeof(TestTrait.Of<<Self, E>>(nil :: any))

-- 컨테이너 정의: ItemRead<number> 마커 포함
type MyContainer = {
	n: number,
	read __readGenerics: { read Item: () -> number },
}

local obj: MyContainer = nil :: any
const ops = TestTrait.Of(obj)

-- 정상 호출: number 전달
local b: boolean = ops.Contains(obj, 10)

-- [NEG 테스트]: number 자리에 string 전달
const NEG_bad_arg = ops.Contains(obj, "string_not_number") -- NEG: Expected number, got string!

local canary: string = 1
return { b, NEG_bad_arg, canary }

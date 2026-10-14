--!strict
-- probe 4: D3에서 table.freeze 한 줄 등록과 주석 단 지역 변수 등록의 대조 실측
local TraitV9 = require("../.claude/research/trait-v9/Trait")
local stl = require("../src")
type Arr<T> = stl.Arr<T>
type A = TraitV9.A

-- 1. table.freeze를 반환하는 팩토리
local function stackDefFreeze<M>(mode: M)
	return function<Self, T>(of: Self)
		return table.freeze({
			Push = TraitV9.Fn<<(Self, T) -> Self>>(),
			Pop = TraitV9.Fn<<(Self) -> T?>>(),
			IsEmpty = TraitV9.Default(mode, function(ops: any)
				return function(s: Self): boolean return true end
			end),
		})
	end
end
const StackFreeze = TraitV9.Trait("StackFreeze", stackDefFreeze(TraitV9.FULL), stackDefFreeze(TraitV9.IMPL))
type StackFreezeImpl<Self, T> = typeof(StackFreeze.ImplOf<<Self, T>>(nil :: any))

-- 트레이트 특화 ImplFor 바인딩
type StackFreezeImplFor = <Self, T>(token: TraitV9.AnyToken, impl: StackFreezeImpl<Self, T>) -> ()
const ImplForSpecialized: StackFreezeImplFor = StackFreeze.ImplFor :: any

const ARR = TraitV9.Token("ArrFreeze")

-- [시험 1]: 한 줄 등록 (표 리터럴 직접 전달)
ImplForSpecialized<<Arr<A>, A>>(ARR, {
	Push = stl.Arr.PushBack,
	Pop = stl.Arr.PopBack,
})

-- [시험 2]: 한 줄 등록에서 필수 메서드 Pop 누락 (NEG)
ImplForSpecialized<<Arr<A>, A>>(ARR, {
	Push = stl.Arr.PushBack,
}) -- NEG missing pop

-- [시험 3]: 한 줄 등록에서 잘못된 시그니처 전달 (NEG)
local function strPush(s: Arr<string>, v: string): Arr<string> return s end
ImplForSpecialized<<Arr<A>, A>>(ARR, {
	Push = strPush,
	Pop = stl.Arr.PopBack,
}) -- NEG bad signature

-- [시험 4]: 표준 방식 (주석 단 지역 변수)
const regStd: StackFreezeImpl<Arr<A>, A> = {
	Push = stl.Arr.PushBack,
	Pop = stl.Arr.PopBack,
}
StackFreeze.ImplFor(ARR, regStd)

local canary: string = 1
return { canary }

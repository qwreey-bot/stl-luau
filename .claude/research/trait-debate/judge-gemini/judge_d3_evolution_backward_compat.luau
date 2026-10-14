--!strict
-- probe 2: 트레이트 진화(새 기본 구현 추가) 시 후보 A vs 후보 D3의 하위 호환성 실측
local TraitV9 = require("../.claude/research/trait-v9/Trait")

-- ========================================================
-- [후보 A 모델]: 기본 구현 칸에 Trait.Inherit 표식을 요구하는 방식
-- ========================================================
local Inherit = table.freeze({}) -- Trait.Inherit 표식

-- v1.0 시점의 Trait A
type ListA_v1<Self, E> = {
	Get: (Self, number) -> E?,
	IndexOf: (Self, E) -> number?,
}

-- v1.0 구현체 (A 방식: 기본 구현 칸에도 Inherit 필수)
const myImplA_v1: ListA_v1<{ n: number }, number> = {
	Get = function(s, i) return 1 end,
	IndexOf = Inherit :: any,
}

-- v1.1 시점: 라이브러리가 기본 구현 Contains를 추가함!
type ListA_v1_1<Self, E> = {
	Get: (Self, number) -> E?,
	IndexOf: (Self, E) -> number?,
	Contains: (Self, E) -> boolean, -- 새 기본 구현 추가!
}

-- [후보 A의 치명적 파괴]: 기존 구현 코드는 아무것도 안 건드렸는데 컴파일 에러 발생!
-- const NEG_broken_existing_A: ListA_v1_1<{ n: number }, number> = myImplA_v1 -- missing field 'Contains'

-- ========================================================
-- [후보 D3 모델]: v9 방식 (등록 표 ImplOf에서 기본 구현 칸이 선택적)
-- ========================================================
-- v1.0 정의: Get 필수, IndexOf 기본 구현
local function listDefD3_v1<M>(mode: M)
	return function<Self, E>(of: Self)
		return {
			Get = TraitV9.Fn<<(Self, number) -> E?>>(),
			IndexOf = TraitV9.Default(mode, function(ops: any)
				return function(s: Self, e: E): number? return nil end
			end),
		}
	end
end
const ListD3_v1 = TraitV9.Trait("ListD3_v1", listDefD3_v1(TraitV9.FULL), listDefD3_v1(TraitV9.IMPL))
type ListImplD3_v1<Self, E> = typeof(ListD3_v1.ImplOf<<Self, E>>(nil :: any))

-- v1.0 구현체: 필수 Get만 구현하고 IndexOf는 생략
const myImplD3_v1: ListImplD3_v1<{ n: number }, number> = {
	Get = function(s, i) return 1 end,
}

-- v1.1 시점: 라이브러리가 새 기본 구현 Contains를 추가함!
local function listDefD3_v1_1<M>(mode: M)
	return function<Self, E>(of: Self)
		return {
			Get = TraitV9.Fn<<(Self, number) -> E?>>(),
			IndexOf = TraitV9.Default(mode, function(ops: any)
				return function(s: Self, e: E): number? return nil end
			end),
			Contains = TraitV9.Default(mode, function(ops: any)
				return function(s: Self, e: E): boolean return false end
			end),
		}
	end
end
const ListD3_v1_1 = TraitV9.Trait("ListD3_v1_1", listDefD3_v1_1(TraitV9.FULL), listDefD3_v1_1(TraitV9.IMPL))
type ListImplD3_v1_1<Self, E> = typeof(ListD3_v1_1.ImplOf<<Self, E>>(nil :: any))

-- [후보 D3의 완벽한 하위 호환성]:
-- v1.0에서 작성된 myImplD3_v1(Contains 없음)을 v1.1 등록 표 타입에 대입해도 0건 통과!
const compatTestD3: ListImplD3_v1_1<{ n: number }, number> = myImplD3_v1

-- 그리고 새 구현체도 Contains 없이 Get만 등록해도 0건 통과!
const newImplD3: ListImplD3_v1_1<{ n: number }, number> = {
	Get = function(s, i) return 1 end,
}

-- 잘못된 필수 메서드 누락은 여전히 칼같이 차단!
const NEG_missing_get: ListImplD3_v1_1<{ n: number }, number> = {} -- NEG

local canary: string = 1
return { myImplA_v1, compatTestD3, newImplD3, NEG_missing_get, canary }

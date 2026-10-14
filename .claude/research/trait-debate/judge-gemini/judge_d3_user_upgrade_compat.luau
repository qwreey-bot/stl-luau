--!strict
-- probe 2b (수정): 실제 관례대로 주석 단 지역 변수에 표 리터럴을 바로 적었을 때의 하위 호환성 실측
local TraitV9 = require("../.claude/research/trait-v9/Trait")

-- 라이브러리 v1.0
local function listDef_v1<M>(mode: M)
	return function<Self, E>(of: Self)
		return {
			Get = TraitV9.Fn<<(Self, number) -> E?>>(),
			IndexOf = TraitV9.Default(mode, function(ops: any)
				return function(s: Self, e: E): number? return nil end
			end),
		}
	end
end
const List_v1 = TraitV9.Trait("List", listDef_v1(TraitV9.FULL), listDef_v1(TraitV9.IMPL))
type ListImpl_v1<Self, E> = typeof(List_v1.ImplOf<<Self, E>>(nil :: any))

-- [D3]: v1.0 시절 사용자 코드: 표 리터럴을 바로 초기화값으로 작성
const userRegD3_v1: ListImpl_v1<{ n: number }, number> = {
	Get = function(s, i) return 1 end,
}

-- 라이브러리 v1.1로 판올림: 라이브러리가 기본 구현 Contains를 추가함!
local function listDef_v1_1<M>(mode: M)
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
const List_v1_1 = TraitV9.Trait("List", listDef_v1_1(TraitV9.FULL), listDef_v1_1(TraitV9.IMPL))
type ListImpl_v1_1<Self, E> = typeof(List_v1_1.ImplOf<<Self, E>>(nil :: any))

-- v1.1 업데이트 후 사용자 코드:
-- 사용자가 작성해둔 기존 코드({ Get = ... } 그대로)를 타입만 v1.1 ListImpl로 재검사할 때
const userRegD3_v1_1: ListImpl_v1_1<{ n: number }, number> = {
	Get = function(s, i) return 1 end,
}
-- 통과! 기본 구현 Contains를 전혀 적지 않았어도 아무런 에러 없이 깨끗하게 통과함!

-- ========================================================
-- 반면 후보 A에서 v1.1로 업데이트되었을 때의 사용자 코드:
-- ========================================================
type ListA_v1<Self, E> = {
	Get: (Self, number) -> E?,
	IndexOf: (Self, E) -> number?,
}
-- v1.0 당시 사용자 코드
const userRegA_v1: ListA_v1<{ n: number }, number> = {
	Get = function(s, i) return 1 end,
	IndexOf = table.freeze({}) :: any, -- Inherit
}

type ListA_v1_1<Self, E> = {
	Get: (Self, number) -> E?,
	IndexOf: (Self, E) -> number?,
	Contains: (Self, E) -> boolean, -- 라이브러리 1.1에서 추가됨
}

-- [후보 A의 치명적 깨짐]:
-- 사용자가 v1.0 당시 작성해둔 코드를 그대로 v1.1 ListA 타입으로 검사하면:
const NEG_userRegA_v1_1: ListA_v1_1<{ n: number }, number> = {
	Get = function(s, i) return 1 end,
	IndexOf = table.freeze({}) :: any,
} -- NEG: missing field 'Contains'

local canary: string = 1
return { userRegD3_v1, userRegD3_v1_1, userRegA_v1, NEG_userRegA_v1_1, canary }

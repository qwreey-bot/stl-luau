--!strict
-- probes/probe_index_limits.luau
-- 내장 index<> 의 한계 및 깨지는 지점 실측 프로브

-- 1. indexee가 테이블이 아닌 경우 (원시 타입, 함수 등)
type ErrIndexPrimitive = index<number, "a"> -- NEG: cannot index into number

-- 2. indexer가 테이블에 없는 키인 경우
type TargetTable = { full: string, impl: string? }
type ErrIndexMissingKey = index<TargetTable, "none"> -- NEG: Property '"none"' does not exist

-- 3. indexer가 string 리터럴이 아닌 넓은 string인 경우
type ErrIndexWideString = index<TargetTable, string> -- NEG: Property 'string' does not exist

-- 4. 제네릭 M 상태에서 반환값을 구체 변수에 넣으려고 할 때 (never로 축약되어 깨짐)
local function failInsideGeneric<M>(mode: M)
	-- 여기서 Default 흉내: 반환 타입이 index<TargetTable, M>
	local function helper(): index<TargetTable, M>
		return nil :: any
	end
	-- helper()의 반환값을 string에 대입 시도
	local s: string = helper() -- NEG: the reduced type is `never`
	return s
end

-- 5. 제네릭 함수를 래핑하는 고차 팩토리에서 mode를 제네릭으로 전달할 때 깨지는 지점
local function wrapDef<M>(mode: M)
	-- M이 ("full" | "impl") 제약 없이 제네릭으로 전달되면 indexee의 키와 매칭 실패
	type BadView = index<TargetTable, M>
	local x: BadView = nil :: any
	return x
end

-- canary
local canary: string = 1

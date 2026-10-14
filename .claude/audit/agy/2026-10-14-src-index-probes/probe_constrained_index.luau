--!strict
-- probes/probe_constrained_index.luau

type TwoViews<F, M> = index<{ full: F, impl: F? }, M>

-- M을 ("full" | "impl")로 제한한 제네릭 함수
local function getGenericView<M>(mode: M & ("full" | "impl")): TwoViews<number, M>
	return nil :: any
end

-- 호출 1: "full" 리터럴로 호출
local vFull = getGenericView("full")
local n: number = vFull

-- 호출 2: "impl" 리터럴로 호출
local vImpl = getGenericView("impl")
local maybeN: number? = vImpl

local canary: string = 1

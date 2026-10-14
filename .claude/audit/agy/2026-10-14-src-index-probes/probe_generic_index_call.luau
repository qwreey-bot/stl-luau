--!strict
-- probes/probe_generic_index_call.luau

type TwoViews<F, M> = index<{ full: F, impl: F? }, M>

local function getGenericView<M>(mode: M): TwoViews<number, M>
	local val: TwoViews<number, M> = 123 -- 몸통 안에서 대입 시도
	return val
end

-- 호출 1: "full" 리터럴로 호출
local vFull = getGenericView("full")
local n: number = vFull -- number로 추론되는가?

-- 호출 2: "impl" 리터럴로 호출
local vImpl = getGenericView("impl")
local maybeN: number? = vImpl -- number?로 추론되는가?

-- 호출 3: 제네릭 M을 받는 다른 함수 안에서 전달
local function passGeneric<T>(m: T)
	local v = getGenericView(m)
	return v
end

local canary: string = 1

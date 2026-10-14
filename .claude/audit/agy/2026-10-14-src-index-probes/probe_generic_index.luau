--!strict
-- probes/probe_generic_index.luau

type TwoViews<F, M> = index<{ full: F, impl: F? }, M>

-- 케이스 1: 구체 싱글톤 "full"로 인덱싱 -> 정상 동작 기대
type ViewFull = TwoViews<number, "full">
local x1: ViewFull = 10 -- ok

-- 케이스 2: 구체 싱글톤 "impl"로 인덱싱 -> 정상 동작 기대 (number?)
type ViewImpl = TwoViews<number, "impl">
local x2: ViewImpl = nil -- ok

-- 케이스 3: 제네릭 M인 상태에서 TwoViews를 반환하는 제네릭 함수 정의
local function getGenericView<M>(mode: M): TwoViews<number, M>
	return nil :: any
end

local canary: string = 1

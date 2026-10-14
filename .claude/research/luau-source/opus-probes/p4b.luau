--!strict
local function id<T>(x: T): T return x end
local direct: (x: number) -> number = id -- B 지역 직접
type Spec = { process: (x: number) -> number }
local viaTable: Spec = { process = id } -- C 지역 표
local s2: Spec = { process = id }
s2 = { process = id } -- D 대입
local function ret(): Spec
	return { process = id } -- E return
end
local function retFn(): (x: number) -> number
	return id -- F return 함수
end
local castT = { process = id } :: Spec -- G 캐스트
return direct, viaTable, ret, retFn, castT

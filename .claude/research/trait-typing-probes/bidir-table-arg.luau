--!strict
-- Gemini ③ 의 상류 보고 후보: 함수 인자 자리의 표 리터럴에서는 제네릭 함수 필드가 기대 타입으로 인스턴스화되지 않음
local function id<T>(x: T): T
	return x
end
type Spec = { process: (x: number) -> number }
local varA: Spec = { process = id } -- 주석 단 지역: 통과해야 함
local function takeSpec(s: Spec) end
takeSpec({ process = id }) -- 인자 자리의 표 리터럴: 에러가 나면 결함
local function takeFn(f: (x: number) -> number) end
takeFn(id) -- 함수 하나를 인자로: 통과해야 함
return varA

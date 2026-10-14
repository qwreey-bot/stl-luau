--!strict
-- probe3: 함수 오버로딩(&)의 한계 실측

type DefaultOverload =
	(<F>(mode: "full", build: (ops: any) -> F) -> F) &
	(<F>(mode: "impl", build: (ops: any) -> F) -> F?)

local Default: DefaultOverload = nil :: any

-- [성공 케이스] 구체 리터럴을 직접 넘길 때는 정확히 분기됨
local fFull = Default("full", function(ops) return function(x: number): boolean return x > 0 end end)
local b: boolean = fFull(10) -- non-nil로 호출 가능 (에러 0건)

local fImpl = Default("impl", function(ops) return function(x: number): boolean return x > 0 end end)
local maybeF: ((number) -> boolean)? = fImpl -- optional로 추론됨 (에러 0건)

-- [실패 케이스] 제네릭 팩토리 안에서 mode: M으로 호출하면 ambiguous 에러 발생!
local function genericFactory<M>(mode: M & ("full" | "impl"))
	return {
		IsEmpty = Default(mode, function(ops) -- FAIL: ambiguous
			return function(x: number): boolean return x > 0 end
		end)
	}
end

local canary: string = 1

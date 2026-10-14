--!strict
-- 5. 재귀 타입 별칭이 유니온(옵셔널 포함)의 갈래일 때 타입 인자가 검사되지 않음.
-- 실행: luau-analyze <이 파일>          → 새 솔버: control 한 줄만 에러
--       luau-analyze --solver=old <이 파일>
type Plain<T> = { value: T, next: Plain<T>? }

local ps: Plain<string> = { value = "s", next = nil }

local control: Plain<number> = ps -- control: TypeError (정상)
local optional: Plain<number>? = ps -- BUG: 0건
local union: Plain<number> | boolean = ps -- BUG: 0건

local function take(node: Plain<number>?): number
	return if node then node.value else 0
end
local viaArg = take(ps) -- BUG: 0건 — 런타임에 문자열이 number 자리로

return { control, optional, union, viaArg }

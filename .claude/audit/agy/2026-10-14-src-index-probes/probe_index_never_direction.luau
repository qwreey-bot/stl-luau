--!strict
-- probes/probe_index_never_direction.luau

type TargetTable = { full: number, impl: number? }

local function testAssign<M>(mode: M)
	local function helper(): index<TargetTable, M>
		return nil :: any
	end

	-- 1. helper()의 결과를 number에 대입:
	-- index<TargetTable, M> -> never로 축약됨 -> never <: number -> 성공!
	local n: number = helper()

	-- 2. number 값을 index<TargetTable, M>에 대입:
	-- index<TargetTable, M> -> never로 축약됨 -> number <: never -> 실패!!
	local val: index<TargetTable, M> = 123 -- NEG: number is not a subtype of never

	return n, val
end

local canary: string = 1

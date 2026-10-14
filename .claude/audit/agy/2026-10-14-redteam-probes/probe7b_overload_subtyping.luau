--!strict
-- probes/probe7b_overload_subtyping.luau
-- Luau에서 OverloadFn? 타입에 단일 시그니처 함수가 대입될 때의 서브타입 검사 분석

type OverloadFn = ((x: number) -> number) & ((x: string) -> string)

-- 1. 직접 변수에 대입
local f1: OverloadFn = function(x: number): number return x end -- NEG: string 갈래 불만족

-- 2. Optional OverloadFn? 에 대입
local f2: OverloadFn? = function(x: number): number return x end -- NEG: ?

-- 3. 테이블 필드 { Process: OverloadFn? } 에 대입
type TableWithOpt = { Process: OverloadFn? }
local t: TableWithOpt = {
	Process = function(x: number): number return x end, -- NEG: ?
}

local canary: string = 1
return { f1, f2, t, canary }

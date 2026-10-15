--!strict
-- probe12_mod_b: imports from mod a and checks return type

local ModA = require("./probe12_mod_a")

type Arr<T> = { [number]: T }
type ProbeFull<Self, T> = ModA.ProbeFull<Self, T>

local function useProbe(p: ProbeFull<Arr<number>, number>, a: Arr<number>)
	-- Twice 의 반환값은 number 여야 함.
	-- string 변수에 대입하면 반드시 NEG 에러가 나야 함!
	local NEG_diffRet: string = p.Twice(a)
	return NEG_diffRet
end

local canary: string = 1

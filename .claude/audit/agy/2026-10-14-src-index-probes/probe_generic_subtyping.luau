--!strict
-- probes/probe_generic_subtyping.luau

type OverloadNumStr =
	((x: number) -> number) &
	((x: string) -> string)

local f: OverloadNumStr = nil :: any

local function test<M>(m: M)
	return f(m)
end

local canary: string = 1

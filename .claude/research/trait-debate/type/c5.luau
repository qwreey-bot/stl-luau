--!strict
local function f<S, E>(ops: { g: (S) -> E })
	return { h = function(s: S): E return ops.g(s) end }
end
type H<S, E> = typeof(f<<S, E>>(nil :: any))
local x: H<string, number> = nil :: any
local r: number = x.h("a")
local r2: string = x.h("a") -- NEG
local canary: string = 1
return { r, r2, canary }

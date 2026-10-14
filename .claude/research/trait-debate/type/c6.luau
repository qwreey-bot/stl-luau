--!strict
local function Fn<F>(): F return nil :: any end
local function req<S, E>() return { g = Fn<<(s: S) -> E>>() } end
local function defs<S, E>(ops: { g: (S) -> E })
	return { h = function(s: S): E return ops.g(s) end }
end
type H<S, E> = typeof(req<<S, E>>()) & typeof(defs<<S, E>>(nil :: any))
local x: H<string, number> = nil :: any
local r: number = x.h("a") -- 0건이어야
local r2: string = x.h("a") -- NEG
local canary: string = 1
return { r, r2, canary }

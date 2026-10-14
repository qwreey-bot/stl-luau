--!strict
local function Fn<F>(): F return nil :: any end
local function req<S, E, I>() return { Get = Fn<<(l: S, i: I) -> E?>>(), First = Fn<<(l: S) -> I?>>() } end
local function defs<S, E, I>(ops: typeof(req<<S, E, I>>()))
	return { IndexOf = function(l: S, x: E): I?
		local i = ops.First(l)
		while i ~= nil do
			if ops.Get(l, i) == x then return i end
			i = ops.First(l)
		end
		return nil
	end }
end
type H<S, E, I> = typeof(req<<S, E, I>>()) & typeof(defs<<S, E, I>>(nil :: any))
local x: H<string, number, number> = nil :: any
local r: number? = x.IndexOf("a", 1)
local r2: string = x.IndexOf("a", 1) -- NEG
local canary: string = 1
return { r, r2, canary }

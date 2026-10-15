--!strict
local stl = require("../src")
local d = stl.CircularDeque.Of(1, 2, 3)
local z: number = stl.List.Of(d)
local z2: number = stl.List
local z3: stl.ListProvided<number, string, number> = 5
local function genericBody<C, E, I>(x: C & stl.ListMarkerMut<E, I>, v: E): E?
	local ops = stl.List.Of(x)
	local f = ops.FirstIndex(x)
	if f == nil then return nil end
	local y: E? = ops.Get(x, f)
	local bad: string = ops.Fold(x, 0, function(a: number, e: E, i: I): number return a end)
	return y
end
return { z, z2, z3, genericBody }

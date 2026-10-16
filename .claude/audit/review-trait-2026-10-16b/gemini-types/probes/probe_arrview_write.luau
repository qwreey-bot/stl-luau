--!strict
local stl = require("../src")
local a = stl.Arr.Of(1, 2)

stl.Arr.Map(a, function(v: number, i: number, view: stl.ArrView<unknown>)
	view[1] = 99 -- Should be rejected
	view.n = 0 -- Should be rejected
	return v
end)

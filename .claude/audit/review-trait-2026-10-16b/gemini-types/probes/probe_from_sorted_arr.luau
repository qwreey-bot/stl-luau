--!strict
local stl = require("../src")
local keys = stl.Arr.Of("a", "b", "c")
local values = stl.Arr.Of(1, 2, 3)

local tm = stl.TreeMap.FromSorted(keys, values, 3, function(a: string, b: string)
	return if a < b then -1 elseif a > b then 1 else 0
end)

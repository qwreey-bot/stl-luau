--!strict
local stl = require("../src")
local arr = stl.Arr.Of(10, 20, 30)

local pos = stl.BSearch.LowerBound(arr, 3, 20, function(elem: number, target: number): number
	return if elem < target then -1 elseif elem > target then 1 else 0
end)
print("pos:", pos)

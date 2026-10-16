--!strict
local stl = require("../src")
local arr = stl.Arr.Of(10, 20, 30)

local c1 = stl.List.Count(arr)
local c2 = stl.List.Count(arr, function(v: number, i: number) return v > 15 end)

print(c1, c2)

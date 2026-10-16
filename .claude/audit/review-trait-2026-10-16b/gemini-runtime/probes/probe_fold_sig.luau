--!strict
local stl = require("../src")
local arr = stl.Arr.Of(1, 2, 3)
local res = stl.List.Fold(arr, "", function(acc: string, v: number): string
	return acc .. tostring(v)
end)
local _: string = res
print("Fold result is string!")

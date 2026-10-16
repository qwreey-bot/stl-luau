local stl = require("../src")
local arr = stl.Arr.Of(10, 20, 30)

local b1 = stl.BSearch.LowerBound(arr :: any, 3, 20, function(a: number, b: number) return a - b end)
local b3 = stl.BSearch.Find(arr :: any, 3, 20, function(a: number, b: number) return a - b end)

local k = stl.Arr.Of("a", "b")
local v = stl.Arr.Of(1, 2)
local tm = stl.TreeMap.FromSorted(k :: any, v :: any, 2, function(a: string, b: string) return if a < b then -1 elseif a > b then 1 else 0 end)
local got = stl.TreeMap.Get(tm, "a")

print("Runtime success:", b1, b3, got)

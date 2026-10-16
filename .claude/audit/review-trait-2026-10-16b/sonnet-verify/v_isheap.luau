--!strict
local stl = require("../src")
local CA = require("../src/Trees/CompleteArray")
local a = stl.Arr.Of(1, 2, 3)
local ok = CA.IsHeap(a, a.n, function(x: number, y: number) return x < y end)
local bad: string = CA.IsHeap({1,2,3}, 3, function(x: number, y: number) return x < y end) -- canary: must error
print(ok)

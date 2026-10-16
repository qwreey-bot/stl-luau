--!strict
local stl = require("../src")
local CompleteArray = require("../src/Trees/CompleteArray")

local arr = stl.Arr.Of(1, 2, 3)
local isHeap = CompleteArray.IsHeap(arr, arr.n, function(a, b) return a < b end)

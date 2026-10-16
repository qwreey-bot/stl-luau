--!strict
-- 재현 프로브: CompleteArray.IsHeap 파라미터가 { T } 로 선언되어 Arr<T> 를 거절함
local stl = require("../src")
local CompleteArray = require("../src/Trees/CompleteArray")

local arr: stl.Arr<number> = stl.Arr.Of(1, 2, 3)
local _isHeap = CompleteArray.IsHeap(arr, arr.n, function(a: number, b: number)
	return a < b
end)

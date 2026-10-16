local stl = require("../src")
local Arr = stl.Arr
local CircularDeque = stl.CircularDeque
local LinkedDeque = stl.LinkedDeque
local HashSet = stl.HashSet
local FlatSet = stl.FlatSet
local TreeSet = stl.TreeSet
local Heap = stl.Heap

local nanArr = Arr.Of(10, 0/0, 30)
local function testNaN(name, fn)
	local ok, err = pcall(fn)
	print(name, ":", ok, err)
end
testNaN("CircularDeque NaN", function() return CircularDeque.FromList(nanArr) end)
testNaN("LinkedDeque NaN", function() return LinkedDeque.FromList(nanArr) end)
testNaN("HashSet NaN", function() return HashSet.FromList(nanArr) end)
testNaN("FlatSet NaN", function() return FlatSet.FromList(nanArr, stl.Common.compareNumber) end)
testNaN("TreeSet NaN", function() return TreeSet.FromList(nanArr, stl.Common.compareNumber) end)
testNaN("Heap NaN", function() return Heap.FromList(nanArr, function(a, b) return a < b end) end)


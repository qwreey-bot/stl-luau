-- 관점 6 종합 프로브: nil 구멍 및 NaN 처리
local stl = require("../src")
local Arr = stl.Arr
local CircularDeque = stl.CircularDeque
local LinkedDeque = stl.LinkedDeque
local HashSet = stl.HashSet
local FlatSet = stl.FlatSet
local TreeSet = stl.TreeSet
local Heap = stl.Heap

local holedArr = Arr.Of(10, nil, 30)

print("=== 1. 구멍 든 Arr 를 FromList 에 전달 ===")
local cd = CircularDeque.FromList(holedArr)
print("CircularDeque len:", CircularDeque.Len(cd), "At(2):", CircularDeque.At(cd, 2))

local ld = LinkedDeque.FromList(holedArr)
print("LinkedDeque Front:", LinkedDeque.Front(ld), "Back:", LinkedDeque.Back(ld))

local hs = HashSet.FromList(holedArr)
print("HashSet size (구멍 건너뜀):", hs.map.size)

local fs = FlatSet.FromList(holedArr, stl.Common.compareNumber)
print("FlatSet size (구멍 건너뜀):", FlatSet.Len(fs))

local ts = TreeSet.FromList(holedArr, stl.Common.compareNumber)
print("TreeSet size (구멍 건너뜀):", TreeSet.Len(ts))

local hp = Heap.FromList(holedArr, function(a, b) return a < b end)
print("Heap size (구멍 건너뜀):", hp.size)

print("\n=== 2. NaN 원소 유입 시 ===")
local nanArr = Arr.Of(10, 0/0, 30)
local function testNaN(name, fn)
	local ok, err = pcall(fn)
	print(name .. ":", ok, err)
end
testNaN("CircularDeque NaN", function() return CircularDeque.FromList(nanArr) end)
testNaN("LinkedDeque NaN", function() return LinkedDeque.FromList(nanArr) end)
testNaN("HashSet NaN", function() return HashSet.FromList(nanArr) end)
testNaN("FlatSet NaN", function() return FlatSet.FromList(nanArr, stl.Common.compareNumber) end)
testNaN("TreeSet NaN", function() return TreeSet.FromList(nanArr, stl.Common.compareNumber) end)
testNaN("Heap NaN", function() return Heap.FromList(nanArr, function(a, b) return a < b end) end)


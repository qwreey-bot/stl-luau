local stl = require("../src")
local Arr = stl.Arr
local CircularDeque = stl.CircularDeque
local LinkedDeque = stl.LinkedDeque
local HashSet = stl.HashSet
local FlatSet = stl.FlatSet
local TreeSet = stl.TreeSet
local Heap = stl.Heap

local holedArr = Arr.Of(10, nil, 30)

print("--- 1. CircularDeque.FromList with holed Arr ---")
local cd = CircularDeque.FromList(holedArr)
print("CD len:", CircularDeque.Len(cd), "At(1):", CircularDeque.At(cd, 1), "At(2):", CircularDeque.At(cd, 2), "At(3):", CircularDeque.At(cd, 3))

print("--- 2. LinkedDeque.FromList with holed Arr ---")
local ld = LinkedDeque.FromList(holedArr)
print("LD len:", ld.count, "Front:", LinkedDeque.Front(ld), "Back:", LinkedDeque.Back(ld))

print("--- 3. HashSet.FromList with holed Arr ---")
local hs = HashSet.FromList(holedArr)
print("HS size:", hs.map.size, "Has 10:", HashSet.Has(hs, 10), "Has 30:", HashSet.Has(hs, 30))

print("--- 4. FlatSet.FromList with holed Arr ---")
local fs = FlatSet.FromList(holedArr, stl.Common.compareNumber)
print("FS size:", fs.count, "Has 10:", FlatSet.Has(fs, 10), "Has 30:", FlatSet.Has(fs, 30))

print("--- 5. TreeSet.FromList with holed Arr ---")
local ts = TreeSet.FromList(holedArr, stl.Common.compareNumber)
print("TS size:", ts.count, "Has 10:", TreeSet.Has(ts, 10), "Has 30:", TreeSet.Has(ts, 30))

print("--- 6. Heap.FromList with holed Arr ---")
local hp = Heap.FromList(holedArr, function(a, b) return a < b end)
print("Heap size:", hp.size, "Peek:", Heap.Peek(hp))

print("--- 7. NaN handling in FromList ---")
local nanArr = Arr.Of(10, 0/0, 30)
local function testNaN(name, fn)
	local ok, err = pcall(fn)
	print(name, ":", ok, err)
end
testNaN("CircularDeque NaN", function() return CircularDeque.FromList(nanArr) end)
testNaN("LinkedDeque NaN", function() return LinkedDeque.FromList(nanArr) end)
testNaN("HashSet NaN", function() return HashSet.FromList(nanArr) end)
testNaN("FlatSet NaN", function() return FlatSet.FromList(nanArr) end)
testNaN("TreeSet NaN", function() return TreeSet.FromList(nanArr) end)
testNaN("Heap NaN", function() return Heap.FromList(nanArr) end)


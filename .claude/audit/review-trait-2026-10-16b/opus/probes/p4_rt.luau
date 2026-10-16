local stl = require("../src")
for name, v in { cd = stl.CircularDeque.Of(1, 2), ld = stl.LinkedDeque.Of(1, 2), hm = stl.HashMap.New(), heap = stl.Heap.New(function(a, b) return a < b end) } do
	print(name, pcall(stl.HashSet.FromList, v))
end

local stl = require("../src")
local hm = stl.HashMap.New()
stl.Map.Set(hm, "a", 1)
local it = stl.Map.Iter(hm)
it.evil = 999
print("T2 size/has:", hm.size, stl.Map.Has(hm, "evil"))
print("T1:", pcall(function() return stl.List.Get(stl.LinkedDeque.Of(1, 2), 123) end))

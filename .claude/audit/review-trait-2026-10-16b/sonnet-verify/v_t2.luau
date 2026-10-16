--!strict
local stl = require("../src")
local hm = stl.HashMap.New<<string, number>>()
stl.Map.Set(hm, "a", 1)
local it = stl.Map.Iter(hm)
if type(it) == "table" then
	it["evil"] = 999       -- via entry: claimed 0 diagnostics
end
local it2 = stl.Map.Of(hm).Iter(hm)
if type(it2) == "table" then
	it2["evil2"] = 1       -- via Of: expected error (control)
end
local c: string = stl.Map.Iter(hm) -- canary
print(hm.size, stl.Map.Has(hm, "evil"))

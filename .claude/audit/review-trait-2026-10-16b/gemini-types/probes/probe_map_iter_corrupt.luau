local stl = require("../src")
local hm = stl.HashMap.New()
stl.HashMap.Set(hm, "a", 1)

local iter = stl.Map.Iter(hm)
if type(iter) == "table" then
	iter["evil_key"] = 999
end

print("hm size:", stl.HashMap.Len(hm))
print("hm has evil_key?", stl.HashMap.Has(hm, "evil_key"))
print("hm raw get evil_key:", stl.HashMap.Get(hm, "evil_key"))

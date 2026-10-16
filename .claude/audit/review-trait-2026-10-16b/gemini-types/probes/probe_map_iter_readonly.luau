--!strict
local stl = require("../src")
local hm = stl.HashMap.New<<string, number>>()

local iter = stl.Map.Iter(hm)
if type(iter) == "table" then
	-- iter was declared as { read [string]: number }
	-- But because of subst in Trait.Entries, does it allow writing?
	iter["evil_key"] = 999
end

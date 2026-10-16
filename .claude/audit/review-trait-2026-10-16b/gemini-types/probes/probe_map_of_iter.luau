--!strict
local stl = require("../src")
local hm = stl.HashMap.New<<string, number>>()

local iter = stl.Map.Of(hm).Iter(hm)
if type(iter) == "table" then
	iter["evil_key"] = 999
end

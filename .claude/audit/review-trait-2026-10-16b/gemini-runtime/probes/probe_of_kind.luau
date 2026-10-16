local stl = require("../src")
local List = stl.List

local ok, err = pcall(function()
	return List.Of(stl.Arr)
end)
print("List.Of(stl.Arr):", ok, err)

local ok2, err2 = pcall(function()
	return List.Of(stl.Arr.Token)
end)
print("List.Of(stl.Arr.Token):", ok2, err2 ~= nil)

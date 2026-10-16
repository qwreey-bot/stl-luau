local stl = require("../src")
local Deque = stl.Deque

local ok, err = pcall(function()
	return Deque.Of(stl.Arr)
end)
print("Deque.Of(stl.Arr):", ok, err)

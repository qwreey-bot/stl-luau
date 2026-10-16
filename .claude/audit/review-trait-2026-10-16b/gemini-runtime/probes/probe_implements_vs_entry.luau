local stl = require("../src")
local Trait = require("../src/Trait")
local List = stl.List

print("Trait.Implements(List, stl.Arr):", Trait.Implements(List, stl.Arr))

local ok, err = pcall(function()
	return List.Get(stl.Arr, 1)
end)
print("List.Get(stl.Arr, 1):", ok, err)

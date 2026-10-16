--!strict
local stl = require("../src")
local ld = stl.LinkedDeque.Of(1, 2)
local nextIdx = stl.List.NextIndex(ld, 123)
print("nextIdx is:", nextIdx)

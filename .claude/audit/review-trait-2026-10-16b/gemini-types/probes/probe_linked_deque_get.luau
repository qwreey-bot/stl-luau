--!strict
local stl = require("../src")
local ld = stl.LinkedDeque.Of(1, 2)
local x = stl.List.Get(ld, 123)
print("x is:", x)

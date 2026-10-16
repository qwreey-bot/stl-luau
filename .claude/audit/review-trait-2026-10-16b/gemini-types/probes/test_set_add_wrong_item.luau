--!strict

local stl = require("../src")
local hs = stl.HashSet.Of("a", "b")
stl.Set.Add(hs, 123)

--!strict

local stl = require("../src")
local hs = stl.HashSet.Of("a", "b")
local x = stl.Set.Has(hs, 123)

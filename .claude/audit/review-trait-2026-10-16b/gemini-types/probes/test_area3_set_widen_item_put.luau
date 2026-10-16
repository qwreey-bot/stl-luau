--!strict

local stl = require("../src")
local hs = stl.HashSet.Of("a", "b")
local function addWide<T>(s: stl.Set<T>, item: T)
    stl.Set.Add(s, item)
end
addWide<<string | number>>(hs, 123)

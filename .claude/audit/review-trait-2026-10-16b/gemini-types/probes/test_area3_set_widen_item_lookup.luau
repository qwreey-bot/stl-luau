--!strict

local stl = require("../src")
local hs = stl.HashSet.Of("a", "b")
local function hasWide<T>(s: stl.Set<T>, item: T): boolean
    return stl.Set.Has(s, item)
end
local x = hasWide<<string | number>>(hs, 123)

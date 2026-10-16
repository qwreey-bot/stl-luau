--!strict
local stl = require("../src")
local hs = stl.HashSet.Of("a", "b")

local has: boolean = stl.Set.Has(hs, "a")
local added: boolean = stl.Set.Add(hs, "c")
local removed: boolean = stl.Set.Remove(hs, "b")
local items: { string } = stl.Set.Items(hs)

print(has, added, removed, #items)

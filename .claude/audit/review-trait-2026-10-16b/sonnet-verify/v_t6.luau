--!strict
local stl = require("../src")
local hm = stl.HashMap.New<<string, number>>()
stl.Map.Set(hm, "a", 1)
local v: number? = stl.Map.Get(hm, "a")
local bad = stl.Map.Get(hm, 5) -- must error

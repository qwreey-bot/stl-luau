--!strict
local stl = require("../src")
local tm = stl.TreeMap.New<<string, number>>(function(a: string, b: string) return if a < b then -1 elseif a > b then 1 else 0 end)

local val: number? = stl.Map.Get(tm, "foo")
stl.Map.Set(tm, "foo", 42)
local has: boolean = stl.Map.Has(tm, "foo")
local rem: number? = stl.Map.Remove(tm, "foo")

print(val, has, rem)

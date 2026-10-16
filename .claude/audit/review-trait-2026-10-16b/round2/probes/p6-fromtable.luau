--!strict
local stl = require("../src")
local HashMap, BSearch, TreeMap, Arr = stl.HashMap, stl.BSearch, stl.TreeMap, stl.Arr
local m1 = HashMap.FromTable({ a = 1, b = 2 })
local g1: number? = HashMap.Get(m1, "a")
local m2 = HashMap.FromTable<<string, number>>({ a = 1 })
local t: { [string]: number } = { a = 1 }
local m3 = HashMap.FromTable(t)
local g3: number? = HashMap.Get(m3, "a")
local m4: stl.HashMap<string, number> = HashMap.FromTable({ a = 1 })
local m5: stl.HashMap<string, number?> = HashMap.FromTable({ a = 1 }) -- bidirectional
local list = { 10, 20 }
local m6 = HashMap.FromTable(list)
local g6: number? = HashMap.Get(m6, 1)
-- NEG
local n1: stl.HashMap<string, string> = HashMap.FromTable({ a = 1 }) -- NEG
local n2: string? = HashMap.Get(m1, "a") -- NEG
HashMap.Set(m3, "a", "x") -- NEG
local n3: stl.HashMap<string, number?> = m4 -- NEG invariance
-- BSearch with Arr
local a = Arr.Of(1, 3, 5)
local p = BSearch.LowerBound(a, a.n, 3, function(x: number, y: number) return x - y end)
local p2 = BSearch.Find(a, a.n, "3", function(x: number, y: number) return x - y end) -- NEG probe types
return { g1, m2, g3, m5, g6, n1, n2, n3, p, p2 }

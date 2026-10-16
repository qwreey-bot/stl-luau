--!strict

local stl = require("../src")
local tm = stl.TreeMap.New<<string, number>>(function(a: string, b: string) return if a < b then -1 elseif a > b then 1 else 0 end)
local function getWide<K, V>(m: stl.Map<K, V>, k: K): V?
    return stl.Map.Get(m, k)
end
local x = getWide<<string | number, number>>(tm, 123)

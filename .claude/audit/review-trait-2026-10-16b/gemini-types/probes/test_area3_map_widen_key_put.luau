--!strict

local stl = require("../src")
local tm = stl.TreeMap.New<<string, number>>(function(a: string, b: string) return if a < b then -1 elseif a > b then 1 else 0 end)
local function putWide<K, V>(m: stl.Map<K, V>, k: K, v: V)
    stl.Map.Set(m, k, v)
end
putWide<<string | number, number>>(tm, 123, 456)

--!strict
local stl = require("../src")
local HashMap, HashSet, TreeSet, Arr = stl.HashMap, stl.HashSet, stl.TreeSet, stl.Arr
local hm = HashMap.New<<string, number>>()
local hs = HashSet.New<<string>>()
local ts = TreeSet.New<<number>>(stl.Common and nil or (nil :: any))

-- POS
local it = stl.Map.Iter(hm)
local items: { string } = stl.Set.Items(hs)
local g: number? = stl.Map.Get(hm, "a")
stl.Map.Set(hm, "a", 1)
local has: boolean = stl.Set.Has(hs, "x")
stl.Set.Add(hs, "x")
-- NEG expected
local nItems: { number } = stl.Set.Items(hs) -- NEG1 element
local nGet: string? = stl.Map.Get(hm, "a") -- NEG2
stl.Map.Set(hm, 1, 1) -- NEG3 key
stl.Map.Set(hm, "a", "x") -- NEG4 value
stl.Set.Add(hs, 5) -- NEG5
local nHas = stl.Set.Has(hs, 5) -- NEG6
-- Iter-based: types of iteration
if type(it) == "table" then
	for k, v in it do
		local ks: number = k -- NEG7 (k is string)
		local vs: string = v -- NEG8
	end
end
-- call Iter then Items then Iter on a different map — shared generics?
local hm2 = HashMap.New<<number, string>>()
local it2 = stl.Map.Iter(hm2)
local items2 = stl.Set.Items(HashSet.New<<number>>())
local nItems2: { string } = items2 -- NEG9
local g2: string? = stl.Map.Get(hm2, 1)
local nG2: number? = stl.Map.Get(hm2, 1) -- NEG10
local n2: number = stl.Map.Keys(hm2)[1]
return { it, items, g, has, nItems, nGet, nHas, it2, items2, g2, nG2, n2, ts, Arr }

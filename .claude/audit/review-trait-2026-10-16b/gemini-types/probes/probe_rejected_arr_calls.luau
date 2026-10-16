--!strict
local stl = require("../src")
local arr = stl.Arr.Of(1, 2, 3)

-- 1. BSearch functions
local b1 = stl.BSearch.LowerBound(arr, 3, 2, function(a: number, b: number) return a - b end)
local b2 = stl.BSearch.UpperBound(arr, 3, 2, function(a: number, b: number) return a - b end)
local b3 = stl.BSearch.Find(arr, 3, 2, function(a: number, b: number) return a - b end)
local b4, b5 = stl.BSearch.EqualRange(arr, 3, 2, function(a: number, b: number) return a - b end)
local b6 = stl.BSearch.IsSorted(arr, 3, function(a: number, b: number) return a < b end)

-- 2. TreeMap.FromSorted
local k = stl.Arr.Of("a", "b")
local v = stl.Arr.Of(1, 2)
local tm = stl.TreeMap.FromSorted(k, v, 2, function(a: string, b: string) return if a < b then -1 elseif a > b then 1 else 0 end)

-- 3. RedBlack.FromSorted
local rb = stl.RedBlack.FromSorted(k, v, 2)

-- 4. Avl.FromSorted
local avl = stl.Avl.FromSorted(k, v, 2)

-- 5. SortedArray.Append
local rawTarget = { 10, 20 }
stl.SortedArray.Append(rawTarget, 2, arr, 3)

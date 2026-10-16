--!strict
local stl = require("../src")

local arr = stl.Arr.Of(1, 2, 3)
local arrRead: stl.ArrRead<number> = arr
local cd = stl.CircularDeque.Of(1, 2)
local cdRead: stl.CircularDequeRead<number> = cd
local ld = stl.LinkedDeque.Of(1, 2)
local ldRead: stl.LinkedDequeRead<number> = ld

-- 1. Calling write entry points on borrowed read references:
-- Collection.Clear on ArrRead
-- local neg1 = stl.Collection.Clear(arrRead)

-- Deque.PushBack on CircularDequeRead
-- local neg2 = stl.Deque.PushBack(cdRead, 3)

-- Deque.PushFront on CircularDequeRead
-- local neg3 = stl.Deque.PushFront(cdRead, 3)

-- Deque.PopBack on CircularDequeRead
-- local neg4 = stl.Deque.PopBack(cdRead)

-- Deque.PopFront on CircularDequeRead
-- local neg5 = stl.Deque.PopFront(cdRead)

-- 2. Calling with wrong element / key / index types on entry points:
-- List.Get(arr, "invalid_index")
-- local neg6 = stl.List.Get(arr, "not_a_number")

-- List.IndexOf(arr, "invalid_item")
-- Wait! Is List.IndexOf(arr, "not_a_number") an error or does it allow wider item?
-- In ListBase, of is (Self & ValueRead<E, I>), item is E.

-- Map.Get / Set
local tm = stl.TreeMap.New<<string, number>>(function(a: string, b: string) return if a < b then -1 elseif a > b then 1 else 0 end)
-- local neg7 = stl.Map.Get(tm, 123)
-- local neg8 = stl.Map.Set(tm, 123, 456)
-- local neg9 = stl.Map.Set(tm, "key", "not_a_number")

-- Set.Has / Add
local hs = stl.HashSet.Of("a", "b")
-- local neg10 = stl.Set.Has(hs, 123)
-- local neg11 = stl.Set.Add(hs, 123)

print("Setup completed")

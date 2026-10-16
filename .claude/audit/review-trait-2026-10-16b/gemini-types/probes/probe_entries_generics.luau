--!strict
local stl = require("../src")

-- 1. Test Deque entry points
local d = stl.CircularDeque.Of(1, 2)
local dr: stl.CircularDequeRead<number> = d

-- PushBack returns Self, so its generics are <Self, T>
-- Can we pass explicit type argument <<number>>?
-- If generics are <Self, T>, then <<number>> would bind Self to number!
local p1 = stl.Deque.PushBack(d, 3)
-- What if we do stl.Deque.PushBack<<typeof(d), number>>(d, 3)?
-- What if someone tries stl.Deque.PushBack<<number>>(d, 3)?
local p2 = stl.Deque.PushBack<<typeof(d), number>>(d, 3)
local p3 = stl.Deque.PushBack<<number>>(d, 3)

-- PopBack generics should be <T>
local x1 = stl.Deque.PopBack<<number>>(d)

-- List.Get generics should be <E, I>
local arr = stl.Arr.Of(10, 20)
local g1 = stl.List.Get<<number, number>>(arr, 1)

print("Probe loaded successfully")

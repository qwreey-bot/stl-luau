--!strict
local stl = require("../src")
local d = stl.CircularDeque.Of(1, 2)
local a = stl.Deque.PushBack<<number>>(d, 3)
local b = stl.Deque.PushBack(d, 3)
local c = stl.Deque.PushBack<<typeof(d), number>>(d, 3)
print(a, b, c)

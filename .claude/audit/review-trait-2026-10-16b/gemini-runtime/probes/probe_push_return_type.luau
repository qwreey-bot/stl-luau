--!strict
local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
local res = stl.Deque.PushBack(cd, 3)
-- Does res retain CircularDeque<number> or only Deque<number>?
local _: stl.CircularDeque<number> = res
print("res type is CircularDeque<number>!")

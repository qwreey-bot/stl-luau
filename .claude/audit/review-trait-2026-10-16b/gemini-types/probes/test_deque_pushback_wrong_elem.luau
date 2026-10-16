--!strict

local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
stl.Deque.PushBack(cd, "wrong")

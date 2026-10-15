--!nocheck
local stl = require("../../../../src")
local ops = stl.List.Of(stl.Arr.Token)
print(pcall(function() return ops.Get(stl.HashMap.New(), "nope") end))
print(pcall(function() return ops.Fold(stl.CircularDeque.Of(1, 2), 0, function(a, x) return a + x end) end))
local st = stl.Stack.Of(stl.CircularDeque.Token)
print(pcall(function() return st.Push(stl.HashMap.New(), 1) end))

local stl = require("../src")
local Stack = stl.Stack
local Deque = stl.Deque

local cd = stl.CircularDeque.Of(10, 20)
print("Before override, AsStack Peek:", Stack.Peek(Deque.AsStack(cd)))

Stack.ImplFor(stl.CircularDeque, {
	Push = function(d, x) return stl.CircularDeque.PushBack(d, x) end,
	Pop = function(d) return stl.CircularDeque.PopBack(d) end,
	Peek = function(d) return "overridden peek from AsStack" end,
})

print("After override, AsStack Peek:", Stack.Peek(Deque.AsStack(cd)))

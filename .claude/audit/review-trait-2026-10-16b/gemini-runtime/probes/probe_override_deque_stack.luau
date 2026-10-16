local stl = require("../src")
local Stack = stl.Stack

local cd = stl.CircularDeque.Of(10, 20)
local s1 = Stack.OfMut(cd)
print("Before override, Peek:", s1.Peek(cd))

-- Explicit override
local ok, err = pcall(function()
	Stack.ImplFor(stl.CircularDeque, {
		Push = function(d, x) return stl.CircularDeque.PushBack(d, x) end,
		Pop = function(d) return stl.CircularDeque.PopBack(d) end,
		Peek = function(d) return "overridden peek" end,
	})
end)
print("Stack.ImplFor on CircularDeque:", ok, err)
if ok then
	local s2 = Stack.OfMut(cd)
	print("After override, Peek:", s2.Peek(cd))
end

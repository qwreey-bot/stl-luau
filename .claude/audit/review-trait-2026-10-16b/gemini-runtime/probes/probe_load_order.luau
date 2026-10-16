-- Test 1: Require Stack only, then CircularDeque
local Stack = require("../src/Traits/Stack")
local CircularDeque = require("../src/Collections/CircularDeque")
local Trait = require("../src/Trait")

local cd = CircularDeque.New()
print("Test 1 - Stack.Implements(cd):", Trait.Implements(Stack, cd))
local s = Stack.OfMut(cd)
s.Push(cd, 42)
print("Test 1 - Pop:", s.Pop(cd))


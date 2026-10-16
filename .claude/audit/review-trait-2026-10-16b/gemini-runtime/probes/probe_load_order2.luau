-- Test 2: Require CircularDeque only, then Stack
local CircularDeque = require("../src/Collections/CircularDeque")
local Stack = require("../src/Traits/Stack")
local Trait = require("../src/Trait")

local cd = CircularDeque.New()
print("Test 2 - Stack.Implements(cd):", Trait.Implements(Stack, cd))
local s = Stack.OfMut(cd)
s.Push(cd, 99)
print("Test 2 - Pop:", s.Pop(cd))

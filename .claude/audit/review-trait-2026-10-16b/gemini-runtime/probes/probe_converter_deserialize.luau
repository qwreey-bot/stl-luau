local Trait = require("../src/Trait")
local stl = require("../src")
local Deque = require("../src/Traits/Deque")
local Stack = require("../src/Traits/Stack")

local asStack = Trait.Converter(Stack, stl.Arr)

local a = stl.Arr.Of(1, 2, 3)
-- Simulate deserialization (shallow clone of a, with shallow clone of __type)
local deserialized = table.clone(a)
deserialized.__type = table.clone(a.__type)

local ok, err = pcall(function()
	return asStack(deserialized)
end)
print("Converter with deserialized Arr:", ok, err)

-- What if token is nil (Trait.Converter(Stack))?
local asAnyStack = Trait.Converter(Stack)
local ok2, err2 = pcall(function()
	return asAnyStack(deserialized)
end)
print("Converter(Stack) with deserialized Arr:", ok2, err2)

-- And what if we Restore it?
Trait.Restore(deserialized)
local ok3, res3 = pcall(function()
	return asStack(deserialized)
end)
print("After Restore:", ok3, res3 == deserialized)

local Trait = require("../src/Trait")
local stl = require("../src")

local toStackWithToken = Trait.Converter(stl.Stack, stl.CircularDeque)
local toStackNoToken = Trait.Converter(stl.Stack)

local cd = stl.CircularDeque.New()
-- Simulate deserialization
local deser = table.clone(cd)
deser.__type = table.clone(cd.__type)

local ok1, err1 = pcall(function()
	return toStackWithToken(deser)
end)
print("Before Restore (with token):", ok1, err1)

local ok2, err2 = pcall(function()
	return toStackNoToken(deser)
end)
print("Before Restore (no token):", ok2, err2)

-- Now restore
Trait.Restore(deser)

local ok3, res3 = pcall(function()
	return toStackWithToken(deser)
end)
print("After Restore (with token):", ok3, res3 == deser)

local ok4, res4 = pcall(function()
	return toStackNoToken(deser)
end)
print("After Restore (no token):", ok4, res4 == deser)

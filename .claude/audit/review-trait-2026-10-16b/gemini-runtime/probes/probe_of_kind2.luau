local stl = require("../src")
local Trait = require("../src/Trait")
local List = stl.List

print("1. List.Of(stl.Arr):")
local ok1, err1 = pcall(function() return List.Of(stl.Arr) end)
print("  result:", ok1, err1)

print("2. List.Of(Trait.TokenOf(stl.Arr)):")
local ok2, res2 = pcall(function() return List.Of(Trait.TokenOf(stl.Arr)) end)
print("  result:", ok2, res2 ~= nil)

print("3. Trait.ImplOf(List, stl.Arr):")
local ok3, res3 = pcall(function() return Trait.ImplOf(List, stl.Arr) end)
print("  result:", ok3, res3 ~= nil)

print("4. Trait.Implements(List, stl.Arr):")
local ok4, res4 = pcall(function() return Trait.Implements(List, stl.Arr) end)
print("  result:", ok4, res4)

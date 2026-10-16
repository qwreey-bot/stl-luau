--!strict

local stl = require("../src")
local a = stl.Arr.Of(1, 2)
local r: stl.ArrRead<number> = a
local asPeek: <T>(a: stl.ArrRead<T>) -> stl.StackRead<T> = stl.Trait.Converter(stl.Stack, stl.Arr)
local s = asPeek(r)
local m = stl.Stack.OfMut(s)

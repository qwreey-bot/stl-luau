--!strict

local stl = require("../src")
local a = stl.Arr.Of(1, 2)
local r: stl.ArrRead<number> = a
local m = stl.Collection.OfMut(r)

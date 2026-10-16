--!strict

local stl = require("../src")
local cd = stl.CircularDeque.Of(1, 2)
local r: stl.CircularDequeRead<number> = cd
local m = stl.Collection.OfMut(r)

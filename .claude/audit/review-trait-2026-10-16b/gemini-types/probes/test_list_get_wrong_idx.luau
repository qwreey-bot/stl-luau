--!strict

local stl = require("../src")
local arr = stl.Arr.Of(1, 2)
local x = stl.List.Get(arr, "wrong")

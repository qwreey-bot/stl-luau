--!strict
local stl = require("../src")
local arr = stl.Arr.Of(1, 2, 3)
local arrRead: stl.ArrRead<number> = arr

stl.Arr.Set(arrRead, 1, 10)

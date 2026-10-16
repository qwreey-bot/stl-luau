--!strict
local stl = require("../src")
local ld = stl.LinkedDeque.Of(1, 2)
local cd = stl.CircularDeque.Of(1, 2)
local arr = stl.Arr.Of(1, 2)
local a1 = stl.List.Get(ld, 123)
local a2 = stl.List.Get(cd, "x")
local a3 = stl.List.NextIndex(arr, "x")
local a4 = stl.List.PrevIndex(ld, 5)
local a5 = stl.List.Get(arr, "x")
local canary: string = stl.List.Get(arr, 1) -- must error

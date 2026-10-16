--!strict
local stl = require("../src")
local a = stl.Arr.Of(1, 2)
local r: stl.ArrRead<number> = a

-- Passing ArrRead as destination 'to' in Map
local res = stl.Arr.Map(a, function(v: number): number return v * 2 end, r)

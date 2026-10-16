--!strict

local stl = require("../src")
local a: stl.Arr<number?> = stl.Arr.Of(1, nil, 2)
local r: stl.ArrRead<number?> = a
local c = stl.Arr.CompactInplace(r)

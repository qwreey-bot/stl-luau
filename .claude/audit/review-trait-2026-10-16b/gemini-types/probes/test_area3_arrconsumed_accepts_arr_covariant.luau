--!strict

local stl = require("../src")
local a: stl.Arr<number?> = stl.Arr.Of(1, nil, 2)
local c: stl.Arr<number> = stl.Arr.CompactInplace(a)

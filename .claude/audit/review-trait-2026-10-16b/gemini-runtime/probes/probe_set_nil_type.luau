--!strict
local stl = require("../src")
local arrDense = stl.Arr.Of(1, 2, 3)
stl.Arr.Set(arrDense, 1, nil)

local arrHoled: stl.Arr<number?> = stl.Arr.Of(1, nil, 3)
stl.Arr.Set(arrHoled, 1, nil)

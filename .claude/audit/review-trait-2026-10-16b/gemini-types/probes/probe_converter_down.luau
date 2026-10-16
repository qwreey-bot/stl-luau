local stl = require("../src")
local asArr = stl.Trait.Converter(stl.Arr)

local a = stl.Arr.Of(1, 2)
local res = asArr(a)
print("asArr on Arr:", rawequal(res, a))

local d = stl.CircularDeque.Of(1, 2)
local ok, err = pcall(function()
	asArr(d)
end)
print("asArr on CircularDeque: ok=", ok, "err=", err)

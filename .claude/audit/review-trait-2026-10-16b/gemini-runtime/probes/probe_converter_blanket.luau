local Trait = require("../src/Trait")
local stl = require("../src")

local cd = stl.CircularDeque.New()
local toStackWithToken = Trait.Converter(stl.Stack, stl.CircularDeque)
print("toStackWithToken created successfully!")

local s = toStackWithToken(cd)
print("s == cd:", s == cd)

-- Non-table passed:
local ok_num, err_num = pcall(function()
	toStackWithToken(123)
end)
print("Non-table to token converter:", ok_num, err_num)

local toStackNoToken = Trait.Converter(stl.Stack)
local ok_num2, err_num2 = pcall(function()
	toStackNoToken(123)
end)
print("Non-table to no-token converter:", ok_num2, err_num2)

local ok_nil, err_nil = pcall(function()
	toStackNoToken(nil)
end)
print("nil to no-token converter:", ok_nil, err_nil)

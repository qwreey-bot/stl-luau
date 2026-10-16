--!strict
local stl = require("../src")
local t: { read [string]: number } = { a = 1, b = 2 }
local hm = stl.HashMap.FromTable(t)

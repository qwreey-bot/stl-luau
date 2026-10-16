--!strict

local stl = require("../src")
local ld = stl.LinkedDeque.Of(1, 2)
local r: stl.LinkedDequeRead<number> = ld
stl.Collection.Clear(r)

--!strict
local stl = require("../src")
local ld = stl.LinkedDeque.Of(1, 2)
ld.size = 0
ld.head = nil
local cd = stl.CircularDeque.Of(1, 2)
cd.size = 0 -- canary: must error (read size)
local a = stl.Arr.Of(1)
a.n = 0     -- canary

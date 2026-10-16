--!strict
local stl = require("../src")
local ld = stl.LinkedDeque.Of(1, 2)

-- Can a user directly mutate LinkedDeque fields?
ld.size = 0
ld.head = nil
ld.tail = nil

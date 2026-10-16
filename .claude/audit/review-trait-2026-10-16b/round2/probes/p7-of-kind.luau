--!strict
local stl = require("../src")
local full = stl.List.Of(stl.Arr)
local tok = stl.List.Of(stl.Trait.TokenOf(stl.Arr))
return { full, tok }

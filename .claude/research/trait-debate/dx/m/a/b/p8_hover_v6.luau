--!strict
local P = require("./trait-v6/Traits")
local stl = require("../../src")
local d = P.Kinds.tag(stl.CircularDeque.Of(1, 2, 3), P.Kinds.CD)
local l = P.List.Of(d)
local s = P.Stack.Of(d)
local e = P.List.IndexOf
return { l, s, e }

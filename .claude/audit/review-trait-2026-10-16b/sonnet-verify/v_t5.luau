--!strict
local stl = require("../src")
local Trait = require("../src/Trait")
type P1 = Trait.A
type P2 = stl.TraitA
type P3 = stl.MapAssocRead<string, number>
type P4 = stl.DequeAssocRead<number>
local x: P1? = nil
local y: P2? = nil
local z: P3? = nil
local w: P4? = nil
print(x, y, z, w)

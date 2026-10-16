--!strict
local stl = require("../src")
local Trait = stl.Trait
local d = stl.CircularDeque.Of(1, 2)
local dtok = Trait.TokenOf(d) :: stl.TraitToken<string>
local opsD = stl.Deque.OfMut(dtok)
local e3: number? = opsD.PopBack(d) -- 맞는 코드
local canary: string = 1
return nil

--!strict

type F = (number) -> boolean

local f1: F | never = function(n: number) return n > 0 end
local res1 = f1(10)

local canary: string = 1

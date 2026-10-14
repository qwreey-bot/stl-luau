--!strict

type Req = {
	Push: (number) -> (),
	Pop: () -> number?,
}

type DefOpt = {
	IsEmpty: ((number) -> boolean)?,
}

type Impl = Req & DefOpt

-- Test 1: Can we omit IsEmpty in Impl?
local reg1: Impl = {
	Push = function(n) end,
	Pop = function() return 1 end,
}

-- Test 2: Can we provide IsEmpty in Impl?
local reg2: Impl = {
	Push = function(n) end,
	Pop = function() return 1 end,
	IsEmpty = function(n) return n == 0 end,
}

-- Test 3: NEG - Does wrong type in IsEmpty fail?
local NEG_bad: Impl = {
	Push = function(n) end,
	Pop = function() return 1 end,
	IsEmpty = function(n: string) return true end, -- NEG: string instead of number
}

local canary: string = 1

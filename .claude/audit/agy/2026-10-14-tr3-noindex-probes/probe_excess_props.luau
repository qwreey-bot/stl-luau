--!strict
type Req = {
	Push: (number) -> (),
	Pop: () -> number?,
}

-- Case 1: Can we add IsEmpty?
local reg1: Req = {
	Push = function(n) end,
	Pop = function() return 1 end,
	IsEmpty = function() return true end,
}

-- Case 2: Is IsEmpty type-checked?
local reg2: Req = {
	Push = function(n) end,
	Pop = function() return 1 end,
	IsEmpty = 12345,
}

local canary: string = 1

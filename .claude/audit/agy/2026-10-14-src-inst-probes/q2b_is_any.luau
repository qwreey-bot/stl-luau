--!strict
type IntersectionWithIndexer = {
	read Of: <Self, T>(x: Self) -> (Self, T),
} & { [string]: any }

local i: IntersectionWithIndexer = nil :: any
local _n: number = i.Of
local _b: boolean = i.Of
local canary: string = 1

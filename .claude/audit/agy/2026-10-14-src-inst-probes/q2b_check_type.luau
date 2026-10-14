--!strict
type IntersectionWithIndexer = {
	read Of: <Self, T>(x: Self) -> (Self, T),
} & { [string]: any }

type SingleWithIndexer = {
	read Of: <Self, T>(x: Self) -> (Self, T),
	[string]: any,
}

local i: IntersectionWithIndexer = nil :: any
local s: SingleWithIndexer = nil :: any

local _ti: string = i.Of
local _ts: string = s.Of

--!strict
type PlainObj = {
	read Of: <Self, T>(x: Self) -> (Self, T),
}

type IntersectionWithIndexer = {
	read Of: <Self, T>(x: Self) -> (Self, T),
} & { [string]: any }

type SingleWithIndexer = {
	read Of: <Self, T>(x: Self) -> (Self, T),
	[string]: any,
}

local p: PlainObj = nil :: any
local i: IntersectionWithIndexer = nil :: any
local s: SingleWithIndexer = nil :: any

-- Plain: Of<<number, string>> 가능?
local f_p = p.Of<<number, string>>

-- SingleWithIndexer: Of<<number, string>> 가능?
local f_s = s.Of<<number, string>>

-- IntersectionWithIndexer: Of<<number, string>> 가능?
local f_i = i.Of<<number, string>>

local canary: string = 1

--!strict
local function a<T>(x: T): string
	return x -- A: T -> string
end
local function b<T>(x: T): T
	return 5 -- B: number -> T
end
local function c<T>(x: T): T?
	return 123 -- C: number -> T?
end
local function d<T>(x: number?): T?
	return x -- D: number? -> T?
end
local function e<T>(x: T): number
	local y: number = x -- E: local annotated
	return y
end
local function f<T>(x: T)
	local y: T = "s" -- F: string -> T local
end
local function g<T, U>(x: T): U
	return x -- G: T -> U
end
local function h<T>(x: T): T | string
	return 5 -- H: number -> T | string
end
local function i<T>(x: T): { T }
	return { 5 } -- I: {number} -> {T}
end
local function j<T>(x: T): (T) -> ()
	return function(v: number) end -- J
end
local function k<T>(x: T): T & {}
	return 5
end

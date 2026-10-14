--!strict

type DefaultFn =
	(<F>(mode: "full", build: (ops: any) -> F) -> F) &
	(<F>(mode: "impl", build: (ops: any) -> F) -> F?)

local Default: DefaultFn = (function(mode: string, build: any): any
	return nil
end) :: any

local function testFull()
	local f = Default("full", function(ops: any)
		return function(n: number): boolean return n > 0 end
	end)
	-- Is f non-optional?
	local b: boolean = f(10) -- Should SUCCEED without nil check
	return b
end

local function testImpl()
	local f = Default("impl", function(ops: any)
		return function(n: number): boolean return n > 0 end
	end)
	-- Is f optional?
	local maybeF: ((number) -> boolean)? = f -- Should SUCCEED
	-- NEG: Calling f without nil check should FAIL
	f(10) -- NEG
	return maybeF
end

local canary: string = 1

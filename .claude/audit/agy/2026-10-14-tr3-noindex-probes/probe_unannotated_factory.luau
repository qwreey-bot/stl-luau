--!strict

local function fnFull<F>(): F return nil :: any end
local function defaultFull<F>(b: (any) -> F): F return nil :: any end

local function fnImpl<F>(): F return nil :: any end
local function defaultImpl<F>(b: (any) -> F): F? return nil :: any end

local function defineStack(fn, default)
	return function(a: number)
		return {
			push = fn :: (number) -> number,
			isEmpty = default(function() return function(x: number): boolean return x == 0 end end),
		}
	end
end

local full = defineStack(fnFull, defaultFull)
local impl = defineStack(fnImpl, defaultImpl)

local fObj = full(1)
local iObj = impl(1)

-- Is fObj.isEmpty non-optional?
local b: boolean = fObj.isEmpty(10)

-- Is iObj.isEmpty optional?
local maybeB: ((number) -> boolean)? = iObj.isEmpty

-- NEG: iObj.isEmpty without check should fail
iObj.isEmpty(10) -- NEG

local canary: string = 1

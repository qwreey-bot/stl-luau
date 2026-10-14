--!strict

type ModeFull = {
	Default: <F>(build: (ops: any) -> F) -> F,
}

type ModeImpl = {
	Default: <F>(build: (ops: any) -> F) -> F?,
}

local modeFull: ModeFull = {
	Default = function<F>(build: (ops: any) -> F): F return nil :: any end,
}

local modeImpl: ModeImpl = {
	Default = function<F>(build: (ops: any) -> F): F? return nil :: any end,
}

local function stackDef<M>(mode: M & (ModeFull | ModeImpl))
	return function<Self, T>()
		return {
			IsEmpty = mode.Default(function(ops: any)
				return function(s: Self): boolean return true end
			end),
		}
	end
end

local fullStack = stackDef(modeFull)
local implStack = stackDef(modeImpl)

type FullS<Self, T> = typeof(fullStack<<Self, T>>())
type ImplS<Self, T> = typeof(implStack<<Self, T>>())

type Arr<T> = { n: number, [number]: T }
local a: Arr<number> = nil :: any

local sFull: FullS<Arr<number>, number> = nil :: any
local sImpl: ImplS<Arr<number>, number> = nil :: any

-- Test 1: Full should be non-optional
local b: boolean = sFull.IsEmpty(a) -- Should SUCCEED without nil check

-- Test 2: Impl should be optional
local maybeEmpty: ((Arr<number>) -> boolean)? = sImpl.IsEmpty -- Should SUCCEED

-- Test 3: NEG - Calling sImpl.IsEmpty without checking for nil should FAIL
sImpl.IsEmpty(a) -- NEG

local canary: string = 1

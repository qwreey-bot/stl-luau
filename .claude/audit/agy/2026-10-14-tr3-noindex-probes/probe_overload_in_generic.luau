--!strict

type DefaultFn =
	(<F>(mode: "full", build: (ops: any) -> F) -> F) &
	(<F>(mode: "impl", build: (ops: any) -> F) -> F?)

local Default: DefaultFn = (function(mode: string, build: any): any
	return nil
end) :: any

local function stackDef<M>(mode: M)
	return function<Self, T>()
		return {
			IsEmpty = Default(mode :: any, function(ops: any)
				return function(s: Self): boolean return true end
			end),
			Fold = Default(mode :: any, function(ops: any)
				return function<U>(s: Self, init: U, fn: (U, T) -> U): U return init end
			end),
		}
	end
end

local fullDef = stackDef<<"full">>("full")
local implDef = stackDef<<"impl">>("impl")

type FullStack<Self, T> = typeof(fullDef<<Self, T>>())
type ImplStack<Self, T> = typeof(implDef<<Self, T>>())

type Arr<T> = { n: number, [number]: T }
local a: Arr<number> = nil :: any

local sFull: FullStack<Arr<number>, number> = nil :: any
local sImpl: ImplStack<Arr<number>, number> = nil :: any

-- Test 1: Full IsEmpty non-optional
local b: boolean = sFull.IsEmpty(a)

-- Test 2: Full Fold preserves <U>
local fsum: number = sFull.Fold(a, 0, function(acc: number, v: number): number return acc + v end)
local fstr: string = sFull.Fold(a, "", function(acc: string, v: number): string return acc end)

-- Test 3: Impl IsEmpty optional
local maybeEmpty: ((Arr<number>) -> boolean)? = sImpl.IsEmpty

-- Test 4: Impl Fold optional
local maybeFold: (<U>(Arr<number>, U, (U, number) -> U) -> U)? = sImpl.Fold

-- NEG: calling without nil check
sImpl.IsEmpty(a) -- NEG

local canary: string = 1

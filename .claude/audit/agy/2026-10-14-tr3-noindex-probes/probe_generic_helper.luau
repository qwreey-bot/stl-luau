--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }

type FullHelper = {
	Default: <F>(build: (any) -> F) -> F,
	Mut: <Self, T>() -> (Self & Item<T>),
}

type ImplHelper = {
	Default: <F>(build: (any) -> F) -> F?,
	Mut: <Self, T>() -> Self,
}

local function stackDef<H>(h: H & (FullHelper | ImplHelper))
	return function<Self, T>()
		type MutType = typeof(h.Mut<<Self, T>>())
		return {
			push = nil :: (stack: MutType, item: T) -> Self,
			isEmpty = h.Default(function(ops) return function(s: Self): boolean return true end end),
		}
	end
end

local fullH: FullHelper = nil :: any
local implH: ImplHelper = nil :: any

local fullStack = stackDef(fullH)
local implStack = stackDef(implH)

type FullS<Self, T> = typeof(fullStack<<Self, T>>())
type ImplS<Self, T> = typeof(implStack<<Self, T>>())

-- Check types
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
type ArrRead<T> = { read n: number, [number]: T }

local a: Arr<number> = nil :: any
local r: ArrRead<number> = nil :: any
local sFull: FullS<Arr<number>, number> = nil :: any
local sImpl: ImplS<Arr<number>, number> = nil :: any

-- Is isEmpty non-optional in FullS?
local b: boolean = sFull.isEmpty(a)

-- Is isEmpty optional in ImplS?
local maybeEmpty: ((Arr<number>) -> boolean)? = sImpl.isEmpty

-- Can push be called with 'a' in FullS?
sFull.push(a, 1)

-- Can push be called with 'r' in FullS? (Should FAIL if MutType is ArrRead & Item)
-- But wait, FullS was instantiated with Arr<number>, not ArrRead<number>.
-- For ArrRead:
local sFullRead: FullS<ArrRead<number>, number> = nil :: any
sFullRead.push(r, 1) -- SHOULD FAIL: ArrRead has no Item<number>

local canary: string = 1

--!strict
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }

local function Def<F>(build: any): F
	return nil :: any
end

const E1 = {
	M = Def<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(123),
}
const E2 = {
	M = Def<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(function(ops: any) return nil end),
}

export type T1<Self, E, I> = {
	M: typeof(E1.M<<Self, E, I>>),
}
export type T2<Self, E, I> = {
	M: typeof(E2.M<<Self, E, I>>),
}

local _c1: string = E1.M
local _c2: string = E2.M

local v1: T1<number, number, number> = nil :: any
local v2: T2<number, number, number> = nil :: any

local _c3: string = v1.M
local _c4: string = v2.M

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

export type AliasDirect1<Self, E, I> = typeof(E1.M<<Self, E, I>>)
export type AliasDirect2<Self, E, I> = typeof(E2.M<<Self, E, I>>)

local a1: AliasDirect1<number, number, number> = nil :: any
local a2: AliasDirect2<number, number, number> = nil :: any

local _t1: string = a1
local _t2: string = a2

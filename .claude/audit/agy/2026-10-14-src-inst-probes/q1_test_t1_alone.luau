--!strict
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }

local function Def<F>(build: any): F
	return nil :: any
end

const E1 = {
	M = Def<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(123),
}

export type T1<Self, E, I> = {
	M: typeof(E1.M<<Self, E, I>>),
}

local v1: T1<number, number, number> = nil :: any
local _c3: string = v1.M

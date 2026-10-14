--!strict
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }

local function Def<F>(build: any): F
	return nil :: any
end

const E2 = {
	M = Def<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(function(ops: any) return nil end),
}

export type T2Read<Self, E, I> = {
	read M: typeof(E2.M<<Self, E, I>>),
}

local v2: T2Read<number, number, number> = nil :: any
local _c4: string = v2.M

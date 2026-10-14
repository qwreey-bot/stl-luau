--!strict
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
type AnyToken = { read name: string }

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

type Obj1 = typeof(E1) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> T1<Self, E, I>,
}
type Obj2 = typeof(E2) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> T2<Self, E, I>,
}

const O1: Obj1 = nil :: any
const O2: Obj2 = nil :: any

type MyDeque<T> = {
	items: { T },
	read __generics: { read Item: (T) -> T, read Index: (number) -> number },
}
local d: MyDeque<number> = nil :: any

local o1 = O1.Of(d)
local _res1 = o1.M(d, 2)

local o2 = O2.Of(d)
local _res2 = o2.M(d, 2)

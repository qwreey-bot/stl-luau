--!strict
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
type AnyToken = { read name: string }

local function Def<F>(build: any): F
	return nil :: any
end

local buildFn = function(ops: any) return nil end

const E3 = {
	M = Def<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(buildFn),
}

export type T3<Self, E, I> = {
	M: typeof(E3.M<<Self, E, I>>),
}

type Obj3 = typeof(E3) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> T3<Self, E, I>,
}

const O3: Obj3 = nil :: any

type MyDeque<T> = {
	items: { T },
	read __generics: { read Item: (T) -> T, read Index: (number) -> number },
}
local d: MyDeque<number> = nil :: any

local o3 = O3.Of(d)
local _res3 = o3.M(d, 2)

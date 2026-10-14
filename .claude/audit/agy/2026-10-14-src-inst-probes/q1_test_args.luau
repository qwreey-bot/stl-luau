--!strict
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
type AnyToken = { read name: string }

local function FnWithArg<F>(arg: any): F
	return nil :: any
end

local function FnNoArg<F>(): F
	return nil :: any
end

const Entries = {
	WithArg = FnWithArg<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(123),
	NoArg = FnNoArg<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(),
}

export type TWithArg<Self, E, I> = {
	M: typeof(Entries.WithArg<<Self, E, I>>),
}
export type TNoArg<Self, E, I> = {
	M: typeof(Entries.NoArg<<Self, E, I>>),
}

type ObjWithArg = typeof(Entries) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> TWithArg<Self, E, I>,
}
type ObjNoArg = typeof(Entries) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> TNoArg<Self, E, I>,
}

const OWithArg: ObjWithArg = nil :: any
const ONoArg: ObjNoArg = nil :: any

type MyDeque<T> = {
	items: { T },
	read __generics: { read Item: (T) -> T, read Index: (number) -> number },
}
local d: MyDeque<number> = nil :: any

-- Test NoArg
local o1 = ONoArg.Of(d)
local _res1 = o1.M(d, 2)

-- Test WithArg
local o2 = OWithArg.Of(d)
local _res2 = o2.M(d, 2)

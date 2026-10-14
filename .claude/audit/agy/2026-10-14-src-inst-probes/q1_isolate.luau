--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
type AnyToken = { read name: string }

local FN_MARK = table.freeze({})
local DEFAULT_MARK = table.freeze({})

local function Fn<F>(): F
	return FN_MARK :: any
end

local function Default<F>(build: any): F
	return table.freeze({ [DEFAULT_MARK] = build }) :: any
end

const ListEntries = {
	Get = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> E? >>(),
	FirstIndex = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>) -> I? >>(),
	LastIndex = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>) -> I? >>(),
	NextIndex = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> I? >>(),
	PrevIndex = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> I? >>(),
	IndexOf = Default<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(function(ops: any)
		return nil
	end),
	Contains = Default<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> boolean >>(function(ops: any)
		return nil
	end),
	Fold = Default<< <Self, E, I, U>(list: Self & ItemIndex<E, I>, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U >>(function(ops: any)
		return nil
	end),
}
export type List<Self, E, I> = {
	Get: typeof(ListEntries.Get<<Self, E, I>>),
	FirstIndex: typeof(ListEntries.FirstIndex<<Self, E, I>>),
	LastIndex: typeof(ListEntries.LastIndex<<Self, E, I>>),
	NextIndex: typeof(ListEntries.NextIndex<<Self, E, I>>),
	PrevIndex: typeof(ListEntries.PrevIndex<<Self, E, I>>),
	IndexOf: typeof(ListEntries.IndexOf<<Self, E, I>>),
	Contains: typeof(ListEntries.Contains<<Self, E, I>>),
}
type ListObject = typeof(ListEntries) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> List<Self, E, I>,
	FnTok: { [string]: number },
}
const List: ListObject = nil :: any

type MyDeque<T> = {
	items: { T },
	read __generics: { read Item: (T) -> T, read Index: (number) -> number },
}
local d: MyDeque<number> = nil :: any

local l = List.Of(d)
const okIdx: number? = l.IndexOf(d, 2)

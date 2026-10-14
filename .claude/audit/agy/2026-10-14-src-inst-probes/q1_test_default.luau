--!strict
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
type AnyToken = { read name: string }

local FN_MARK = table.freeze({})
local function Fn<F>(): F
	return FN_MARK :: any
end

local DEFAULT_MARK = table.freeze({})
local function Default<F>(build: any): F
	return table.freeze({ [DEFAULT_MARK] = build }) :: any
end

const ListEntries = {
	IndexOf = Default<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(function(ops: any)
		return nil
	end),
}
export type List<Self, E, I> = {
	IndexOf: typeof(ListEntries.IndexOf<<Self, E, I>>),
}
type ListObject = typeof(ListEntries) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> List<Self, E, I>,
}
const List: ListObject = nil :: any

type MyDeque<T> = {
	items: { T },
	read __generics: { read Item: (T) -> T, read Index: (number) -> number },
}
local d: MyDeque<number> = nil :: any

local l = List.Of(d)
local _okIdx: number? = l.IndexOf(d, 2)

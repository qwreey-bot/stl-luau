--!strict
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
type AnyToken = { read name: string }

local FN_MARK = table.freeze({})
local function Fn<F>(): F
	return FN_MARK :: any
end

const ListEntries = {
	Get = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> E? >>(),
}
export type List<Self, E, I> = {
	Get: typeof(ListEntries.Get<<Self, E, I>>),
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
local _got: number? = l.Get(d, 1)

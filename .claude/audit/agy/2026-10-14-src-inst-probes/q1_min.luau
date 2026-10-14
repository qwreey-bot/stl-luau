--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
type AnyToken = { read name: string }

local FN_MARK = table.freeze({})
local function Fn<F>(): F
	return FN_MARK :: any
end

-- Stack (2 params: Self, T)
const StackEntries = {
	Push = Fn<< <Self, T>(stack: Self & Item<T>, item: T) -> Self >>(),
}
export type Stack<Self, T> = {
	Push: typeof(StackEntries.Push<<Self, T>>),
}
type StackObject = typeof(StackEntries) & {
	Of: <Self, T>(of: (Self & Item<T>) | AnyToken) -> Stack<Self, T>,
}
const Stack: StackObject = nil :: any

-- List (3 params: Self, E, I)
const ListEntries = {
	IndexOf = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(),
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

-- Test 1: Stack
local s = Stack.Of(d)
local _s_push = s.Push(d, 5)

-- Test 2: List (implicit Of)
local l = List.Of(d)
local _l_idx = l.IndexOf(d, 2)

-- Test 3: List (explicit Of)
local l_exp = List.Of<<MyDeque<number>, number, number>>(d)
local _l_exp_idx = l_exp.IndexOf(d, 2)

--!strict
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

local dummyIndexOf = function(ops: any) return nil end
local dummyContains = function(ops: any) return nil end

const ListEntriesFixA = {
	IndexOf = Default<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(dummyIndexOf),
	Contains = Default<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> boolean >>(dummyContains),
}

export type ListFixA<Self, E, I> = {
	IndexOf: typeof(ListEntriesFixA.IndexOf<<Self, E, I>>),
	Contains: typeof(ListEntriesFixA.Contains<<Self, E, I>>),
}

type ListObjectFixA = typeof(ListEntriesFixA) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> ListFixA<Self, E, I>,
}
const ListFixA: ListObjectFixA = nil :: any

type MyDeque<T> = {
	items: { T },
	read __generics: { read Item: (T) -> T, read Index: (number) -> number },
}
local d: MyDeque<number> = nil :: any

-- 검증 A
local la = ListFixA.Of(d)
local res_a: number? = la.IndexOf(d, 2)
local has_a: boolean = la.Contains(d, 3)

local NEG_wrong_item_a = la.IndexOf(d, "wrong") -- NEG
local canary: string = 1

--!strict
-- probes/q1_solution.luau: Q1 원인 규명 및 해결 프로브
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

-- 방법 A: build 함수를 인라인 람다가 아닌 외부 변수로 분리 (Unblock)
local dummyIndexOf = function(ops: any) return nil end
local dummyContains = function(ops: any) return nil end
local dummyFold = function(ops: any) return nil end

const ListEntriesFixA = {
	Get = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> E? >>(),
	FirstIndex = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>) -> I? >>(),
	LastIndex = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>) -> I? >>(),
	NextIndex = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> I? >>(),
	PrevIndex = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> I? >>(),
	IndexOf = Default<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(dummyIndexOf),
	Contains = Default<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> boolean >>(dummyContains),
}

export type ListFixA<Self, E, I> = {
	Get: typeof(ListEntriesFixA.Get<<Self, E, I>>),
	FirstIndex: typeof(ListEntriesFixA.FirstIndex<<Self, E, I>>),
	LastIndex: typeof(ListEntriesFixA.LastIndex<<Self, E, I>>),
	NextIndex: typeof(ListEntriesFixA.NextIndex<<Self, E, I>>),
	PrevIndex: typeof(ListEntriesFixA.PrevIndex<<Self, E, I>>),
	IndexOf: typeof(ListEntriesFixA.IndexOf<<Self, E, I>>),
	Contains: typeof(ListEntriesFixA.Contains<<Self, E, I>>),
}

type ListObjectFixA = typeof(ListEntriesFixA) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> ListFixA<Self, E, I>,
}
const ListFixA: ListObjectFixA = nil :: any

-- 방법 B: Entries 에서는 Default 에 인라인 람다를 넘기더라도, 
-- 타입 정의용 서명(Signature) 테이블을 순수 Fn<<...>>() 으로 두는 방식
-- (런타임 Default 와 타입 서명을 분리)
const ListSigs = {
	IndexOf = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(),
	Contains = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> boolean >>(),
}
export type ListFixB<Self, E, I> = {
	IndexOf: typeof(ListSigs.IndexOf<<Self, E, I>>),
	Contains: typeof(ListSigs.Contains<<Self, E, I>>),
}
type ListObjectFixB = typeof(ListSigs) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> ListFixB<Self, E, I>,
}
const ListFixB: ListObjectFixB = nil :: any

type MyDeque<T> = {
	items: { T },
	read __generics: { read Item: (T) -> T, read Index: (number) -> number },
}
local d: MyDeque<number> = nil :: any

-- 검증 A
local la = ListFixA.Of(d)
local res_a: number? = la.IndexOf(d, 2)
local has_a: boolean = la.Contains(d, 3)

-- 검증 B
local lb = ListFixB.Of(d)
local res_b: number? = lb.IndexOf(d, 2)
local has_b: boolean = lb.Contains(d, 3)

-- NEG 검증
local NEG_wrong_item_a = la.IndexOf(d, "wrong") -- NEG
local NEG_wrong_item_b = lb.IndexOf(d, "wrong") -- NEG
local canary: string = 1

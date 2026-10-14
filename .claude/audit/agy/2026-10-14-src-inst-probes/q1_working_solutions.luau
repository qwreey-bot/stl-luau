--!strict
-- probes/q1_working_solutions.luau
-- Q1 정상 동작하는 적는 법 검증 프로브
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
type AnyToken = { read name: string }

local function Fn<F>(): F return nil :: any end
local function Default<F>(build: any): F return nil :: any end

-- [해법 1] 외부 바인딩 함수 전달 방식:
-- Default 의 구현 빌더를 인라인 람다가 아닌 외부 변수로 전달
local defaultIndexOf = function(ops: any) return nil end
local defaultContains = function(ops: any) return nil end

const ListEntriesSol1 = {
	Get = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> E? >>(),
	IndexOf = Default<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(defaultIndexOf),
	Contains = Default<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> boolean >>(defaultContains),
}

export type ListSol1<Self, E, I> = {
	Get: typeof(ListEntriesSol1.Get<<Self, E, I>>),
	IndexOf: typeof(ListEntriesSol1.IndexOf<<Self, E, I>>),
	Contains: typeof(ListEntriesSol1.Contains<<Self, E, I>>),
}

type ListObjectSol1 = typeof(ListEntriesSol1) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> ListSol1<Self, E, I>,
}
const ListSol1: ListObjectSol1 = nil :: any

-- [해법 2] 순수 서명 테이블(Signatures) 분리 방식:
-- 런타임용 테이블(Entries)과 타입 유도용 테이블(Sigs)을 분리하되 서명은 Fn<<..>>() 으로 단 1회 작성
const ListSigs = {
	Get = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> E? >>(),
	IndexOf = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(),
	Contains = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> boolean >>(),
}
export type ListSol2<Self, E, I> = {
	Get: typeof(ListSigs.Get<<Self, E, I>>),
	IndexOf: typeof(ListSigs.IndexOf<<Self, E, I>>),
	Contains: typeof(ListSigs.Contains<<Self, E, I>>),
}

type ListObjectSol2 = typeof(ListSigs) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> ListSol2<Self, E, I>,
}
const ListSol2: ListObjectSol2 = nil :: any

-- 테스트 데이터
type MyDeque<T> = {
	items: { T },
	read __generics: { read Item: (T) -> T, read Index: (number) -> number },
}
local d: MyDeque<number> = nil :: any

-- 해법 1 정상 호출: 0건
local l1 = ListSol1.Of(d)
local _res1_get: number? = l1.Get(d, 1)
local _res1_idx: number? = l1.IndexOf(d, 2)
local _res1_has: boolean = l1.Contains(d, 3)

-- 해법 2 정상 호출: 0건
local l2 = ListSol2.Of(d)
local _res2_get: number? = l2.Get(d, 1)
local _res2_idx: number? = l2.IndexOf(d, 2)
local _res2_has: boolean = l2.Contains(d, 3)

-- 음성 대조군 (-- NEG 4건)
local NEG_l1_get = l1.Get(d, "wrong") -- NEG 1: idx 타입 불일치
local NEG_l1_idx = l1.IndexOf(d, "wrong") -- NEG 2: item 타입 불일치
local NEG_l2_get = l2.Get(d, "wrong") -- NEG 3: idx 타입 불일치
local NEG_l2_idx = l2.IndexOf(d, "wrong") -- NEG 4: item 타입 불일치

local canary: string = 1

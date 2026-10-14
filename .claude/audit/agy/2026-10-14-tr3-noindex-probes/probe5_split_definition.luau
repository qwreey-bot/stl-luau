--!strict
-- probe5: index<> 없이 분리 정의(Split & Intersect)로 두 보기를 구성하는 시도

type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }

local function Fn<F>(): F return nil :: any end

type A = { read __probeA: true }
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T }, [number]: T }
type ArrRead<T> = { read n: number, read __readGenerics: { read Item: () -> T }, read [number]: T }

local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end
local function peek<T>(a: ArrRead<T>): T? return nil end
local function len<T>(a: ArrRead<T>): number return a.n end
local function strPush(a: Arr<string>, v: string): Arr<string> return a end

-- [방안 A] 정의자가 필수(Req)와 기본(Defaults)을 별도로 작성하는 경우
-- 하지만 MutSelf(Item<T> 유무)와 Defaults(F vs F?)의 차이 때문에:

-- 필수 연산 정의 (등록용: Self)
local function stackReqImpl<Self, T>()
	return {
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
		Peek = Fn<<(stack: Self) -> T?>>(),
	}
end

-- 필수 연산 정의 (완성용: Self & Item<T>)
local function stackReqFull<Self, T>()
	return {
		Push = Fn<<(stack: Self & Item<T>, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self & Item<T>) -> T?>>(),
		Peek = Fn<<(stack: Self) -> T?>>(),
	}
end

-- 기본 구현 정의 (완성용: non-nil F)
local function stackDefaultsFull<Self, T>()
	return {
		IsEmpty = function(s: Self): boolean return true end,
		Fold = function<U>(s: Self, init: U, fn: (U, T) -> U): U return init end,
	}
end

-- 기본 구현 정의 (등록용: optional F?)
local function stackDefaultsOpt<Self, T>()
	return {
		IsEmpty = Fn<<((s: Self) -> boolean)?>>(),
		Fold = Fn<<(<U>(s: Self, init: U, fn: (U, T) -> U) -> U)?>>(),
	}
end

-- 완성 표: stackReqFull & stackDefaultsFull
export type Stack<Self, T> = typeof(stackReqFull<<Self, T>>()) & typeof(stackDefaultsFull<<Self, T>>())

-- 등록 표: stackReqImpl & stackDefaultsOpt
export type StackImpl<Self, T> = typeof(stackReqImpl<<Self, T>>()) & typeof(stackDefaultsOpt<<Self, T>>())

-- [테스트 1] 등록 표 검증
const reg: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek } -- 통과
const regOv: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek, IsEmpty = function(a: Arr<A>): boolean return a.n == 0 end } -- 통과
const NEG_missing: StackImpl<Arr<A>, A> = { Push = pushBack, Peek = peek } -- NEG
const NEG_pinned: StackImpl<Arr<A>, A> = { Push = strPush, Pop = popBack, Peek = peek } -- NEG
const NEG_badov: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek, IsEmpty = len } -- NEG

-- [테스트 2] 완성 표 검증
local full: Stack<Arr<number>, number> = nil :: any
local a: Arr<number> = nil :: any
local b: boolean = full.IsEmpty(a) -- non-nil로 호출 가능
full.Push(a, 1) -- 통과

-- [테스트 3] 빌린 참조 검증
local fullRead: Stack<ArrRead<number>, number> = nil :: any
local r: ArrRead<number> = nil :: any
fullRead.Push(r, 1) -- NEG: ArrRead lacks Item<number>

local canary: string = 1

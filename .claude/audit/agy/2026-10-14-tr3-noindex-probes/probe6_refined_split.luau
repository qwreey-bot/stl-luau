--!strict
-- probe6: MutSelf 매개변수화를 통한 필수 표 중복 제거 + 기본 구현 표 분리

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

-- 1. 필수 표: MutSelf를 타입 매개변수로 받아 단 1번만 선언! (7줄)
local function stackReq<MutSelf, Self, T>()
	return {
		Push = Fn<<(stack: MutSelf, item: T) -> Self>>(),
		Pop = Fn<<(stack: MutSelf) -> T?>>(),
		Peek = Fn<<(stack: Self) -> T?>>(),
	}
end

-- 2. 기본 구현 함수 본체 (런타임 + 완성 표 타입: 6줄)
local function stackDefaults<Self, T>()
	return {
		IsEmpty = function(s: Self): boolean return true end,
		Fold = function<U>(s: Self, init: U, fn: (U, T) -> U): U return init end,
	}
end

-- 3. 기본 구현 등록 표 (옵셔널 서명 선언: 6줄)
local function stackDefaultsOpt<Self, T>()
	return {
		IsEmpty = Fn<<((s: Self) -> boolean)?>>(),
		Fold = Fn<<(<U>(s: Self, init: U, fn: (U, T) -> U) -> U)?>>(),
	}
end

-- 완성 표: MutSelf = Self & Item<T>, Defaults = non-nil
export type Stack<Self, T> = typeof(stackReq<<Self & Item<T>, Self, T>>()) & typeof(stackDefaults<<Self, T>>())

-- 등록 표: MutSelf = Self, Defaults = optional
export type StackImpl<Self, T> = typeof(stackReq<<Self, Self, T>>()) & typeof(stackDefaultsOpt<<Self, T>>())

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

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
-- 메인 변형: 옵셔널 서명을 다시 적지 않고 typeof 로 칸마다 `?` 만
type StackDefaults<Self, T> = typeof(stackDefaults<<Self, T>>())
export type Stack<Self, T> = typeof(stackReq<<Self & Item<T>, Self, T>>()) & StackDefaults<Self, T>
export type StackImpl<Self, T> = typeof(stackReq<<Self, Self, T>>()) & {
	IsEmpty: typeof(stackDefaults<<Self, T>>().IsEmpty)?,
	Fold: typeof(stackDefaults<<Self, T>>().Fold)?,
}
const reg: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek }
const regOv: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek, IsEmpty = function(a: Arr<A>): boolean return a.n == 0 end }
const NEG_missing: StackImpl<Arr<A>, A> = { Push = pushBack, Peek = peek } -- NEG
const NEG_badov: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek, IsEmpty = len } -- NEG
const NEG_pinU: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek, Fold = function(s: Arr<A>, init: number, fn: (number, A) -> number): number return init end } -- NEG
local full: Stack<Arr<number>, number> = nil :: any
local a: Arr<number> = nil :: any
local b: boolean = full.IsEmpty(a)
const s: string = full.Fold(a, "", function(acc: string, x: number): string return acc end)
local canary: string = 1
return { reg, regOv, NEG_missing, NEG_badov, NEG_pinU, b, s }

--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
local function Fn<F>(): F return nil :: any end
type A = { read __probeA: true }
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end
local function len<T>(a: Arr<T>): number return a.n end
local function stackReq<MutSelf, Self, T>()
	return { Push = Fn<<(stack: MutSelf, item: T) -> Self>>(), Pop = Fn<<(stack: MutSelf) -> T?>>() }
end
local function stackDefaults<Self, T>()
	return {
		IsEmpty = function(s: Self): boolean return true end,
		Count = function(s: Self): number return 0 end, -- 새로 더한 기본 구현
	}
end
type StackDefaults<Self, T> = typeof(stackDefaults<<Self, T>>())
export type Stack<Self, T> = typeof(stackReq<<Self & Item<T>, Self, T>>()) & StackDefaults<Self, T>
-- 드리프트: Impl 쪽 선택 목록에 Count 를 안 적음
export type StackImpl<Self, T> = typeof(stackReq<<Self, Self, T>>()) & {
	IsEmpty: typeof(stackDefaults<<Self, T>>().IsEmpty)?,
}
const ok: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack }
const over: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Count = len } -- 드리프트 시 재정의 불가? (Count: 올바른 서명)
const wrong: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Count = pushBack } -- 드리프트 시 서명 틀려도 통과? NEG
local canary: string = 1
return { ok, over, wrong, canary }

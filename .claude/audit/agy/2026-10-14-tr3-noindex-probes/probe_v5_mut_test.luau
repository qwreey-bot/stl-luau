--!strict
type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }
type Mut<Self, T, M> = Self & Item<T> -- index 없이 항상 Self & Item<T>로 둬봄!
type Object<F, G> = { read Of: F, read ImplOf: G }
local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end
local function Trait<F, G>(name: string, factory: (mode: "full") -> F, _impl: ((mode: "impl") -> G)?): Object<F, G> return nil :: any end
type A = { read __probeA: true }

type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T }, [number]: T }
type ArrRead<T> = { read n: number, read __readGenerics: { read Item: () -> T }, read [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end
local function peek<T>(a: ArrRead<T>): T? return nil end
local function len<T>(a: ArrRead<T>): number return a.n end
local function strPush(a: Arr<string>, v: string): Arr<string> return a end

local function stackDef<M>(mode: M)
	return function<Self, T>(of: (Self & ItemRead<T>) | Token)
		return {
			Push = Fn<<(stack: Mut<Self, T, M>, item: T) -> Self>>(),
			Pop = Fn<<(stack: Mut<Self, T, M>) -> T?>>(),
			Peek = Fn<<(stack: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: any) return function(s: Self): boolean return true end end),
			Fold = Default(mode, function(ops: any) return function<U>(s: Self, init: U, fn: (U, T) -> U): U return init end end),
		}
	end
end
const Stack = Trait("Stack", stackDef<<"full">>, stackDef<<"impl">>)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))

-- 등록 보기
const reg: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek }
const regOv: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek, IsEmpty = function(a: Arr<A>): boolean return a.n == 0 end }
const NEG_missing: StackImpl<Arr<A>, A> = { Push = pushBack, Peek = peek } -- NEG
const NEG_pinned: StackImpl<Arr<A>, A> = { Push = strPush, Pop = popBack, Peek = peek } -- NEG
const NEG_badov: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek, IsEmpty = len } -- NEG
const NEG_badfold: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek, Fold = len } -- NEG
-- 완성 보기
local a: Arr<number> = nil :: any
local s = Stack.Of(a)
const e: boolean = s.IsEmpty(a)
const fsum: number = s.Fold(a, 0, function(acc: number, v: number): number return acc + v end)
const fstr: string = s.Fold(a, "", function(acc: string, v: number): string return acc end)
const keep: (Arr<number>) -> boolean = s.IsEmpty
s.Push(a, 1)
s.Push(a, "x") -- NEG
const NEG_fold: string = s.Fold(a, 0, function(acc: number, v: number): number return acc end) -- NEG
const NEG_pop: string? = s.Pop(a) -- NEG
-- 빌린 참조
local r: ArrRead<number> = nil :: any
const pk: number? = Stack.Of(r).Peek(r)
Stack.Of(r).Push(r, 1) -- NEG
const NEG_pk: string? = Stack.Of(r).Peek(r) -- NEG
-- 뭉텅이 몸통
type Deque<Self, T> = { PushBack: (Self, T) -> Self, PopBack: (Self) -> T?, Back: (Self) -> T? }
local function fromDeque<C, T>(d: Deque<C, T>): StackImpl<C, T>
	return { Push = d.PushBack, Pop = d.PopBack, Peek = d.Back }
end
local function NEG_fromDequeMissing<C, T>(d: Deque<C, T>): StackImpl<C, T>
	return { Push = d.PushBack, Pop = d.PopBack } -- NEG
end
local canary: string = 1
return { reg, regOv, NEG_missing, NEG_pinned, NEG_badov, NEG_badfold, e, fsum, fstr, keep, NEG_fold, NEG_pop, pk, NEG_pk, fromDeque, NEG_fromDequeMissing }

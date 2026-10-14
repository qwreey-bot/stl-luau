--!strict
type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }
type Mut<Self, T, M> = Self & Item<T>
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

const NEG_pinU: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek,
	Fold = function(s: Arr<A>, init: number, fn: (number, A) -> number): number return init end } -- NEG (U 를 못박음)
const okU: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek,
	Fold = function<U>(s: Arr<A>, init: U, fn: (U, A) -> U): U return init end }
-- 종류를 모르는 제네릭 알고리즘
local function pushTwice<C, T>(c: C & Item<T> & ItemRead<T>, x: T)
	const st = Stack.Of(c)
	st.Push(c, x)
	st.Push(c, x)
end
local a: Arr<number> = nil :: any
pushTwice(a, 1)
pushTwice(a, "x") -- NEG
local canary: string = 1
return { NEG_pinU, okU, pushTwice }

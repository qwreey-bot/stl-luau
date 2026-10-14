--!strict
type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end
local function Trait<F, G>(name: string, def: ((mode: "full") -> F) & ((mode: "impl") -> G)): { read Of: F, read ImplOf: G } return nil :: any end
type A = { read __probeA: true }
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end
type B = { read __probeB: true }
-- 빌더를 밖의 이름 있는 함수로(탐침 타입 몸통 — 몸통 검사도 받음)
local function buildIsEmpty(ops: any): (s: A) -> boolean return function(s: A): boolean return true end end
local function buildFold(ops: any): <U>(s: A, init: U, fn: (U, B) -> U) -> U return function<U>(s: A, init: U, fn: (U, B) -> U): U return init end end
-- v8 모양: Mut 없음, 기본 구현 둘, 인라인 한 번 넘기기, 같은 파일에서 바로 씀
const Stack = Trait("Stack", function<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return {
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
		IsEmpty = Default(mode, buildIsEmpty :: (ops: any) -> (s: Self) -> boolean),
		Fold = Default(mode, buildFold :: (ops: any) -> <U>(s: Self, init: U, fn: (U, T) -> U) -> U),
	}
	end
end)
type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))
local a: Arr<number> = nil :: any
const r1: string = Stack.Of(a).IsEmpty(a) -- NEG
const r2: number = Stack.Of(a).Fold(a, "", function(acc: string, x: number): string return acc end) -- NEG
const r3: string = Stack.Of(a).Pop(a) -- NEG
local s: Stack<Arr<number>, number> = Stack.Of(a)
const r4: string = s.IsEmpty(a) -- NEG
const reg: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack }
const NEG_ov: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, IsEmpty = popBack } -- NEG
local canary: string = 1
return { r1, r2, r3, r4, reg, NEG_ov }

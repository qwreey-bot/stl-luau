--!strict
-- v5 기준선: 내장 타입 함수 index<>를 사용한 두 보기와 빌린 읽기 참조
type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }
type Mut<Self, T, M> = index<{ full: Self & Item<T>, impl: Self }, M>
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

-- [검증 1] 등록 보기 (ImplOf)
const reg: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek } -- 필수만 구현: 통과
const regOv: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek, IsEmpty = function(a: Arr<A>): boolean return a.n == 0 end } -- 오버라이드: 통과
const NEG_missing: StackImpl<Arr<A>, A> = { Push = pushBack, Peek = peek } -- NEG: Pop 누락
const NEG_pinned: StackImpl<Arr<A>, A> = { Push = strPush, Pop = popBack, Peek = peek } -- NEG: A 대신 string
const NEG_badov: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek, IsEmpty = len } -- NEG: 잘못된 반환 타입
const NEG_badfold: StackImpl<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek, Fold = len } -- NEG: 잘못된 시그니처

-- [검증 2] 완성 보기 (Of)
local a: Arr<number> = nil :: any
local s = Stack.Of(a)
const e: boolean = s.IsEmpty(a) -- non-nil 함수로 호출 가능
const fsum: number = s.Fold(a, 0, function(acc: number, v: number): number return acc + v end) -- <U> 보존
s.Push(a, 1) -- 통과
s.Push(a, "x") -- NEG: number 자리에 string
const NEG_fold: string = s.Fold(a, 0, function(acc: number, v: number): number return acc end) -- NEG: 반환값 불일치

-- [검증 3] 빌린 읽기 참조 거절
local r: ArrRead<number> = nil :: any
const pk: number? = Stack.Of(r).Peek(r) -- 읽기 허용
Stack.Of(r).Push(r, 1) -- NEG: ArrRead는 Item<number>가 없어 거절됨

-- [검증 4] 카나리아
local canary: string = 1

return { reg, regOv, NEG_missing, NEG_pinned, NEG_badov, NEG_badfold, e, fsum, NEG_fold, pk }

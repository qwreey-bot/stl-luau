--!strict
-- probe_freeze_default.luau
-- table.freeze({ Push = ..., IsEmpty = Default(mode, ...) }) 검증

type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end
local function Trait<F, G>(name: string, def: (mode: "full") -> F, implDef: ((mode: "impl") -> G)?): { read Of: F, read ImplOf: G } return nil :: any end

type A = { read __probeA: true }
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end

local function stackDef<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return table.freeze({
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
		IsEmpty = Default(mode, function(ops: any) return function(s: Self): boolean return true end end),
	})
	end
end

const Stack = Trait("Stack", stackDef<<"full">>, stackDef<<"impl">>)
type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))

local function testRegister<Self, T>(impl: StackImpl<Self, T>) end

-- 1. 기본 구현(IsEmpty) 생략하고 표 리터럴 인자로 전달 -> 통과해야 함!
testRegister<<Arr<A>, A>>({
	Push = pushBack,
	Pop = popBack,
})

-- 2. 기본 구현(IsEmpty) 재정의하면서 표 리터럴 인자로 전달 -> 통과해야 함!
local function myIsEmpty<T>(a: Arr<T>): boolean return a.n == 0 end
testRegister<<Arr<A>, A>>({
	Push = pushBack,
	Pop = popBack,
	IsEmpty = myIsEmpty,
})

local canary: string = 1

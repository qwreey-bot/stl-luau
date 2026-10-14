--!strict
-- probes/probe8_freeze_on_b_prime.luau
-- B' 위에 table.freeze 기반 한 줄 등록(For)을 얹었을 때의 동작 시험

type Token = { read name: string }
type AnyToken = Token
type Item<T> = { read __generics: { read Item: (T) -> T } }
local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end

type Object<F, G> = {
	read Of: F,
	read ImplOf: G,
	read For: <R>(witness: (...any) -> R) -> (token: AnyToken, impl: R) -> (),
}

local function Trait<F, G>(
	name: string,
	def: (mode: "full") -> F,
	implDef: (mode: "impl") -> G
): Object<F, G>
	return nil :: any
end

-- B' 정의에 table.freeze 적용
local function stackDef<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | AnyToken)
		return table.freeze({
			Push = Fn<<(stack: Self, item: T) -> Self>>(),
			Pop = Fn<<(stack: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: any) return function(s: Self): boolean return true end end),
		})
	end
end

const Stack = Trait("Stack", stackDef<<"full">>, stackDef<<"impl">>)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))

type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end
local function strPush(a: Arr<string>, v: string): Arr<string> return a end

type A = { read __probeA: true }
local ARR_TOK: Token = { name = "Arr" }

-- [1] 정상 등록: 필수만 (IsEmpty 생략)
Stack.For(Stack.ImplOf<<Arr<A>, A>>)(ARR_TOK, {
	Push = pushBack,
	Pop = popBack,
})

-- [2] 정상 등록: IsEmpty 재정의 포함
Stack.For(Stack.ImplOf<<Arr<A>, A>>)(ARR_TOK, {
	Push = pushBack,
	Pop = popBack,
	IsEmpty = function(s: Arr<A>): boolean return s.n == 0 end,
})

-- [3] NEG: 원소를 못박은 함수 strPush 전달
Stack.For(Stack.ImplOf<<Arr<A>, A>>)(ARR_TOK, {
	Push = strPush, -- NEG: Arr<A>, A 여야 함
	Pop = popBack,
})

-- [4] NEG: 필수 함수 Pop 누락
Stack.For(Stack.ImplOf<<Arr<A>, A>>)(ARR_TOK, {
	Push = pushBack, -- NEG: Pop 누락
})

-- [5] NEG: IsEmpty 재정의 타입 불일치
Stack.For(Stack.ImplOf<<Arr<A>, A>>)(ARR_TOK, {
	Push = pushBack,
	Pop = popBack,
	IsEmpty = function(s: Arr<A>): string return "wrong" end, -- NEG: boolean이어야 함
})

local canary: string = 1
return { canary }

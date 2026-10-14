--!strict
-- probes/probe4_token_of.luau
-- Stack.Of(TOKEN)을 타입 인자 없이 부르거나,
-- Stack.Of<<C, T>>(TOKEN)으로 부를 때 동작

type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end

local function Trait<F, G>(
	name: string,
	def: (mode: "full") -> F,
	implDef: (mode: "impl") -> G
): { read Of: F, read ImplOf: G }
	return nil :: any
end

local function stackDef<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | Token)
		return {
			Push = Fn<<(stack: Self, item: T) -> Self>>(),
			Pop = Fn<<(stack: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: any) return function(s: Self): boolean return true end end),
		}
	end
end

const Stack = Trait("Stack", stackDef<<"full">>, stackDef<<"impl">>)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))

type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local ARR: Token = { name = "Arr" }

-- 1. 토큰으로 명시적 인자 주며 꺼냄
local ops = Stack.Of<<Arr<number>, number>>(ARR)
local a: Arr<number> = nil :: any
local ok_push: Arr<number> = ops.Push(a, 10)
local bad_push: Arr<string> = ops.Push(a, 10) -- NEG: Arr<number>이어야 함
local bad_empty: string = ops.IsEmpty(a) -- NEG: boolean이어야 함

-- 2. 토큰으로 타입 인자 없이 꺼냄 (Stack.Of(ARR))
local bare_ops = Stack.Of(ARR)
-- bare_ops의 Self, T는 무엇인가?
-- bare_ops.Push(a, 10)을 호출했을 때 타입이 어떻게 되는가?
local bare_push = bare_ops.Push(a, 10)

local canary: string = 1
return { canary, ok_push, bad_push, bad_empty, bare_push }

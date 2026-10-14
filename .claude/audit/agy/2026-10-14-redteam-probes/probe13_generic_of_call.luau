--!strict
-- probes/probe13_generic_of_call.luau
-- 제네릭 함수 몸통 안에서 Stack.Of(c)를 직접 호출할 때
-- 기본 구현 메서드(IsEmpty)와 index<>의 타입 동작 분석

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

-- 제네릭 함수 안에서 Stack.Of(c) 호출
local function genericAlgorithm<C, T>(c: C & Item<T>)
	local ops = Stack.Of(c)
	
	-- 1. ops.IsEmpty(c)의 반환 타입 검사
	local empty = ops.IsEmpty(c)
	local bad_empty: string = empty -- NEG: boolean이어야 함! never로 떨어져서 통과하는가?
	
	-- 2. ops.Pop(c)의 반환 타입 검사
	local popped = ops.Pop(c)
	local bad_pop: number = popped -- NEG: T? 여야 함!
	
	-- 3. ops.Push(c, item) 검사
	local bad_push: string = ops.Push(c, nil :: any) -- NEG: C 여야 함!
	local ok_push: C = ops.Push(c, nil :: any) -- 정상 대입: C에 들어가는가?
	
	return { bad_empty, bad_pop, bad_push, ok_push }
end

local canary: string = 1
return { canary, genericAlgorithm }

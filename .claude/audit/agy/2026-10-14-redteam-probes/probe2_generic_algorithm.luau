--!strict
-- probes/probe2_generic_algorithm.luau
-- 제네릭 알고리즘 함수 안에서 Stack<C, T>의 기본 구현 메서드를 호출할 때
-- 반환 타입 검사가 살아 있는가?

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

-- 제네릭 알고리즘 안에서 Stack<C, T>를 받아 IsEmpty 호출
local function genericCheck<C, T>(ops: Stack<C, T>, c: C)
	-- IsEmpty는 boolean을 반환해야 함.
	-- 만약 index<>가 제네릭 스코프에서 never로 떨어졌다면 string 대입이 0건으로 통과할 것!
	local bad_ret: string = ops.IsEmpty(c) -- NEG: 잡혀야 함!
	
	-- Pop은 원래 기본 구현이 아닌 Fn (필수) 칸
	local bad_pop: number = ops.Pop(c) -- NEG: T? 이므로 number 대입 불가 (T가 number가 아님)
	
	-- IsEmpty에 잘못된 타입의 인자 전달 시
	local bad_arg = ops.IsEmpty("invalid_arg") -- NEG: c: C 여야 함
	
	return { bad_ret, bad_pop, bad_arg }
end

local canary: string = 1
return { canary, genericCheck }

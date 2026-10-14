--!strict
-- probes/probe3_cyclic_ops_type.luau
-- B'에서 stackDef가 Stack<Self, T>를 참조하고,
-- Stack이 stackDef를 참조하여 순환할 때,
-- ops에 대한 타입 검사가 실제로 작동하는가? (any로 무너지지 않는가?)

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

-- stackDef에서 아직 아래에 선언되지 않은 Stack<Self, T>를 ops 타입으로 사용
local function stackDef<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | Token)
		return {
			Push = Fn<<(stack: Self, item: T) -> Self>>(),
			Pop = Fn<<(stack: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: Stack<Self, T>)
				-- 1. 없는 필드 접근 시 잡히는가?
				local nope = ops.NonExistentField -- NEG: 잡혀야 정상!
				
				-- 2. ops.Pop의 인자 타입 오류가 잡히는가?
				local bad_pop = ops.Pop("not_self") -- NEG: 잡혀야 정상!
				
				return function(s: Self): boolean
					return ops.Pop(s) == nil
				end
			end),
			Contains = Default(mode, function(ops: Stack<Self, T>)
				-- 다른 기본 구현 IsEmpty를 부를 때
				return function(s: Self): boolean
					local bad_empty: string = ops.IsEmpty(s) -- NEG: boolean이어야 함!
					return not ops.IsEmpty(s)
				end
			end),
		}
	end
end

const Stack = Trait("Stack", stackDef<<"full">>, stackDef<<"impl">>)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))

local canary: string = 1
return { Stack, canary }

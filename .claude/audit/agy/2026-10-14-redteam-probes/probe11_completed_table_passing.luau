--!strict
-- probes/probe11_completed_table_passing.luau
-- Stack<C, T> (완성 표)와 StackImpl<C, T> (등록 표)를
-- 함수 인자, 반환값, 테이블 필드로 주고받을 때의 검사 동작

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
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))

type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local a: Arr<number> = nil :: any
local fullOps: Stack<Arr<number>, number> = Stack.Of(a)

-- [1] 함수 인자로 Stack (완성 표) 전달
local function useFull(ops: Stack<Arr<number>, number>)
	return ops.IsEmpty(a)
end
local res1: boolean = useFull(fullOps)

-- [2] StackImpl (등록 표)를 useFull (완성 표 요구)에 전달 시도
-- 등록 표는 IsEmpty가 선택(optional)이므로, 완성 표 자리에 들어가면 안 됨!
local implOps: StackImpl<Arr<number>, number> = {
	Push = function(s, x) return s end,
	Pop = function(s) return nil end,
	-- IsEmpty 생략됨!
}
local NEG_implAsFull = useFull(implOps) -- NEG: 잡혀야 함!

-- [3] 함수 반환값으로 Stack 전달
local function getOps(): Stack<Arr<number>, number>
	return fullOps
end
local NEG_getOps: Stack<Arr<number>, number> = implOps -- NEG: 잡혀야 함!

-- [4] 테이블 필드로 Stack 보관
type Holder<C, T> = {
	ops: Stack<C, T>,
}
local h: Holder<Arr<number>, number> = {
	ops = fullOps,
}
local NEG_holder: Holder<Arr<number>, number> = {
	ops = implOps, -- NEG: 잡혀야 함!
}

local canary: string = 1
return { canary, res1, NEG_implAsFull, NEG_getOps, h, NEG_holder }

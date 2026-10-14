--!strict
-- probes/probe17_non_generic_mode.luau
-- 사용자가 stackDef<M>(mode: M) 대신
-- local function stackDef(mode: "full" | "impl") 로 작성했을 때
-- 어떤 일이 벌어지는가?

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

-- 실수: <M>(mode: M) 대신 비제네릭 (mode: "full" | "impl")로 정의
local function stackDefNonGeneric(mode: "full" | "impl")
	return function<Self, T>(of: (Self & Item<T>) | Token)
		return {
			Push = Fn<<(stack: Self, item: T) -> Self>>(),
			Pop = Fn<<(stack: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: any) return function(s: Self): boolean return true end end),
		}
	end
end

-- Trait에 넘길 때 stackDefNonGeneric은 타입 인자를 가질 수 없음
const StackNG = Trait("Stack", stackDefNonGeneric, stackDefNonGeneric)
type StackNG<Self, T> = typeof(StackNG.Of<<Self, T>>(nil :: any))
type StackNGImpl<Self, T> = typeof(StackNG.ImplOf<<Self, T>>(nil :: any))

type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local a: Arr<number> = nil :: any

-- IsEmpty의 타입은 무엇인가?
local r1: string = StackNG.Of(a).IsEmpty(a) -- NEG: boolean이어야 함!

local canary: string = 1
return { canary, r1 }

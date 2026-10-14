--!strict
-- probes/probe1_omit_mode_arg.luau
-- B'에서 사용자가 실수로 stackDef<<"full">> 대신 stackDef만 넘겼을 때 타입 검사가 잡는가?

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

-- 실수: B'에서 <<"full">>과 <<"impl">>을 빠뜨리고 그냥 stackDef, stackDef를 넘김!
const StackMistake = Trait("Stack", stackDef, stackDef)
type Stack<Self, T> = typeof(StackMistake.Of<<Self, T>>(nil :: any))

type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local a: Arr<number> = nil :: any

-- IsEmpty는 boolean을 반환해야 하므로 string 대입 시 에러여야 함!
local bad1: string = StackMistake.Of(a).IsEmpty(a) -- NEG: 침묵! (never이므로 통과)
local bad2: number = StackMistake.Of(a).IsEmpty(a) -- NEG: 침묵!
local bad3: { [string]: boolean } = StackMistake.Of(a).IsEmpty(a) -- NEG: 침묵!

-- 올바른 B' 표기: stackDef<<"full">>, stackDef<<"impl">>
const StackCorrect = Trait("Stack", stackDef<<"full">>, stackDef<<"impl">>)
local correct_bad1: string = StackCorrect.Of(a).IsEmpty(a) -- NEG: 이것은 잡히는가?

local canary: string = 1
return { bad1, canary, correct_bad1 }


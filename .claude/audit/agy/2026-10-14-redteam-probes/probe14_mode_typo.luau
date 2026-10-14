--!strict
-- probes/probe14_mode_typo.luau
-- B'에서 사용자가 stackDef<<"full">> 대신 오타 stackDef<<"ful">>을 넘겼을 때
-- 타입 검사가 즉시 잡는가, 아니면 쓰는 자리로 오염이 번지는가?

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

-- 오타 1: "full" 대신 "ful"
const StackTypo1 = Trait("Stack", stackDef<<"ful">>, stackDef<<"impl">>) -- NEG: 잡혀야 정상!

-- 오타 2: 둘 다 "full"로 넘김
const StackTypo2 = Trait("Stack", stackDef<<"full">>, stackDef<<"full">>) -- NEG: 잡혀야 정상!

local canary: string = 1
return { canary, StackTypo1, StackTypo2 }

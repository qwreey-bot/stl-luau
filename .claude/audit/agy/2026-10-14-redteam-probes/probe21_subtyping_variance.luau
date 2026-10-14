--!strict
-- probes/probe21_subtyping_variance.luau
-- 서브타이핑 관계가 있는 원소 타입에서 Stack.Of 연산의 불변성 검사

type Item<T> = { read __generics: { read Item: (T) -> T } }
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }

type Base = { name: string }
type Derived = { name: string, extra: number }

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
	return function<Self, T>(of: (Self & Item<T>) | { read name: string })
		return {
			Push = Fn<<(stack: Self, item: T) -> Self>>(),
			Pop = Fn<<(stack: Self) -> T?>>(),
		}
	end
end

const Stack = Trait("Stack", stackDef<<"full">>, stackDef<<"impl">>)

local dList: Arr<Derived> = nil :: any
local ops = Stack.Of(dList)

local bVal: Base = { name = "base" }
local dVal: Derived = { name = "derived", extra = 1 }

-- 1. Derived 리스트에 Derived 넣기: 정상
local ok_push: Arr<Derived> = ops.Push(dList, dVal)

-- 2. Derived 리스트에 부모 타입 Base 넣기: 에러여야 함! (불변성)
local NEG_pushBase = ops.Push(dList, bVal) -- NEG: Base는 Derived의 슈퍼타입이므로 대입 불가!

local canary: string = 1
return { canary, ok_push, NEG_pushBase }

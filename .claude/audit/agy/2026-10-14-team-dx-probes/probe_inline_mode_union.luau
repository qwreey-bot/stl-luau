--!strict
-- probe_inline_mode_union.luau
-- 가설: function(mode: "full" | "impl") 처럼 제네릭 M 없이 유니온으로 받으면?

type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end
local function Trait<F, G>(name: string, def: ((mode: "full") -> F) & ((mode: "impl") -> G)): { read Of: F, read ImplOf: G } return nil :: any end

type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }

const Stack = Trait("Stack", function(mode: "full" | "impl") return function<Self, T>(of: (Self & Item<T>) | Token)
	return {
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
		IsEmpty = Default(mode, function(ops: any) return function(s: Self): boolean return true end end),
	}
	end
end)

local a: Arr<number> = nil :: any
const r1: string = Stack.Of(a).IsEmpty(a) -- NEG: 잡혀야 함!

local canary: string = 1

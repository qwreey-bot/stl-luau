--!strict
-- probe_inline_soundness.luau
-- 목표: 인라인으로 정의를 넘기면서도 같은 모듈 구멍(never)이 생기지 않는 패턴 탐색

type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end

type A = { read __probeA: true }
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end

-- 기준: 기존 v8 (실패해야 함 - r1, r2가 안 잡힘)
local function TraitV8<F, G>(name: string, def: ((mode: "full") -> F) & ((mode: "impl") -> G)): { read Of: F, read ImplOf: G } return nil :: any end

const StackOrig = TraitV8("Stack", function<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return {
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
		IsEmpty = Default(mode, function(ops: any) return function(s: Self): boolean return true end end),
	}
	end
end)

local a: Arr<number> = nil :: any
-- 원래 v8에서 안 잡히던 줄:
const r1_orig: string = StackOrig.Of(a).IsEmpty(a) -- v8에서는 이게 안 잡힘!

local canary: string = 1

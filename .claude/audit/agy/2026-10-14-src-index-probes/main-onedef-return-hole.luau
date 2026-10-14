--!strict
type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }
type Mut<Self, T, M> = index<{ full: Self & Item<T>, impl: Self }, M>
local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end
type A = { read __probeA: true }
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T }, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end

local function stackDef<M>(mode: M)
	return function<Self, T>(of: (Self & ItemRead<T>) | Token)
		return {
			Push = Fn<<(stack: Mut<Self, T, M>, item: T) -> Self>>(),
			Pop = Fn<<(stack: Mut<Self, T, M>) -> T?>>(),
			IsEmpty = Default(mode, function(ops: any) return function(s: Self): boolean return true end end),
		}
	end
end
-- (가) 교집합 인자 하나
local function TraitX<F, G>(name: string, def: ((mode: "full") -> F) & ((mode: "impl") -> G)): { read Of: F, read ImplOf: G } return nil :: any end
const S1 = TraitX("S1", stackDef)
type S1<Self, T> = typeof(S1.Of<<Self, T>>(nil :: any))
type S1Impl<Self, T> = typeof(S1.ImplOf<<Self, T>>(nil :: any))
const r1: S1Impl<Arr<A>, A> = { Push = pushBack, Pop = popBack }
local a: Arr<number> = nil :: any
const e1: boolean = S1.Of(a).IsEmpty(a)
const n1: string = S1.Of(a).IsEmpty(a) -- NEG?
local s = S1.Of(a)
const n2: string = s.IsEmpty(a) -- NEG?
const n3: string = s.Pop(a) -- NEG?
local full: S1<Arr<number>, number> = s
const n4: string = full.IsEmpty(a) -- NEG?
return { n1, n2, n3, n4 }

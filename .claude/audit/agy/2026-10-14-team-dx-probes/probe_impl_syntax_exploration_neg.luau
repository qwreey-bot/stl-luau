--!strict
-- probe_impl_syntax_exploration_neg.luau
type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
local function Fn<F>(): F return nil :: any end
local function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M> return nil :: any end

type A = { read __probeA: true }
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end

local function stackDef<M>(mode: M) return function<Self, T>(of: (Self & Item<T>) | Token)
	return table.freeze({
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
		IsEmpty = Default(mode, function(ops: any) return function(s: Self): boolean return true end end),
	})
	end
end

local dummyImplFactory = stackDef<<"impl">>("impl")
type StackImpl<Self, T> = typeof(dummyImplFactory<<Self, T>>(nil :: any))

type StackTrait = {
	read Of: typeof(stackDef<<"full">>("full")),
	read ImplOf: typeof(dummyImplFactory),
	read ImplFor: <Self, T>(token: Token, impl: StackImpl<Self, T>) -> (),
}

local function makeStackTrait(): StackTrait
	return {
		Of = stackDef<<"full">>("full"),
		ImplOf = dummyImplFactory,
		ImplFor = function(token, impl) end,
	}
end

const Stack = makeStackTrait()

-- NEG 1: 필수 필드 누락 (Pop 누락)
Stack.ImplFor<<Arr<A>, A>>({ name = "ARR" }, { -- NEG 1
	Push = pushBack,
})

local canary: string = 1

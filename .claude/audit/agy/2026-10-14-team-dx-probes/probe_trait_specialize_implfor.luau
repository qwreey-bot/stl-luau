--!strict
-- probe_trait_specialize_implfor.luau
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

type Object<F, G> = {
	read Of: F,
	read ImplOf: G,
	read ImplFor: (token: Token, impl: any) -> (),
}

local function Trait<F, G>(name: string, fullDef: (mode: "full") -> F, implDef: (mode: "impl") -> G): Object<F, G>
	local obj: Object<F, G> = {
		Of = fullDef("full"),
		ImplOf = implDef("impl"),
		ImplFor = function(token, impl) end,
	}
	return obj
end

const rawStack = Trait("Stack", stackDef<<"full">>, stackDef<<"impl">>)

export type Stack<Self, T> = typeof(rawStack.Of<<Self, T>>(nil :: any))
export type StackImpl<Self, T> = typeof(rawStack.ImplOf<<Self, T>>(nil :: any))

local function implFor<Self, T>(token: Token, impl: StackImpl<Self, T>)
	rawStack.ImplFor(token, impl)
end

const Stack = {
	Of = rawStack.Of,
	ImplOf = rawStack.ImplOf,
	ImplFor = implFor,
}

-- 바깥 컨테이너 등록 자리 (한 줄!)
Stack.ImplFor<<Arr<A>, A>>({ name = "ARR" }, {
	Push = pushBack,
	Pop = popBack,
})

local canary: string = 1

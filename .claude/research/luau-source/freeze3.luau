--!strict
local function Fn<F>(): F return nil :: any end
type Token = { read name: string }
type A = { read __probeA: true }
type Arr<T> = { n: number, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end
local function strPush(a: Arr<string>, v: string): Arr<string> return a end
type Object<F> = { read Of: F, read For: <R>(view: (...any) -> R) -> (token: Token, impl: R) -> () }
local function Trait<F>(name: string, factory: F): Object<F> return nil :: any end
const Stack = Trait("Stack", function<Self, T>(of: Self?)
	return table.freeze({
		Push = Fn<<(s: Self, x: T) -> Self>>(),
		Pop = Fn<<(s: Self) -> T?>>(),
	})
end)
local TOK: Token = nil :: any
Stack.For(Stack.Of<<Arr<A>, A>>)(TOK, { Push = pushBack, Pop = popBack })
Stack.For(Stack.Of<<Arr<A>, A>>)(TOK, { Push = strPush, Pop = popBack }) -- NEG
Stack.For(Stack.Of<<Arr<A>, A>>)(TOK, { Push = pushBack }) -- NEG
Stack.For(Stack.Of<<Arr<A>, A>>)(TOK, { Push = pushBack, Pop = popBack, Pek = popBack }) -- 오타 칸?
local canary: string = 1

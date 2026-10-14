--!strict
local function Fn<F>(): F return nil :: any end
type Token = { read name: string }
type A = { read __probeA: true }
type Arr<T> = { n: number, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end
local function strPush(a: Arr<string>, v: string): Arr<string> return a end
-- (가) 증인 함수: ImplFor(토큰, Stack.Of<<…>>, 표)
type Object<F> = { read Of: F, read ImplFor: <R>(token: Token, view: (...any) -> R, impl: R) -> () }
local function Trait<F>(name: string, factory: F): Object<F> return nil :: any end
const Stack = Trait("Stack", function<Self, T>(of: Self?)
	return table.freeze({
		Push = Fn<<(s: Self, x: T) -> Self>>(),
		Pop = Fn<<(s: Self) -> T?>>(),
	})
end)
local TOK: Token = nil :: any
Stack.ImplFor(TOK, Stack.Of<<Arr<A>, A>>, { Push = pushBack, Pop = popBack })
Stack.ImplFor(TOK, Stack.Of<<Arr<A>, A>>, { Push = strPush, Pop = popBack }) -- NEG
Stack.ImplFor(TOK, Stack.Of<<Arr<A>, A>>, { Push = pushBack }) -- NEG
-- (나) 지역 주석(지금 방식)도 그대로 되는가
type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
const t: Stack<Arr<A>, A> = { Push = pushBack, Pop = popBack }
const NEG_t: Stack<Arr<A>, A> = { Push = strPush, Pop = popBack } -- NEG
-- (다) 쓰는 자리: Of 로 꺼낸 표를 부를 수 있나
local a: Arr<number> = nil :: any
Stack.Of(a).Push(a, 1)
Stack.Of(a).Push(a, "x") -- NEG
local canary: string = 1

--!strict
local function Fn<F>(): F return nil :: any end
type A = { read __probeA: true }
type Arr<T> = { n: number, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end
local function strPush(a: Arr<string>, v: string): Arr<string> return a end
local function factory<Self, T>(of: Self?)
	return table.freeze({
		Push = Fn<<(s: Self, x: T) -> Self>>(),
		Pop = Fn<<(s: Self) -> T?>>(),
	})
end
local SHOW: number = factory<<Arr<A>, A>>(nil)
type View<Self, T> = typeof(factory<<Self, T>>(nil))
local function implFor(token: string, impl: View<Arr<A>, A>) end
implFor("x", { Push = pushBack, Pop = popBack })
local canary: string = 1

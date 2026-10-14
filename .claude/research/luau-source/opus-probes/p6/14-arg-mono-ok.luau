--!strict
type A = { read __probeA: true }
type Arr<T> = { n: number, [number]: T }
local function PushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function PopBack<T>(a: Arr<T>): T? return a[a.n] end
local function strPush(a: Arr<string>, v: string): Arr<string> return a end
type Stack<Self, T> = { Push: (Self, T) -> Self, Pop: (Self) -> T? }
type StackR<Self, T> = { read Push: (Self, T) -> Self, read Pop: (Self) -> T? }
local function register(t: Stack<Arr<A>, A>) end
local function registerR(t: StackR<Arr<A>, A>) end
local function registerG<S, T>(t: Stack<S, T>) end
local function registerGR<S, T>(t: StackR<S, T>) end
local function monoPush(a: Arr<A>, v: A): Arr<A> return a end
local function monoPop(a: Arr<A>): A? return nil end
register({ Push = monoPush, Pop = monoPop }) -- 제네릭 아닌 함수는 인자 자리도 됨?

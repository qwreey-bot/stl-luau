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
register({ Push = PushBack, Pop = PopBack })
local f: (Arr<A>, A) -> Arr<A> = PushBack -- 앞의 실패가 캐시를 오염시키면 이것도 실패

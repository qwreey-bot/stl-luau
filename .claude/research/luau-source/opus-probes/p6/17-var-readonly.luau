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
const t: Stack<Arr<A>, A> = { Push = PushBack, Pop = PopBack }
local impl = { Push = PushBack, Pop = PopBack }
registerR(impl) -- 변수에 담은 표 + read 필드

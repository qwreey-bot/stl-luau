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
register({ Push = PushBack<<string>>, Pop = PopBack<<A>> }) -- NEG: 다른 타입 인자
local inst = PushBack<<A>>
local show: number = inst -- 타입 보기용 NEG
register({ Push = PushBack<<A>>, Pop = PopBack }) -- 하나만 명시
local g = { Push = PushBack<<A>>, Pop = PopBack<<A>> }
register(g) -- 변수에 담은 표, 읽기쓰기 필드

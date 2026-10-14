--!strict
type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }

type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T }, [number]: T }
type ArrRead<T> = { read n: number, read __readGenerics: { read Item: () -> T }, read [number]: T }

local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end

type A = { read __probeA: true }

type StackImplWithIntersection<Self, T> = {
	Push: (Self & Item<T>, T) -> Self,
}

type StackImplWithoutIntersection<Self, T> = {
	Push: (Self, T) -> Self,
}

-- test 1: without intersection
local ok: StackImplWithoutIntersection<Arr<A>, A> = { Push = pushBack }

-- test 2: with intersection
local test2: StackImplWithIntersection<Arr<A>, A> = { Push = pushBack }

local canary: string = 1

type Deque<Self, T> = { PushBack: (Self, T) -> Self, PopBack: (Self) -> T?, Back: (Self) -> T? }

local function fromDeque<C, T>(d: Deque<C, T>): StackImplWithIntersection<C, T>
	return { Push = d.PushBack }
end

local function fromDequeWithout<C, T>(d: Deque<C, T>): StackImplWithoutIntersection<C, T>
	return { Push = d.PushBack }
end

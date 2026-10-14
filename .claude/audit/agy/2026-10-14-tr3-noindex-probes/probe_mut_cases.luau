--!strict
type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T }, [number]: T }
type ArrRead<T> = { read n: number, read __readGenerics: { read Item: () -> T }, read [number]: T }

local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end
local function peek<T>(a: ArrRead<T>): T? return nil end
local function len<T>(a: ArrRead<T>): number return a.n end
local function strPush(a: Arr<string>, v: string): Arr<string> return a end

type A = { read __probeA: true }

type StackMut<Self, T> = {
	Push: (Self & Item<T>, T) -> Self,
	Pop: (Self & Item<T>) -> T?,
	Peek: (Self) -> T?,
}

-- test 1: Arr implementation
local reg1: StackMut<Arr<A>, A> = { Push = pushBack, Pop = popBack, Peek = peek }

-- test 2: Deque blanket implementation
type Deque<Self, T> = { PushBack: (Self, T) -> Self, PopBack: (Self) -> T?, Back: (Self) -> T? }
local function fromDeque<C, T>(d: Deque<C, T>): StackMut<C, T>
	return { Push = d.PushBack, Pop = d.PopBack, Peek = d.Back }
end

-- NEG tests
local NEG_missing: StackMut<Arr<A>, A> = { Push = pushBack, Peek = peek } -- NEG
local NEG_pinned: StackMut<Arr<A>, A> = { Push = strPush, Pop = popBack, Peek = peek } -- NEG

local canary: string = 1

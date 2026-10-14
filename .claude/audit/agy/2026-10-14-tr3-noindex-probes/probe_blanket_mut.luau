--!strict
type Token = { read name: string }
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }

type StackMut<Self, T> = {
	Push: (Self & Item<T>, T) -> Self,
	Pop: (Self & Item<T>) -> T?,
	Peek: (Self) -> T?,
}

type Deque<Self, T> = {
	PushFront: (Self & Item<T>, T) -> Self,
	PushBack: (Self & Item<T>, T) -> Self,
	PopFront: (Self & Item<T>) -> T?,
	PopBack: (Self & Item<T>) -> T?,
	Front: (Self) -> T?,
	Back: (Self) -> T?,
}

-- Blanket from Deque
local function stackFromDeque<C, T>(d: Deque<C, T>): StackMut<C, T>
	return {
		Push = d.PushBack,
		Pop = d.PopBack,
		Peek = d.Back,
	}
end

-- What if Deque doesn't have Item<T>?
type PlainDeque<Self, T> = {
	PushFront: (Self, T) -> Self,
	PushBack: (Self, T) -> Self,
	PopFront: (Self) -> T?,
	PopBack: (Self) -> T?,
	Front: (Self) -> T?,
	Back: (Self) -> T?,
}

local function stackFromPlainDeque<C, T>(d: PlainDeque<C, T>): StackMut<C, T>
	return {
		Push = d.PushBack,
		Pop = d.PopBack,
		Peek = d.Back,
	}
end

-- What about passing a concrete function?
type Arr<T> = { n: number, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T }, [number]: T }
local function pushBack<T>(a: Arr<T>, v: T): Arr<T> return a end
local function popBack<T>(a: Arr<T>): T? return nil end
local function peek<T>(a: Arr<T>): T? return nil end
type A = { read __probeA: true }

local s1: StackMut<Arr<A>, A> = {
	Push = pushBack,
	Pop = popBack,
	Peek = peek,
}

-- What if someone defines a function expecting Self & Item<T>?
local function pushBackItem<T>(a: Arr<T> & Item<T>, v: T): Arr<T> return a end
local s2: StackMut<Arr<A>, A> = {
	Push = pushBackItem,
	Pop = popBack,
	Peek = peek,
}

-- What if someone registers a function returning Self?
local canary: string = 1

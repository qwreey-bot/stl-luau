--!strict
-- probe_all_traits.luau: 모든 트레이트(Deque, Stack, Queue, List)에 대한 단일 원천 진입점 타이핑 종합 검증
local stl = require("../src")
type CircularDeque<T> = stl.CircularDeque<T>
type Arr<T> = stl.Arr<T>

type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
type AnyToken = { read name: string }
type A = { read __probeA: true }

local FN_MARK = table.freeze({})
local DEFAULT_MARK = table.freeze({})

local function Fn<F>(): F
	return FN_MARK :: any
end

local function Default<F>(build: any): F
	return table.freeze({ [DEFAULT_MARK] = build }) :: any
end

-- ==========================================
-- 1. 트레이트 정의: Deque
-- ==========================================
const DequeEntries = {
	PushFront = Fn<< <Self, T>(deque: Self & Item<T>, item: T) -> Self >>(),
	PushBack = Fn<< <Self, T>(deque: Self & Item<T>, item: T) -> Self >>(),
	PopFront = Fn<< <Self, T>(deque: Self & Item<T>) -> T? >>(),
	PopBack = Fn<< <Self, T>(deque: Self & Item<T>) -> T? >>(),
	Front = Fn<< <Self, T>(deque: Self & Item<T>) -> T? >>(),
	Back = Fn<< <Self, T>(deque: Self & Item<T>) -> T? >>(),
}
export type Deque<Self, T> = {
	PushFront: typeof(DequeEntries.PushFront<<Self, T>>),
	PushBack: typeof(DequeEntries.PushBack<<Self, T>>),
	PopFront: typeof(DequeEntries.PopFront<<Self, T>>),
	PopBack: typeof(DequeEntries.PopBack<<Self, T>>),
	Front: typeof(DequeEntries.Front<<Self, T>>),
	Back: typeof(DequeEntries.Back<<Self, T>>),
}
type DequeObject = typeof(DequeEntries) & {
	Of: <Self, T>(of: (Self & Item<T>) | AnyToken) -> Deque<Self, T>,
	FnTok: { [string]: number },
}
const Deque: DequeObject = nil :: any

-- ==========================================
-- 2. 트레이트 정의: Stack
-- ==========================================
const StackEntries = {
	Push = Fn<< <Self, T>(stack: Self & Item<T>, item: T) -> Self >>(),
	Pop = Fn<< <Self, T>(stack: Self & Item<T>) -> T? >>(),
	Peek = Default<< <Self, T>(stack: Self & Item<T>) -> T? >>(function(ops: any)
		return nil
	end),
}
export type Stack<Self, T> = {
	Push: typeof(StackEntries.Push<<Self, T>>),
	Pop: typeof(StackEntries.Pop<<Self, T>>),
	Peek: typeof(StackEntries.Peek<<Self, T>>),
}
type StackObject = typeof(StackEntries) & {
	Of: <Self, T>(of: (Self & Item<T>) | AnyToken) -> Stack<Self, T>,
	FnTok: { [string]: number },
}
const Stack: StackObject = nil :: any

-- ==========================================
-- 3. 트레이트 정의: List (기본 구현 IndexOf, Contains, Fold 포함)
-- ==========================================
const ListEntries = {
	Get = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> E? >>(),
	FirstIndex = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>) -> I? >>(),
	LastIndex = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>) -> I? >>(),
	NextIndex = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> I? >>(),
	PrevIndex = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, idx: I) -> I? >>(),
	IndexOf = Default<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(function(ops: any)
		return nil
	end),
	Contains = Default<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> boolean >>(function(ops: any)
		return nil
	end),
	Fold = Default<< <Self, E, I, U>(list: Self & ItemIndex<E, I>, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U >>(function(ops: any)
		return nil
	end),
}
export type List<Self, E, I> = {
	Get: typeof(ListEntries.Get<<Self, E, I>>),
	FirstIndex: typeof(ListEntries.FirstIndex<<Self, E, I>>),
	LastIndex: typeof(ListEntries.LastIndex<<Self, E, I>>),
	NextIndex: typeof(ListEntries.NextIndex<<Self, E, I>>),
	PrevIndex: typeof(ListEntries.PrevIndex<<Self, E, I>>),
	IndexOf: typeof(ListEntries.IndexOf<<Self, E, I>>),
	Contains: typeof(ListEntries.Contains<<Self, E, I>>),
	Fold: typeof(ListEntries.Fold<<Self, E, I, any>>),
}
type ListObject = typeof(ListEntries) & {
	Of: <Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken) -> List<Self, E, I>,
	FnTok: { [string]: number },
}
const List: ListObject = nil :: any

-- ==========================================
-- 테스트 데이터 준비
-- ==========================================
type MyDeque<T> = {
	items: { T },
	read __generics: { read Item: (T) -> T, read Index: (number) -> number },
}
local d: MyDeque<number> = nil :: any

-- [[ 진입점 테스트 ]]
-- 정상 진입점 호출
local pushed: MyDeque<number> = Stack.Push(d, 4)
local popped: number? = Stack.Pop(d)
local peeked: number? = Stack.Peek(d)
local at: number? = List.IndexOf(d, 2)
local has: boolean = List.Contains(d, 3)

-- NEG 1: 진입점 Stack.Push 원소 타입 오류 (v4에서는 any라 놓쳤던 것!)
local NEG_entry_push = Stack.Push(d, "wrong") -- NEG
-- NEG 2: 진입점 Stack.Pop 반환 타입 불일치
local NEG_entry_pop: string? = Stack.Pop(d) -- NEG
-- NEG 3: 진입점 List.IndexOf 원소 타입 불일치
local NEG_entry_idx = List.IndexOf(d, "wrong") -- NEG
-- NEG 4: 진입점 List.Contains 원소 타입 불일치
local NEG_entry_has = List.Contains(d, "wrong") -- NEG

-- [[ Of 테스트 ]]
local s = Stack.Of(d)
local s_pushed: MyDeque<number> = s.Push(d, 5)
local s_popped: number? = s.Pop(d)

-- NEG 5: s.Push 원소 타입 오류
local NEG_s_push = s.Push(d, "wrong") -- NEG
-- NEG 6: s.Pop 반환 타입 오류
local NEG_s_pop: string? = s.Pop(d) -- NEG
-- NEG 7: Of에 잘못된 타입 주장
local NEG_claim = Stack.Of<<MyDeque<number>, string>>(d) -- NEG

-- [[ 뭉텅이 구현 테스트 ]]
local function stackFromDeque<C, T>(deque: Deque<C, T>): Stack<C, T>
	return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
end

-- NEG 8: 뭉텅이 구현에서 필드 불일치 (Pop 자리에 PushFront)
local function badStack<C, T>(deque: Deque<C, T>): Stack<C, T>
	return { Push = deque.PushBack, Pop = deque.PushFront, Peek = deque.Back } -- NEG
end

-- [[ 탐침 등록 테스트 ]]
local function strPush(self: MyDeque<string>, item: string): MyDeque<string>
	return self
end
-- NEG 9: 원소를 못박은 함수 등록 차단
local NEG_pinned: Stack<MyDeque<A>, A> = { -- NEG
	Push = strPush,
	Pop = nil :: any,
	Peek = nil :: any,
}

local canary: string = 1

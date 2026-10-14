--!strict
--[[
	시제품 v5 위의 트레이트 넷과 등록. v4 의 `Traits.luau` 와 나란히 놓고 보세요 — 바뀐 자리는 셋입니다.

	- 정의: 팩토리를 **모드 `M` 을 받는 한 겹**(`dequeDef<M>(mode: M)`)으로 감싸고 `Trait.Trait(이름, def, def)` — 같은 정의를 두 번(솔버가 받는 자리에서 두 모드를 알아냄).
	  쓰는 함수의 self 는 `Mut<Self, T, M>`, 기본 구현은 `Default(mode, 빌더)`. 팩토리는 읽기 연관 타입(`ItemRead`)으로 받음.
	- 구현: 등록 표는 `XImpl<…>`(등록 보기) 주석을 단 지역 변수 — **기본 구현 칸은 안 적으면 기본 구현**(`Inherit` 없음).
	- 등록 호출은 트레이트 객체에서: `Deque.ImplFor(CD, cdDeque)`, `Stack.ImplWhere({ Deque }, …)`.
]]
local Trait = require("./Trait")
local stl = require("../../../src")

type CircularDeque<T> = stl.CircularDeque<T>
type LinkedDeque<T> = stl.LinkedDeque<T>
type Arr<T> = stl.Arr<T>
type ArrRead<T> = stl.ArrRead<T>
type ItemRead<T> = Trait.ItemRead<T>
type ItemIndexRead<E, I> = Trait.ItemIndexRead<E, I>
type Mut<Self, T, M> = Trait.Mut<Self, T, M>
type AnyToken = Trait.AnyToken
type A = Trait.A

const Fn, Default = Trait.Fn, Trait.Default
const CircularDequeModule, LinkedDequeModule, ArrModule = stl.CircularDeque, stl.LinkedDeque, stl.Arr

--[[ 토큰 — 우리 것은 `Stl.` ]]
const CD = Trait.Token("Stl.CircularDeque")
const LD = Trait.Token("Stl.LinkedDeque")
const ARR = Trait.Token("Stl.Arr")

--[[ 정의 ]]

local function dequeDef<M>(mode: M)
	return function<Self, T>(of: (Self & ItemRead<T>) | AnyToken)
		return {
			PushFront = Fn<<(deque: Mut<Self, T, M>, item: T) -> Self>>(),
			PushBack = Fn<<(deque: Mut<Self, T, M>, item: T) -> Self>>(),
			PopFront = Fn<<(deque: Mut<Self, T, M>) -> T?>>(),
			PopBack = Fn<<(deque: Mut<Self, T, M>) -> T?>>(),
			Front = Fn<<(deque: Self) -> T?>>(),
			Back = Fn<<(deque: Self) -> T?>>(),
		}
	end
end
const Deque = Trait.Trait("Deque", dequeDef, dequeDef)
export type Deque<Self, T> = typeof(Deque.Of<<Self, T>>(nil :: any))
export type DequeImpl<Self, T> = typeof(Deque.ImplOf<<Self, T>>(nil :: any))

local function stackDef<M>(mode: M)
	return function<Self, T>(of: (Self & ItemRead<T>) | AnyToken)
		return {
			Push = Fn<<(stack: Mut<Self, T, M>, item: T) -> Self>>(),
			Pop = Fn<<(stack: Mut<Self, T, M>) -> T?>>(),
			Peek = Fn<<(stack: Self) -> T?>>(),
		}
	end
end
const Stack = Trait.Trait("Stack", stackDef, stackDef)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))

local function queueDef<M>(mode: M)
	return function<Self, T>(of: (Self & ItemRead<T>) | AnyToken)
		return {
			Push = Fn<<(queue: Mut<Self, T, M>, item: T) -> Self>>(),
			Pop = Fn<<(queue: Mut<Self, T, M>) -> T?>>(),
			Peek = Fn<<(queue: Self) -> T?>>(),
		}
	end
end
const Queue = Trait.Trait("Queue", queueDef, queueDef)
export type Queue<Self, T> = typeof(Queue.Of<<Self, T>>(nil :: any))
export type QueueImpl<Self, T> = typeof(Queue.ImplOf<<Self, T>>(nil :: any))

-- 기본 구현은 빌더로. 빌더가 받는 `ops` 는 그 종류의 완성 표(구현이 준 것 + 다른 기본 구현) — 지역으로 붙잡아도 됨.
-- 리스트는 읽기만 하는 트레이트라 `Mut` 이 없음(빌린 참조도 전부 씀)
local function listDef<M>(mode: M)
	return function<Self, E, I>(of: (Self & ItemIndexRead<E, I>) | AnyToken)
		return {
			Get = Fn<<(list: Self, idx: I) -> E?>>(),
			FirstIndex = Fn<<(list: Self) -> I?>>(),
			LastIndex = Fn<<(list: Self) -> I?>>(),
			NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),
			PrevIndex = Fn<<(list: Self, idx: I) -> I?>>(),
			IndexOf = Default(mode, function(ops: List<Self, E, I>)
				const get, firstIndex, nextIndex = ops.Get, ops.FirstIndex, ops.NextIndex
				return function(list: Self, item: E): I?
					local idx = firstIndex(list)
					while idx ~= nil do
						if get(list, idx) == item then
							return idx
						end
						idx = nextIndex(list, idx)
					end
					return nil
				end
			end),
			Contains = Default(mode, function(ops: List<Self, E, I>)
				const indexOf = ops.IndexOf -- 형제 기본 구현(재정의됐으면 그것)
				return function(list: Self, item: E): boolean
					return indexOf(list, item) ~= nil
				end
			end),
			Fold = Default(mode, function(ops: List<Self, E, I>)
				const get, firstIndex, nextIndex = ops.Get, ops.FirstIndex, ops.NextIndex
				return function<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U): U
					local acc, idx = init, firstIndex(list)
					while idx ~= nil do
						acc = fn(acc, get(list, idx) :: E, idx)
						idx = nextIndex(list, idx)
					end
					return acc
				end
			end),
		}
	end
end
const List = Trait.Trait("List", listDef, listDef)
export type List<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))
export type ListImpl<Self, E, I> = typeof(List.ImplOf<<Self, E, I>>(nil :: any))

--[[ 뭉텅이 구현 — 몸통을 등록 보기의 제네릭 함수로(모양·인자 수는 검사됨, 원소를 못박은 함수는 몸통 결함으로 0건 — AA 3번) ]]
local function stackFromDeque<C, T>(deque: DequeImpl<C, T>): StackImpl<C, T>
	return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
end
Stack.ImplWhere({ Deque }, function(deps)
	return stackFromDeque(deps[Deque])
end)
local function queueFromDeque<C, T>(deque: DequeImpl<C, T>): QueueImpl<C, T>
	return { Push = deque.PushBack, Pop = deque.PopFront, Peek = deque.Front }
end
Queue.ImplWhere({ Deque }, function(deps)
	return queueFromDeque(deps[Deque])
end)

--[[ 등록 — 탐침 타입 A 로 주석을 단 지역 변수(등록 보기) ]]
const cdDeque: DequeImpl<CircularDeque<A>, A> = {
	PushFront = CircularDequeModule.PushFront,
	PushBack = CircularDequeModule.PushBack,
	PopFront = CircularDequeModule.PopFront,
	PopBack = CircularDequeModule.PopBack,
	Front = CircularDequeModule.Front,
	Back = CircularDequeModule.Back,
}
Deque.ImplFor(CD, cdDeque)
-- 기본 구현 셋(IndexOf·Contains·Fold)은 안 적음 = 기본 구현
const cdList: ListImpl<CircularDeque<A>, A, number> = {
	Get = CircularDequeModule.Get,
	FirstIndex = CircularDequeModule.FirstIndex,
	LastIndex = CircularDequeModule.LastIndex,
	NextIndex = CircularDequeModule.NextIndex,
	PrevIndex = CircularDequeModule.PrevIndex,
}
List.ImplFor(CD, cdList)

const ldDeque: DequeImpl<LinkedDeque<A>, A> = {
	PushFront = LinkedDequeModule.PushFront,
	PushBack = LinkedDequeModule.PushBack,
	PopFront = LinkedDequeModule.PopFront,
	PopBack = LinkedDequeModule.PopBack,
	Front = LinkedDequeModule.Front,
	Back = LinkedDequeModule.Back,
}
Deque.ImplFor(LD, ldDeque)

-- Arr: 리스트(기본 구현 셋을 자기 직접 구현으로 재정의 — 적으면 재정의) + 스택(덱이 아니어도)
const arrList: ListImpl<Arr<A>, A, number> = {
	Get = ArrModule.Get,
	FirstIndex = ArrModule.FirstIndex,
	LastIndex = ArrModule.LastIndex,
	NextIndex = ArrModule.NextIndex,
	PrevIndex = ArrModule.PrevIndex,
	IndexOf = ArrModule.IndexOf,
	Contains = ArrModule.Contains,
	Fold = ArrModule.Fold,
}
List.ImplFor(ARR, arrList)
const function arrPeek<T>(self: ArrRead<T>): T?
	return self[self.n]
end
const arrStack: StackImpl<Arr<A>, A> = { Push = ArrModule.PushBack, Pop = ArrModule.PopBack, Peek = arrPeek }
Stack.ImplFor(ARR, arrStack)

--[[ 중개자 Into — 둘 다 아는 이 자리에서 찾기 함수에 정확한 타입만(비용 0, 감싸는 함수 없음) ]]
const arrIntoStack: <T>(a: Arr<T>) -> Stack<Arr<T>, T> = Stack.Of :: any
const Into = { ArrStack = arrIntoStack }

-- 값에 이 시제품의 토큰을 붙임(같은 자료, `__type` 만)
const Kinds = { CD = CD, LD = LD, ARR = ARR }
function Kinds.tag<V>(value: V, token: any): V
	(value :: any).__type = token
	return value
end

-- stylua: ignore
return {
	Trait = Trait, Deque = Deque, Stack = Stack, Queue = Queue, List = List, Into = Into, Kinds = Kinds,
}

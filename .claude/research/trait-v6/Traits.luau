--!strict
--[[
	시제품 v6 위의 트레이트 넷과 등록. v4 의 같은 파일과 나란히 보세요 — 정의의 모양은 v4 그대로이고 바뀐 곳은 셋입니다.

	- 리스트(읽기만 하는 트레이트)의 팩토리가 `ItemIndexRead` 로 받음 → 빌린 참조도 `List.Of`. 덱·스택·큐는 `Item` 그대로
	  (쓰는 함수가 있어서 빌린 참조는 아예 못 얻음).
	- 등록은 트레이트 객체에서: `Deque.ImplFor(CD, cdDeque)`, `Stack.ImplWhere({ Deque }, …)`.
	- 뭉텅이 몸통은 탐침 타입으로(`Deque<A, B> → Stack<A, B>`) — 원소를 못박은 함수까지 잡힘.
]]
local Trait = require("./Trait")
local stl = require("../../../src")

type CircularDeque<T> = stl.CircularDeque<T>
type LinkedDeque<T> = stl.LinkedDeque<T>
type Arr<T> = stl.Arr<T>
type ArrRead<T> = stl.ArrRead<T>
type Item<T> = Trait.Item<T>
type ItemIndexRead<E, I> = Trait.ItemIndexRead<E, I>
type AnyToken = Trait.AnyToken
type A = Trait.A
type B = Trait.B

const Fn, Default = Trait.Fn, Trait.Default
const CircularDequeModule, LinkedDequeModule, ArrModule = stl.CircularDeque, stl.LinkedDeque, stl.Arr

--[[ 토큰 — 우리 것은 `Stl.` ]]
const CD = Trait.Token("Stl.CircularDeque")
const LD = Trait.Token("Stl.LinkedDeque")
const ARR = Trait.Token("Stl.Arr")

--[[ 정의 ]]

const Deque = Trait.Trait("Deque", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return {
		PushFront = Fn<<(deque: Self, item: T) -> Self>>(),
		PushBack = Fn<<(deque: Self, item: T) -> Self>>(),
		PopFront = Fn<<(deque: Self) -> T?>>(),
		PopBack = Fn<<(deque: Self) -> T?>>(),
		Front = Fn<<(deque: Self) -> T?>>(),
		Back = Fn<<(deque: Self) -> T?>>(),
	}
end)
export type Deque<Self, T> = typeof(Deque.Of<<Self, T>>(nil :: any))

const Stack = Trait.Trait("Stack", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return {
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
		Peek = Fn<<(stack: Self) -> T?>>(),
	}
end)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))

const Queue = Trait.Trait("Queue", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return {
		Push = Fn<<(queue: Self, item: T) -> Self>>(),
		Pop = Fn<<(queue: Self) -> T?>>(),
		Peek = Fn<<(queue: Self) -> T?>>(),
	}
end)
export type Queue<Self, T> = typeof(Queue.Of<<Self, T>>(nil :: any))

-- 기본 구현은 빌더로. 빌더가 받는 `ops` 는 그 종류의 완성 표(구현이 준 것 + 다른 기본 구현) — 지역으로 붙잡아도 됨
-- 읽기만 하는 트레이트: 공변 연관 타입으로 받아 빌린 참조(`ArrRead` 등)도 꺼냄
const List = Trait.Trait("List", function<Self, E, I>(of: (Self & ItemIndexRead<E, I>) | AnyToken)
	return {
		Get = Fn<<(list: Self, idx: I) -> E?>>(),
		FirstIndex = Fn<<(list: Self) -> I?>>(),
		LastIndex = Fn<<(list: Self) -> I?>>(),
		NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),
		PrevIndex = Fn<<(list: Self, idx: I) -> I?>>(),
		IndexOf = Default(function(ops: List<Self, E, I>)
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
		Contains = Default(function(ops: List<Self, E, I>)
			const indexOf = ops.IndexOf -- 형제 기본 구현(재정의됐으면 그것)
			return function(list: Self, item: E): boolean
				return indexOf(list, item) ~= nil
			end
		end),
		Fold = Default(function(ops: List<Self, E, I>)
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
end)
export type List<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))

--[[ 뭉텅이 구현 — 몸통을 탐침 타입(A = 종류, B = 원소)으로: 제네릭 `<C, T>` 로 짜면 몸통 결함(AA 3번)으로 원소를 못박은
     함수가 0건이었음. 런타임은 타입을 안 보니 어느 종류에나 그대로 ]]
local function stackFromDeque(deque: Deque<A, B>): Stack<A, B>
	return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
end
Stack.ImplWhere({ Deque }, function(deps)
	return stackFromDeque(deps[Deque])
end)
local function queueFromDeque(deque: Deque<A, B>): Queue<A, B>
	return { Push = deque.PushBack, Pop = deque.PopFront, Peek = deque.Front }
end
Queue.ImplWhere({ Deque }, function(deps)
	return queueFromDeque(deps[Deque])
end)

--[[ 등록 — 탐침 타입 A 로 주석을 단 지역 변수 ]]
const cdDeque: Deque<CircularDeque<A>, A> = {
	PushFront = CircularDequeModule.PushFront,
	PushBack = CircularDequeModule.PushBack,
	PopFront = CircularDequeModule.PopFront,
	PopBack = CircularDequeModule.PopBack,
	Front = CircularDequeModule.Front,
	Back = CircularDequeModule.Back,
}
Deque.ImplFor(CD, cdDeque)
const cdList: List<CircularDeque<A>, A, number> = {
	Get = CircularDequeModule.Get,
	FirstIndex = CircularDequeModule.FirstIndex,
	LastIndex = CircularDequeModule.LastIndex,
	NextIndex = CircularDequeModule.NextIndex,
	PrevIndex = CircularDequeModule.PrevIndex,
	IndexOf = Trait.Inherit,
	Contains = Trait.Inherit,
	Fold = Trait.Inherit,
}
List.ImplFor(CD, cdList)

const ldDeque: Deque<LinkedDeque<A>, A> = {
	PushFront = LinkedDequeModule.PushFront,
	PushBack = LinkedDequeModule.PushBack,
	PopFront = LinkedDequeModule.PopFront,
	PopBack = LinkedDequeModule.PopBack,
	Front = LinkedDequeModule.Front,
	Back = LinkedDequeModule.Back,
}
Deque.ImplFor(LD, ldDeque)

-- Arr: 리스트(기본 구현 셋을 자기 직접 구현으로 재정의) + 스택(덱이 아니어도)
const arrList: List<Arr<A>, A, number> = {
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
const arrStack: Stack<Arr<A>, A> = { Push = ArrModule.PushBack, Pop = ArrModule.PopBack, Peek = arrPeek }
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

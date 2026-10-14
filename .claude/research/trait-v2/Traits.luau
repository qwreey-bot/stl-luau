--!strict
--[[
	시제품 v2 위의 트레이트 넷과 등록 — 나중에 `src/Traits/*` 가 될 모양.

	- 시그니처 표 하나가 런타임 이름 목록이자 진입점 타입이고, `For<…>` 별칭(타입 함수)이 등록 검사용 모양입니다.
	- `Stack`·`Queue` 는 `Deque` 의 **뭉텅이 구현**(`Where`)으로 따라오고, `Arr` 는 `For` 로 직접 스택이 됩니다.
	- `src` 의 컨테이너 함수를 그대로 쓰고, 값에는 이 시제품의 토큰을 붙입니다(`Kinds.tag`).
]]
local Trait = require("./Trait")
local Fill = require("./Trait/Fill")
local stl = require("../../../src")

type CircularDeque<T> = stl.CircularDeque<T>
type LinkedDeque<T> = stl.LinkedDeque<T>
type Arr<T> = stl.Arr<T>
type ArrRead<T> = stl.ArrRead<T>
type DequeMarker<T> = stl.DequeMarker<T>
type DequeMarkerMut<T> = stl.DequeMarkerMut<T>
type ListMarker<E, I> = stl.ListMarker<E, I>

const Fn, Default = Trait.Fn, Trait.Default
const CircularDequeModule, LinkedDequeModule, ArrModule = stl.CircularDeque, stl.LinkedDeque, stl.Arr

--[[ 토큰 — 우리 것은 `Stl.` ]]
const CD = Trait.Token("Stl.CircularDeque")
const LD = Trait.Token("Stl.LinkedDeque")
const ARR = Trait.Token("Stl.Arr")

--[[ Deque — 필수 여섯 ]]
const dequeFns = {
	PushFront = Fn<<<Self, T>(deque: Self & DequeMarkerMut<T>, item: T) -> Self>>(),
	PushBack = Fn<<<Self, T>(deque: Self & DequeMarkerMut<T>, item: T) -> Self>>(),
	PopFront = Fn<<<Self, T>(deque: Self & DequeMarkerMut<T>) -> T?>>(),
	PopBack = Fn<<<Self, T>(deque: Self & DequeMarkerMut<T>) -> T?>>(),
	Front = Fn<<<Self, T>(deque: Self & DequeMarker<T>) -> T?>>(),
	Back = Fn<<<Self, T>(deque: Self & DequeMarker<T>) -> T?>>(),
}
export type DequeFor<Self, T> = Fill.FillGenerics<typeof(dequeFns), { Self: Self, T: T }>
const Deque = Trait.Trait("Deque", dequeFns)

--[[ Stack — 필수 셋, 덱이면 뭉텅이 구현으로 따라옴(덱의 함수 그대로) ]]
const stackFns = {
	Push = Fn<<<Self, T>(stack: Self & DequeMarkerMut<T>, item: T) -> Self>>(),
	Pop = Fn<<<Self, T>(stack: Self & DequeMarkerMut<T>) -> T?>>(),
	Peek = Fn<<<Self, T>(stack: Self & DequeMarker<T>) -> T?>>(),
}
export type StackFor<Self, T> = Fill.FillGenerics<typeof(stackFns), { Self: Self, T: T }>
const Stack = Trait.Trait("Stack", stackFns)
Trait.Impl(Stack):Where({ Deque })(function(deps)
	const deque = deps[Deque]
	return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
end)

const queueFns = {
	Push = Fn<<<Self, T>(queue: Self & DequeMarkerMut<T>, item: T) -> Self>>(),
	Pop = Fn<<<Self, T>(queue: Self & DequeMarkerMut<T>) -> T?>>(),
	Peek = Fn<<<Self, T>(queue: Self & DequeMarker<T>) -> T?>>(),
}
const Queue = Trait.Trait("Queue", queueFns)
Trait.Impl(Queue):Where({ Deque })(function(deps)
	const deque = deps[Deque]
	return { Push = deque.PushBack, Pop = deque.PopFront, Peek = deque.Front }
end)

--[[ List — 필수 다섯 + 기본 구현 셋(만들 때 붙잡음, 같은 트레이트의 다른 기본 구현은 `ops.X or 내것`) ]]
const listFns = {
	Get = Fn<<<Self, E, I>(list: Self & ListMarker<E, I>, idx: I) -> E?>>(),
	FirstIndex = Fn<<<Self, E, I>(list: Self & ListMarker<E, I>) -> I?>>(),
	LastIndex = Fn<<<Self, E, I>(list: Self & ListMarker<E, I>) -> I?>>(),
	NextIndex = Fn<<<Self, E, I>(list: Self & ListMarker<E, I>, idx: I) -> I?>>(),
	PrevIndex = Fn<<<Self, E, I>(list: Self & ListMarker<E, I>, idx: I) -> I?>>(),
	Fold = Default<<<Self, E, I, U>(
		list: Self & ListMarker<E, I>,
		init: U,
		fn: (acc: U, item: E, idx: I, ...any) -> U
	) -> U>>(),
	IndexOf = Default<<<Self, E, I>(list: Self & ListMarker<E, I>, item: E) -> I?>>(),
	Contains = Default<<<Self, E, I>(list: Self & ListMarker<E, I>, item: E) -> boolean>>(),
}
export type ListFor<Self, E, I> = Fill.FillGenerics<typeof(listFns), { Self: Self, E: E, I: I }>
const List = Trait.Trait("List", listFns, function(ops: any)
	const get, firstIndex, nextIndex = ops.Get, ops.FirstIndex, ops.NextIndex
	const function IndexOf(self: any, item: any): any
		local idx = firstIndex(self)
		while idx ~= nil do
			if get(self, idx) == item then
				return idx
			end
			idx = nextIndex(self, idx)
		end
		return nil
	end
	const indexOf: (any, any) -> any = ops.IndexOf or IndexOf
	return {
		Fold = function(self: any, init: any, fn: (any, any, any) -> any): any
			local acc, idx = init, firstIndex(self)
			while idx ~= nil do
				acc = fn(acc, get(self, idx), idx)
				idx = nextIndex(self, idx)
			end
			return acc
		end,
		IndexOf = IndexOf,
		Contains = function(self: any, item: any): boolean
			return indexOf(self, item) ~= nil
		end,
	}
end)

--[[ 등록 — 표는 `…For<구체 타입>` 주석을 단 지역 변수(그래야 검사가 섬) ]]
const cdDeque: DequeFor<CircularDeque<string>, string> = {
	PushFront = CircularDequeModule.PushFront,
	PushBack = CircularDequeModule.PushBack,
	PopFront = CircularDequeModule.PopFront,
	PopBack = CircularDequeModule.PopBack,
	Front = CircularDequeModule.Front,
	Back = CircularDequeModule.Back,
}
Trait.Impl(Deque):For(CD)(cdDeque)
const cdList: ListFor<CircularDeque<string>, string, number> = {
	Get = CircularDequeModule.Get,
	FirstIndex = CircularDequeModule.FirstIndex,
	LastIndex = CircularDequeModule.LastIndex,
	NextIndex = CircularDequeModule.NextIndex,
	PrevIndex = CircularDequeModule.PrevIndex,
}
Trait.Impl(List):For(CD)(cdList)

const ldDeque: DequeFor<LinkedDeque<string>, string> = {
	PushFront = LinkedDequeModule.PushFront,
	PushBack = LinkedDequeModule.PushBack,
	PopFront = LinkedDequeModule.PopFront,
	PopBack = LinkedDequeModule.PopBack,
	Front = LinkedDequeModule.Front,
	Back = LinkedDequeModule.Back,
}
Trait.Impl(Deque):For(LD)(ldDeque)

-- Arr: 리스트(일곱 중 셋을 자기 직접 구현으로 재정의) + **스택**(덱이 아니어도 For 로 — 예전 틀에선 못 하던 것)
const arrList: ListFor<Arr<string>, string, number> = {
	Get = ArrModule.Get,
	FirstIndex = ArrModule.FirstIndex,
	LastIndex = ArrModule.LastIndex,
	NextIndex = ArrModule.NextIndex,
	PrevIndex = ArrModule.PrevIndex,
	Fold = ArrModule.Fold,
	IndexOf = ArrModule.IndexOf,
	Contains = ArrModule.Contains,
}
Trait.Impl(List):For(ARR)(arrList)
const function arrPeek<T>(self: ArrRead<T>): T?
	return self[self.n]
end
const arrStack: StackFor<Arr<string>, string> = {
	Push = ArrModule.PushBack,
	Pop = ArrModule.PopBack,
	Peek = arrPeek,
}
Trait.Impl(Stack):For(ARR)(arrStack)

-- 값에 이 시제품의 토큰을 붙임(같은 자료, `__type` 만)
const Kinds = { CD = CD, LD = LD, ARR = ARR }
function Kinds.tag<V>(value: V, token: any): V
	(value :: any).__type = token
	return value
end

-- stylua: ignore
return {
	Trait = Trait, Deque = Deque, Stack = Stack, Queue = Queue, List = List, Kinds = Kinds,
}

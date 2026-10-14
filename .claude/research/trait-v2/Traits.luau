--!strict
--[[
	시제품 v2 위의 트레이트 넷과 등록 — 나중에 `src/Traits/*` 가 될 모양.

	- 시그니처 표 하나가 런타임 이름 목록이자 진입점 타입입니다. 원소·위치는 **연관 타입 표식**(`UseGeneric<Item>`)으로
	  적고, `Fn` 이 역추론되는 모양으로 바꿔 끼웁니다. 등록 표는 `Fill.ImplFor<typeof(fns), 구체 종류>` 로 검사합니다.
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
type UseGeneric<Tag> = Fill.UseGeneric<Tag>
type Item = Fill.Item
type Index = Fill.Index

const Fn, Default = Trait.Fn, Trait.Default
const CircularDequeModule, LinkedDequeModule, ArrModule = stl.CircularDeque, stl.LinkedDeque, stl.Arr

--[[ 토큰 — 우리 것은 `Stl.` ]]
const CD = Trait.Token("Stl.CircularDeque")
const LD = Trait.Token("Stl.LinkedDeque")
const ARR = Trait.Token("Stl.Arr")

--[[ Deque — 필수 여섯 ]]
const dequeFns = {
	PushFront = Fn<<<Self>(deque: Self, item: UseGeneric<Item>) -> Self>>(),
	PushBack = Fn<<<Self>(deque: Self, item: UseGeneric<Item>) -> Self>>(),
	PopFront = Fn<<<Self>(deque: Self) -> UseGeneric<Item>?>>(),
	PopBack = Fn<<<Self>(deque: Self) -> UseGeneric<Item>?>>(),
	Front = Fn<<<Self>(deque: Self) -> UseGeneric<Item>?>>(),
	Back = Fn<<<Self>(deque: Self) -> UseGeneric<Item>?>>(),
}
export type DequeFor<S> = Fill.ImplFor<typeof(dequeFns), S>
const Deque = Trait.Trait("Deque", dequeFns)

--[[ Stack — 필수 셋, 덱이면 뭉텅이 구현으로 따라옴(덱의 함수 그대로) ]]
const stackFns = {
	Push = Fn<<<Self>(stack: Self, item: UseGeneric<Item>) -> Self>>(),
	Pop = Fn<<<Self>(stack: Self) -> UseGeneric<Item>?>>(),
	Peek = Fn<<<Self>(stack: Self) -> UseGeneric<Item>?>>(),
}
export type StackFor<S> = Fill.ImplFor<typeof(stackFns), S>
const Stack = Trait.Trait("Stack", stackFns)
Trait.Impl(Stack):Where({ Deque })(function(deps)
	const deque = deps[Deque]
	return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
end)

const queueFns = {
	Push = Fn<<<Self>(queue: Self, item: UseGeneric<Item>) -> Self>>(),
	Pop = Fn<<<Self>(queue: Self) -> UseGeneric<Item>?>>(),
	Peek = Fn<<<Self>(queue: Self) -> UseGeneric<Item>?>>(),
}
const Queue = Trait.Trait("Queue", queueFns)
Trait.Impl(Queue):Where({ Deque })(function(deps)
	const deque = deps[Deque]
	return { Push = deque.PushBack, Pop = deque.PopFront, Peek = deque.Front }
end)

--[[ List — 필수 다섯 + 기본 구현 셋(만들 때 붙잡음, 같은 트레이트의 다른 기본 구현은 `ops.X or 내것`) ]]
const listFns = {
	Get = Fn<<<Self>(list: Self, idx: UseGeneric<Index>) -> UseGeneric<Item>?>>(),
	FirstIndex = Fn<<<Self>(list: Self) -> UseGeneric<Index>?>>(),
	LastIndex = Fn<<<Self>(list: Self) -> UseGeneric<Index>?>>(),
	NextIndex = Fn<<<Self>(list: Self, idx: UseGeneric<Index>) -> UseGeneric<Index>?>>(),
	PrevIndex = Fn<<<Self>(list: Self, idx: UseGeneric<Index>) -> UseGeneric<Index>?>>(),
	Fold = Default<<<Self, U>(
		list: Self,
		init: U,
		fn: (acc: U, item: UseGeneric<Item>, idx: UseGeneric<Index>, ...any) -> U
	) -> U>>(),
	IndexOf = Default<<<Self>(list: Self, item: UseGeneric<Item>) -> UseGeneric<Index>?>>(),
	Contains = Default<<<Self>(list: Self, item: UseGeneric<Item>) -> boolean>>(),
}
export type ListFor<S> = Fill.ImplFor<typeof(listFns), S>
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
const cdDeque: DequeFor<CircularDeque<string>> = {
	PushFront = CircularDequeModule.PushFront,
	PushBack = CircularDequeModule.PushBack,
	PopFront = CircularDequeModule.PopFront,
	PopBack = CircularDequeModule.PopBack,
	Front = CircularDequeModule.Front,
	Back = CircularDequeModule.Back,
}
Trait.Impl(Deque):For(CD)(cdDeque)
const cdList: ListFor<CircularDeque<string>> = {
	Get = CircularDequeModule.Get,
	FirstIndex = CircularDequeModule.FirstIndex,
	LastIndex = CircularDequeModule.LastIndex,
	NextIndex = CircularDequeModule.NextIndex,
	PrevIndex = CircularDequeModule.PrevIndex,
}
Trait.Impl(List):For(CD)(cdList)

const ldDeque: DequeFor<LinkedDeque<string>> = {
	PushFront = LinkedDequeModule.PushFront,
	PushBack = LinkedDequeModule.PushBack,
	PopFront = LinkedDequeModule.PopFront,
	PopBack = LinkedDequeModule.PopBack,
	Front = LinkedDequeModule.Front,
	Back = LinkedDequeModule.Back,
}
Trait.Impl(Deque):For(LD)(ldDeque)

-- Arr: 리스트(일곱 중 셋을 자기 직접 구현으로 재정의) + **스택**(덱이 아니어도 For 로 — 예전 틀에선 못 하던 것)
const arrList: ListFor<Arr<string>> = {
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
const arrStack: StackFor<Arr<string>> = {
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

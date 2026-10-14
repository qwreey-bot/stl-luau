--!strict
--[[
	시제품 v3 위의 트레이트 넷과 등록 — 트레이트가 **제네릭 타입**(`Stack<Self, T>`)을 가집니다.

	- 정의는 팩토리 한 곳(`stackDef<Self, T>()`): 런타임은 이름 목록을, 타입은 `typeof(stackDef<<Self, T>>())` 를.
	- 등록 표는 구체 타입으로 주석(`Stack<CircularDeque<string>, string>`), 기본 구현이 있는 트레이트는 `Provided<…>`.
	- 뭉텅이 구현(`Where`)은 **제네릭 함수**(`stackFromDeque<C, T>(deque: Deque<C, T>): Stack<C, T>`)로 짜서 검사를 받습니다.
	- 동적 경로로 꺼낼 땐 받는 쪽이 `T` 를 밝힙니다(`Stack.Of<<C, T>>(value)`) — 주장이라 검사되지 않음(자바의 검사 안 된 형변환).
	- 트레이트 객체의 타입은 `Stack<any, any> & { Of, For, FnTok }` — 진입점(`Stack.Push`)은 원소 검사 없는 any 경로.
	  ⚠️ `[string]: any` 인덱서가 든 타입과 교집합으로 적으면 `Stack.Of` 가 "제네릭 함수 | 에러" 가 되어 `<<…>>` 를 못 붙임.
	- `src` 의 컨테이너 함수를 그대로 쓰고, 값에는 이 시제품의 토큰을 붙입니다(`Kinds.tag`).
]]
local Trait = require("./Trait")
local stl = require("../../../src")

type CircularDeque<T> = stl.CircularDeque<T>
type LinkedDeque<T> = stl.LinkedDeque<T>
type Arr<T> = stl.Arr<T>
type ArrRead<T> = stl.ArrRead<T>
type Token = Trait.Token<any>

const Fn, Default = Trait.Fn, Trait.Default
const CircularDequeModule, LinkedDequeModule, ArrModule = stl.CircularDeque, stl.LinkedDeque, stl.Arr

--[[ 토큰 — 우리 것은 `Stl.` ]]
const CD = Trait.Token("Stl.CircularDeque")
const LD = Trait.Token("Stl.LinkedDeque")
const ARR = Trait.Token("Stl.Arr")

--[[ Deque — 필수 여섯 ]]
local function dequeDef<Self, T>()
	return {
		PushFront = Fn<<(deque: Self, item: T) -> Self>>(),
		PushBack = Fn<<(deque: Self, item: T) -> Self>>(),
		PopFront = Fn<<(deque: Self) -> T?>>(),
		PopBack = Fn<<(deque: Self) -> T?>>(),
		Front = Fn<<(deque: Self) -> T?>>(),
		Back = Fn<<(deque: Self) -> T?>>(),
	}
end
export type Deque<Self, T> = typeof(dequeDef<<Self, T>>())
const Deque = Trait.Trait("Deque", dequeDef) :: Deque<any, any> & {
	read FnTok: { [string]: number },
	read Of: <C, T>(value: C) -> Deque<C, T>,
	read For: <C, T>(token: Token) -> Deque<C, T>,
}

--[[ Stack — 필수 셋. 덱이면 뭉텅이 구현으로 따라옴(덱의 함수 그대로) ]]
local function stackDef<Self, T>()
	return {
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
		Peek = Fn<<(stack: Self) -> T?>>(),
	}
end
export type Stack<Self, T> = typeof(stackDef<<Self, T>>())
const Stack = Trait.Trait("Stack", stackDef) :: Stack<any, any> & {
	read FnTok: { [string]: number },
	read Of: <C, T>(value: C) -> Stack<C, T>,
	read For: <C, T>(token: Token) -> Stack<C, T>,
}
-- 뭉텅이 구현의 몸통은 제네릭 함수로 — 타입이 "덱의 무엇이 스택의 무엇이 되는가" 를 검사
local function stackFromDeque<C, T>(deque: Deque<C, T>): Stack<C, T>
	return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
end
Trait.Impl(Stack):Where({ Deque })(function(deps)
	return stackFromDeque(deps[Deque])
end)

local function queueDef<Self, T>()
	return {
		Push = Fn<<(queue: Self, item: T) -> Self>>(),
		Pop = Fn<<(queue: Self) -> T?>>(),
		Peek = Fn<<(queue: Self) -> T?>>(),
	}
end
export type Queue<Self, T> = typeof(queueDef<<Self, T>>())
const Queue = Trait.Trait("Queue", queueDef) :: Queue<any, any> & {
	read FnTok: { [string]: number },
	read Of: <C, T>(value: C) -> Queue<C, T>,
	read For: <C, T>(token: Token) -> Queue<C, T>,
}
local function queueFromDeque<C, T>(deque: Deque<C, T>): Queue<C, T>
	return { Push = deque.PushBack, Pop = deque.PopFront, Peek = deque.Front }
end
Trait.Impl(Queue):Where({ Deque })(function(deps)
	return queueFromDeque(deps[Deque])
end)

--[[ List — 필수 다섯 + 기본 구현 셋. 위치 I 도 트레이트의 제네릭 ]]
local function listDef<Self, E, I>()
	return {
		Get = Fn<<(list: Self, idx: I) -> E?>>(),
		FirstIndex = Fn<<(list: Self) -> I?>>(),
		LastIndex = Fn<<(list: Self) -> I?>>(),
		NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),
		PrevIndex = Fn<<(list: Self, idx: I) -> I?>>(),
		Fold = Default<<<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U>>(),
		IndexOf = Default<<(list: Self, item: E) -> I?>>(),
		Contains = Default<<(list: Self, item: E) -> boolean>>(),
	}
end
export type List<Self, E, I> = typeof(listDef<<Self, E, I>>())
export type ListProvided<Self, E, I> = Trait.Provided<List<Self, E, I>>
const List = Trait.Trait("List", listDef, function(ops: any)
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
end) :: List<any, any, any> & {
	read FnTok: { [string]: number },
	read Of: <C, E, I>(value: C) -> List<C, E, I>,
	read For: <C, E, I>(token: Token) -> List<C, E, I>,
}

--[[ 등록 — 표는 구체 타입으로 주석을 단 지역 변수 ]]
const cdDeque: Deque<CircularDeque<string>, string> = {
	PushFront = CircularDequeModule.PushFront,
	PushBack = CircularDequeModule.PushBack,
	PopFront = CircularDequeModule.PopFront,
	PopBack = CircularDequeModule.PopBack,
	Front = CircularDequeModule.Front,
	Back = CircularDequeModule.Back,
}
Trait.Impl(Deque):For(CD)(cdDeque)
const cdList: ListProvided<CircularDeque<string>, string, number> = {
	Get = CircularDequeModule.Get,
	FirstIndex = CircularDequeModule.FirstIndex,
	LastIndex = CircularDequeModule.LastIndex,
	NextIndex = CircularDequeModule.NextIndex,
	PrevIndex = CircularDequeModule.PrevIndex,
}
Trait.Impl(List):For(CD)(cdList)

const ldDeque: Deque<LinkedDeque<string>, string> = {
	PushFront = LinkedDequeModule.PushFront,
	PushBack = LinkedDequeModule.PushBack,
	PopFront = LinkedDequeModule.PopFront,
	PopBack = LinkedDequeModule.PopBack,
	Front = LinkedDequeModule.Front,
	Back = LinkedDequeModule.Back,
}
Trait.Impl(Deque):For(LD)(ldDeque)

-- Arr: 리스트(일곱 중 셋을 자기 직접 구현으로) + 스택(덱이 아니어도 For 로)
const arrList: ListProvided<Arr<string>, string, number> = {
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
const arrStack: Stack<Arr<string>, string> = {
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

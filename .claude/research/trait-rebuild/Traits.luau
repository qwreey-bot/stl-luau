--!strict
--[[
	시제품 위에 올린 트레이트들 — `Deque`·`Stack`·`Queue`·`List`. `src/Traits/*` 와 같은 뜻이고 다른 것은 둘입니다:

	1. **기본 구현이 함수를 만들 때 붙잡습니다**(다시 만들기가 있으니 낡지 않음).
	   - `Stack`·`Queue`: 감싸지 않고 **덱의 함수 자체**를 돌려줍니다.
	   - `List`: 프리미티브를 만들 때 지역으로 꺼내 두고, 같은 트레이트의 다른 기본 구현은 `ops.X or 내것`.
	2. 진입점을 세 모양으로 둡니다(견주려고): `Entry`(지금 모양 — `expectImpl(T, v, 이름).이름(…)`),
	   `Inline`(구현 찾기를 진입점 안에 펼침 — 호출 하나를 덞), `ByFn`(함수별 표 — 조회 하나로 함수에).

	`src` 의 `CircularDeque`·`LinkedDeque` 를 그 토큰 그대로 여기에 등록합니다(값은 같은 것을 씀).
]]
local Trait3 = require("./Trait3")
local stl = require("../../../src")
local CircularDeque: any, LinkedDeque: any = stl.CircularDeque, stl.LinkedDeque

const Deque = Trait3.New("Deque", {
	required = { "PushFront", "PushBack", "PopFront", "PopBack", "Front", "Back" },
})

-- ⭐ 덱의 함수 자체 — 감싸는 겹이 없습니다. 덱의 표가 다시 만들어지면 이 함수가 다시 불립니다.
const Stack = Trait3.New("Stack", {
	dependencies = { Deque },
	defaults = function(_ops: any, deps: any)
		const deque = deps[Deque]
		return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
	end,
})

const Queue = Trait3.New("Queue", {
	dependencies = { Deque },
	defaults = function(_ops: any, deps: any)
		const deque = deps[Deque]
		return { Push = deque.PushBack, Pop = deque.PopFront, Peek = deque.Front }
	end,
})

-- 프리미티브를 **만들 때** 꺼내 둡니다(`src` 는 부를 때마다 `ops.Get` …).
const List = Trait3.New("List", {
	required = { "Get", "FirstIndex", "LastIndex", "NextIndex", "PrevIndex" },
	defaults = function(ops: any)
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
		-- 같은 트레이트의 다른 기본 구현: 구현이 재정의했으면 그것(이미 `ops` 에 있음), 아니면 위의 것
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
	end,
})

-- `src` 의 컨테이너를 그 토큰으로 등록(넘길 것만 든 표)
for _, module: any in { CircularDeque, LinkedDeque } do
	Trait3.Impl(Deque, module.Token, {
		PushFront = module.PushFront,
		PushBack = module.PushBack,
		PopFront = module.PopFront,
		PopBack = module.PopBack,
		Front = module.Front,
		Back = module.Back,
	})
	Trait3.Impl(List, module.Token, {
		Get = module.Get,
		FirstIndex = module.FirstIndex,
		LastIndex = module.LastIndex,
		NextIndex = module.NextIndex,
		PrevIndex = module.PrevIndex,
	})
end

const expectImpl = Trait3.ExpectImpl

--[[ 진입점 1 — 지금 모양(`src/Traits/Stack.luau` 와 같은 몸통) ]]
const Entry = {
	Push = function(stack: any, item: any): any
		expectImpl(Stack, stack, "Push").Push(stack, item)
		return stack
	end,
	Pop = function(stack: any): any
		return expectImpl(Stack, stack, "Pop").Pop(stack)
	end,
	IndexOf = function(list: any, item: any): any
		return expectImpl(List, list, "IndexOf").IndexOf(list, item)
	end,
	Contains = function(list: any, item: any): boolean
		return expectImpl(List, list, "Contains").Contains(list, item)
	end,
	Fold = function(list: any, init: any, fn: (any, any, any) -> any): any
		return expectImpl(List, list, "Fold").Fold(list, init, fn)
	end,
}

--[[ 진입점 2 — 구현 찾기를 진입점 안에 펼침(`expectImpl` 호출이 없음. 빗나가면 느린 길) ]]
const stackImpls = Stack.impls
const Inline = {
	Push = function(stack: any, item: any): any
		const impl: any = if type(stack) == "table" then stackImpls[rawget(stack, "__type")] else nil
		if impl == nil then
			expectImpl(Stack, stack, "Push").Push(stack, item)
			return stack
		end
		impl.Push(stack, item)
		return stack
	end,
	Pop = function(stack: any): any
		const impl: any = if type(stack) == "table" then stackImpls[rawget(stack, "__type")] else nil
		if impl == nil then
			return expectImpl(Stack, stack, "Pop").Pop(stack)
		end
		return impl.Pop(stack)
	end,
}

--[[ 진입점 3 — 함수별 표(`[토큰] = 함수`). 조회 하나로 함수에 닿고 이름 조회가 없음 ]]
type AnyFn = (...any) -> ...any
const pushOf: { [any]: AnyFn }, popOf: { [any]: AnyFn } = Trait3.FnTable(Stack, "Push"), Trait3.FnTable(Stack, "Pop")
const fnMiss = Trait3.FnMiss
const ByFn = {
	Push = function(stack: any, item: any): any
		const fn: AnyFn? = if type(stack) == "table" then pushOf[rawget(stack, "__type")] else nil
		if fn ~= nil then
			fn(stack, item)
			return stack
		end
		fnMiss(Stack, stack, "Push")(stack, item)
		return stack
	end,
	Pop = function(stack: any): any
		const fn: AnyFn? = if type(stack) == "table" then popOf[rawget(stack, "__type")] else nil
		if fn ~= nil then
			return fn(stack)
		end
		return fnMiss(Stack, stack, "Pop")(stack)
	end,
}

-- stylua: ignore
return {
	Deque = Deque, Stack = Stack, Queue = Queue, List = List,
	Entry = Entry, Inline = Inline, ByFn = ByFn,
}

--!strict
--[[
	Stack — 나중에 넣은 것이 먼저 나오는(LIFO) 컨테이너의 트레이트(2026-10-14 사용자 결정, 질문 AV: *"트레이트로 두는거 동의. stack 으로 무엇을 쓸지,
	queue 로 무엇을 쓸 지는 유저가 선택 가능하다고 봐"*).

	**필수 함수가 없습니다 — `Deque` 를 구현한 종류면 저절로 따라옵니다**(페이퍼 07 의 "A 가 되면 이것도 된다").
	`CircularDeque`·`LinkedDeque`, 바깥에서 `Deque` 를 구현한 종류 모두 등록 없이 스택입니다:

	| 여기 | 덱의 무엇 |
	|---|---|
	| `Stack.Push(x, item)` | `Deque.PushBack` |
	| `Stack.Pop(x)` | `Deque.PopBack` |
	| `Stack.Peek(x)` | `Deque.Back` |

	어느 덱을 쓸지는 쓰는 쪽이 고릅니다 — 양끝만 쓰면 원형이 빠르고(perf 38-3절), 가운데 위치를 쥐어야 하면 연결.
	더 빠른 판이 있는 종류는 같은 이름을 등록해 재정의할 수 있습니다(`Trait.Impl(Stack, TOKEN, { Push = … })`).

	⚠️ 진입점을 거치면 호출이 두 겹 더 붙습니다(구현 찾기 + 기본 구현이 덱의 함수를 부름 — perf 48절). 종류를 아는
	코드는 그 모듈의 함수(`CircularDeque.PushBack`)를 직접 쓰세요.

	타입은 `Deque` 의 마커 그대로입니다(덱이면 타입으로도 스택) — 새 팬텀 필드가 없습니다.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")
local Deque = require("./Deque")

--[[ 계약 ]]

-- 완성 표(셋 다 기본 구현이 채움). `Push` 는 자기 자신을 돌려주고, `Pop`·`Peek` 은 비었으면 `nil`.
export type Full<C, T> = {
	read Push: (stack: C, item: T) -> C,
	read Pop: (stack: C) -> T?,
	read Peek: (stack: C) -> T?,
}
-- 구현이 `Trait.Impl` 에 넘기는 표 — 전부 선택(재정의할 것만).
export type Provided<C, T> = {
	read Push: ((stack: C, item: T) -> C)?,
	read Pop: ((stack: C) -> T?)?,
	read Peek: ((stack: C) -> T?)?,
}

--[[ 마커 — `Deque` 의 것 그대로 ]]

export type Marker<T> = Deque.Marker<T>
export type MarkerMut<T> = Deque.MarkerMut<T>

const Stack = Trait.New<<Full<any, any>>>("Stack", {
	dependencies = { Deque },
	-- 덱의 함수는 **부를 때** 꺼냅니다(만들 때 붙잡으면 나중의 재정의를 못 봄 — 규약).
	defaults = function(_ops: any, deps: any)
		const deque = deps[Deque]
		return {
			Push = function(self: any, item: any): any
				return deque.PushBack(self, item)
			end,
			Pop = function(self: any): any
				return deque.PopBack(self)
			end,
			Peek = function(self: any): any
				return deque.Back(self)
			end,
		}
	end,
}) :: Trait.Trait<Full<any, any>, Provided<any, any>>
const expectImpl = Trait.ExpectImpl
const impls = Stack.impls :: any
-- 진입점은 구현 찾기를 **안에 펼쳐** 둡니다 — `expectImpl(…)` 을 부르는 것만으로 호출당 9~10ns 였습니다(perf 51절).
-- 못 찾았을 때만 `expectImpl` 로 갑니다(에러 메시지).

--[[ 진입점 — 종류를 모르는 코드가 부릅니다 ]]

-- 맨 위에 넣고 넣은 타입 그대로 돌려줍니다.
const function Push<C, T>(stack: C & MarkerMut<T>, item: T): C
	const impl: any = (if type(stack) == "table" then impls[rawget(stack :: any, "__type")] else nil)
		or expectImpl(Stack, stack, "Push")
	impl.Push(stack, item)
	return stack
end

-- 맨 위(마지막에 넣은 것)를 꺼냅니다. 비었으면 `nil`.
const function Pop<T>(stack: MarkerMut<T>): T?
	const impl: any = (if type(stack) == "table" then impls[rawget(stack :: any, "__type")] else nil)
		or expectImpl(Stack, stack, "Pop")
	return impl.Pop(stack)
end

-- 맨 위를 봅니다(꺼내지 않음). 비었으면 `nil`. 읽기라 빌린 참조도 받습니다.
const function Peek<T>(stack: Marker<T>): T?
	const impl: any = (if type(stack) == "table" then impls[rawget(stack :: any, "__type")] else nil)
		or expectImpl(Stack, stack, "Peek")
	return impl.Peek(stack)
end

-- stylua: ignore
return Trait.Expose(Stack, {
	Push = Push, Pop = Pop, Peek = Peek,
})

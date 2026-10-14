--!strict
-- probe_direction1.luau: 진입점을 단일 원천으로 둔 트레이트 시스템 검증
local stl = require("../src")
type CircularDeque<T> = stl.CircularDeque<T>
type Arr<T> = stl.Arr<T>

type Item<T> = { read __generics: { read Item: (T) -> T } }
type AnyToken = { read name: string }
type A = { read __probeA: true }

-- 런타임 마커 및 헬퍼 흉내
local FN_MARK = table.freeze({})
local DEFAULT_MARK = table.freeze({})

local function Fn<F>(): F
	return FN_MARK :: any
end

local function Default<F>(build: any): F
	return table.freeze({ [DEFAULT_MARK] = build }) :: any
end

--[[ 트레이트 정의: Stack ]]
const StackEntries = {
	Push = Fn<< <Self, T>(stack: Self & Item<T>, item: T) -> Self >>(),
	Pop = Fn<< <Self, T>(stack: Self & Item<T>) -> T? >>(),
	Peek = Default<< <Self, T>(stack: Self & Item<T>) -> T? >>(function(ops: any)
		return function(stack: any)
			return ops.Pop(stack)
		end
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

-- Trait.Trait 모의
local function makeTrait<E>(name: string, entries: E): any
	local trait: any = {}
	for k, _ in entries :: any do
		trait[k] = function(...) return (...) end
	end
	trait.Of = function(x: any) return trait end
	return trait
end

-- 트레이트 생성 (정의 쪽 1줄 캐스트 허용)
const Stack: StackObject = makeTrait("Stack", StackEntries) :: StackObject

--[[ 테스트 준비: 컨테이너 인스턴스 ]]
local CD_TOKEN: AnyToken = { name = "Stl.CircularDeque" }
local d = stl.CircularDeque.Of(1, 2, 3)
(d :: any).__generics = { Item = function(x: number) return x end }
(d :: any).__type = CD_TOKEN

local a = stl.Arr.Of("x", "y")
(a :: any).__generics = { Item = function(x: string) return x end }

--[[ 1. 시스템이 만든 진입점 사용 (Stack.Push) ]]
local p1: CircularDeque<number> = Stack.Push(d, 4)
local p2: number? = Stack.Pop(d)
local p3: number? = Stack.Peek(d)

-- NEG 1: 잘못된 타입 푸시
local NEG_push = Stack.Push(d, "wrong") -- NEG: number 에 string 푸시
-- NEG 2: 잘못된 반환 타입 기대
local NEG_pop: string? = Stack.Pop(d) -- NEG: number? 를 string? 에 대입
-- NEG 3: Peek 반환 타입
local NEG_peek: string? = Stack.Peek(d) -- NEG: number? 를 string? 에 대입

--[[ 2. Of 로 완성 표 꺼내서 사용 (Stack.Of) ]]
local s = Stack.Of(d)
local sp1: CircularDeque<number> = s.Push(d, 5)
local sp2: number? = s.Pop(d)

-- NEG 4: s.Push 에 잘못된 타입
local NEG_s_push = s.Push(d, "wrong") -- NEG
-- NEG 5: s.Pop 잘못된 타입
local NEG_s_pop: string? = s.Pop(d) -- NEG
-- NEG 6: Of 에 잘못된 T 명시
local NEG_claim = Stack.Of<<CircularDeque<number>, string>>(d) -- NEG: 값의 T와 불일치

--[[ 3. 토큰으로 꺼내기 ]]
local byToken = Stack.Of<<CircularDeque<number>, number>>(CD_TOKEN)
local tp: number? = byToken.Pop(d)

--[[ 4. 구현하는 자리: 등록 표 (탐침 검사) ]]
local function strPush(self: Arr<string>, item: string): Arr<string>
	return self
end
-- NEG 7: 원소를 못박은 함수 등록 차단
local NEG_pinned: Stack<Arr<A>, A> = { -- NEG
	Push = strPush,
	Pop = stl.Arr.PopBack,
	Peek = stl.Arr.PopBack,
}

-- 정상 등록 표
local okArr: Stack<Arr<A>, A> = {
	Push = stl.Arr.PushBack,
	Pop = stl.Arr.PopBack,
	Peek = stl.Arr.PopBack,
}

--[[ 5. 뭉텅이 구현 ]]
type Deque<Self, T> = {
	PushBack: (Self, T) -> Self,
	PopBack: (Self) -> T?,
	Back: (Self) -> T?,
}
local function stackFromDeque<C, T>(deque: Deque<C, T>): Stack<C, T>
	return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
end

-- NEG 8: 뭉텅이 구현에서 필드 불일치
local function badStackFromDeque<C, T>(deque: Deque<C, T>): Stack<C, T>
	return { Push = deque.PushBack, Pop = deque.PushBack :: any, Peek = deque.Back }
end

local canary: string = 1

--!strict
-- 시제품 v6 의 타입. `-- NEG` 줄은 잡혀야 하고, `-- 경계` 줄은 0건이어야(알려진 한계), 나머지는 0건.
local P = require("./Traits")
local Trait = require("./Trait")
local stl = require("../../../src")
type CircularDeque<T> = stl.CircularDeque<T>
type Arr<T> = stl.Arr<T>
type A = Trait.A
type B = Trait.B
type Stack<Self, T> = P.Stack<Self, T>
type List<Self, E, I> = P.List<Self, E, I>
type Deque<Self, T> = P.Deque<Self, T>
local d = P.Kinds.tag(stl.CircularDeque.Of(1, 2, 3), P.Kinds.CD)
local a = P.Kinds.tag(stl.Arr.Of("x", "y"), P.Kinds.ARR)

--[[ 쓰는 자리 ]]
-- 값으로 꺼냄: Self·T 를 값에서(주장 없음)
const s = P.Stack.Of(d)
const pushed: CircularDeque<number> = s.Push(d, 4)
const popped: number? = s.Pop(d)
const NEG_push = s.Push(d, "x") -- NEG
const NEG_pop: string? = s.Pop(d) -- NEG
const NEG_claim = P.Stack.Of<<CircularDeque<number>, string>>(d) -- NEG: 밝힌 T 가 값과 어긋남
-- 토큰으로(밝힌 T 는 주장)
const byToken = P.Stack.Of<<CircularDeque<number>, number>>(P.Kinds.CD)
const fromToken: number? = byToken.Pop(d)
const claimed = P.Stack.Of<<CircularDeque<number>, string>>(P.Kinds.CD) -- 경계: 토큰으로 밝힌 T 는 검사 안 됨
-- Arr 스택과 중개자 Into
const arrPeek: string? = P.Stack.Of(a).Peek(a)
const viaInto: string? = P.Into.ArrStack(a).Pop(a)
const NEG_arr = P.Into.ArrStack(a).Push(a, 1) -- NEG
const NEG_into = P.Into.ArrStack(d) -- NEG: 덱은 Arr 가 아님
-- 리스트: 위치 타입도 값에서, 기본 구현 칸도 타입이 섬
const l = P.List.Of(d)
const where: number? = l.IndexOf(d, 2)
const has: boolean = l.Contains(d, 3)
const total: number = l.Fold(d, 0, function(acc: number, x: number, _i: number): number
	return acc + x
end)
const NEG_where: string? = l.IndexOf(d, 2) -- NEG
const NEG_contains = l.Contains(d, "z") -- NEG
-- 자바 식: 받는 함수가 Stack<C, T> 를 적음
local function drain<C, T>(st: Stack<C, T>, c: C): { T }
	const out = {}
	local x = st.Pop(c)
	while x ~= nil do
		table.insert(out, x)
		x = st.Pop(c)
	end
	return out
end
const all: { number } = drain(s, d)
const NEG_drain: { string } = drain(s, d) -- NEG
-- 편한 진입점은 any
P.Stack.Push(d, "any") -- 경계: 원소 검사 없음

--[[ 구현하는 자리: 등록 표(탐침) ]]
local function strPush(self: Arr<string>, item: string): Arr<string>
	return self
end
const NEG_pinned: Stack<Arr<A>, A> = { Push = strPush, Pop = stl.Arr.PopBack, Peek = stl.Arr.PopBack } -- NEG: 원소를 못박은 함수
const NEG_fold: List<Arr<A>, A, number> = {
	Get = stl.Arr.Get,
	FirstIndex = stl.Arr.FirstIndex,
	LastIndex = stl.Arr.LastIndex,
	NextIndex = stl.Arr.NextIndex,
	PrevIndex = stl.Arr.PrevIndex,
	IndexOf = Trait.Inherit,
	Contains = Trait.Inherit,
	Fold = stl.Arr.Len, -- NEG: 제네릭 칸 Fold 자리에 Len
}
const NEG_missing: Deque<CircularDeque<A>, A> = { PushBack = stl.CircularDeque.PushBack } -- NEG: 빠짐
const inheritAnywhere: Stack<Arr<A>, A> = { Push = stl.Arr.PushBack, Pop = Trait.Inherit, Peek = Trait.Inherit } -- 경계: Inherit 는 any(필수 칸은 런타임이 잡음)

--[[ 정의하는 자리: 기본 구현 빌더의 몸통, 뭉텅이 몸통 ]]
const Probe = Trait.Trait("TypesProbe", function<Self, T>(of: (Self & Trait.Item<T>) | Trait.AnyToken)
	return {
		Get = Trait.Fn<<(s: Self) -> T>>(),
		Twice = Trait.Default(function(ops: Probe<Self, T>)
			const get = ops.Get
			const _nope = ops.Nope -- NEG: 없는 형제
			return function(s: Self): T
				return get(s)
			end
		end),
		Wrong = Trait.Default(function(ops: Probe<Self, T>)
			return function(s: Self): T
				return "s" -- NEG: 반환 타입
			end
		end),
	}
end)
export type Probe<Self, T> = typeof(Probe.Of<<Self, T>>(nil :: any))
local function badStack(deque: Deque<A, B>): Stack<A, B>
	return { Push = deque.PushBack, Pop = deque.PushFront, Peek = deque.Back } -- NEG: Pop 자리에 PushFront
end
-- 탐침 몸통이라 원소를 못박은 함수도 잡힘(제네릭 몸통 `<C, T>` 였던 v4 는 0건)
local function pinnedStack(deque: Deque<A, B>): Stack<A, B>
	return { Push = deque.PushBack, Pop = function(_c: A): string? -- NEG: 원소를 못박은 Pop
		return nil
	end, Peek = deque.Back }
end

--[[ 빌린 읽기 참조: 읽기만 하는 트레이트(List)만 ]]
local borrowed: stl.CircularDequeRead<number> = d
const found: number? = P.List.Of(borrowed).IndexOf(borrowed, 2)
const foundEntry = P.List.IndexOf(borrowed, 2) -- 진입점(any)도 됨
const NEG_borrowStack = P.Stack.Of(borrowed) -- NEG: 쓰는 트레이트는 빌린 참조에 없음
const NEG_borrowDeque = P.Deque.Of(borrowed) -- NEG
const NEG_borrowFound: string? = P.List.Of(borrowed).IndexOf(borrowed, 2) -- NEG: 위치 타입은 그대로 섬
local wide: stl.CircularDequeRead<number?> = d
const wideGet: number? = P.List.Of(wide).Get(wide, 1)

local canary: string = 1
return {
	pushed,
	popped,
	NEG_push,
	NEG_pop,
	NEG_claim,
	fromToken,
	claimed,
	arrPeek,
	viaInto,
	NEG_arr,
	NEG_into,
	where,
	has,
	total,
	NEG_where,
	NEG_contains,
	all,
	NEG_drain,
	NEG_pinned,
	NEG_fold,
	NEG_missing,
	inheritAnywhere,
	badStack,
	pinnedStack,
	found,
	foundEntry,
	NEG_borrowStack,
	NEG_borrowDeque,
	NEG_borrowFound,
	wideGet,
	canary,
}

--!strict
local Trait = require("../.claude/research/trait-v4/Trait")
local stl = require("../src")
type ItemIndex<E, I> = Trait.ItemIndex<E, I>
type AnyToken = Trait.AnyToken

type ProbeSelf = { read __probeSelf: true }
type ProbeE = { read __probeE: true }
type ProbeI = { read __probeI: true }
type A = Trait.A
type B = Trait.B

-- ============================================================
-- PATTERN P1: Declarative Trait with External Probe-typed Defaults
-- ============================================================
-- 1. Trait definition declares pure signatures (both required and default)
const ListTrait = Trait.Trait("ListTrait", function<Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken)
	return {
		Get = Trait.Fn<<(list: Self, idx: I) -> E?>>(),
		FirstIndex = Trait.Fn<<(list: Self) -> I?>>(),
		LastIndex = Trait.Fn<<(list: Self) -> I?>>(),
		NextIndex = Trait.Fn<<(list: Self, idx: I) -> I?>>(),
		PrevIndex = Trait.Fn<<(list: Self, idx: I) -> I?>>(),
		IndexOf = Trait.Fn<<(list: Self, item: E) -> I?>>(),
		Contains = Trait.Fn<<(list: Self, item: E) -> boolean>>(),
	}
end)
export type ListTrait<Self, E, I> = typeof(ListTrait.Of<<Self, E, I>>(nil :: any))

-- Default implementation subset type
type ListDefaults<Self, E, I> = {
	IndexOf: (list: Self, item: E) -> I?,
	Contains: (list: Self, item: E) -> boolean,
}

-- 2. Defaults builder written monomorphically with probe types!
local function buildListDefaults(ops: ListTrait<ProbeSelf, ProbeE, ProbeI>): ListDefaults<ProbeSelf, ProbeE, ProbeI>
	const get, firstIndex, nextIndex = ops.Get, ops.FirstIndex, ops.NextIndex

	local function indexOf(list: ProbeSelf, item: ProbeE): ProbeI?
		local idx = firstIndex(list)
		while idx ~= nil do
			if get(list, idx) == item then
				return idx
			end
			idx = nextIndex(list, idx)
		end
		return nil
	end

	local function contains(list: ProbeSelf, item: ProbeE): boolean
		return indexOf(list, item) ~= nil
	end

	return {
		IndexOf = indexOf,
		Contains = contains,
	}
end

-- ============================================================
-- PATTERN B1: Monomorphic Blanket Body with Probe Types
-- ============================================================
type Deque<Self, T> = {
	PushFront: (deque: Self, item: T) -> Self,
	PushBack: (deque: Self, item: T) -> Self,
	PopFront: (deque: Self) -> T?,
	PopBack: (deque: Self) -> T?,
	Front: (deque: Self) -> T?,
	Back: (deque: Self) -> T?,
}
type Stack<Self, T> = {
	Push: (stack: Self, item: T) -> Self,
	Pop: (stack: Self) -> T?,
	Peek: (stack: Self) -> T?,
}

local function stackFromDeque_mono(deque: Deque<A, B>): Stack<A, B>
	return {
		Push = deque.PushBack,
		Pop = deque.PopBack,
		Peek = deque.Back,
	}
end

-- ============================================================
-- PATTERN I1: Into with Top-level Probe Assertion
-- ============================================================
type Arr<T> = stl.Arr<T>
const arrIntoStack: <T>(a: Arr<T>) -> Stack<Arr<T>, T> = (function(a: any): any return nil end) :: any

-- Top-level probe assertion on Into:
local _checkInto: (a: Arr<A>) -> Stack<Arr<A>, A> = arrIntoStack

-- ============================================================
-- PATTERN A1: Implementer Adapter with Probe Type
-- ============================================================
type ArrRead<T> = stl.ArrRead<T>
local function arrPeek_mono(self: ArrRead<A>): A?
	return self[self.n]
end

local canary: string = 1
return {
	buildListDefaults,
	stackFromDeque_mono,
	_checkInto,
	arrPeek_mono,
	canary,
}

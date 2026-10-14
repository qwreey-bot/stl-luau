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

const ListTrait = Trait.Trait("ListTrait", function<Self, E, I>(of: (Self & ItemIndex<E, I>) | AnyToken)
	return {
		Get = Trait.Fn<<(list: Self, idx: I) -> E?>>(),
		FirstIndex = Trait.Fn<<(list: Self) -> I?>>(),
		NextIndex = Trait.Fn<<(list: Self, idx: I) -> I?>>(),
		PrevIndex = Trait.Fn<<(list: Self, idx: I) -> I?>>(),
		IndexOf = Trait.Fn<<(list: Self, item: E) -> I?>>(),
		Contains = Trait.Fn<<(list: Self, item: E) -> boolean>>(),
	}
end)
type ListTrait<Self, E, I> = typeof(ListTrait.Of<<Self, E, I>>(nil :: any))

type ListDefaults<Self, E, I> = {
	IndexOf: (list: Self, item: E) -> I?,
	Contains: (list: Self, item: E) -> boolean,
}

-- Negative 1: Default builder pinned element type (string)
local function neg1_builder_pinnedElem(ops: ListTrait<ProbeSelf, ProbeE, ProbeI>): ListDefaults<ProbeSelf, ProbeE, ProbeI>
	return {
		IndexOf = function(list: ProbeSelf, item: string): ProbeI? return nil end, -- NEG
		Contains = function(list: ProbeSelf, item: ProbeE): boolean return true end,
	}
end

-- Negative 2: Default builder internal body return concrete literal into optional ProbeI?
local function neg2_builder_internalReturn(ops: ListTrait<ProbeSelf, ProbeE, ProbeI>): ListDefaults<ProbeSelf, ProbeE, ProbeI>
	return {
		IndexOf = function(list: ProbeSelf, item: ProbeE): ProbeI?
			return 123 -- NEG
		end,
		Contains = function(list: ProbeSelf, item: ProbeE): boolean return true end,
	}
end

-- Negative 3: Default builder sibling call passing wrong argument
local function neg3_builder_siblingArg(ops: ListTrait<ProbeSelf, ProbeE, ProbeI>): ListDefaults<ProbeSelf, ProbeE, ProbeI>
	const get = ops.Get
	return {
		IndexOf = function(list: ProbeSelf, item: ProbeE): ProbeI?
			return get(list, item) -- NEG: item (ProbeE) where idx (ProbeI) expected
		end,
		Contains = function(list: ProbeSelf, item: ProbeE): boolean return true end,
	}
end

-- Negative 4: Monomorphic blanket body pinned element type
type Deque<Self, T> = {
	PushFront: (deque: Self, item: T) -> Self,
	PushBack: (deque: Self, item: T) -> Self,
	PopFront: (deque: Self) -> T?,
	PopBack: (deque: Self) -> T?,
	Front: (deque: Self) -> T?,
	Back: (deque: Self) -> T?,
	IsEmpty: (deque: Self) -> boolean,
}
type Stack<Self, T> = {
	Push: (stack: Self, item: T) -> Self,
	Pop: (stack: Self) -> T?,
	Peek: (stack: Self) -> T?,
}

local function neg4_blanket_pinnedPop(deque: Deque<A, B>): Stack<A, B>
	return {
		Push = deque.PushBack,
		Pop = function(c: A): string? return nil end, -- NEG: string? vs B?
		Peek = deque.Back,
	}
end

local function neg5_blanket_siblingReturn(deque: Deque<A, B>): Stack<A, B>
	return {
		Push = deque.PushBack,
		Pop = deque.IsEmpty, -- NEG: boolean vs B?
		Peek = deque.Back,
	}
end

-- Negative 6: Into pinned element type
type Arr<T> = stl.Arr<T>
const badIntoElem: <T>(a: Arr<T>) -> Stack<Arr<T>, string> = (function(a: any): any return nil end) :: any
local neg6_into_check: (a: Arr<A>) -> Stack<Arr<A>, A> = badIntoElem -- NEG

-- Negative 7: Implementer adapter returning concrete type
type ArrRead<T> = stl.ArrRead<T>
local function neg7_adapter_body(self: ArrRead<A>): A?
	return 999 -- NEG: number vs A?
end

local canary: string = 1
return {
	neg1_builder_pinnedElem,
	neg2_builder_internalReturn,
	neg3_builder_siblingArg,
	neg4_blanket_pinnedPop,
	neg5_blanket_siblingReturn,
	neg6_into_check,
	neg7_adapter_body,
	canary,
}

--!strict
-- probes/comprehensive_record_mapping.luau
-- Porting the full negative controls of .claude/research/trait-v9/types.luau to the Record Mapping scheme.

local stl = require("../src")
type CircularDeque<T> = stl.CircularDeque<T>
type CircularDequeRead<T> = stl.CircularDequeRead<T>
type Arr<T> = stl.Arr<T>

export type function FullOf(defTable: type): type
	local props: any = {}
	for name, prop in defTable:properties() do
		local entry = prop.read :: type
		local fnProp = entry:readproperty(types.singleton("fn")) :: type
		props[name] = { read = fnProp }
	end
	return types.newtable(props)
end

export type function ImplOf(defTable: type): type
	local props: any = {}
	for name, prop in defTable:properties() do
		local entry = prop.read :: type
		local reqProp = entry:readproperty(types.singleton("required")) :: type
		local fnProp = entry:readproperty(types.singleton("fn")) :: type
		local isRequired = false
		if reqProp and reqProp:is("singleton") and reqProp:value() == true then
			isRequired = true
		end
		if isRequired then
			props[name] = { read = fnProp }
		else
			props[name] = { read = types.optional(fnProp) }
		end
	end
	return types.newtable(props)
end

type Req<F> = { read required: true, read fn: F }
type Def<F> = { read required: false, read fn: F }

type A = { read __probeA: true }
type B = { read __probeB: true }

-- Phantom markers for testing
type Item<T> = { read __generics: { read Item: (T) -> T } }
type ItemIndexRead<E, I> = { read __readGenerics: { read Item: () -> E, read Index: () -> I } }
type AnyToken = { read name: string }

-- 1. Stack 정의 (기본 구현 없음)
type StackDef<Self, T> = {
	Push: Req<(stack: Self, item: T) -> Self>,
	Pop: Req<(stack: Self) -> T?>,
	Peek: Req<(stack: Self) -> T?>,
}
type Stack<Self, T> = FullOf<StackDef<Self, T>>
type StackImpl<Self, T> = ImplOf<StackDef<Self, T>>

-- 2. List 정의 (기본 구현 IndexOf, Contains, Fold)
type ListDef<Self, E, I> = {
	Get: Req<(list: Self, idx: I) -> E?>,
	FirstIndex: Req<(list: Self) -> I?>,
	LastIndex: Req<(list: Self) -> I?>,
	NextIndex: Req<(list: Self, idx: I) -> I?>,
	PrevIndex: Req<(list: Self, idx: I) -> I?>,
	IndexOf: Def<(list: Self, item: E) -> I?>,
	Contains: Def<(list: Self, item: E) -> boolean>,
	Fold: Def<<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U>,
}
type List<Self, E, I> = FullOf<ListDef<Self, E, I>>
type ListImpl<Self, E, I> = ImplOf<ListDef<Self, E, I>>

-- 3. Deque 정의
type DequeDef<Self, T> = {
	PushFront: Req<(deque: Self, item: T) -> Self>,
	PushBack: Req<(deque: Self, item: T) -> Self>,
	PopFront: Req<(deque: Self) -> T?>,
	PopBack: Req<(deque: Self) -> T?>,
	Front: Req<(deque: Self) -> T?>,
	Back: Req<(deque: Self) -> T?>,
}
type Deque<Self, T> = FullOf<DequeDef<Self, T>>
type DequeImpl<Self, T> = ImplOf<DequeDef<Self, T>>

-- Mock factories
type StackFactory = {
	Of: (<Self, T>(of: (Self & Item<T>) | AnyToken) -> Stack<Self, T>)
}
type ListFactory = {
	Of: (<Self, E, I>(of: (Self & ItemIndexRead<E, I>) | AnyToken) -> List<Self, E, I>)
}
local StackMod: StackFactory = nil :: any
local ListMod: ListFactory = nil :: any

local d: CircularDeque<number> = stl.CircularDeque.Of(1, 2, 3)

-- [[ Section 1: 쓰는 자리 (소비 측) ]]
local s = StackMod.Of(d)
local _pushed: CircularDeque<number> = s.Push(d, 4)
local _popped: number? = s.Pop(d)
local NEG_push = s.Push(d, "x") -- NEG 1: 원소 불일치 (잡혀야 함)
local NEG_pop: string? = s.Pop(d) -- NEG 2: 반환 불일치 (잡혀야 함)

local l = ListMod.Of(d)
local _where: number? = l.IndexOf(d, 2)
local _has: boolean = l.Contains(d, 3)
local NEG_where: string? = l.IndexOf(d, 2) -- NEG 3: 위치 타입 불일치 (잡혀야 함)
local NEG_contains = l.Contains(d, "z") -- NEG 4: 원소 타입 불일치 (잡혀야 함)

-- [[ Section 2: 제네릭 알고리즘 (D3 와 대조) ]]
-- D3 types.luau:46-56 drain 함수
-- !! 레코드 매핑 안에서는 아래 함수 자체가 컴파일 에러가 됨: Type 'FullOf<...>' does not have key 'Pop' !!
-- local function drain<C, T>(st: Stack<C, T>, c: C): { T }
--     local out = {}
--     local x = st.Pop(c)
--     return out
-- end

-- [[ Section 3: 구현/등록 자리 (인라인 vs 별칭) ]]
local function strPush(self: Arr<string>, item: string): Arr<string>
	return self
end

-- NEG 5: 원소를 못박은 함수 (StackImpl 인라인 대입)
local NEG_pinned_inline: StackImpl<Arr<A>, A> = {
	Push = strPush, -- NEG 5 (잡혀야 함)
	Pop = stl.Arr.PopBack,
	Peek = stl.Arr.PopBack,
}

-- NEG 6: Fold 자리에 Arr.Len 대입 (ListImpl 인라인 대입)
local NEG_fold_inline: ListImpl<Arr<A>, A, number> = {
	Get = stl.Arr.Get,
	FirstIndex = stl.Arr.FirstIndex,
	LastIndex = stl.Arr.LastIndex,
	NextIndex = stl.Arr.NextIndex,
	PrevIndex = stl.Arr.PrevIndex,
	Fold = stl.Arr.Len, -- NEG 6 (D3에선 잡힘! UDTF 인라인에선 누락?!)
}

-- NEG 7: Fold 의 누적 타입 U 를 못박음 (ListImpl 인라인 대입)
local NEG_pinU_inline: ListImpl<Arr<A>, A, number> = {
	Get = stl.Arr.Get,
	FirstIndex = stl.Arr.FirstIndex,
	LastIndex = stl.Arr.LastIndex,
	NextIndex = stl.Arr.NextIndex,
	PrevIndex = stl.Arr.PrevIndex,
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number -- NEG 7 (D3에선 잡힘! UDTF 인라인에선 누락?!)
		return init
	end,
}

-- NEG 8: 필수 칸 누락 (StackImpl 인라인 대입)
local NEG_missing_inline: StackImpl<Arr<A>, A> = {
	Push = stl.Arr.PushBack,
	Peek = stl.Arr.PopBack,
	-- Pop 누락! (잡혀야 함)
}

-- [[ Section 4: 같은 모듈 기본 구현 반환 ]]
type ProbeDef<Self, T> = {
	Get: Req<(Self) -> T>,
	Twice: Def<(Self) -> T>,
}
type Probe<Self, T> = FullOf<ProbeDef<Self, T>>
local probeInst: Probe<Arr<number>, number> = nil :: any
local NEG_sameRet: string = probeInst.Twice(stl.Arr.Of(1, 2)) -- NEG 9: 기본 구현 반환 타입 (잡혀야 함)

local canary: string = 1

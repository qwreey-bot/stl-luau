--!strict
-- probe10: Deep dive into inline generic instantiation vs alias instantiation

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

type Arr<T> = { [number]: T }
type A = { read __probeA: true }

type GenericDefTable<Self, E, I> = {
	Fold: Def<<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U>,
}
type GenericImpl<Self, E, I> = ImplOf<GenericDefTable<Self, E, I>>

-- Case A: 인라인 인스턴스화 (변수 타입 자리에 직접 GenericImpl<...>)
-- NEG: Fold 를 number 로 못박음
local _caseA_pinned: GenericImpl<Arr<A>, A, number> = {
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number
		return init
	end,
}

-- Case B: 중간 별칭 사용 (type Alias = GenericImpl<...>)
type InstAlias = GenericImpl<Arr<A>, A, number>
local _caseB_pinned: InstAlias = {
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number
		return init
	end,
}

-- Case C: D3 (내장 index<>) 방식의 인라인 인스턴스화
type D3_Fold<Self, E, I, M> = index<{
	full: <U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U,
	impl: (<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U)?,
}, M>

type D3_ListImpl<Self, E, I> = {
	Fold: D3_Fold<Self, E, I, "impl">,
}

-- D3 방식으로 인라인 인스턴스화했을 때:
local _caseC_d3_pinned: D3_ListImpl<Arr<A>, A, number> = {
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number
		return init
	end,
}

local canary: string = 1

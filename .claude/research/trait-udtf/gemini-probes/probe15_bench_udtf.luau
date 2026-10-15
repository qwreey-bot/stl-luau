--!strict
-- probe15_bench_udtf: 10 trait definitions with User Defined Type Function

local Trait = require("../.claude/research/trait-v9/Trait")
local stl = require("../src")
type Arr<T> = stl.Arr<T>
type CircularDeque<T> = stl.CircularDeque<T>

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

type ListDef<Self, E, I> = {
	Get: Req<(list: Self, idx: I) -> E?>,
	FirstIndex: Req<(list: Self) -> I?>,
	LastIndex: Req<(list: Self) -> I?>,
	NextIndex: Req<(list: Self, idx: I) -> I?>,
	PrevIndex: Req<(list: Self, idx: I) -> I?>,
	IndexOf: Def<(list: Self, item: E) -> I?>,
	Fold: Def<<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U>,
}

export type T0Impl<Self, E, I> = ImplOf<ListDef<Self, E, I>>
export type T1Impl<Self, E, I> = ImplOf<ListDef<Self, E, I>>
export type T2Impl<Self, E, I> = ImplOf<ListDef<Self, E, I>>
export type T3Impl<Self, E, I> = ImplOf<ListDef<Self, E, I>>
export type T4Impl<Self, E, I> = ImplOf<ListDef<Self, E, I>>
export type T5Impl<Self, E, I> = ImplOf<ListDef<Self, E, I>>
export type T6Impl<Self, E, I> = ImplOf<ListDef<Self, E, I>>
export type T7Impl<Self, E, I> = ImplOf<ListDef<Self, E, I>>
export type T8Impl<Self, E, I> = ImplOf<ListDef<Self, E, I>>
export type T9Impl<Self, E, I> = ImplOf<ListDef<Self, E, I>>

-- Instantiations
type A = Trait.A
local _i0: T0Impl<Arr<A>, A, number> = { Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex }
local _i1: T1Impl<Arr<A>, A, number> = { Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex }
local _i2: T2Impl<Arr<A>, A, number> = { Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex }
local _i3: T3Impl<Arr<A>, A, number> = { Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex }
local _i4: T4Impl<Arr<A>, A, number> = { Get = stl.Arr.Get, FirstIndex = stl.Arr.FirstIndex, LastIndex = stl.Arr.LastIndex, NextIndex = stl.Arr.NextIndex, PrevIndex = stl.Arr.PrevIndex }

local canary: string = 1

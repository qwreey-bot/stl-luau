--!strict
-- probe5c: Test NEG_pinned_u and Arr.Len with real types

local stl = require("../src")
type Arr<T> = stl.Arr<T>

export type function ImplOf(defTable: type): type
	if defTable.tag ~= "table" then
		error("ImplOf requires a table")
	end
	local props: any = {}
	for name, prop in defTable:properties() do
		local entry = prop.read
		if not entry or entry.tag ~= "table" then
			error("Expected entry to be a table")
		end
		local reqProp = entry:readproperty(types.singleton("required"))
		local fnProp = entry:readproperty(types.singleton("fn"))
		if not fnProp then
			error("Expected entry to have fn property")
		end
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

type ListDefTable<Self, E, I> = {
	Get: Req<(Self, I) -> E?>,
	FirstIndex: Req<(Self) -> I?>,
	LastIndex: Req<(Self) -> I?>,
	NextIndex: Req<(Self, I) -> I?>,
	PrevIndex: Req<(Self, I) -> I?>,
	Fold: Def<<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U>,
}

type ListImpl<Self, E, I> = ImplOf<ListDefTable<Self, E, I>>
type A = { read __probeA: true }

-- D3 types.luau 와 똑같이 대입해봄:
local _NEG_fold: ListImpl<Arr<A>, A, number> = {
	Get = stl.Arr.Get,
	FirstIndex = stl.Arr.FirstIndex,
	LastIndex = stl.Arr.LastIndex,
	NextIndex = stl.Arr.NextIndex,
	PrevIndex = stl.Arr.PrevIndex,
	Fold = stl.Arr.Len, -- NEG
}

local _NEG_pinU: ListImpl<Arr<A>, A, number> = {
	Get = stl.Arr.Get,
	FirstIndex = stl.Arr.FirstIndex,
	LastIndex = stl.Arr.LastIndex,
	NextIndex = stl.Arr.NextIndex,
	PrevIndex = stl.Arr.PrevIndex,
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number -- NEG
		return init
	end,
}

local canary: string = 1

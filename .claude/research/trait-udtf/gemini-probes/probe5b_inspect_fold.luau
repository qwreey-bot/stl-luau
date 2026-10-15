--!strict
-- probe5b: Inspect what ImplOf actually produces

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
	Fold: Def<<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I) -> U) -> U>,
}

type ListImpl<Self, E, I> = ImplOf<ListDefTable<Self, E, I>>

type Arr<T> = { [number]: T }
type A = { read __probeA: true }

-- ListImpl의 Fold 프로퍼티 타입을 강제로 꺼내보자
type T_Fold = (ListImpl<Arr<A>, A, number>)

local x: T_Fold = nil :: any
local fold_fn = x.Fold -- fold_fn 의 타입은 무엇인가?

-- 만약 fold_fn 이 any 나 never 라면?
local should_fail_string: string = fold_fn

local canary: string = 1

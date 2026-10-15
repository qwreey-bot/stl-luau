--!strict
-- probe9b: Exact comparison inside probe 9

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

type Inst = GenericImpl<Arr<A>, A, number>

-- 대입 1: Inst 타입으로 직접 대입
local _assign1: Inst = {
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number
		return init
	end,
}

-- 대입 2: GenericImpl<Arr<A>, A, number> 로 직접 대입
local _assign2: GenericImpl<Arr<A>, A, number> = {
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number
		return init
	end,
}

local canary: string = 1

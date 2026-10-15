--!strict
-- probe9: Inspect what GenericImpl actually is

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

local val: Inst = nil :: any

-- val 의 타입 검사
local check1: string = val
local check2: string = val.Fold

local canary: string = 1

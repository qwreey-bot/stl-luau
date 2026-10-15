--!strict
-- probe13: Pinned element type test with probe type A

local stl = require("../src")
type Arr<T> = stl.Arr<T>

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

type StackDef<Self, T> = {
	Push: Req<(Self, T) -> Self>,
	Pop: Req<(Self) -> T?>,
	Peek: Def<(Self) -> T?>,
}

type StackImpl<Self, T> = ImplOf<StackDef<Self, T>>
type A = { read __probeA: true }

local function strPush(self: Arr<string>, item: string): Arr<string>
	return self
end

-- 1. 인라인 대입:
local _neg_inline_pinned: StackImpl<Arr<A>, A> = {
	Push = strPush,
	Pop = stl.Arr.PopBack,
	Peek = stl.Arr.PopBack,
}

-- 2. 별칭 경유 대입:
type StackImplInst = StackImpl<Arr<A>, A>
local _neg_alias_pinned: StackImplInst = {
	Push = strPush,
	Pop = stl.Arr.PopBack,
	Peek = stl.Arr.PopBack,
}

local canary: string = 1

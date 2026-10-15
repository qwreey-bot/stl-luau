--!strict
-- probe5: Fold generic <U> pinned override test

export type function FullOf(defTable: type): type
	if defTable.tag ~= "table" then
		error("FullOf requires a table")
	end
	local props: any = {}
	for name, prop in defTable:properties() do
		local entry = prop.read
		if not entry or entry.tag ~= "table" then
			error("Expected entry to be a table")
		end
		local fnProp = entry:readproperty(types.singleton("fn"))
		if not fnProp then
			error("Expected entry to have fn property")
		end
		props[name] = { read = fnProp }
	end
	return types.newtable(props)
end

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

-- 1. 올바른 제네릭 재정의
local _ok_generic_fold: ListImpl<Arr<A>, A, number> = {
	Get = function(s: Arr<A>, i: number): A? return s[i] end,
	Fold = function<U>(list: Arr<A>, init: U, fn: (acc: U, item: A, idx: number) -> U): U
		return init
	end,
}

-- 2. U 를 number 로 못박은 재정의 (NEG: 잡혀야 함!)
local _NEG_pinned_u: ListImpl<Arr<A>, A, number> = {
	Get = function(s: Arr<A>, i: number): A? return s[i] end,
	Fold = function(list: Arr<A>, init: number, fn: (acc: number, item: A, idx: number) -> number): number
		return init
	end,
}

-- 3. Fold 자리에 엉뚱한 함수 Arr.Len 대입 (NEG: 잡혀야 함!)
local function arrLen(x: any): number
	return 0
end
local _NEG_fold_len: ListImpl<Arr<A>, A, number> = {
	Get = function(s: Arr<A>, i: number): A? return s[i] end,
	Fold = arrLen,
}

local canary: string = 1

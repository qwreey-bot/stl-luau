--!strict
-- probe8: Testing Hypothesis A, B, and C

export type function ImplOf(defTable: type): type
	local props: any = {}
	for name, prop in defTable:properties() do
		local entry = prop.read
		local reqProp = entry:readproperty(types.singleton("required"))
		local fnProp = entry:readproperty(types.singleton("fn"))
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

-- Test 1: Def + types.optional, but instantiated directly without Self generic alias
type ConcreteDefTable = {
	Fold: Def<<U>(list: Arr<A>, init: U, fn: (acc: U, item: A, idx: number, ...any) -> U) -> U>,
}
type Test1_Impl = ImplOf<ConcreteDefTable>

local _test1_neg: Test1_Impl = {
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number
		return init
	end,
}

-- Test 2: Same as Test 1, but WITHOUT ...any
type ConcreteDefTableNoAny = {
	Fold: Def<<U>(list: Arr<A>, init: U, fn: (acc: U, item: A, idx: number) -> U) -> U>,
}
type Test2_Impl = ImplOf<ConcreteDefTableNoAny>

local _test2_neg: Test2_Impl = {
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number
		return init
	end,
}

-- Test 3: Generic alias: ImplOf called inside generic alias
type GenericDefTable<Self, E, I> = {
	Fold: Def<<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U) -> U>,
}
type GenericImpl<Self, E, I> = ImplOf<GenericDefTable<Self, E, I>>

local _test3_neg: GenericImpl<Arr<A>, A, number> = {
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number) -> number): number
		return init
	end,
}

local canary: string = 1

--!strict
-- probe4: basic record mapping type functions

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

local function _Fn<F>(): Req<F>
	return nil :: any
end

local function _Default<F>(build: (ops: any) -> F): Def<F>
	return nil :: any
end

-- 정의
type DefTable<Self, T> = {
	Push: Req<(Self, T) -> Self>,
	Pop: Req<(Self) -> T?>,
	Peek: Def<(Self) -> T?>,
}

type StackFull<Self, T> = FullOf<DefTable<Self, T>>
type StackImpl<Self, T> = ImplOf<DefTable<Self, T>>

-- 1. 구체 타입 인스턴스화
type S = StackFull<string, number>
type SI = StackImpl<string, number>

local _ok_impl: SI = {
	Push = function(s: string, t: number) return s end,
	Pop = function(s: string) return 1 end,
	-- Peek 은 생략 가능 (Def)
}

local _ok_peek: SI = {
	Push = function(s: string, t: number) return s end,
	Pop = function(s: string) return 1 end,
	Peek = function(s: string) return 1 end,
}

local canary: string = 1

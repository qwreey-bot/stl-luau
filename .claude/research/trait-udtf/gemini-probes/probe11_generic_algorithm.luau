--!strict
-- probe11: Generic algorithm receiving FullOf table

export type function FullOf(defTable: type): type
	local props: any = {}
	for name, prop in defTable:properties() do
		local entry = prop.read :: type
		local fnProp = entry:readproperty(types.singleton("fn")) :: type
		props[name] = { read = fnProp }
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

-- 사용자 타입 함수 방식:
type UDTF_Stack<Self, T> = FullOf<StackDef<Self, T>>

-- D3 방식:
type D3_Stack<Self, T> = {
	Push: (Self, T) -> Self,
	Pop: (Self) -> T?,
	Peek: (Self) -> T?,
}

-- 1. D3 방식으로 drain 함수 작성
local function drain_d3<C, T>(st: D3_Stack<C, T>, c: C): { T }
	local out = {}
	local x = st.Pop(c)
	while x ~= nil do
		table.insert(out, x)
		x = st.Pop(c)
	end
	return out
end

-- 2. UDTF 방식으로 drain 함수 작성
local function drain_udtf<C, T>(st: UDTF_Stack<C, T>, c: C): { T }
	local out = {}
	local x = st.Pop(c)
	while x ~= nil do
		table.insert(out, x)
		x = st.Pop(c)
	end
	return out
end

local canary: string = 1

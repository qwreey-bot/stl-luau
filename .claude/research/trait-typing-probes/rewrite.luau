--!strict
--[[ 라이브러리 ]]
-- 시그니처 안의 표식(타입 함수 아님)
type Gen<Name> = { read __genericMarker: Name }

-- 시그니처를 역추론되는 모양으로: 표식 → 새 제네릭, Self → Self & { read __generics: { read 이름: (G) -> G } }
type function RewriteSig(fnType: type): type
	-- 한 함수 타입을 다시 짓기
	local function rewriteFn(f: type): type
		const found: { [string]: type } = {}
		local function walk(t: type): type
			if t.tag == "table" then
				const marker = t:readproperty(types.singleton("__genericMarker"))
				if marker and marker:is("singleton") then
					const name = marker:value() :: string
					if not found[name] then
						found[name] = types.generic(name)
					end
					return found[name]
				end
				return t
			elseif t.tag == "union" or t.tag == "intersection" then
				const comps = t:components()
				for i, c in comps do
					comps[i] = walk(c)
				end
				return if t.tag == "union" then types.unionof(table.unpack(comps)) else types.intersectionof(table.unpack(comps))
			elseif t.tag == "function" then
				const p, r = t:parameters(), t:returns()
				if p.head then for i, v in p.head do p.head[i] = walk(v) end end
				if r.head then for i, v in r.head do r.head[i] = walk(v) end end
				return types.newfunction(p, r, t:generics())
			end
			return t
		end
		const params, returns = f:parameters(), f:returns()
		if params.head then for i, v in params.head do params.head[i] = walk(v) end end
		if returns.head then for i, v in returns.head do returns.head[i] = walk(v) end end
		-- Self(첫 매개변수의 제네릭) 에 제네릭 묶음을 요구하는 교집합
		const props = {}
		for name, g in found do
			props[types.singleton(name)] = { read = types.newfunction({ head = { g } }, { head = { g } }) }
		end
		const generics = f:generics()
		for _, g in found do
			table.insert(generics, g)
		end
		if params.head and params.head[1] then
			params.head[1] = types.intersectionof(params.head[1], types.newtable({
				[types.singleton("__generics")] = { read = types.newtable(props) },
			}))
		end
		return types.newfunction(params, returns, generics)
	end
	if fnType.tag == "function" then
		return rewriteFn(fnType)
	end
	error("RewriteSig needs a function type")
end

-- 자료 쪽: 진짜 필드를 붙임 — ApplyGeneric<기본 테이블, { Item: T }>
type function ApplyGeneric(base: type, gens: type): type
	const props = base:properties()
	const inner = {}
	for name, v in gens:properties() do
		const t = v.read :: type
		inner[name] = { read = types.newfunction({ head = { t } }, { head = { t } }) }
	end
	props[types.singleton("__generics")] = { read = types.newtable(inner) }
	return types.newtable(props, base:indexer(), base:metatable())
end

local function Fn<T>(): RewriteSig<T>
	return nil :: any
end

--[[ 계약 정의(사용자 눈에는 표식만) ]]
const Stack = {
	Push = Fn<<<Self>(stack: Self, item: Gen<"Item">) -> Self>>(),
	Pop = Fn<<<Self>(stack: Self) -> Gen<"Item">?>>(),
}
-- 바깥 사람의 새 계약
const Graph = {
	Link = Fn<<<Self>(g: Self, a: Gen<"Node">, b: Gen<"Node">) -> Self>>(),
	Nodes = Fn<<<Self>(g: Self) -> () -> Gen<"Node">?>>(),
}

--[[ 자료(사용자는 ApplyGeneric 으로 이름과 타입만) ]]
type Bag<T> = ApplyGeneric<{ items: { T }, count: number }, { Item: T }>
type MyGraph<T, N> = ApplyGeneric<{ verts: { N } }, { Item: T, Node: N }>
local bag: Bag<boolean> = nil :: any
local g: MyGraph<boolean, string> = nil :: any

local b1: Bag<boolean> = Stack.Push(bag, true)
local b2: boolean? = Stack.Pop(bag)
local g1: MyGraph<boolean, string> = Stack.Push(g, false)
local g2: MyGraph<boolean, string> = Graph.Link(g, "a", "b")
for n in Graph.Nodes(g) do
	local _s: string = n
end
local negB1 = Stack.Push(bag, 1) -- NEG
local negB2: string? = Stack.Pop(bag) -- NEG
local negG = Graph.Link(g, 1, "b") -- NEG
local negNoNode = Graph.Nodes(bag) -- NEG
local canary: string = 1
local show: never = Stack.Push -- 바뀐 모양 보기
return { b1, b2, g1, g2, negB1, negB2, negG, negNoNode, canary, show }

--!strict
--[[ 라이브러리: 이름으로 꺼내는 도구(둘 — 내장 index 를 겹친 것 / 사용자 타입 함수) ]]
type GenericOf<S, Name> = index<index<S, "__generics">, Name>
type function GenericOfFn(s: type, name: type): type
	const g = s:readproperty(types.singleton("__generics"))
	if not g then
		error("no __generics")
	end
	const t = g:readproperty(name)
	if not t then
		error("no generic " .. tostring(name:value()))
	end
	return t
end

--[[ 계약(진입점 시그니처) — 인자에서 Self 를 정하고, 원소는 앞으로 계산 ]]
local function push<Self>(x: Self, item: GenericOf<Self, "Item">): Self
	return x
end
local function pop<Self>(x: Self): GenericOf<Self, "Item">?
	return nil :: any
end
local function popFn<Self>(x: Self): GenericOfFn<Self, "Item">?
	return nil :: any
end
-- 바깥 사람이 새 계약: 이름만 정함
type NodeOf<S> = GenericOf<S, "Node">
local function nodes<Self>(g: Self): () -> NodeOf<Self>?
	return nil :: any
end
local function link<Self>(g: Self, a: NodeOf<Self>, b: NodeOf<Self>): Self
	return g
end

--[[ 컨테이너: 평범한 레코드로(공변) ]]
type Bag<T> = { items: { T }, read __generics: { read Item: T } }
type Graph<T, N> = { verts: { N }, read __generics: { read Item: T, read Node: N } }
local bag: Bag<boolean> = nil :: any
local g: Graph<boolean, string> = nil :: any

local b1: Bag<boolean> = push(bag, true)
local b2: boolean? = pop(bag)
local b3: boolean? = popFn(bag)
local g1: Graph<boolean, string> = push(g, false)
for n in nodes(g) do
	local _s: string = n
end
local g2: Graph<boolean, string> = link(g, "a", "b")
local negB1 = push(bag, 1) -- NEG
local negB2: string? = pop(bag) -- NEG
local negB3: string? = popFn(bag) -- NEG
local negG1 = push(g, "x") -- NEG
local negG2 = link(g, 1, "b") -- NEG
local negNoNode = nodes(bag) -- NEG(Node 가 없는 종류)
local canary: string = 1
return { b1, b2, b3, g1, g2, negB1, negB2, negB3, negG1, negG2, negNoNode, canary }

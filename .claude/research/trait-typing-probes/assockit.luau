--!strict
--[[ 라이브러리가 공개하는 도구 둘 + 토큰 타입 ]]
export type Inv<T> = (T) -> T -- 불변 팬텀
export type Assoc<A> = { read __type: { read __assoc: A } } -- "토큰이 연관 타입 묶음 A 를 듦"
export type Token<N, A> = { read name: N, read __assoc: A }

--[[ 라이브러리 자신의 어휘도 같은 도구로 정의 ]]
export type HasItem<T> = Assoc<{ read Item: Inv<T> }>
local function push<Self, T>(x: Self & HasItem<T>, item: T): Self
	return x
end
local function itemOf<Self, T>(x: Self & HasItem<T>): T
	return nil :: any
end

--[[ 바깥 사람: 새 계약(그래프)과 새 연관 타입(Node, Edge)을 정의 — 도구 둘만 씀 ]]
type HasNode<N> = Assoc<{ read Node: Inv<N> }>
type HasEdge<E> = Assoc<{ read Edge: Inv<E> }>
local function nodes<Self, N>(g: Self & HasNode<N>): () -> N?
	return nil :: any
end
local function link<Self, N, E>(g: Self & HasNode<N> & HasEdge<E>, a: N, b: N, e: E): Self
	return g
end

--[[ 다른 바깥 사람: 우리 Item 과 그래프의 Node·Edge 를 다 드는 컨테이너 ]]
type Graph<T, N, E> = {
	verts: { N },
	read __type: Token<"Other.Graph", { read Item: Inv<T>, read Node: Inv<N>, read Edge: Inv<E> }>,
}
local g: Graph<boolean, string, number> = nil :: any
local i1: boolean = itemOf(g) -- 우리 계약은 Item 만 봄
local g2: Graph<boolean, string, number> = push(g, true)
for n in nodes(g) do -- 그래프 계약은 Node 만 봄
	local _s: string = n
end
local g3: Graph<boolean, string, number> = link(g, "a", "b", 1)
local negI = push(g, "x") -- NEG
local negN: number = itemOf(g) -- NEG
local negLink = link(g, 1, "b", 1) -- NEG: 노드 타입
local negLink2 = link(g, "a", "b", "e") -- NEG: 간선 타입
local canary: string = 1
return { i1, g2, g3, negI, negN, negLink, negLink2, canary }

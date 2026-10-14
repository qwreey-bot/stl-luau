--!strict
type Inv<T> = (T) -> T
type Assoc<A> = { read __type: { read __assoc: A } }
type Token<N, A> = { read name: N, read __assoc: A }
type HasNode<N> = { read __type: { read __assoc: { read Node: (N) -> N } } }
local function nodeOf<Self, N>(g: Self & HasNode<N>): N
	return nil :: any
end
-- 필드 둘(Node, Edge)
local g2: { read __type: Token<"G2", { read Node: (string) -> string, read Edge: (number) -> number }> } = nil :: any
local a: string = nodeOf(g2)
-- 필드 둘(Item, Node)
local g2b: { read __type: Token<"G2b", { read Item: (boolean) -> boolean, read Node: (string) -> string }> } = nil :: any
local b: string = nodeOf(g2b)
-- 필드 셋(Edge, Node, Weight) — Item 없이
local g3: { read __type: Token<"G3", { read Edge: (number) -> number, read Node: (string) -> string, read Weight: (boolean) -> boolean }> } = nil :: any
local c: string = nodeOf(g3)
-- 필드 하나(Node)
local g1: { read __type: Token<"G1", { read Node: (string) -> string }> } = nil :: any
local d: string = nodeOf(g1)
return { a, b, c, d }

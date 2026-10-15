--!strict
-- probe14: Borrowed read reference with record mapping

local stl = require("../src")
type CircularDeque<T> = stl.CircularDeque<T>
type CircularDequeRead<T> = stl.CircularDequeRead<T>

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

type ItemIndexRead<E, I> = { read __readGenerics: { read Item: () -> E, read Index: () -> I } }
type AnyToken = { read name: string }

type ListDef<Self, E, I> = {
	Get: Req<(Self, I) -> E?>,
	IndexOf: Def<(Self, E) -> I?>,
}

type List<Self, E, I> = FullOf<ListDef<Self, E, I>>

type ListFactory = {
	Of: (<Self, E, I>(of: (Self & ItemIndexRead<E, I>) | AnyToken) -> List<Self, E, I>)
}

local ListMod: ListFactory = nil :: any

local d: CircularDeque<number> = stl.CircularDeque.Of(1, 2, 3)
local borrowed: CircularDequeRead<number> = d

-- 1. 빌린 참조로 Of 호출
local l = ListMod.Of(borrowed)
local found: number? = l.IndexOf(borrowed, 2)
local NEG_borrowFound: string? = l.IndexOf(borrowed, 2) -- NEG

local canary: string = 1

--!strict
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }

local function Def<F>(build: any): F
	return nil :: any
end

local function buildFn(ops: any) return nil end

const E1 = {
	M = Def<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(123),
}
const E2 = {
	M = Def<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(function(ops: any) return nil end),
}
const E3 = {
	M = Def<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(buildFn),
}

-- E1.M<<number, number, number>> 직접 인스턴스화
local m1 = E1.M<<number, number, number>>
local _t1: string = m1

-- E2.M<<number, number, number>> 직접 인스턴스화
local m2 = E2.M<<number, number, number>>
local _t2: string = m2

-- E3.M<<number, number, number>> 직접 인스턴스화
local m3 = E3.M<<number, number, number>>
local _t3: string = m3

--!strict
-- probes/q1_defect_isolation.luau
-- Q1 현상 규명: 람다 인자가 포함된 Default 와 typeof 별칭 인스턴스화 누락
type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }

local function Fn<F>(): F
	return nil :: any
end

local function Def<F>(build: any): F
	return nil :: any
end

local externalBuildFn = function(ops: any) return nil end

const Entries = {
	-- 케이스 1: 인자 없는 Fn
	FromFn = Fn<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(),
	-- 케이스 2: 상수 인자가 있는 Def
	FromConst = Def<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(123),
	-- 케이스 3: 외부 함수 인자가 있는 Def
	FromExternal = Def<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(externalBuildFn),
	-- 케이스 4: 인라인 람다 인자가 있는 Def (문제의 케이스)
	FromInline = Def<< <Self, E, I>(list: Self & ItemIndex<E, I>, item: E) -> I? >>(function(ops: any) return nil end),
}

export type TableWrapper<Self, E, I> = {
	FromFn: typeof(Entries.FromFn<<Self, E, I>>),
	FromConst: typeof(Entries.FromConst<<Self, E, I>>),
	FromExternal: typeof(Entries.FromExternal<<Self, E, I>>),
	FromInline: typeof(Entries.FromInline<<Self, E, I>>),
}

local w: TableWrapper<number, number, number> = nil :: any

-- 각각의 구체화 타입 검사
local _t1: string = w.FromFn        -- (ItemIndex<number, number> & number, number) -> number?
local _t2: string = w.FromConst     -- (ItemIndex<number, number> & number, number) -> number?
local _t3: string = w.FromExternal  -- (ItemIndex<number, number> & number, number) -> number?
local _t4: string = w.FromInline    -- (ItemIndex<E, I> & Self, E) -> I?  <-- 치환 누락!

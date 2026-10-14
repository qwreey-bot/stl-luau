--!strict
-- A(v6): 바깥 사람이 자기 컨테이너로 List 를 구현할 때의 실수들
local P = require("./trait-v6/Traits")
local Trait = require("./trait-v6/Trait")
type A = Trait.A
type List<Self, E, I> = P.List<Self, E, I>

-- 바깥 사람의 컨테이너(원소 T, 위치 number)
export type MyList<T> = { items: { T }, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T }, read __readIndex: { read Item: () -> number } }
local function get<T>(l: MyList<T>, i: number): T? return l.items[i] end
local function first<T>(l: MyList<T>): number? return if #l.items > 0 then 1 else nil end
local function last<T>(l: MyList<T>): number? return if #l.items > 0 then #l.items else nil end
local function nxt<T>(l: MyList<T>, i: number): number? return if i < #l.items then i + 1 else nil end
local function prv<T>(l: MyList<T>, i: number): number? return if i > 1 then i - 1 else nil end

-- (1) 처음 보는 사람: 필수 다섯만 적음 → A 는 기본 구현 칸 셋을 Inherit 로 채우라고 해야 함
const first1: List<MyList<A>, A, number> = { Get = get, FirstIndex = first, LastIndex = last, NextIndex = nxt, PrevIndex = prv }
-- (2) 필수 칸에 Inherit — 타입 0건
const inh: List<MyList<A>, A, number> = { Get = get, FirstIndex = Trait.Inherit, LastIndex = Trait.Inherit, NextIndex = Trait.Inherit, PrevIndex = Trait.Inherit, IndexOf = Trait.Inherit, Contains = Trait.Inherit, Fold = Trait.Inherit }
return { first1, inh }

--!strict
-- B(v8): 같은 바깥 사람
local P = require("./trait-v8/Traits")
local Trait = require("./trait-v8/Trait")
type A = Trait.A
type List<Self, E, I> = P.List<Self, E, I>
type ListImpl<Self, E, I> = P.ListImpl<Self, E, I>

export type MyList<T> = { items: { T }, read __generics: { read Item: (T) -> T } }
local function get<T>(l: MyList<T>, i: number): T? return l.items[i] end
local function first<T>(l: MyList<T>): number? return if #l.items > 0 then 1 else nil end
local function last<T>(l: MyList<T>): number? return if #l.items > 0 then #l.items else nil end
local function nxt<T>(l: MyList<T>, i: number): number? return if i < #l.items then i + 1 else nil end
local function prv<T>(l: MyList<T>, i: number): number? return if i > 1 then i - 1 else nil end
local function myIndexOfStr(l: MyList<string>, x: string): number? return nil end

-- (1) 필수 다섯만 — 통과해야 함
const ok: ListImpl<MyList<A>, A, number> = { Get = get, FirstIndex = first, LastIndex = last, NextIndex = nxt, PrevIndex = prv }
-- (2) 처음 보는 사람이 Impl 대신 List(완성 보기)로 주석 — 어떤 문구?
const wrongAlias: List<MyList<A>, A, number> = { Get = get, FirstIndex = first, LastIndex = last, NextIndex = nxt, PrevIndex = prv }
-- (3) 재정의 서명 틀림(원소를 못박음)
const badOv: ListImpl<MyList<A>, A, number> = { Get = get, FirstIndex = first, LastIndex = last, NextIndex = nxt, PrevIndex = prv, IndexOf = myIndexOfStr }
-- (4) 재정의 이름 오타(IndexOff) — 타입은?
const typo: ListImpl<MyList<A>, A, number> = { Get = get, FirstIndex = first, LastIndex = last, NextIndex = nxt, PrevIndex = prv, IndexOff = get }
-- (5) 필수 빠짐
const miss: ListImpl<MyList<A>, A, number> = { Get = get, FirstIndex = first, LastIndex = last, NextIndex = nxt }
return { ok, wrongAlias, badOv, typo, miss }

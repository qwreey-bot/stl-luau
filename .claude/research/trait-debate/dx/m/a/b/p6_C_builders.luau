--!strict
-- C 를 실제 List 처럼: 기본 구현은 형제(ops)를 받아야 함(빌더). 후보 문서의 C 조각은 ops 가 없음.
local Trait = require("./trait-v8/Trait")
type ItemIndexRead<E, I> = Trait.ItemIndexRead<E, I>
type A = Trait.A
local function Fn<F>(): F return nil :: any end

local function listReq<Self, E, I>()
	return {
		Get = Fn<<(list: Self, idx: I) -> E?>>(),
		FirstIndex = Fn<<(list: Self) -> I?>>(),
		NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),
	}
end
local function listDefaults<Self, E, I>()
	return {
		IndexOf = function(ops: List<Self, E, I>)
			const get, firstIndex, nextIndex = ops.Get, ops.FirstIndex, ops.NextIndex
			return function(list: Self, item: E): I?
				local idx = firstIndex(list)
				while idx ~= nil do
					if get(list, idx) == item then
						return idx
					end
					idx = nextIndex(list, idx)
				end
				return nil
			end
		end,
		Contains = function(ops: List<Self, E, I>)
			const indexOf = ops.IndexOf
			return function(list: Self, item: E): boolean
				return indexOf(list, item) ~= nil
			end
		end,
	}
end
type Built<Self, E, I> = {
	IndexOf: typeof(listDefaults<<Self, E, I>>().IndexOf(nil :: any)),
	Contains: typeof(listDefaults<<Self, E, I>>().Contains(nil :: any)),
}
export type List<Self, E, I> = typeof(listReq<<Self, E, I>>()) & Built<Self, E, I>
export type ListImpl<Self, E, I> = typeof(listReq<<Self, E, I>>()) & {
	IndexOf: typeof(listDefaults<<Self, E, I>>().IndexOf(nil :: any))?,
	Contains: typeof(listDefaults<<Self, E, I>>().Contains(nil :: any))?,
}

export type MyList<T> = { items: { T } }
local function get<T>(l: MyList<T>, i: number): T? return l.items[i] end
local function first<T>(l: MyList<T>): number? return 1 end
local function nxt<T>(l: MyList<T>, i: number): number? return nil end
local function strIndexOf(l: MyList<string>, x: string): number? return nil end
const ok: ListImpl<MyList<A>, A, number> = { Get = get, FirstIndex = first, NextIndex = nxt }
const NEG_ov: ListImpl<MyList<A>, A, number> = { Get = get, FirstIndex = first, NextIndex = nxt, IndexOf = strIndexOf } -- NEG
const NEG_miss: ListImpl<MyList<A>, A, number> = { Get = get, FirstIndex = first } -- NEG
local full: List<MyList<number>, number, number> = nil :: any
local m: MyList<number> = nil :: any
const w: number? = full.IndexOf(m, 1)
const NEG_w: string? = full.IndexOf(m, 1) -- NEG
const NEG_c: string = full.Contains(m, 1) -- NEG
local canary: string = 1
return { ok, NEG_ov, NEG_miss, w, NEG_w, NEG_c, canary }

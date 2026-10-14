--!strict
local Trait = require("./trait-v8/Trait")
local TraitD = require("./TraitD")
type Item<T> = Trait.Item<T>
type ItemIndexRead<E, I> = Trait.ItemIndexRead<E, I>
type AnyToken = Trait.AnyToken
type A = Trait.A
type DefaultFn<M> = TraitD.DefaultFn<M>
const Fn = Trait.Fn

-- D1: 바깥 겹이 Default 를 받음(주석 있음)
const List = TraitD.WithDefaults("ListD", function<M>(Default: DefaultFn<M>)
	return function<Self, E, I>(of: (Self & ItemIndexRead<E, I>) | AnyToken)
		return {
			Get = Fn<<(list: Self, idx: I) -> E?>>(),
			FirstIndex = Fn<<(list: Self) -> I?>>(),
			NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),
			IndexOf = Default(function(ops: List<Self, E, I>)
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
			end),
			Contains = Default(function(ops: List<Self, E, I>)
				const indexOf = ops.IndexOf
				return function(list: Self, item: E): boolean
					return indexOf(list, item) ~= nil
				end
			end),
			Fold = Default(function(ops: List<Self, E, I>)
				const get, firstIndex, nextIndex = ops.Get, ops.FirstIndex, ops.NextIndex
				return function<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U): U
					local acc, idx = init, firstIndex(list)
					while idx ~= nil do
						acc = fn(acc, get(list, idx) :: E, idx)
						idx = nextIndex(list, idx)
					end
					return acc
				end
			end),
			Wrong = Default(function(ops: List<Self, E, I>)
				return function(list: Self): E
					return "s" -- NEG: 몸통의 반환 타입
				end
			end),
		}
	end
end)
export type List<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))
export type ListImpl<Self, E, I> = typeof(List.ImplOf<<Self, E, I>>(nil :: any))

-- 바깥 사람의 컨테이너
export type MyList<T> = { items: { T }, read __readGenerics: { read Item: () -> T, read Index: () -> number } }
local function get<T>(l: MyList<T>, i: number): T? return l.items[i] end
local function first<T>(l: MyList<T>): number? return if #l.items > 0 then 1 else nil end
local function nxt<T>(l: MyList<T>, i: number): number? return if i < #l.items then i + 1 else nil end
local function strIndexOf(l: MyList<string>, x: string): number? return nil end
local function len<T>(l: MyList<T>): number return #l.items end

const ok: ListImpl<MyList<A>, A, number> = { Get = get, FirstIndex = first, NextIndex = nxt }
const ov: ListImpl<MyList<A>, A, number> = { Get = get, FirstIndex = first, NextIndex = nxt, Contains = function(l: MyList<A>, x: A): boolean return false end }
const NEG_ov: ListImpl<MyList<A>, A, number> = { Get = get, FirstIndex = first, NextIndex = nxt, IndexOf = strIndexOf } -- NEG
const NEG_fold: ListImpl<MyList<A>, A, number> = { Get = get, FirstIndex = first, NextIndex = nxt, Fold = len } -- NEG
const NEG_miss: ListImpl<MyList<A>, A, number> = { Get = get, FirstIndex = first } -- NEG
-- 쓰는 자리
local m: MyList<number> = { items = { 10, 20 } } :: any
const L = List.Of(m)
const where: number? = L.IndexOf(m, 20)
const has: boolean = L.Contains(m, 20)
const s: string = L.Fold(m, "", function(acc: string, x: number, _i: number): string return acc end)
const NEG_where: string? = L.IndexOf(m, 20) -- NEG
const NEG_has = L.Contains(m, "x") -- NEG
const NEG_ret: string = L.Contains(m, 1) -- NEG

-- D2: 바깥 겹의 주석을 잊음(function(Default))
const Size = TraitD.WithDefaults("SizeD2", function(Default)
	return function<Self, T>(of: (Self & Item<T>) | AnyToken)
		return {
			Len = Fn<<(s: Self) -> number>>(),
			IsEmpty = Default(function(ops: any)
				return function(s: Self): boolean return true end
			end),
		}
	end
end)
export type Size<Self, T> = typeof(Size.Of<<Self, T>>(nil :: any))
export type SizeImpl<Self, T> = typeof(Size.ImplOf<<Self, T>>(nil :: any))
const szImpl: SizeImpl<{ n: number }, number> = { Len = function(_s: { n: number }): number return 0 end }
local szFull: Size<{ n: number }, number> = nil :: any
const e: boolean = szFull.IsEmpty({ n = 1 })

local canary: string = 1
return { ok, ov, NEG_ov, NEG_fold, NEG_miss, where, has, s, NEG_where, NEG_has, NEG_ret, szImpl, e, canary }

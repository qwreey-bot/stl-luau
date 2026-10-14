--!strict
-- D2: 같은 모듈에서 정의·등록·쓰기. 기본 구현 없는 Stack 은 한 겹, List 는 B'
local Trait = require("../trait-v8/Trait")
local TF = require("../TraitF")
type Item<T> = Trait.Item<T>
type ItemIndexRead<E, I> = Trait.ItemIndexRead<E, I>
type AnyToken = Trait.AnyToken
type A = Trait.A
const Fn, Default = Trait.Fn, Trait.Default

const Stack = TF.Trait("StackF", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return {
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
	}
end)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))

local function listDef<M>(mode: M)
	return function<Self, E, I>(of: (Self & ItemIndexRead<E, I>) | AnyToken)
		return {
			Get = Fn<<(list: Self, idx: I) -> E?>>(),
			FirstIndex = Fn<<(list: Self) -> I?>>(),
			NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),
			Contains = Default(mode, function(ops: List<Self, E, I>)
				const get, firstIndex, nextIndex = ops.Get, ops.FirstIndex, ops.NextIndex
				return function(list: Self, item: E): boolean
					local idx = firstIndex(list)
					while idx ~= nil do
						if get(list, idx) == item then
							return true
						end
						idx = nextIndex(list, idx)
					end
					return false
				end
			end),
			Fold = Default(mode, function(ops: List<Self, E, I>)
				return function<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I, ...any) -> U): U
					return init
				end
			end),
		}
	end
end
const List = TF.Trait("ListF", listDef<<"full">>)
export type List<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))
export type ListImpl<Self, E, I> = typeof(List.ImplOf<<Self, E, I>>(nil :: any))
export type MyArr<T> = { items: { T }, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T, read Index: () -> number } }
local function get<T>(l: MyArr<T>, i: number): T? return l.items[i] end
local function first<T>(l: MyArr<T>): number? return 1 end
local function nxt<T>(l: MyArr<T>, i: number): number? return nil end
const li: ListImpl<MyArr<A>, A, number> = { Get = get, FirstIndex = first, NextIndex = nxt } -- 구현자 줄(정상)
const NEG_li: ListImpl<MyArr<A>, A, number> = { Get = get, FirstIndex = first, NextIndex = nxt, Contains = get } -- NEG
local m: MyArr<number> = nil :: any
const has: boolean = List.Of(m).Contains(m, 1) -- 쓰는 줄(정상)
const NEG_has: string = List.Of(m).Contains(m, 1) -- NEG
return { li, NEG_li, has, NEG_has }

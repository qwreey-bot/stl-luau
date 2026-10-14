--!strict
local Trait = require("./trait-v8/Trait")
local TE = require("./TraitE")
type Item<T> = Trait.Item<T>
type ItemIndexRead<E, I> = Trait.ItemIndexRead<E, I>
type AnyToken = Trait.AnyToken
type A = Trait.A
const Fn, Default = Trait.Fn, Trait.Default

-- 기본 구현 없는 트레이트: A 모양 한 겹
const Stack = TE.Trait("StackE", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return {
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
	}
end)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))

-- 기본 구현 있는 트레이트: B 모양 두 겹
const List = TE.Trait("ListE", function<M>(mode: M)
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
		}
	end
end)
export type List<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))
export type ListImpl<Self, E, I> = typeof(List.ImplOf<<Self, E, I>>(nil :: any))

export type MyArr<T> = { items: { T }, read __generics: { read Item: (T) -> T }, read __readGenerics: { read Item: () -> T, read Index: () -> number } }
local function push<T>(a: MyArr<T>, v: T): MyArr<T> return a end
local function pop<T>(a: MyArr<T>): T? return nil end
local function strPush(a: MyArr<string>, v: string): MyArr<string> return a end
local function get<T>(l: MyArr<T>, i: number): T? return l.items[i] end
local function first<T>(l: MyArr<T>): number? return 1 end
local function nxt<T>(l: MyArr<T>, i: number): number? return nil end

const st: StackImpl<MyArr<A>, A> = { Push = push, Pop = pop }
const NEG_st: StackImpl<MyArr<A>, A> = { Push = strPush, Pop = pop } -- NEG
const NEG_stMiss: StackImpl<MyArr<A>, A> = { Push = push } -- NEG
const li: ListImpl<MyArr<A>, A, number> = { Get = get, FirstIndex = first, NextIndex = nxt }
const NEG_li: ListImpl<MyArr<A>, A, number> = { Get = get, FirstIndex = first, NextIndex = nxt, Contains = get } -- NEG
local m: MyArr<number> = nil :: any
const popped: number? = Stack.Of(m).Pop(m)
const NEG_push = Stack.Of(m).Push(m, "x") -- NEG
const has: boolean = List.Of(m).Contains(m, 1)
const NEG_has: string = List.Of(m).Contains(m, 1) -- NEG
local canary: string = 1
return { st, NEG_st, NEG_stMiss, li, NEG_li, popped, NEG_push, has, NEG_has, canary }

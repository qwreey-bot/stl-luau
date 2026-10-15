--!strict
-- 진입점 타입 입히기: 트레이트 객체 타입(인덱서 없음) & 진입점 서명(트레이트 파일이 적음)
local Trait = require("./Trait")
local stl = require("../../../src")
type Item<T> = Trait.Item<T>
type ItemIndexRead<E, I> = Trait.ItemIndexRead<E, I>
type AnyToken = Trait.AnyToken
type A = Trait.A
const Fn, Default = Trait.Fn, Trait.Default

const StackBase = Trait.Trait("OvStack", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return table.freeze({
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
		Peek = Fn<<(stack: Self) -> T?>>(),
	})
end)
const Stack = StackBase :: typeof(StackBase) & {
	read Push: <C, T>(stack: C & Item<T>, item: T) -> C,
	read Pop: <C, T>(stack: C & Item<T>) -> T?,
}
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))

local function listDef<M>(mode: M)
	return function<Self, E, I>(of: (Self & ItemIndexRead<E, I>) | AnyToken)
		return table.freeze({
			Get = Fn<<(list: Self, idx: I) -> E?>>(),
			Has = Default(mode, function(ops: any)
				return function(list: Self, item: E): boolean
					return false
				end
			end),
		})
	end
end
const ListBase = Trait.Trait("OvList", listDef(Trait.FULL), listDef(Trait.IMPL))
const List = ListBase :: typeof(ListBase) & {
	read Has: <S, E, I>(list: S & ItemIndexRead<E, I>, item: E) -> boolean,
}
export type List<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))
export type ListImpl<Self, E, I> = typeof(List.ImplOf<<Self, E, I>>(nil :: any))

local d = stl.CircularDeque.Of(1, 2)
-- 진입점
const p: stl.CircularDeque<number> = Stack.Push(d, 3)
Stack.Push(d, "x") -- NEG
const NEG_pop: string? = Stack.Pop(d) -- NEG
const h: boolean = List.Has(d, 1)
-- Of 와 명시 인스턴스화
const s = Stack.Of(d)
s.Push(d, 1)
s.Push(d, "x") -- NEG
const byTok = Stack.Of<<stl.CircularDeque<number>, number>>(d)
const NEG_l: string = List.Of(d).Has(d, 1) -- NEG (같은 모듈 기본 구현 반환)
-- 등록
const reg: StackImpl<stl.CircularDeque<A>, A> = { Push = stl.CircularDeque.PushBack, Pop = stl.CircularDeque.PopBack, Peek = stl.CircularDeque.Back }
Stack.ImplFor(Trait.NewToken and nil :: any, reg)
const NEG_reg: StackImpl<stl.CircularDeque<A>, A> = { Push = stl.CircularDeque.PushBack, Pop = stl.CircularDeque.Len, Peek = stl.CircularDeque.Back } -- NEG
-- 없는 이름은 이제 에러(인덱서가 없으니)
const NEG_nope = Stack.Nope -- NEG
local canary: string = 1
return { p, NEG_pop, h, s, byTok, NEG_l, reg, NEG_reg, NEG_nope }

--!strict
-- J1b: 같은 트레이트가 첫 기본 구현(IsEmpty)을 얻음 → 정의만 두 인자 모양으로. 바깥 등록 두 줄은 J1a 와 글자 그대로
local Trait = require("../trait-v9/Trait")
local stl = require("../../../src")
type Arr<T> = stl.Arr<T>
type Item<T> = Trait.Item<T>
type A = Trait.A
const Fn, Default = Trait.Fn, Trait.Default
local function stackDef<M>(mode: M)
	return function<Self, T>(of: (Self & Item<T>) | Trait.AnyToken)
		return {
			Push = Fn<<(stack: Self, item: T) -> Self>>(),
			Pop = Fn<<(stack: Self) -> T?>>(),
			IsEmpty = Default(mode, function(ops: Stack<Self, T>)
				return function(s: Self): boolean
					return false
				end
			end),
		}
	end
end
const Stack = Trait.Trait("J1Stack", stackDef(Trait.FULL), stackDef(Trait.IMPL))
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))
const arrStack: StackImpl<Arr<A>, A> = { Push = stl.Arr.PushBack, Pop = stl.Arr.PopBack }
Stack.ImplFor(Trait.Token("J1.Arr"), arrStack)
local function drain<C, T>(st: Stack<C, T>, c: C): T?
	return st.Pop(c)
end
-- 같은 모듈에서 새 기본 구현의 반환
const a: Arr<number> = stl.Arr.Of(1)
const ok: boolean = Stack.Of<<Arr<number>, number>>(a).IsEmpty(a)
const NEG_ret: string = Stack.Of<<Arr<number>, number>>(a).IsEmpty(a) -- NEG
const NEG_override: StackImpl<Arr<A>, A> = { Push = stl.Arr.PushBack, Pop = stl.Arr.PopBack, IsEmpty = stl.Arr.Len } -- NEG: number 반환
local canary: string = 1
return { drain, ok, NEG_ret, NEG_override, canary }

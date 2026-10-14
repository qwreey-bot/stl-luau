--!strict
-- J1a: 기본 구현 없는 트레이트(D3 한 겹) + 바깥 등록(StackImpl 별칭) — "자라기 전"
local Trait = require("../trait-v9/Trait")
local stl = require("../../../src")
type Arr<T> = stl.Arr<T>
type Item<T> = Trait.Item<T>
type A = Trait.A
const Fn = Trait.Fn
const Stack = Trait.Trait("J1Stack", function<Self, T>(of: (Self & Item<T>) | Trait.AnyToken)
	return { Push = Fn<<(stack: Self, item: T) -> Self>>(), Pop = Fn<<(stack: Self) -> T?>>() }
end)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))
-- 바깥 사람의 등록(이 두 줄은 J1b 에서도 글자 그대로)
const arrStack: StackImpl<Arr<A>, A> = { Push = stl.Arr.PushBack, Pop = stl.Arr.PopBack }
Stack.ImplFor(Trait.Token("J1.Arr"), arrStack)
local function drain<C, T>(st: Stack<C, T>, c: C): T?
	return st.Pop(c)
end
local canary: string = 1
return { drain, canary }

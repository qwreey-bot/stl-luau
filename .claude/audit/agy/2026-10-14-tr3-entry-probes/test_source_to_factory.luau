--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
type AnyToken = { read name: string }

local function Fn<T>(): T
	return nil :: any
end

-- 1. 진입점 서명을 단 한 번 적는다 (단일 원천 S)
const S = {
	Push = Fn<< <Self, T>(stack: Self & Item<T>, item: T) -> Self >>(),
	Pop = Fn<< <Self, T>(stack: Self & Item<T>) -> T? >>(),
}

-- 2. 팩토리가 S 를 받아서 Self, T 로 구체화된 완성 표를 반환할 수 있는가?
local function factory<Self, T>(of: (Self & Item<T>) | AnyToken)
	return {
		Push = S.Push<<Self, T>>,
		Pop = S.Pop<<Self, T>>,
	}
end

export type Stack<Self, T> = typeof(factory<<Self, T>>(nil :: any))

-- 확인: Stack<Self, T> 가 올바른 완성 표 타입인가?
type NumStack = Stack<number, string>
local dummy: NumStack = nil :: any
local _check_push: string = dummy.Push
local _check_pop: string = dummy.Pop

local canary: string = 1

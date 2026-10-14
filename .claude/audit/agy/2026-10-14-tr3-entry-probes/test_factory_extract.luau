--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
type AnyToken = { read name: string }

type Factory = <Self, T>(of: (Self & Item<T>) | AnyToken) -> {
	Push: (stack: Self, item: T) -> Self,
	Pop: (stack: Self) -> T?,
}

-- 1. Factory 의 반환 타입을 타입 레벨에서 꺼낼 수 있는가?
-- type Ret = return<Factory> -- Luau has no return<> type operator
-- type Ret = Factory["return"] -- No

-- 2. typeof(factory(...))
local factory: Factory = nil :: any
type RetOfCall = typeof(factory(nil :: any))

-- RetOfCall.Push 의 타입은?
local dummy: RetOfCall = nil :: any
local _check_push: string = dummy.Push

local canary: string = 1

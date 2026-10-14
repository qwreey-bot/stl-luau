--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
type AnyToken = { read name: string }

local function Fn<T>(): T
	return nil :: any
end

local factory = function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return {
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
	}
end

type F = typeof(factory)

-- factory 의 반환 타입을 얻으려고 하면?
type Ret = typeof(factory(nil :: any))
local dummy: Ret = nil :: any
local _check_push: string = dummy.Push

local canary: string = 1

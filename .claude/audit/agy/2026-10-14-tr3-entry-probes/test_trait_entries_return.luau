--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
type AnyToken = { read name: string }

local function Fn<T>(): T
	return nil :: any
end

local function Trait<E>(name: string, entries: E)
	-- E 로부터 Of 의 타입을 어떻게 만들 수 있을까?
	return entries
end

const StackEntries = {
	Push = Fn<< <Self, T>(stack: Self & Item<T>, item: T) -> Self >>(),
	Pop = Fn<< <Self, T>(stack: Self & Item<T>) -> T? >>(),
}

const Stack = Trait("Stack", StackEntries)

local _check_push: string = Stack.Push
local canary: string = 1

--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
type AnyToken = { read name: string }

type Object<F, E> = { read Of: F, read FnTok: { [string]: number } } & E

local function Trait<F, E>(name: string, factory: F): Object<F, E>
	return nil :: any
end

local Stack = Trait("Stack", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return {
		Push = nil :: any,
		Pop = nil :: any,
	}
end)

-- Stack.Push 를 호출하면?
local _check_push: string = Stack.Push
local canary: string = 1

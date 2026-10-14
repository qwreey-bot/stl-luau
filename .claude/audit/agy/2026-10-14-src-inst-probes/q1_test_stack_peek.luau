--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
type AnyToken = { read name: string }

local DEFAULT_MARK = table.freeze({})
local function Default<F>(build: any): F
	return table.freeze({ [DEFAULT_MARK] = build }) :: any
end

const StackEntries = {
	Peek = Default<< <Self, T>(stack: Self & Item<T>) -> T? >>(function(ops: any)
		return nil
	end),
}
export type Stack<Self, T> = {
	Peek: typeof(StackEntries.Peek<<Self, T>>),
}
type StackObject = typeof(StackEntries) & {
	Of: <Self, T>(of: (Self & Item<T>) | AnyToken) -> Stack<Self, T>,
}
const Stack: StackObject = nil :: any

type MyDeque<T> = {
	items: { T },
	read __generics: { read Item: (T) -> T },
}
local d: MyDeque<number> = nil :: any

local s = Stack.Of(d)
local _peek = s.Peek(d)

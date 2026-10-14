--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }

type PushGeneric = <Self, T>(stack: Self & Item<T>, item: T) -> Self

local push: PushGeneric = nil :: any

local f = push<<number, number>>
local _check_f: string = f

type Ops<C, T> = {
	-- Can we specialize PushGeneric to (C, T) -> C ?
}

local canary: string = 1

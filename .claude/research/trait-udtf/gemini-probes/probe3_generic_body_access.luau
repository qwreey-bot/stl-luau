--!strict
type function identity(t: type): type
	return t
end

type GenericOuter<T> = {
	fn: <U>(x: T, y: U) -> (T, U),
}

type Wrapped<T> = identity<GenericOuter<T>>

local function use<T>(w: Wrapped<T>, val: T)
	local res1, res2 = w.fn(val, "hello")
	return res1
end

local canary: string = 1

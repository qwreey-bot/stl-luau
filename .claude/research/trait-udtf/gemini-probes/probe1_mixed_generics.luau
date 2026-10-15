--!strict
type function identity(t: type): type
	return t
end

type GenericOuter<T> = {
	fn: <U>(x: T, y: U) -> (T, U),
}

type Instantiated = identity<GenericOuter<number>>

local canary: string = 1

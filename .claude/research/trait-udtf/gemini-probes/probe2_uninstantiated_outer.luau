--!strict
type function identity(t: type): type
	return t
end

type GenericOuter<T> = {
	fn: <U>(x: T, y: U) -> (T, U),
}

-- 제네릭 타입 별칭 정의 안에서 타입 함수를 호출:
type Wrapped<T> = identity<GenericOuter<T>>

local function test<T>(x: Wrapped<T>)
	return x
end

local canary: string = 1

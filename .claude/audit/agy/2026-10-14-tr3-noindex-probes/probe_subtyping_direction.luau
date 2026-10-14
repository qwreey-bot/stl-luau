--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }

-- Case 1: Target expects (C, T) -> C, but provided is (C & Item<T>, T) -> C
type TargetWithoutItem<C, T> = {
	Push: (C, T) -> C
}
type SourceWithItem<C, T> = {
	Push: (C & Item<T>, T) -> C
}

local function test1<C, T>(src: SourceWithItem<C, T>): TargetWithoutItem<C, T>
	return { Push = src.Push } -- DOES THIS FAIL?
end

-- Case 2: Target expects (C & Item<T>, T) -> C, but provided is (C, T) -> C
local function test2<C, T>(src: TargetWithoutItem<C, T>): SourceWithItem<C, T>
	return { Push = src.Push } -- DOES THIS FAIL?
end

local canary: string = 1

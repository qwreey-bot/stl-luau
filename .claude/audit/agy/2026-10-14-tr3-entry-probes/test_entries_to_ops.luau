--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
type AnyToken = { read name: string }

local function Fn<T>(): T
	return nil :: any
end

local entries = {
	Push = Fn<< <Self, T>(stack: Self & Item<T>, item: T) -> Self >>(),
	Pop = Fn<< <Self, T>(stack: Self & Item<T>) -> T? >>(),
}

-- entries 의 각 함수는 제네릭 함수다.
-- 여기서 C, T 에 대한 완성 표 타입을 만들 수 있는가?

-- 시도 1: typeof(entries)
type Entries = typeof(entries)

type Ops<C, T> = {
	Push: typeof(entries.Push<<C, T>>),
	Pop: typeof(entries.Pop<<C, T>>),
}

local dummy_ops: Ops<number, string> = nil :: any
local _check_ops_push: string = dummy_ops.Push
local canary: string = 1

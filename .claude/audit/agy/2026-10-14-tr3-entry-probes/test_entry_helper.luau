--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }
type AnyToken = { read name: string }

type Factory<Self, T> = (of: (Self & Item<T>) | AnyToken) -> {
	Push: (stack: Self, item: T) -> Self,
	Pop: (stack: Self) -> T?,
}

-- 헬퍼: factory 로부터 제네릭 진입점을 추출할 수 있는가?
-- 만약 EntryMaker 가 factory 를 받는다면?
local function entryPush<Self, T>(stack: Self & Item<T>, item: T): Self
	return stack
end

local canary: string = 1

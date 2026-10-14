--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }

-- 컨테이너 타입 정의 (Item<T> 를 구조적으로 포함)
type MyDeque<T> = {
	items: { T },
	read __generics: { read Item: (T) -> T },
}

local function dequePush<T>(self: MyDeque<T>, item: T): MyDeque<T>
	return self
end

type A = { read __probeA: true }

-- 진입점 서명에서 인스턴스화된 타입
type EntryPushInstantiated<Self, T> = (Self & Item<T>, T) -> Self

-- 순수 완성 표 타입
type PureOpsPush<Self, T> = (Self, T) -> Self

-- MyDeque<A> 에 대해 테스트
local f1: EntryPushInstantiated<MyDeque<A>, A> = dequePush
local f2: PureOpsPush<MyDeque<A>, A> = dequePush

local canary: string = 1

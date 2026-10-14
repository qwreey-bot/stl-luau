--!strict
local stl = require("../src")
local Arr = stl.Arr
type Arr<T> = stl.Arr<T>
type ArrData<T> = stl.ArrData<T>
type ArrRead<T> = stl.ArrRead<T>
type Item<T> = { read __generics: { read Item: (T) -> T } }
type A = { read __probeA: true }

-- [검증 1] 완성 표: Self & Item<T>는 ArrRead의 Push 호출을 성공적으로 차단함
type FullPush<Self, T> = (stack: Self & Item<T>, item: T) -> Self
local fullPush: FullPush<ArrRead<number>, number> = nil :: any
local r: ArrRead<number> = nil :: any
fullPush(r, 1) -- NEG: ArrRead lacks Item<number>

-- [검증 2] 등록 표: Self & Item<T>를 요구하면 제네릭 함수 대입이 깨짐!
type RegWithIntersection<Self, T> = {
	Push: (stack: Self & Item<T>, item: T) -> Self,
}
-- Arr.PushBack은 <T>(ArrData<T>, T) -> ArrData<T>
local NEG_regFail: RegWithIntersection<Arr<A>, A> = {
	Push = Arr.PushBack -- FAIL: 제네릭 함수 유니피케이션 실패
}

-- [검증 3] 등록 표: Self만 요구하면 제네릭 함수 대입이 성공함!
type RegPlain<Self, T> = {
	Push: (stack: Self, item: T) -> Self,
}
local regOk: RegPlain<Arr<A>, A> = {
	Push = Arr.PushBack -- 통과 (에러 0건)
}

local canary: string = 1

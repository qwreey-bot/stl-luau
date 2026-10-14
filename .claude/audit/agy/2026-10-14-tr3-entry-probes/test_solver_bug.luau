--!strict
type Item<T> = { read __generics: { read Item: (T) -> T } }

local function Fn<T>(): T
	return nil :: any
end

-- "제네릭 함수 몸통 안에서는 그 함수의 타입 매개변수가 구체 타입 자리에 조용히 들어갑니다"
-- 이게 무슨 뜻인지 실험:
local function outer<Self, T>()
	-- outer 안에서 Self, T 가 있는 상태
	-- 만약 여기서 제네릭 함수를 정의하거나 캐스트를 하면?
	local f: <S, U>(S & Item<U>, U) -> S = nil :: any

	-- 또는 Fn<<...>>() ?
	local g = Fn<<(s: Self, item: T) -> Self>>()
	-- g 는 (Self, T) -> Self
	
	return {
		g = g,
	}
end

local canary: string = 1

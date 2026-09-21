--!strict
-- quad 방식: 타입 파일에 **스텁 함수**를 두고 typeof 로 인터페이스를 만든다.
-- 구현 파일은 이 시그니처에 맞는 진짜 함수를 제공한다.
export type ArrData<T> = { n: number, [number]: T }

local function PushBack<T>(self: Arr<T>, v: T): Arr<T>
	return nil :: any
end
local function Map<T, G>(self: Arr<T>, fn: (el: T, idx: number) -> G): Arr<G>
	return nil :: any
end
local function Len<T>(self: Arr<T>): number
	return nil :: any
end

export type ArrIfce = { PushBack: typeof(PushBack), Map: typeof(Map), Len: typeof(Len) }
export type Arr<T> = ArrData<T> & ArrIfce

return {}

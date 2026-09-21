--!strict
--[[
	Arr — 배열 기반 순차 컨테이너.

	Types.ListCore<T, number> 를 만족하므로 Algorithm 의 공용 함수를 그대로
	쓸 수 있습니다(위치 타입이 number).
]]
local Types = require("./Types")

export type ArrData<T> = { n: number, [number]: T }

-- 콜백이 받는 뷰. **Arr<T> 를 언급하지 않습니다** — 언급하면 타입 변환
-- 체이닝이 죽습니다(.claude/audit/arr-type-redesign/).
export type ArrView<T> = ArrData<T> & {
	Len: (self: ArrView<T>) -> number,
	Slice: (self: ArrView<T>, s: number?, l: number?) -> ArrView<T>,
}

-- 메소드는 이름 붙은 top-level 함수로 쓰고 typeof 로 나열합니다(quad ③).
local Ifce: ArrIfce & Types.ListCore<any, number>

local function PushBack<T>(self: Arr<T>, v: T): Arr<T>
	local n = self.n + 1
	self[n] = v
	self.n = n
	return self
end
local function Map<T, G>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrView<T>) -> G): Arr<G>
	local len = self.n
	local result = table.create(len)
	result.n = len
	for idx = 1, len do
		result[idx] = fn(self[idx], idx, self :: any)
	end
	return setmetatable(result, Ifce :: any) :: any
end
local function Len<T>(self: Arr<T>): number
	return self.n
end
local function Get<T>(self: Arr<T>, idx: number): T?
	return self[idx]
end
local function FirstIndex<T>(self: Arr<T>): number?
	return if self.n > 0 then 1 else nil
end
local function LastIndex<T>(self: Arr<T>): number?
	return if self.n > 0 then self.n else nil
end
local function NextIndex<T>(self: Arr<T>, idx: number): number?
	return if idx < self.n then idx + 1 else nil
end
local function PrevIndex<T>(self: Arr<T>, idx: number): number?
	return if idx > 1 then idx - 1 else nil
end

-- ⭐ 계약(ListCore)이 주는 멤버는 **여기 다시 쓰지 않습니다.**
-- 중복 선언하면 self 타입이 달라 교집합이 충돌하고, 메소드 타입이
-- 통째로 죽습니다(실측: NoSuchMethod 도 안 잡힘).
type ArrIfce = {
	PushBack: typeof(PushBack),
	Map: typeof(Map),
	Len: typeof(Len),
}

-- 전체형 = 데이터부 & 메소드부 & 공유 계약.
-- setmetatable<> 이 아니라 교집합인 이유: 메소드 30개에서 붕괴합니다.
export type Arr<T> = ArrData<T> & ArrIfce & Types.ListCore<T, number>

Ifce = {
	PushBack = PushBack, Map = Map, Len = Len, Get = Get,
	FirstIndex = FirstIndex, LastIndex = LastIndex,
	NextIndex = NextIndex, PrevIndex = PrevIndex,
} :: any
;(Ifce :: any).__index = Ifce

local function Of<T>(...: T): Arr<T>
	local result = table.pack(...)
	return setmetatable(result, Ifce :: any) :: any
end
local function Sized<T>(len: number, fill: T): Arr<T>
	local result = table.create(len, fill)
	result.n = len
	return setmetatable(result, Ifce :: any) :: any
end

return {
	Of = Of,
	Sized = Sized,
}

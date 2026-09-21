--!strict
-- __iter 타입이 죽는 경계는 어디인가? 제네릭? 교집합? typeof 선언?
type Data<T> = { n: number, [number]: T }

--#region W1: 비제네릭 + 인라인 선언
type B1 = { n: number, [number]: number, __iter: (self: B1) -> (((B1, number) -> (number?, number?)), B1, number) }
local b1 = (nil :: any) :: B1
for i, v in b1 do
	local bad1: string = v
end
--#endregion

--#region W2: 비제네릭 + 교집합 없음 + 단순 클로저
type B2 = { n: number, __iter: (self: B2) -> () -> (number?, number?) }
local b2 = (nil :: any) :: B2
for i, v in b2 do
	local bad2: string = v
end
--#endregion

--#region W3: 제네릭이지만 교집합 아님 (단일 테이블 타입)
type B3<T> = { n: number, [number]: T, __iter: (self: B3<T>) -> (((B3<T>, number) -> (number?, T?)), B3<T>, number) }
local b3 = (nil :: any) :: B3<number>
for i, v in b3 do
	local bad3: string = v
end
--#endregion

--#region W4: setmetatable<> 로 __iter 를 붙임
type Ifce4 = { __iter: (self: any) -> (((any, number) -> (number?, number?)), any, number) }
type B4 = setmetatable<Data<number>, Ifce4>
local b4 = (nil :: any) :: B4
for i, v in b4 do
	local bad4: string = v
end
--#endregion

--#region W5: 통제군 — __iter 없이 교집합만 (인덱서로 순회)
type B5 = Data<number> & { Len: (self: B5) -> number }
local b5 = (nil :: any) :: B5
for i, v in b5 do
	local bad5: string = v
end
--#endregion

local canary: string = 42
return { canary }

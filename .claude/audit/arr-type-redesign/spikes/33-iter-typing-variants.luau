--!strict
-- __iter 를 어떻게 선언해야 for-in 루프 변수의 타입이 사는가?
-- 기준: NEG(루프 변수를 틀린 타입에 대입)가 잡혀야 살아있는 것.
type Data<T> = { n: number, [number]: T }

--#region V1: __iter 가 (fn, state, control) 3튜플 — 지금 쓴 것
local function Iter1<T>(self: A1<T>): (((Data<T>, number) -> (number?, T?)), Data<T>, number)
	return nil :: any
end
type A1<T> = Data<T> & { __iter: typeof(Iter1) }
local a1 = (nil :: any) :: A1<number>
for i, v in a1 do
	local bad1: string = v -- 에러여야 함
end
--#endregion

--#region V2: 자기 타입을 state 로
local function Iter2<T>(self: A2<T>): (((A2<T>, number) -> (number?, T?)), A2<T>, number)
	return nil :: any
end
type A2<T> = Data<T> & { __iter: typeof(Iter2) }
local a2 = (nil :: any) :: A2<number>
for i, v in a2 do
	local bad2: string = v -- 에러여야 함
end
--#endregion

--#region V3: 클로저 하나만 반환
local function Iter3<T>(self: A3<T>): () -> (number?, T?)
	return nil :: any
end
type A3<T> = Data<T> & { __iter: typeof(Iter3) }
local a3 = (nil :: any) :: A3<number>
for i, v in a3 do
	local bad3: string = v -- 에러여야 함
end
--#endregion

--#region V4: 통제군 — 메타테이블 없는 평범한 배열
local plain = (nil :: any) :: { number }
for i, v in plain do
	local bad4: string = v -- 에러여야 함
end
--#endregion

--#region V5: 통제군 — ipairs
for i, v in ipairs(plain) do
	local bad5: string = v -- 에러여야 함
end
--#endregion

local canary: string = 42
return { canary }

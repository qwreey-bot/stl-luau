--!strict
-- Fold 계열 최종안이 타입에서 서는가?
--   Fold(init, fn)       왼쪽부터, 초기값 있음        -> U
--   FoldRight(init, fn)  오른쪽부터                  -> U
--   Reduce(fn)           초기값 없음, 첫 원소가 씨앗  -> T?
--   FoldUntil(init, fn)  콜백이 (acc, done) 반환      -> (U, number?)
--                        후행 조건이라 While 이 아니라 Until (Lua repeat/until)
export type ArrData<T> = { n: number, [number]: T }
export type ArrView<T> = ArrData<T> & { Len: (self: ArrView<T>) -> number }

local function Fold<T, U>(self: Arr<T>, init: U, fn: (acc: U, el: T, idx: number, arr: ArrView<T>) -> U): U
	return nil :: any
end
local function FoldRight<T, U>(self: Arr<T>, init: U, fn: (acc: U, el: T, idx: number, arr: ArrView<T>) -> U): U
	return nil :: any
end
local function Reduce<T>(self: Arr<T>, fn: (acc: T, el: T) -> T): T?
	return nil :: any
end
-- 두 번째 반환이 truthy 면 멈춘다. 멈춘 인덱스를 같이 돌려준다(끝까지 갔으면 nil).
local function FoldUntil<T, U>(self: Arr<T>, init: U, fn: (acc: U, el: T, idx: number, arr: ArrView<T>) -> (U, boolean?)): (U, number?)
	return nil :: any, nil
end
local function Map<T, G>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrView<T>) -> G): Arr<G>
	return nil :: any
end
type ArrIfce = { Fold: typeof(Fold), FoldRight: typeof(FoldRight), Reduce: typeof(Reduce), FoldUntil: typeof(FoldUntil), Map: typeof(Map) }
export type Arr<T> = ArrData<T> & ArrIfce

local a = (nil :: any) :: Arr<number>

-- POS
local sum: number = a:Fold(0, function(acc: number, v: number)
	return acc + v
end)
local joined: string = a:FoldRight("", function(acc: string, v: number)
	return acc .. tostring(v)
end)
local biggest: number? = a:Reduce(function(x: number, y: number)
	return if x > y then x else y
end)
-- 누적하다 100 넘으면 멈춤 — 후행 조건
local partial, stoppedAt = a:FoldUntil(0, function(acc: number, v: number)
	local next = acc + v
	return next, next > 100
end)
local p1: number = partial
local p2: number? = stoppedAt
-- 체이닝
local chained: number = a:Map(function(v: number)
	return v * 2
end):Fold(0, function(acc: number, v: number)
	return acc + v
end)
-- 콜백에서 뷰 읽기
local avg: number = a:Fold(0, function(acc: number, v: number, idx: number, arr: ArrView<number>)
	return acc + v / arr.n
end)

-- NEG: 전부 에러여야 함
local n1: string = sum
local n2: number = biggest -- T? 인데 T
local n3: number = stoppedAt -- number? 인데 number
local n4 = a:Fold("", function(acc: number, v: number)
	return acc
end) -- init 이 string 인데 acc 가 number
local n5 = a:FoldUntil(0, function(acc: number, v: number)
	return acc, "문자열" -- done 은 boolean? 이어야 함
end)
local canary: string = 42
return { sum, joined, biggest, partial, p1, p2, chained, avg, n1, n2, n3, n4, n5, canary }

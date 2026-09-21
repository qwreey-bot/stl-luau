--!strict
-- (a) __iter 가 교집합 설계에서 타입이 서는가
-- (b) Fold 의 인자 순서: init 먼저 vs 콜백 먼저 — 후행 클로저 가독성
-- (c) init 없는 Reduce 가 빈 배열에서 nil 을 주는가
export type ArrData<T> = { n: number, [number]: T }
export type ArrView<T> = ArrData<T> & { Len: (self: ArrView<T>) -> number }

local function Iter<T>(self: Arr<T>): (((ArrData<T>, number) -> (number?, T?)), ArrData<T>, number)
	return nil :: any
end
local function Fold<T, U>(self: Arr<T>, init: U, fn: (acc: U, el: T, idx: number, arr: ArrView<T>) -> U): U
	return nil :: any
end
local function FoldRight<T, U>(self: Arr<T>, init: U, fn: (acc: U, el: T, idx: number, arr: ArrView<T>) -> U): U
	return nil :: any
end
local function Reduce<T>(self: Arr<T>, fn: (acc: T, el: T) -> T): T?
	return nil :: any
end
local function Map<T, G>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrView<T>) -> G): Arr<G>
	return nil :: any
end
local function Len<T>(self: Arr<T>): number
	return nil :: any
end
type ArrIfce = {
	__iter: typeof(Iter),
	Fold: typeof(Fold),
	FoldRight: typeof(FoldRight),
	Reduce: typeof(Reduce),
	Map: typeof(Map),
	Len: typeof(Len),
}
export type Arr<T> = ArrData<T> & ArrIfce

local a = (nil :: any) :: Arr<number>

-- (a) 제네릭 for 가 도는가 + 원소 타입이 잡히는가
local total = 0
for idx, v in a do
	total += v
end

-- (b) init 먼저 — 후행 클로저가 자연스럽다
local sum: number = a:Fold(0, function(acc: number, v: number)
	return acc + v
end)
local joined: string = a:Fold("", function(acc: string, v: number)
	return acc .. tostring(v)
end)
-- 체이닝에서도
local chainFold: number = a:Map(function(v: number)
	return v * 2
end):Fold(0, function(acc: number, v: number)
	return acc + v
end)

-- (c) init 없는 Reduce 는 T? (빈 배열이면 nil)
local maybeMax: number? = a:Reduce(function(x: number, y: number)
	return if x > y then x else y
end)

-- NEG: 전부 에러여야 함
local n1: string = a:Fold(0, function(acc: number, v: number)
	return acc + v
end)
local n2: number = a:Reduce(function(x: number, y: number)
	return x + y
end) -- T? 인데 T 로 받음
local n3 = a:Fold(0, function(acc: string, v: number)
	return acc
end) -- init 이 number 인데 acc 가 string
local n4: string = total
local canary: string = 42
return { total, sum, joined, chainFold, maybeMax, n1, n2, n3, n4, canary }

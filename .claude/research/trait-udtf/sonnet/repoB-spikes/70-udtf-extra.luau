--!strict
local stl = require("../src")
type A = { read __probeA: true }
type Arr<T> = stl.Arr<T>
local d = stl.CircularDeque.Of(1, 2, 3)
local l = stl.List.Of(d)

local function base(): { Get: any }
	return nil :: any
end
-- 등록 표 재료
local get, first, last, nextI, prevI = stl.Arr.Get, stl.Arr.FirstIndex, stl.Arr.LastIndex, stl.Arr.NextIndex, stl.Arr.PrevIndex

-- POS: 자기 제네릭 U 를 지킨 재정의
local okGeneric: stl.ListProvided<Arr<A>, A, number> = {
	Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI,
	Fold = function<U>(list: Arr<A>, init: U, fn: (U, A, number, ...any) -> U): U
		return init
	end,
}
-- NEG: 누적 U 를 number 로 못박음
local negPinU: stl.ListProvided<Arr<A>, A, number> = { -- NEG (line 20 아님: 아래 Fold 줄에서 에러)
	Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI,
	Fold = function(list: Arr<A>, init: number, fn: (number, A, number, ...any) -> number): number -- NEG
		return init
	end,
}
-- NEG: 원소를 string 으로 못박음 (A 대신)
local negPinE: stl.ListProvided<Arr<A>, A, number> = {
	Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI,
	Fold = function<U>(list: Arr<A>, init: U, fn: (U, string, number, ...any) -> U): U -- NEG
		return init
	end,
}
-- NEG: 반환을 U 가 아니라 number 로
local negRetU: stl.ListProvided<Arr<A>, A, number> = {
	Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI,
	Fold = function<U>(list: Arr<A>, init: U, fn: (U, A, number, ...any) -> U): number -- NEG
		return 1
	end,
}
-- NEG: Find 자리에 Len
local negFind: stl.ListProvided<Arr<A>, A, number> = {
	Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI,
	Find = stl.Arr.Len, -- NEG
}
-- POS: Arr.Fold 그대로, 필수만
local okArrFold: stl.ListProvided<Arr<A>, A, number> = {
	Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI, Fold = stl.Arr.Fold,
}
local okOnly: stl.ListProvided<Arr<A>, A, number> = { Get = get, FirstIndex = first, LastIndex = last, NextIndex = nextI, PrevIndex = prevI }

-- 완성 표의 Fold: U 가 부르는 자리에서 정해짐
local sum: number = l.Fold(d, 0, function(a: number, x: number, _i: number): number return a + x end)
local joined: string = l.Fold(d, "", function(a: string, x: number, _i: number): string return a .. x end)
local negFoldRet: string = l.Fold(d, 0, function(a: number, x: number, _i: number): number return a + x end) -- NEG
local negFoldFn = l.Fold(d, 0, function(a: string, x: number, _i: number): string return a end) -- NEG

-- 제네릭 알고리즘이 완성 표를 받음
local function useFull<Self, E, I>(t: stl.ListFull<Self, E, I>, v: Self): E?
	local f, i = t.FirstIndex(v), nil
	if f == nil then return nil end
	return t.Get(v, f)
end
local got: number? = useFull(l, d)
local negGot: string? = useFull(l, d) -- NEG

-- 완성 표의 칸이 선택이 아님 (nil 불가)
local foldF = l.Fold
local contains = l.Contains
local c: boolean = contains(d, 1)

local canary: string = 1
return { okGeneric, negPinU, negPinE, negRetU, negFind, okArrFold, okOnly, sum, joined, negFoldRet, negFoldFn, got, negGot, c, foldF, base, canary }

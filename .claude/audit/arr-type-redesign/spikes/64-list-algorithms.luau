--!strict
--[[
	리스트 알고리즘의 공용 진입점 (2026-10-13, papers/07 2단계).

	`List.Fold`·`Find`·`IndexOf`·`Contains`·`Count`·`Some`·`Every` 는 그 종류의 `stl.List` 완성 표
	(구현이 준 것 + 기본 구현)를 부릅니다. 타입은 진입점 한 곳에 — 트레이트 마커에서 원소·위치를 추론합니다.

	지키는 성질:
	- 종류와 무관하게 같은 서명: `Arr`·`Deque`·읽기 전용으로 빌린 참조(`ArrRead`·`DequeRead`)가 다 들어감.
	- 반환 타입: `Fold` 는 초기값의 타입, `Find` 는 `(E?, I?)`(둘 다 옵셔널), `IndexOf` 는 `I?`.
	- 콜백은 원소와 위치를 받고, 주석을 단 콜백의 원소 타입이 어긋나면 에러.
	- 리스트가 아닌 것(맵·셋·리터럴)은 못 들어옴.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 13 + CANARY 1)
]]
local stl = require("../../../../src")
local Arr, Deque, HashMap, HashSet = stl.Arr, stl.Deque, stl.HashMap, stl.HashSet

local nums = Arr.Of(10, 20, 30)
local queue = Deque.Of("a", "b")
local holed = Arr.Of<<number?>>(10, nil)

--[[ POS ]]
local sum: number = stl.List.Fold(nums, 0, function(acc: number, v: number): number
	return acc + v
end)
local joined: string = stl.List.Fold(queue, "", function(acc: string, v: string, at: number): string
	return acc .. v .. tostring(at)
end)
local item: number?, at: number? = stl.List.Find(nums, function(v: number): boolean
	return v > 15
end)
local word: string?, wordAt: number? = stl.List.Find(queue, function(v: string, idx: number): boolean
	return idx > 1 and v ~= ""
end)
local where: number? = stl.List.IndexOf(queue, "b")
local has: boolean = stl.List.Contains(nums, 20)
local firstHole: number? = stl.List.IndexOf(holed, nil)
local total: number = stl.List.Count(queue)
local big: number = stl.List.Count(nums, function(v: number): boolean
	return v > 15
end)
local some: boolean = stl.List.Some(nums, function(v: number): boolean
	return v > 25
end)
local every: boolean = stl.List.Every(queue, function(v: string): boolean
	return #v == 1
end)
-- 읽기 전용으로 빌린 참조도(넓은 원소 타입으로)
local function borrowed(list: stl.ArrRead<number?>, dq: stl.DequeRead<string>): number
	return stl.List.Count(list)
		+ stl.List.Fold(dq, 0, function(acc: number, v: string): number
			return acc + #v
		end)
end
local viaBorrow: number = borrowed(nums, queue)

--[[ NEG — 반환 타입 ]]
local negSum: string = stl.List.Fold(nums, 0, function(acc: number, v: number): number
	return acc + v
end)
local negItem: number = stl.List.Find(nums, function(v: number): boolean
	return true
end)
local negWord: number? = stl.List.Find(queue, function(v: string): boolean
	return true
end)
local negWhere: number = stl.List.IndexOf(queue, "b")
local negHas: number = stl.List.Contains(nums, 20)
local negEvery: string = stl.List.Every(queue, function(v: string): boolean
	return true
end)

--[[ NEG — 콜백의 원소 타입 ]]
local negCallback = stl.List.Some(nums, function(v: string): boolean
	return v == ""
end)
local negHoled = stl.List.Fold(holed, 0, function(acc: number, v: number): number
	return acc + v
end)

--[[ NEG — 리스트가 아닌 것 ]]
local negMap = stl.List.Fold(HashMap.New<<string, number>>(), 0, function(acc: number, v: number): number
	return acc
end)
local negSet = stl.List.Contains(HashSet.Of(1), 1)

--[[ 구현이 넘기는 표(`ListImpl`) — 필수 다섯 + 재정의는 선택 필드라 서명이 검사됨 ]]
-- POS: 모듈이 그대로 들어감(Arr 는 일곱을 재정의, Deque 는 필수만)
local arrImpl: stl.ListImpl<stl.Arr<number>, number, number> = Arr
local dequeImpl: stl.ListImpl<stl.Deque<string>, string, number> = Deque
-- NEG: 재정의 자리에 함수가 아닌 것 / 반환 타입이 다른 함수 / 필수 함수가 빠짐
local negOverride: stl.ListImpl<stl.Deque<string>, string, number> = {
	Get = Deque.Get,
	FirstIndex = Deque.FirstIndex,
	LastIndex = Deque.LastIndex,
	NextIndex = Deque.NextIndex,
	PrevIndex = Deque.PrevIndex,
	Fold = "not a function",
}
local negOverrideReturn: stl.ListImpl<stl.Deque<string>, string, number> = {
	Get = Deque.Get,
	FirstIndex = Deque.FirstIndex,
	LastIndex = Deque.LastIndex,
	NextIndex = Deque.NextIndex,
	PrevIndex = Deque.PrevIndex,
	Contains = function(_list: stl.Deque<string>, _item: string): number
		return 1
	end,
}
local negMissing: stl.ListImpl<stl.Deque<string>, string, number> = {
	Get = Deque.Get,
	FirstIndex = Deque.FirstIndex,
	LastIndex = Deque.LastIndex,
	NextIndex = Deque.NextIndex,
}

local canary: string = 42

return {
	sum,
	joined,
	item,
	at,
	word,
	wordAt,
	where,
	has,
	firstHole,
	total,
	big,
	some,
	every,
	viaBorrow,
	negSum,
	negItem,
	negWord,
	negWhere,
	negHas,
	negEvery,
	negCallback,
	negHoled,
	negMap,
	negSet,
	arrImpl,
	dequeImpl,
	negOverride,
	negOverrideReturn,
	negMissing,
	canary,
}

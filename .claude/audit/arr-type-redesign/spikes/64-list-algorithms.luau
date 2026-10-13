--!strict
--[[
	리스트 알고리즘의 공용 진입점 (2026-10-13, papers/07 2단계).

	`List.Fold`·`Find`·`IndexOf`·`Contains`·`Count`·`Some`·`Every` 는 그 종류의 `stl.List` 완성 표
	(구현이 준 것 + 기본 구현)를 부릅니다. 타입은 진입점 한 곳에 — 트레이트 마커에서 원소·위치를 추론합니다.

	지키는 성질:
	- 종류와 무관하게 같은 서명: `Arr`·`CircularDeque`·읽기 전용으로 빌린 참조(`ArrRead`·`CircularDequeRead`)가 다 들어감.
	- 반환 타입: `Fold` 는 초기값의 타입, `Find` 는 `(E?, I?)`(둘 다 옵셔널), `IndexOf` 는 `I?`.
	- 콜백은 원소와 위치를 받고, 주석을 단 콜백의 원소 타입이 어긋나면 에러.
	- 리스트가 아닌 것(맵·셋·리터럴)은 못 들어옴.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 23 + CANARY 1 — "알려진 함정" 두 줄은 0건이어야 함)
]]
local stl = require("../../../../src")
local Arr, CircularDeque, HashMap, HashSet = stl.Arr, stl.CircularDeque, stl.HashMap, stl.HashSet

local nums = Arr.Of(10, 20, 30)
local queue = CircularDeque.Of("a", "b")
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
local function borrowed(list: stl.ArrRead<number?>, dq: stl.CircularDequeRead<string>): number
	return stl.List.Count(list) + stl.List.Fold(dq, 0, function(acc: number, v: string): number
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

--[[ 2단계 리뷰가 짚은 공백 — 지키는 NEG 가 없던 성질들 ]]
-- ⚠️ **알려진 함정**(기대 0건 — 타입이 막지 못함): 가변인자 함수를 콜백으로 그대로 넘기면 위치(와 `Arr` 의 읽기
-- 뷰)까지 값으로 삼아 틀린 값·라이브러리 줄 에러가 됩니다. 콜백 타입에 `...unknown` 꼬리를 두면 이 둘은 잡히지만
-- 아래 "타입을 적은 콜백" 이 전부 거절됩니다(한 번 넣었다가 회귀로 확인해 걷음 — 구조 재배치 리뷰).
local knownVariadic = stl.List.Fold(nums, 0, math.max)
local knownVariadicBits = stl.List.Fold(CircularDeque.Of(1, 1, 4), 0, bit32.bor)
-- POS: **타입을 적은 콜백 변수·파라미터·함수가 돌려준 콜백**이 그대로 들어감(종류를 모르는 코드가 술어를 받아 넘김)
type NumberPred = (number, number) -> boolean
local typedPred: NumberPred = function(v: number, _at: number): boolean
	return v % 2 == 0
end
local viaTypedVar: number = stl.List.Count(nums, typedPred)
local function countWhere<E, I>(list: stl.ListMarker<E, I>, pred: (E, I) -> boolean): number
	return stl.List.Count(list, pred)
end
local function negate<E, I>(pred: (E, I) -> boolean): (E, I) -> boolean
	return function(item: E, at: I): boolean
		return not pred(item, at)
	end
end
local viaPassed: number = countWhere(nums, typedPred)
local viaReturned: boolean = stl.List.Some(nums, negate(typedPred))
local typedFolder: (number, number, number) -> number = function(acc: number, v: number, _at: number): number
	return acc + v
end
local viaTypedFold: number = stl.List.Fold(nums, 0, typedFolder)
local viaTypedFind: number? = (stl.List.Find(nums, typedPred))
local viaTypedEvery: boolean = stl.List.Every(nums, typedPred)
-- Count: 반환은 number / 술어의 원소·위치 타입 / 리스트가 아닌 것
local negCountReturn: string = stl.List.Count(nums)
local negCountElem = stl.List.Count(nums, function(v: string): boolean
	return v == "x"
end)
local negCountAt = stl.List.Count(nums, function(_v: number, at: string): boolean
	return at == "x"
end)
local negCountMap = stl.List.Count(HashMap.New<<string, number>>())
-- Find 의 둘째 반환(위치)도 옵셔널 / 콜백의 위치 타입 / 리터럴은 리스트가 아님
local _, negFindAt: number = stl.List.Find(nums, function(v: number): boolean
	return v > 1
end)
local negFoldAt = stl.List.Fold(nums, 0, function(acc: number, _v: number, at: string): number
	return acc + #at
end)
local negEveryElem = stl.List.Every(nums, function(v: string): boolean
	return v == "x"
end)
local negLiteral = stl.List.Count({ 1, 2, 3 })

--[[ 구현이 넘기는 표(`ListProvided`) — 필수 다섯 + 재정의는 선택 필드라 서명이 검사됨 ]]
-- POS: 모듈이 그대로 들어감(Arr 는 일곱을 재정의, CircularDeque 는 필수만)
local arrImpl: stl.ListProvided<stl.Arr<number>, number, number> = Arr
local dequeImpl: stl.ListProvided<stl.CircularDeque<string>, string, number> = CircularDeque
-- NEG: 재정의 자리에 함수가 아닌 것 / 반환 타입이 다른 함수 / 필수 함수가 빠짐
local negOverride: stl.ListProvided<stl.CircularDeque<string>, string, number> = {
	Get = CircularDeque.Get,
	FirstIndex = CircularDeque.FirstIndex,
	LastIndex = CircularDeque.LastIndex,
	NextIndex = CircularDeque.NextIndex,
	PrevIndex = CircularDeque.PrevIndex,
	Fold = "not a function",
}
local negOverrideReturn: stl.ListProvided<stl.CircularDeque<string>, string, number> = {
	Get = CircularDeque.Get,
	FirstIndex = CircularDeque.FirstIndex,
	LastIndex = CircularDeque.LastIndex,
	NextIndex = CircularDeque.NextIndex,
	PrevIndex = CircularDeque.PrevIndex,
	Contains = function(_list: stl.CircularDeque<string>, _item: string): number
		return 1
	end,
}
local negMissing: stl.ListProvided<stl.CircularDeque<string>, string, number> = {
	Get = CircularDeque.Get,
	FirstIndex = CircularDeque.FirstIndex,
	LastIndex = CircularDeque.LastIndex,
	NextIndex = CircularDeque.NextIndex,
}

--[[ 1단계 2라운드 리뷰 — 실제 `List` 트레이트에 걸린 검사와 `Some`/`Every` 의 두 모양 ]]
-- POS: 완성 표 타입(`ListFull` — 꼬리 없는 서명)으로 적은 표도 구현 표로 들어감 / 구간이 선택인 Some
local asFull: stl.ListFull<stl.CircularDeque<string>, string, number> = nil :: any
local fullAsImpl: stl.ListProvided<stl.CircularDeque<string>, string, number> = asFull
stl.Trait.Impl(stl.List, stl.Trait.NewToken("FromFull"), asFull)
local function someOptional(
	list: stl.CircularDeque<string>,
	pred: (item: string, idx: number) -> boolean,
	start: number?
): boolean
	return pred(CircularDeque.Get(list, start or 1) :: string, start or 1)
end
local optionalRange: stl.ListProvided<stl.CircularDeque<string>, string, number> = {
	Get = CircularDeque.Get,
	FirstIndex = CircularDeque.FirstIndex,
	LastIndex = CircularDeque.LastIndex,
	NextIndex = CircularDeque.NextIndex,
	PrevIndex = CircularDeque.PrevIndex,
	Some = someOptional,
}
-- NEG: 셋째 인자를 **꼭** 받는 Some(진입점은 둘만 넘김) / `Trait.Impl(stl.List, …)` 호출 자체가 재정의 자리를 봄
local function someRequired(
	list: stl.CircularDeque<string>,
	pred: (item: string, idx: number) -> boolean,
	start: number
): boolean
	return pred(CircularDeque.Get(list, start) :: string, start)
end
local negRequiredRange: stl.ListProvided<stl.CircularDeque<string>, string, number> = {
	Get = CircularDeque.Get,
	FirstIndex = CircularDeque.FirstIndex,
	LastIndex = CircularDeque.LastIndex,
	NextIndex = CircularDeque.NextIndex,
	PrevIndex = CircularDeque.PrevIndex,
	Some = someRequired,
}
stl.Trait.Impl(stl.List, stl.Trait.NewToken("BadFold"), {
	Get = CircularDeque.Get,
	FirstIndex = CircularDeque.FirstIndex,
	LastIndex = CircularDeque.LastIndex,
	NextIndex = CircularDeque.NextIndex,
	PrevIndex = CircularDeque.PrevIndex,
	Fold = "not a function",
})

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
	knownVariadic,
	knownVariadicBits,
	viaTypedVar,
	viaPassed,
	viaReturned,
	viaTypedFold,
	viaTypedFind,
	viaTypedEvery,
	negCountReturn,
	negCountElem,
	negCountAt,
	negCountMap,
	negFindAt,
	negFoldAt,
	negEveryElem,
	negLiteral,
	fullAsImpl,
	optionalRange,
	negRequiredRange,
	canary,
}

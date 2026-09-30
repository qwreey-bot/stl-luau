--!strict
--[[
	정렬 가족(M2, 2026-09-30)의 음성 대조군 — `StableSort`/`SortBy`/`NthElement`/
	`PartialSort`/`MergeSorted`/`IsSorted` 와 `*Inplace` 판.

	특히 본다:
	- `SortBy` 의 키 타입 `K` 와 키 비교자가 따로 추론되는가(원소 `T` 와 섞이지 않게)
	- `NthElement` 가 `T?` 를 돌려주는가(범위 밖 nil)
	- 구멍 배열(`Arr<number?>`)에 좁은 키 콜백을 주면 잡히는가(질문 V 의 구멍이
	  이 새 콜백 모양에서도 닫혀 있는지)

	기대 진단: 11건 (NEG 10 + CANARY 1)
]]
local stl = require("../../../../src")
local Arr = stl.Arr
type Arr<T> = stl.Arr<T>
type Rec = { name: string, age: number }

local nums = Arr.Of(30, 10, 20)
local strs = Arr.Of("b", "a")
local recs = Arr.Of<<Rec>>({ name = "x", age = 30 }, { name = "y", age = 20 })
local holed = Arr.Of<<number?>>(30, nil, 10)

--[[ POS ]]
local okStable: Arr<number> = Arr.StableSort(nums)
local okStableIn: Arr<number> = nums:StableSortInplace(function(a: number, b: number): boolean
	return a > b
end)
local okBy: Arr<Rec> = Arr.SortBy(recs, function(r: Rec): number
	return r.age
end)
local okByName: Arr<Rec> = recs:SortBy(function(r: Rec): string
	return r.name
end, function(a: string, b: string): boolean
	return a > b
end)
local okNth: number? = Arr.NthElement(nums, 2)
local okNthIn: Arr<number> = nums:NthElementInplace(-1)
local okPartial: Arr<number> = Arr.PartialSort(nums, 2)
local okPartialIn: Arr<number> = nums:PartialSortInplace(1)
local okMerged: Arr<number> = Arr.MergeSorted(nums, nums)
local okSorted: boolean = Arr.IsSorted(nums)
local okHoledBy: Arr<number?> = Arr.SortBy(holed, function(v: number?): number
	return v or 0
end)

--[[ NEG ]]
local neg1: number = Arr.NthElement(nums, 1) -- T? 를 number 에
local neg2: Arr<string> = Arr.StableSort(nums)
local neg3 = Arr.StableSort(nums, function(a: string, b: string): boolean -- 비교자 원소 타입
	return a < b
end)
local neg4 = Arr.SortBy(recs, function(r: Rec): number
	return r.age
end, function(a: string, b: string): boolean -- 키는 number
	return a < b
end)
local neg5: Arr<number> = Arr.SortBy(recs, function(r: Rec): number -- 결과는 Arr<Rec>
	return r.age
end)
local neg6 = Arr.MergeSorted(nums, strs)
local neg7 = Arr.PartialSort(nums, "2")
local neg8: string = Arr.IsSorted(nums)
local neg9 = Arr.SortBy(holed, function(v: number): number -- 구멍 배열에 좁은 키 콜백
	return v
end)
local neg10: Arr<number> = Arr.PartialSort(holed, 1) -- 구멍 배열의 결과도 number?
local canary: string = 42

return {
	okStable, okStableIn, okBy, okByName, okNth, okNthIn, okPartial, okPartialIn, okMerged, okSorted, okHoledBy,
	neg1, neg2, neg3, neg4, neg5, neg6, neg7, neg8, neg9, neg10, canary,
}

--!strict
--[[
	실제 `src/BSearch.luau` 에 대한 음성 대조군.

	`Probe<E, K>` 는 원소 타입과 찾는 값의 타입이 다를 수 있는 제네릭이라,
	조용히 `any` 로 무너질 여지가 있는 자리입니다.

	기대 진단: 6건 (NEG 5 + CANARY 1)
]]
local stl = require("../../../../src")

local nums: { number } = { 10, 20, 30 }
type Rec = { key: string, value: number }
local recs: { Rec } = { { key = "a", value = 1 } }

--[[ POS ]]
local okLower: number = stl.BSearch.LowerBound(nums, 3, 20, stl.Common.compareNumber)
local okFind: number? = stl.BSearch.Find(nums, 3, 20, stl.Common.compareNumber)
local okFirst: number?, okLast: number? = stl.BSearch.EqualRange(nums, 3, 20, stl.Common.compareNumber)
local okSorted: boolean = stl.BSearch.IsSorted(nums, 3, stl.Common.compareNumber)
-- 원소 타입과 찾는 값의 타입이 달라도 됩니다
local okByKey: number? = stl.BSearch.Find(recs, 1, "a", function(element: Rec, target: string): number
	return stl.Common.compareString(element.key, target)
end)

--[[ NEG ]]
local neg1 = stl.BSearch.Find(nums, 3, "문자열", stl.Common.compareNumber) -- 찾는 값 타입이 다름
local neg2: string = stl.BSearch.LowerBound(nums, 3, 20, stl.Common.compareNumber) -- 위치는 number
local neg3 = stl.BSearch.Find(recs, 1, "a", stl.Common.compareString) -- probe 의 원소 타입이 Rec 이 아님
local neg4 = stl.BSearch.Nope -- 네임스페이스 오타
local neg5 = stl.BSearch.Find(nums, 3, 20, function(element: number, target: number): string
	return "숫자가 아님" -- probe 는 number 를 돌려줘야 함
end)
local canary: string = 42

return { okLower, okFind, okFirst, okLast, okSorted, okByKey, neg1, neg2, neg3, neg4, neg5, canary }

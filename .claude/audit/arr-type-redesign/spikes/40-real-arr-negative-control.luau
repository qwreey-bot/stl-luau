--!strict
--[[
	⭐ **실제 `src/Arr.luau` 에 대한 음성 대조군.**

	`src` 는 진단 0건인데, 이 저장소에서 0건은 축하가 아니라 경보입니다 —
	2026-08-31 에 음성 대조군이 0/6 이었던(= 타입 검사가 통째로 죽어 있던)
	전례가 있습니다. 그래서 "틀린 코드가 정말 틀리다고 나오는지" 를 따로
	고정합니다.

	기대 진단: 17건 (NEG 12 + CANARY 1 — neg6/neg11 은 한 줄에서 3건씩 납니다)
]]
local stl = require("../../../../src")

type Arr<T> = stl.Arr<T>
type ArrView<T> = stl.ArrView<T>

local nums: Arr<number> = stl.Arr.Of(1, 2, 3)
local strs: Arr<string> = stl.Arr.Of("a", "b")

--[[ POS: 이것들은 전부 통과해야 합니다 ]]
local okLen: number = nums:Len()
local okItem: number = nums[1]
local okJoin: string = nums:Join(",")
local okChain: Arr<string> = nums:Map(function(v: number)
	return tostring(v)
end)
local okDeep: Arr<number> = nums
	:Map(function(v: number)
		return tostring(v)
	end)
	:Map(function(s: string)
		return #s
	end)
-- 콜백 안에서 뷰 메소드가 되어야 합니다
local okView: Arr<number> = nums:Map(function(v: number, idx: number, arr: ArrView<number>)
	return v + arr.n + arr:Len() + #arr:Join(",") + arr:Slice(1, idx):Len()
end)
-- 계약이 주는 메소드
local okFirst: number? = nums:FirstIndex()
local okGet: number? = nums:Get(1)
-- 이터레이터 루프 변수가 비옵셔널이어야 합니다
local okSum = 0
for i, v in nums:Iter() do
	okSum += i + v
end
-- 접기 네 갈래
local okFold: number = nums:Fold(0, function(acc: number, v: number)
	return acc + v
end)
local okReduce: number? = nums:Reduce(function(a: number, b: number)
	return a + b
end)
local okUntil: number, okStop: number? = nums:FoldUntil(0, function(acc: number, v: number)
	return acc + v, v > 2
end)
-- unchecked 계열도 checked 와 같은 타입이어야 합니다
local okSumU: number = nums:SumUnchecked()
local okMaxU: number? = nums:MaxUnchecked()
local okSortU: Arr<number> = nums:SortUnchecked()

--[[ NEG: 전부 에러여야 합니다 ]]
local neg1: string = nums:Len()
local neg2: string = nums[1]
local neg3 = nums:NoSuchMethod()
local neg4 = stl.Arr.Off
local neg5: Arr<string> = nums:Map(function(v: number)
	return v * 2
end)
local neg6 = strs:Sum() -- Sum 은 숫자 배열 전용
local neg7 = nums:PushBack("문자열") -- 원소 타입이 다름
local neg8 = nums:Equal(strs) -- 원소 타입이 다른 배열과 비교
local neg9: string = nums:Fold(0, function(acc: number, v: number)
	return acc + v
end)
local neg10 = stl.Arr.Of(1, 2):Get("첫번째") -- 위치는 number
local neg11 = strs:SumUnchecked() -- unchecked 도 숫자 배열 전용이어야 함
local neg12: string = nums:MaxUnchecked() -- 원소는 number
local canary: string = 42

return {
	okLen, okItem, okJoin, okChain, okDeep, okView, okFirst, okGet, okSum,
	okFold, okReduce, okUntil, okStop, okSumU, okMaxU, okSortU,
	neg1, neg2, neg3, neg4, neg5, neg6, neg7, neg8, neg9, neg10, neg11, neg12, canary,
}

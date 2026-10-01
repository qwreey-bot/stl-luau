--!strict
--[[
	⭐ **실제 `src/Arr.luau` 에 대한 음성 대조군.**

	`src` 는 진단 0건인데, 이 저장소에서 0건은 축하가 아니라 경보입니다 —
	2026-08-31 에 음성 대조군이 0/6 이었던(= 타입 검사가 통째로 죽어 있던)
	전례가 있습니다. 그래서 "틀린 코드가 정말 틀리다고 나오는지" 를 따로
	고정합니다.

	기대 진단: 17건 (NEG 15 + CANARY 1 — neg15 는 2건. 콜론 호출이던 때는 neg6/neg11 이 3건씩이었음, 질문 AB)
	(2026-09-30 M1: `At`/`Concat`/`Splice` 를 POS·NEG 하나씩 더함, 17 → 21)
]]
local stl = require("../../../../src")
local Arr = stl.Arr

type Arr<T> = stl.Arr<T>
type ArrView<T> = stl.ArrView<T>

local nums: Arr<number> = stl.Arr.Of(1, 2, 3)
local strs: Arr<string> = stl.Arr.Of("a", "b")

--[[ POS: 이것들은 전부 통과해야 합니다 ]]
local okLen: number = Arr.Len(nums)
local okItem: number = nums[1]
local okJoin: string = Arr.Join(nums, ",")
local okChain: Arr<string> = Arr.Map(nums, function(v: number)
	return tostring(v)
end)
local okDeep: Arr<number> = Arr.Map(Arr.Map(nums, function(v: number)
		return tostring(v)
	end), function(s: string)
		return #s
	end)
-- 콜백의 셋째 인자는 읽기 전용 평범한 테이블입니다(질문 AB·Z — 메소드 없음, 원소는 unknown)
local okView: Arr<number> = Arr.Map(nums, function(v: number, idx: number, arr: ArrView<unknown>)
	return v + arr.n + (arr[idx] :: number)
end)
-- 계약이 주는 메소드
local okFirst: number? = Arr.FirstIndex(nums)
local okGet: number? = Arr.Get(nums, 1)
-- 이터레이터 루프 변수가 비옵셔널이어야 합니다
local okSum = 0
for i, v in Arr.Iter(nums) do
	okSum += i + v
end
-- 접기 네 갈래
local okFold: number = Arr.Fold(nums, 0, function(acc: number, v: number)
	return acc + v
end)
local okReduce: number? = Arr.Reduce(nums, function(a: number, b: number)
	return a + b
end)
local okUntil: number, okStop: number? = Arr.FoldUntil(nums, 0, function(acc: number, v: number)
	return acc + v, v > 2
end)
-- unchecked 계열도 checked 와 같은 타입이어야 합니다
local okSumU: number = Arr.SumUnchecked(nums)
local okMaxU: number? = Arr.MaxUnchecked(nums)
local okSortU: Arr<number> = Arr.SortUnchecked(nums)

--[[ NEG: 전부 에러여야 합니다 ]]
local neg1: string = Arr.Len(nums)
local neg2: string = nums[1]
local neg3 = Arr.NoSuchMethod(nums)
local neg4 = stl.Arr.Off
local neg5: Arr<string> = Arr.Map(nums, function(v: number)
	return v * 2
end)
local neg6 = Arr.Sum(strs) -- Sum 은 숫자 배열 전용
local neg7 = Arr.PushBack(nums, "문자열") -- 원소 타입이 다름
local neg8 = Arr.Equal(nums, strs) -- 원소 타입이 다른 배열과 비교
local neg9: string = Arr.Fold(nums, 0, function(acc: number, v: number)
	return acc + v
end)
local neg10 = Arr.Get(stl.Arr.Of(1, 2), "첫번째") -- 위치는 number
local neg11 = Arr.SumUnchecked(strs) -- unchecked 도 숫자 배열 전용이어야 함
local neg12: string = Arr.MaxUnchecked(nums) -- 원소는 number
local neg13: number = Arr.At(nums, -1) -- At 은 T? 를 돌려줌 — `?` 를 지키는 줄(string 이면 원소 타입 때문에 에러라 `?` 를 못 지킴)
local neg14 = stl.Arr.Concat(nums, strs) -- 원소 타입이 섞임(같은 타입끼리면 가변인자가 any 여도 통과해 못 지킴)
local neg15: Arr<number> = Arr.Splice(nums, 1, 1, strs) -- with 도 같은 T
local canary: string = 42

--[[ POS (M1) ]]
local okAt: number? = stl.Arr.At(nums, -1)
local okConcat: Arr<number> = stl.Arr.Concat(nums, nums)
local okSplice: Arr<number> = Arr.Splice(nums, 2, 3, stl.Arr.Of(9))
local okConcatIn: Arr<number> = Arr.ConcatInplace(nums, nums)

return {
	okLen, okItem, okJoin, okChain, okDeep, okView, okFirst, okGet, okSum,
	okFold, okReduce, okUntil, okStop, okSumU, okMaxU, okSortU, okAt, okConcat, okSplice, okConcatIn,
	neg1, neg2, neg3, neg4, neg5, neg6, neg7, neg8, neg9, neg10, neg11, neg12, neg13, neg14, neg15, canary,
}

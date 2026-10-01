--!strict
--[[
	실제 `src/Heap.luau` 에 대한 음성 대조군.

	힙은 계약(`Types` 의 셋 중 어느 것)도 만족하지 않는 유일한 컨테이너라,
	교집합이 두 조각(`HeapData` & `HeapIfce`)뿐입니다. 그 모양에서도 타입이
	사는지를 봅니다.

	기대 진단: 9건 (NEG 8 + CANARY 1)
]]
local stl = require("../../../../src")
local Heap = stl.Heap

type Heap<T> = stl.Heap<T>

local lessNum = function(a: number, b: number): boolean
	return a < b
end

local nums = stl.Heap.FromList({ 3, 1, 2 }, lessNum)

--[[ POS ]]
local okPeek: number? = Heap.Peek(nums)
local okPop: number? = Heap.Pop(nums)
local okLen: number = Heap.Len(nums)
local okEmpty: boolean = Heap.Empty(nums)
local okItems: { number } = Heap.Items(nums)
local okSorted: { number } = Heap.Sorted(nums)
local okPushed: Heap<number> = Heap.Push(nums, 4)
local okPushPop: number = Heap.PushPop(nums, 5)
local okReplaced: number? = Heap.Replace(nums, 6)
local okClone: Heap<number> = Heap.Clone(nums)
-- 3방향 비교자를 어댑터로 감싸기
local okAdapted = stl.Heap.New(stl.Common.lessFrom(stl.Common.compareNumber)) :: Heap<number>

--[[ NEG ]]
local neg1: string = Heap.Peek(nums) -- 원소는 number
local neg2 = Heap.Push(nums, "문자열") -- 원소 타입이 다름
local neg3 = Heap.NoSuchMethod(nums)
local neg4 = stl.Heap.Nope -- 네임스페이스 오타
local neg5: { string } = Heap.Sorted(nums) -- 원소는 number
local neg6 = Heap.PushPop(nums, "문자열") -- 원소 타입이 다름
local neg7 = stl.Heap.FromList({ 1, 2 }, function(a: string, b: string): boolean
	return a < b -- 비교자의 원소 타입이 배열과 다름
end)
local neg8 = stl.Heap.New(function(a: number, b: number): number
	return a - b -- 힙은 불리언 비교자를 받습니다
end)
local canary: string = 42

return {
	okPeek, okPop, okLen, okEmpty, okItems, okSorted, okPushed, okPushPop,
	okReplaced, okClone, okAdapted,
	neg1, neg2, neg3, neg4, neg5, neg6, neg7, neg8, canary,
}

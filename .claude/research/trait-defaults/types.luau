--!strict
-- 시제품의 타입 대조 (papers/07): POS 는 0건, NEG 는 줄마다 에러여야 함
local stl = require("../../../src")
local Algo = require("./Algo")
local Arr, Deque = stl.Arr, stl.Deque

local nums = Arr.Of(10, 20, 30)
local queue = Deque.Of("a", "b")

--[[ POS ]]
local sum: number = Algo.Fold(nums, 0, function(acc: number, v: number): number
	return acc + v
end)
local joined: string = Algo.Fold(queue, "", function(acc: string, v: string): string
	return acc .. v
end)
local found: string? = Algo.Find(queue, function(v: string): boolean
	return v == "b"
end)
local has: boolean = Algo.Contains(nums, 20)
-- 넣은 타입 그대로
local evens: stl.Arr<number> = Algo.Filter(nums, function(v: number): boolean
	return v % 20 == 0
end)
local kept: stl.Deque<string> = Algo.Filter(queue, function(v: string): boolean
	return v ~= "a"
end)
-- 원소 타입이 바뀌는 것은 목적지로: Arr<number> → Deque<string>
local texts: stl.Deque<string> = Algo.MapInto(nums, function(v: number): string
	return tostring(v)
end, Deque.New<<string>>())
-- 빌린 읽기 참조도 읽는 알고리즘에는 들어감
local function total(list: stl.DequeRead<number>): number
	return Algo.Fold(list, 0, function(acc: number, v: number): number
		return acc + v
	end)
end

--[[ NEG ]]
local neg1: string = Algo.Fold(nums, 0, function(acc: number, v: number): number
	return acc + v
end)
local neg2: number? = Algo.Find(queue, function(v: string): boolean
	return true
end)
local neg3: stl.Deque<number> = Algo.Filter(nums, function(v: number): boolean
	return true
end)
local neg4 = Algo.MapInto(nums, function(v: number): string
	return tostring(v)
end, Deque.New<<number>>())
local neg5 = Algo.Fold(stl.HashMap.New<<string, number>>(), 0, function(acc: number, v: number): number
	return acc
end)
local function borrowedInto(list: stl.DequeRead<string>)
	Algo.MapInto(nums, function(v: number): string
		return tostring(v)
	end, list)
end

return { sum, joined, found, has, evens, kept, texts, total, neg1, neg2, neg3, neg4, neg5, borrowedInto }

--!strict
--[[
	절차적(네임스페이스 함수) 호출의 타입 (2026-09-30).

	사용자 방향: 데이터 처리는 문장으로 쓰는 맥락이라 `Arr.Map(a, fn)` 같은
	**네임스페이스 함수가 정식 모양**이고 콜론은 설탕이다. 메소드와 같은
	함수라 타입도 같아야 한다 — 그걸 확인한다. 특히 `local Map = Arr.Map` 으로
	받아 쓸 때(가장 빠른 모양, 36%)도 제네릭이 사는지.

	기대 진단: 10건 (NEG 9 + CANARY 1)
]]
local stl = require("../../../../src")
local Arr = stl.Arr
local HashMap = stl.HashMap
local Optional = stl.Optional
type Arr<T> = stl.Arr<T>

--[[ POS — 문장으로 나눠 쓰는 파이프라인 ]]
local nums = Arr.Of(5, 2, 8, 3, 6)
local evens = Arr.Filter(nums, function(v: number)
	return v % 2 == 0
end)
local scaled: Arr<number> = Arr.Map(evens, function(v: number): number
	return v * 10
end)
local labels: Arr<string> = Arr.Map(scaled, function(v: number): string
	return tostring(v)
end)
local joined: string = Arr.Join(labels, ", ")
local total: number = Arr.Sum(scaled)
local first: number? = Arr.Get(nums, 1)

-- local 로 받아 쓰기 — 제네릭이 호출마다 새로 풀려야 한다
local Map = Arr.Map
local asText: Arr<string> = Map(nums, function(v: number): string
	return tostring(v)
end)
local asLen: Arr<number> = Map(asText, function(s: string): number
	return #s
end)

-- 유니온 원소
local maybe = Arr.Of<<number?>>(1, nil, 3)
local dense: Arr<number> = Arr.Compact(maybe)

-- 다른 모듈도 같은 모양
local ages = HashMap.New<<string, number>>()
HashMap.Set(ages, "철수", 20)
local age: number = HashMap.GetOr(ages, "철수", 0)
local present: number = Optional.UnwrapOr(Optional.Present(1), 0)

--[[ NEG ]]
local neg1: Arr<string> = Arr.Map(evens, function(v: number): number
	return v
end)
local neg2: string = Arr.Sum(scaled)
local neg3 = Arr.Sum(labels) -- Sum 은 숫자 배열 전용
local neg4: Arr<number> = Map(nums, function(v: number): string
	return tostring(v)
end)
local neg5 = Map(nums, function(v: string): string -- 원소 타입이 다름
	return v
end)
local neg6 = Arr.PushBack(nums, "문자열")
local neg7: string = Arr.Get(nums, 1)
HashMap.Set(ages, 42, 1) -- neg8: 키 타입이 다름 (Set 은 반환이 없어 문장으로)
local neg9 = Arr.Nope
local canary: string = 42

return {
	joined, total, first, asLen, dense, age, present,
	neg1, neg2, neg3, neg4, neg5, neg6, neg7, neg9, canary,
}

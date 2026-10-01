--!strict
--[[
	⭐ **M0(2026-10-01, 질문 AB) 의 새 성질을 지키는 음성 대조군** — 데이터는
	엔티티(메타테이블 없는 평범한 테이블), 함수는 서비스(네임스페이스).

	M0 리뷰(opus 셋)가 "어느 스파이크도 지키지 않는다" 고 짚은 셋:
	1. **리터럴은 컨테이너가 아니다** — 교집합을 걷어내 전체형이 구조적 평범한
	   테이블이 되자 `{ n = 3 }` 이 `Arr<number>` 자리에 진단 0건으로 들어갔습니다.
	   데이터부의 `read __arr__: true` 같은 팬텀 태그가 막습니다.
	2. **인스턴스에 메소드가 없다** — 옛 콜론 코드(`nums:Len()`)가 조용히 통과하지
	   않아야 합니다. 데이터부에 `[any]` 같은 인덱서가 들어오면 무너질 자리입니다.
	3. **모듈을 잘못 고른 호출** — 네임스페이스 모양에서 새로 생긴 실수 유형.

	기대 진단: 16건 (NEG 15 + CANARY 1)
]]
local stl = require("../../../../src")
local Arr, HashMap, HashSet, TreeMap, TreeSet, Heap, Fut =
	stl.Arr, stl.HashMap, stl.HashSet, stl.TreeMap, stl.TreeSet, stl.Heap, stl.Fut
type Arr<T> = stl.Arr<T>

local nums = Arr.Of(10, 20)
local anys = Arr.Of<<any>>(1, "a")
local hm = HashMap.New<<string, number>>()
local hs = HashSet.Of(1, 2)
local tm = TreeMap.New<<string, number>>(stl.Common.compareString)
local ts = TreeSet.FromList({ 1, 2 }, stl.Common.compareNumber)
local hp = Heap.New(function(a: number, b: number): boolean
	return a < b
end)
local f = Fut.Resolved(1)

--[[ POS — 생성자를 거친 것은 전부 통과 ]]
local okLen: number = Arr.Len(nums)
local okHas: boolean = HashSet.Has(hs, 1)
local okGet: number? = TreeMap.Get(tm, "x")
local okPacked: Arr<number> = Arr.Of(1, 2)

--[[ NEG 1 — 리터럴은 컨테이너가 아니다 ]]
local neg1: Arr<number> = { n = 3 }
local neg2 = Arr.PushBack({ n = 0 }, 5)
local neg3: stl.HashMap<string, number> = { data = { a = 1 }, size = 0 }
local neg4: stl.Heap<number> = { items = {}, size = 0, less = function(a: number, b: number): boolean
	return a < b
end }

--[[ NEG 2 — 인스턴스에 메소드가 없다(옛 콜론 코드) ]]
local neg5 = nums:Len()
local neg6 = anys:Map(function(v: any): any
	return v
end)
local neg7 = hm:Get("a")
local neg8 = f:Await()

--[[ NEG 3 — 모듈을 잘못 고른 호출 ]]
local neg9 = HashSet.Has(ts, 1)
local neg10 = HashMap.Get(tm, "x")
local neg11 = Heap.Len(hm)
local neg12 = TreeSet.Len(hs)
local neg13 = Arr.Len(hp)
local neg14 = HashMap.Len(hs)
local neg15 = Fut.Status(nums)
local canary: string = 42

return {
	okLen, okHas, okGet, okPacked,
	neg1, neg2, neg3, neg4, neg5, neg6, neg7, neg8, neg9, neg10, neg11, neg12, neg13, neg14, neg15, canary,
}

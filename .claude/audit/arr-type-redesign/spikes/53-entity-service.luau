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

	(2라운드) 리터럴 NEG 를 모든 컨테이너로 넓히고, `CompactInplace` 의 `ArrRead`
	self 로 리터럴·`table.pack` 결과·콜백 뷰가 `Arr` 로 둔갑하던 우회로를 막는 NEG 를 더함.

	(3라운드) `Fut` 에도 팬텀 태그를 둬 리터럴 NEG 를 더함(다른 컨테이너와 대칭).

	기대 진단: 23건 (NEG 22 + CANARY 1)
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
local neg16: stl.HashSet<number> = { map = HashMap.New<<number, true>>() }
local neg17: stl.TreeSet<number> = { map = TreeMap.New<<number, true>>(stl.Common.compareNumber) }
local neg18 = TreeMap.Clone({ records = {}, size = 0, compare = stl.Common.compareString, probe = (nil :: any) })
-- ArrRead self 우회로 — 리터럴·table.pack·읽기 전용 뷰가 Arr 로 둔갑하면 안 됨
local neg19: Arr<number> = Arr.CompactInplace({ n = 2, 10, 20 })
local neg20 = Arr.CompactInplace(table.pack(1, nil, 3))
local neg21 = Arr.Count(nums, function(_v: number, _i: number, view)
	Arr.CompactInplace(view)
	return true
end)
local neg22: stl.Fut<number> = { status = "Resolved", listeners = {}, _pack = function(_x: number) end }

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
	neg1, neg2, neg3, neg4, neg5, neg6, neg7, neg8, neg9, neg10, neg11, neg12, neg13, neg14, neg15, neg16, neg17, neg18, neg19, neg20, neg21, neg22, canary,
}

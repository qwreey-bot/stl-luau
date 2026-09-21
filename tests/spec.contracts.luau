--!strict
--[[
	계약 테스트 — **구현을 모르는 코드가 정말 돌아가는가.**

	`Types` 의 계약 셋(`ListCore` / `MapCore` / `SetCore`)이 존재하는 이유는
	"구현을 바꿔 끼울 수 있게" 하기 위함입니다. 그게 정말 되는지는 계약만
	아는 함수를 써서 **같은 함수에 서로 다른 구현을 넣어보는 것**으로만
	확인됩니다. 이 파일이 그 일을 합니다.

	⭐ 여기서 가장 중요한 것은 **런타임이 아니라 타입**입니다. 이 파일이
	`--!strict` 로 진단 0건이라는 사실 자체가 "계약이 정말 섰다" 는 증거입니다.
	`HashSet` 을 받는 자리에 `TreeSet` 을 넣었을 때 타입 에러가 나면 계약이
	선 게 아닙니다.
]]
local stl = require("../src")
local Types = require("../src/Types")
local Common = stl.Common

type ListCore<E, I> = Types.ListCore<E, I>
type MapCore<K, V> = Types.MapCore<K, V>
type SetCore<T> = Types.SetCore<T>

--[[ 계약만 아는 함수들. 어떤 구현이 오는지 전혀 모릅니다. ]]

-- 순차 컨테이너: 위치 타입 `I` 가 무엇인지도 모른 채 순회합니다.
local function sumThroughContract<I>(list: ListCore<number, I>): number
	local total = 0
	local idx = list:FirstIndex()
	while idx ~= nil do
		total += list:Get(idx) :: number
		idx = list:NextIndex(idx)
	end
	return total
end

-- 맵: 넣고 빼고 세어봅니다.
local function fillAndCount<V>(map: MapCore<string, V>, value: V): number
	map:Set("하나", value)
	map:Set("둘", value)
	map:Set("하나", value) -- 덮어쓰기
	return #map:Records()
end

-- 셋: 넣고 확인하고 뺍니다.
local function exerciseSet<T>(set: SetCore<T>, a: T, b: T): string
	local added = set:Add(a)
	local again = set:Add(a)
	set:Add(b)
	local hasA = set:Has(a)
	local removed = set:Remove(a)
	local hasAfter = set:Has(a)
	return `{added},{again},{hasA},{removed},{hasAfter},{#set:Items()}`
end

print("=== 1. ListCore — Arr 가 만족하는가 ===")
do
	const a = stl.Arr.Of(1, 2, 3)
	assert(sumThroughContract(a) == 6, "계약을 통한 합")
	assert(sumThroughContract(stl.Arr.Of() :: stl.Arr<number>) == 0, "빈 것")
	-- 공용 알고리즘도 계약만 압니다
	assert(stl.Algorithm.IndexOf(a, 2) == 2, "Algorithm.IndexOf")
	assert(stl.Algorithm.Count(a) == 3, "Algorithm.Count")
end
print("PASS")

print("=== 2. ⭐ MapCore — HashMap 과 TreeMap 을 바꿔 끼울 수 있는가 ===")
do
	-- **같은 함수**에 두 구현을 넣습니다. 타입이 갈리면 여기서 진단이 납니다.
	const hash = stl.HashMap.New() :: stl.HashMap<string, number>
	const tree = stl.TreeMap.New(Common.compareString) :: stl.TreeMap<string, number>

	assert(fillAndCount(hash, 1) == 2, "HashMap 을 계약으로")
	assert(fillAndCount(tree, 1) == 2, "TreeMap 을 계약으로")
	assert(hash:Len() == tree:Len(), "둘의 크기가 같아야 합니다")

	-- 공용 알고리즘도 양쪽에서 같아야 합니다
	assert(#stl.Algorithm.Keys(hash) == #stl.Algorithm.Keys(tree), "Algorithm.Keys")
	assert(#stl.Algorithm.Values(hash) == #stl.Algorithm.Values(tree), "Algorithm.Values")

	-- 계약 자리에 담아 두고 나중에 쓰는 것도 돼야 합니다
	const both: { MapCore<string, number> } = { hash, tree }
	for _, map in both do
		assert(map:Get("하나") == 1, "계약 자리에 담긴 뒤에도 동작")
	end
end
print("PASS")

print("=== 3. ⭐ SetCore — HashSet 과 TreeSet 을 바꿔 끼울 수 있는가 ===")
do
	const hash = stl.HashSet.New() :: stl.HashSet<number>
	const tree = stl.TreeSet.New(Common.compareNumber) :: stl.TreeSet<number>

	const hashResult = exerciseSet(hash, 10, 20)
	const treeResult = exerciseSet(tree, 10, 20)
	assert(hashResult == "true,false,true,true,false,1", `HashSet 결과: {hashResult}`)
	-- **두 구현이 글자 하나까지 같은 답을 내야 합니다**
	assert(hashResult == treeResult, `구현마다 답이 다릅니다: {hashResult} vs {treeResult}`)

	const both: { SetCore<number> } = { hash, tree }
	for _, set in both do
		assert(set:Has(20), "계약 자리에 담긴 뒤에도 동작")
		assert(#set:Items() == 1, "Items")
	end
end
print("PASS")

print("=== 4. 계약이 주는 것과 구현 고유의 것이 섞이지 않는가 ===")
do
	-- 계약을 통해 보면 구현 고유 메소드는 안 보여야 합니다. 런타임 테이블엔
	-- 있지만 타입 선언에서는 계약이 주는 것만 보이는 게 맞습니다.
	const set: SetCore<number> = stl.TreeSet.New(Common.compareNumber)
	assert((set :: any).Union ~= nil, "런타임 테이블에는 고유 메소드가 있습니다")
	-- 타입으로는 안 보입니다 — 아래를 주석 해제하면 진단이 나야 합니다:
	--   local _ = set:Union(set)
	-- 이 "안 보여야 함" 을 실제로 고정하는 것은 음성 대조군 스파이크의 몫입니다.

	-- 반대로 구현 타입으로 보면 계약이 주는 것도 다 보여야 합니다
	const concrete = stl.TreeSet.New(Common.compareNumber) :: stl.TreeSet<number>
	concrete:Add(1)
	assert(concrete:Has(1) and #concrete:Items() == 1, "구현 타입에서 계약 메소드")
	assert(concrete:Union(concrete):Len() == 1, "구현 타입에서 고유 메소드")
end
print("PASS")

print()
print("=== ALL PASS (계약) ===")

return true

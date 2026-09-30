--!strict
--[[
	TreeSet 테스트.

	⭐ 집합 연산이 **병합**이라 `HashSet` 과 알고리즘이 완전히 다릅니다.
	그래서 같은 입력에 대해 `HashSet` 과 **답이 같은지 직접 대조**합니다 —
	병합 루프의 인덱스 실수는 눈으로 안 보이기 때문입니다.
]]
local stl = require("../src")
local TreeSet = stl.TreeSet
local Common = stl.Common

type TreeSet<T> = stl.TreeSet<T>

const function itemsOf(s: TreeSet<number>): string
	return table.concat(s:Items(), ",")
end
const function setOf(...: number): TreeSet<number>
	return TreeSet.FromList({ ... }, Common.compareNumber)
end

print("=== 1. 정렬 순서와 기본 ===")
do
	const s = TreeSet.New(Common.compareNumber) :: TreeSet<number>
	assert(s:Empty() and s:Len() == 0, "New")
	assert(stl.isTreeSet(s), "isTreeSet")
	assert(not stl.isTreeSet({}), "평범한 테이블은 isTreeSet 이 아님")

	assert(s:Add(3) == true, "새로 넣으면 true")
	assert(s:Add(3) == false, "이미 있으면 false")
	s:Add(1)
	s:Add(2)
	assert(itemsOf(s) == "1,2,3", `정렬 순서가 아님: {itemsOf(s)}`)
	assert(s:Len() == 3, "크기")
	assert(s:Has(2) and not s:Has(9), "Has")
	assert(s:Remove(2) == true and itemsOf(s) == "1,3", "Remove 후 순서 유지")
	assert(s:Remove(2) == false, "없는 걸 Remove")
end
assert(itemsOf(setOf(3, 1, 2, 1, 3)) == "1,2,3", "FromList 는 정렬하고 중복을 접음")
assert(setOf():Empty(), "FromList 빈 것")
print("PASS")

print("=== 2. Iter / Clear / Clone ===")
do
	const s = setOf(3, 1, 2)
	local seen = ""
	for _, item in s:Iter() do
		seen ..= tostring(item)
	end
	assert(seen == "123", `Iter 가 정렬 순서가 아님: {seen}`)
	local emptyCount = 0
	for _, _item in (TreeSet.New(Common.compareNumber) :: TreeSet<number>):Iter() do
		emptyCount += 1
	end
	assert(emptyCount == 0, "빈 셋의 Iter")

	const cloned = s:Clone()
	cloned:Add(4)
	assert(s:Len() == 3 and cloned:Len() == 4, "Clone 은 독립적")
	s:Clear()
	assert(s:Empty() and not s:Has(1), "Clear")
	s:Add(9)
	assert(s:Len() == 1, "Clear 후 다시 쓸 수 있어야 합니다")
end
print("PASS")

print("=== 3. 정렬이 있어야만 되는 것들 ===")
do
	const s = setOf(10, 20, 30)
	assert(s:First() == 10 and s:Last() == 30, "First/Last")
	assert(s:FloorItem(25) == 20 and s:FloorItem(20) == 20, "FloorItem")
	assert(s:FloorItem(5) == nil, "FloorItem 전부보다 작음")
	assert(s:CeilingItem(15) == 20 and s:CeilingItem(20) == 20, "CeilingItem")
	assert(s:CeilingItem(99) == nil, "CeilingItem 전부보다 큼")
	assert(table.concat(s:RangeItems(10, 20), ",") == "10,20", "RangeItems 양끝 포함")
	assert(#s:RangeItems(25, 15) == 0, "RangeItems 뒤집히면 빈 것")

	const empty = TreeSet.New(Common.compareNumber) :: TreeSet<number>
	assert(empty:First() == nil and empty:Last() == nil, "빈 셋의 First/Last")
end
print("PASS")

print("=== 4. 집합 연산 ===")
do
	const a = setOf(1, 2, 3)
	const b = setOf(3, 4)
	const empty = TreeSet.New(Common.compareNumber) :: TreeSet<number>

	assert(itemsOf(a:Union(b)) == "1,2,3,4", "Union")
	assert(itemsOf(a:Union(empty)) == "1,2,3", "Union 빈 것")
	assert(itemsOf(empty:Union(a)) == "1,2,3", "Union 빈 것이 앞")
	assert(itemsOf(a:Intersect(b)) == "3", "Intersect")
	assert(a:Intersect(empty):Empty(), "Intersect 빈 것")
	assert(itemsOf(a:Difference(b)) == "1,2", "Difference")
	assert(itemsOf(b:Difference(a)) == "4", "Difference 는 방향이 있습니다")
	assert(itemsOf(a:SymmetricDifference(b)) == "1,2,4", "SymmetricDifference")
	assert(a:SymmetricDifference(a):Empty(), "자기 자신과의 대칭차")
	-- 결과도 정렬돼 있어야 합니다
	assert(itemsOf(setOf(5, 1):Union(setOf(3))) == "1,3,5", "Union 결과가 정렬돼야 합니다")
	-- 원본 불변
	assert(a:Len() == 3 and b:Len() == 2, "집합 연산은 원본을 안 건드림")

	assert(setOf(1, 2):IsSubsetOf(a), "IsSubsetOf")
	assert(a:IsSubsetOf(a) and empty:IsSubsetOf(a), "자기 자신 / 빈 것")
	assert(not a:IsSubsetOf(b), "IsSubsetOf 아님")
	assert(not setOf(9):IsSubsetOf(a), "크기만 작다고 부분집합은 아님")
	-- 병합 루프가 b 를 다 써버리는 경계
	assert(not setOf(1, 9):IsSubsetOf(setOf(1, 2)), "b 가 먼저 끝나는 경우")

	assert(setOf(1):IsDisjointFrom(setOf(2)), "IsDisjointFrom")
	assert(not a:IsDisjointFrom(b), "겹치면 아님")
	assert(a:IsDisjointFrom(empty), "빈 것과는 서로소")

	assert(a:Equal(setOf(3, 2, 1)), "Equal 은 순서 무관")
	assert(not a:Equal(b) and not a:Equal(setOf(1, 2)), "Equal 아님")
end
print("PASS")

print("=== 5. ⭐ HashSet 과 답이 같은가 (무작위 대조) ===")
do
	-- 병합 기반과 해시 기반은 알고리즘이 완전히 다릅니다. 같은 입력에 대해
	-- 답이 갈리면 둘 중 하나가 틀린 것이니, 무작위 입력으로 대조합니다.
	local seed = 987654321
	const nextRand = function(limit: number): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed % limit
	end
	const sorted = function(list: { number }): string
		const copy = table.create(#list) :: { number }
		table.move(list, 1, #list, 1, copy)
		table.sort(copy)
		return table.concat(copy, ",")
	end

	for _trial = 1, 150 do
		const listA = table.create(8) :: { number }
		const listB = table.create(8) :: { number }
		for idx = 1, nextRand(8) do
			listA[idx] = nextRand(12)
		end
		for idx = 1, nextRand(8) do
			listB[idx] = nextRand(12)
		end

		const ta = TreeSet.FromList(listA, Common.compareNumber)
		const tb = TreeSet.FromList(listB, Common.compareNumber)
		const ha = stl.HashSet.FromList(listA)
		const hb = stl.HashSet.FromList(listB)

		assert(itemsOf(ta) == sorted(ha:Items()), "원소 집합이 같아야 합니다")
		assert(itemsOf(ta:Union(tb)) == sorted(ha:Union(hb):Items()), "Union 불일치")
		assert(itemsOf(ta:Intersect(tb)) == sorted(ha:Intersect(hb):Items()), "Intersect 불일치")
		assert(itemsOf(ta:Difference(tb)) == sorted(ha:Difference(hb):Items()), "Difference 불일치")
		assert(
			itemsOf(ta:SymmetricDifference(tb)) == sorted(ha:SymmetricDifference(hb):Items()),
			"SymmetricDifference 불일치"
		)
		assert(ta:IsSubsetOf(tb) == ha:IsSubsetOf(hb), "IsSubsetOf 불일치")
		assert(ta:IsDisjointFrom(tb) == ha:IsDisjointFrom(hb), "IsDisjointFrom 불일치")
		assert(ta:Equal(tb) == ha:Equal(hb), "Equal 불일치")
	end
end
print("PASS")

print("=== 6. 맵과 어휘가 갈려 있는가 ===")
do
	const s = setOf(1)
	assert((s :: any).Set == nil, "셋에 Set 이 있으면 안 됩니다")
	assert((s :: any).Get == nil, "셋에 Get 이 있으면 안 됩니다")
	assert((s :: any).Keys == nil, "셋에 Keys 가 있으면 안 됩니다")
	-- 안쪽 맵과 크기가 어긋나지 않아야 합니다
	assert(s:Len() == s.map:Len(), "셋의 크기와 안쪽 맵의 크기")
	s:Add(2)
	assert(s:Len() == s.map:Len() and #s:Items() == s:Len(), "Add 후")
end
print("PASS")

print("=== 7. 회귀 — 2026-09-30 리뷰 ===")
do
	-- (5) for item in 이 인덱스가 아니라 원소를 돌려줘야 함 — HashSet 과 바꿔 끼울 수 있게
	const s = setOf(10, 20, 30)
	local one = ""
	for item in s:Iter() do
		one ..= tostring(item) .. ","
	end
	assert(one == "10,20,30,", `for item in: {one}`)
	local two = ""
	for _, item in s:Iter() do
		two ..= tostring(item) .. ","
	end
	assert(two == "10,20,30,", `for _, item in: {two}`)

	-- (2) NaN 원소는 거절
	assert(not pcall(function()
		TreeSet.FromList({ 3, 0 / 0, 1 }, Common.compareNumber)
	end), "FromList 가 NaN 을 거절")
	assert(not pcall(function()
		setOf(1):Add(0 / 0)
	end), "Add 가 NaN 을 거절")

	-- 비교자가 다른 두 셋을 섞으면 곧바로 에러 — 불변식이 깨진 셋이 퍼지지 않게
	const desc = TreeSet.FromList({ 30, 20, 5 }, function(a: number, b: number): number
		return b - a
	end)
	assert(not pcall(function()
		return setOf(10, 20):Union(desc)
	end), "비교자가 다르면 Union 은 에러")
	assert(not pcall(function()
		return setOf(10, 20):IsSubsetOf(desc)
	end), "비교자가 다르면 IsSubsetOf 도 에러")
end
print("PASS")

print()
print("=== ALL PASS (TreeSet) ===")

return true

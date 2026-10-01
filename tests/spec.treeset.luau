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
	return table.concat(TreeSet.Items(s), ",")
end
const function setOf(...: number): TreeSet<number>
	return TreeSet.FromList({ ... }, Common.compareNumber)
end

print("=== 1. 정렬 순서와 기본 ===")
do
	const s = TreeSet.New(Common.compareNumber) :: TreeSet<number>
	assert(TreeSet.Empty(s) and TreeSet.Len(s) == 0, "New")
	assert(stl.isTreeSet(s), "isTreeSet")
	assert(not stl.isTreeSet({}), "평범한 테이블은 isTreeSet 이 아님")

	assert(TreeSet.Add(s, 3) == true, "새로 넣으면 true")
	assert(TreeSet.Add(s, 3) == false, "이미 있으면 false")
	TreeSet.Add(s, 1)
	TreeSet.Add(s, 2)
	assert(itemsOf(s) == "1,2,3", `정렬 순서가 아님: {itemsOf(s)}`)
	assert(TreeSet.Len(s) == 3, "크기")
	assert(TreeSet.Has(s, 2) and not TreeSet.Has(s, 9), "Has")
	assert(TreeSet.Remove(s, 2) == true and itemsOf(s) == "1,3", "Remove 후 순서 유지")
	assert(TreeSet.Remove(s, 2) == false, "없는 걸 Remove")
end
assert(itemsOf(setOf(3, 1, 2, 1, 3)) == "1,2,3", "FromList 는 정렬하고 중복을 접음")
assert(TreeSet.Empty(setOf()), "FromList 빈 것")
print("PASS")

print("=== 2. Iter / Clear / Clone ===")
do
	const s = setOf(3, 1, 2)
	local seen = ""
	for _, item in TreeSet.Iter(s) do
		seen ..= tostring(item)
	end
	assert(seen == "123", `Iter 가 정렬 순서가 아님: {seen}`)
	local emptyCount = 0
	for _, _item in TreeSet.Iter(TreeSet.New(Common.compareNumber) :: TreeSet<number>) do
		emptyCount += 1
	end
	assert(emptyCount == 0, "빈 셋의 Iter")

	const cloned = TreeSet.Clone(s)
	TreeSet.Add(cloned, 4)
	assert(TreeSet.Len(s) == 3 and TreeSet.Len(cloned) == 4, "Clone 은 독립적")
	TreeSet.Clear(s)
	assert(TreeSet.Empty(s) and not TreeSet.Has(s, 1), "Clear")
	TreeSet.Add(s, 9)
	assert(TreeSet.Len(s) == 1, "Clear 후 다시 쓸 수 있어야 합니다")
end
print("PASS")

print("=== 3. 정렬이 있어야만 되는 것들 ===")
do
	const s = setOf(10, 20, 30)
	assert(TreeSet.First(s) == 10 and TreeSet.Last(s) == 30, "First/Last")
	assert(TreeSet.FloorItem(s, 25) == 20 and TreeSet.FloorItem(s, 20) == 20, "FloorItem")
	assert(TreeSet.FloorItem(s, 5) == nil, "FloorItem 전부보다 작음")
	assert(TreeSet.CeilingItem(s, 15) == 20 and TreeSet.CeilingItem(s, 20) == 20, "CeilingItem")
	assert(TreeSet.CeilingItem(s, 99) == nil, "CeilingItem 전부보다 큼")
	assert(table.concat(TreeSet.RangeItems(s, 10, 20), ",") == "10,20", "RangeItems 양끝 포함")
	assert(#TreeSet.RangeItems(s, 25, 15) == 0, "RangeItems 뒤집히면 빈 것")

	const empty = TreeSet.New(Common.compareNumber) :: TreeSet<number>
	assert(TreeSet.First(empty) == nil and TreeSet.Last(empty) == nil, "빈 셋의 First/Last")
end
print("PASS")

print("=== 4. 집합 연산 ===")
do
	const a = setOf(1, 2, 3)
	const b = setOf(3, 4)
	const empty = TreeSet.New(Common.compareNumber) :: TreeSet<number>

	assert(itemsOf(TreeSet.Union(a, b)) == "1,2,3,4", "Union")
	assert(itemsOf(TreeSet.Union(a, empty)) == "1,2,3", "Union 빈 것")
	assert(itemsOf(TreeSet.Union(empty, a)) == "1,2,3", "Union 빈 것이 앞")
	assert(itemsOf(TreeSet.Intersect(a, b)) == "3", "Intersect")
	assert(TreeSet.Empty(TreeSet.Intersect(a, empty)), "Intersect 빈 것")
	assert(itemsOf(TreeSet.Difference(a, b)) == "1,2", "Difference")
	assert(itemsOf(TreeSet.Difference(b, a)) == "4", "Difference 는 방향이 있습니다")
	assert(itemsOf(TreeSet.SymmetricDifference(a, b)) == "1,2,4", "SymmetricDifference")
	assert(TreeSet.Empty(TreeSet.SymmetricDifference(a, a)), "자기 자신과의 대칭차")
	-- 결과도 정렬돼 있어야 합니다
	assert(itemsOf(TreeSet.Union(setOf(5, 1), setOf(3))) == "1,3,5", "Union 결과가 정렬돼야 합니다")
	-- 원본 불변
	assert(TreeSet.Len(a) == 3 and TreeSet.Len(b) == 2, "집합 연산은 원본을 안 건드림")

	assert(TreeSet.IsSubsetOf(setOf(1, 2), a), "IsSubsetOf")
	assert(TreeSet.IsSubsetOf(a, a) and TreeSet.IsSubsetOf(empty, a), "자기 자신 / 빈 것")
	assert(not TreeSet.IsSubsetOf(a, b), "IsSubsetOf 아님")
	assert(not TreeSet.IsSubsetOf(setOf(9), a), "크기만 작다고 부분집합은 아님")
	-- 병합 루프가 b 를 다 써버리는 경계
	assert(not TreeSet.IsSubsetOf(setOf(1, 9), setOf(1, 2)), "b 가 먼저 끝나는 경우")

	assert(TreeSet.IsDisjointFrom(setOf(1), setOf(2)), "IsDisjointFrom")
	assert(not TreeSet.IsDisjointFrom(a, b), "겹치면 아님")
	assert(TreeSet.IsDisjointFrom(a, empty), "빈 것과는 서로소")

	assert(TreeSet.Equal(a, setOf(3, 2, 1)), "Equal 은 순서 무관")
	assert(not TreeSet.Equal(a, b) and not TreeSet.Equal(a, setOf(1, 2)), "Equal 아님")
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

		assert(itemsOf(ta) == sorted(stl.HashSet.Items(ha)), "원소 집합이 같아야 합니다")
		assert(
			itemsOf(TreeSet.Union(ta, tb)) == sorted(stl.HashSet.Items(stl.HashSet.Union(ha, hb))),
			"Union 불일치"
		)
		assert(
			itemsOf(TreeSet.Intersect(ta, tb)) == sorted(stl.HashSet.Items(stl.HashSet.Intersect(ha, hb))),
			"Intersect 불일치"
		)
		assert(
			itemsOf(TreeSet.Difference(ta, tb)) == sorted(stl.HashSet.Items(stl.HashSet.Difference(ha, hb))),
			"Difference 불일치"
		)
		assert(
			itemsOf(TreeSet.SymmetricDifference(ta, tb))
				== sorted(stl.HashSet.Items(stl.HashSet.SymmetricDifference(ha, hb))),
			"SymmetricDifference 불일치"
		)
		assert(TreeSet.IsSubsetOf(ta, tb) == stl.HashSet.IsSubsetOf(ha, hb), "IsSubsetOf 불일치")
		assert(TreeSet.IsDisjointFrom(ta, tb) == stl.HashSet.IsDisjointFrom(ha, hb), "IsDisjointFrom 불일치")
		assert(TreeSet.Equal(ta, tb) == stl.HashSet.Equal(ha, hb), "Equal 불일치")
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
	assert(TreeSet.Len(s) == stl.TreeMap.Len(s.map), "셋의 크기와 안쪽 맵의 크기")
	TreeSet.Add(s, 2)
	assert(TreeSet.Len(s) == stl.TreeMap.Len(s.map) and #TreeSet.Items(s) == TreeSet.Len(s), "Add 후")
end
print("PASS")

print("=== 7. 회귀 — 2026-09-30 리뷰 ===")
do
	-- (5) for item in 이 인덱스가 아니라 원소를 돌려줘야 함 — HashSet 과 바꿔 끼울 수 있게
	const s = setOf(10, 20, 30)
	local one = ""
	for item in TreeSet.Iter(s) do
		one ..= tostring(item) .. ","
	end
	assert(one == "10,20,30,", `for item in: {one}`)
	local two = ""
	for _, item in TreeSet.Iter(s) do
		two ..= tostring(item) .. ","
	end
	assert(two == "10,20,30,", `for _, item in: {two}`)

	-- (2) NaN 원소는 거절
	assert(not pcall(function()
		TreeSet.FromList({ 3, 0 / 0, 1 }, Common.compareNumber)
	end), "FromList 가 NaN 을 거절")
	assert(not pcall(function()
		TreeSet.Add(setOf(1), 0 / 0)
	end), "Add 가 NaN 을 거절")

	-- 비교자가 다른 두 셋을 섞으면 곧바로 에러 — 불변식이 깨진 셋이 퍼지지 않게
	const desc = TreeSet.FromList({ 30, 20, 5 }, function(a: number, b: number): number
		return b - a
	end)
	assert(not pcall(function()
		return TreeSet.Union(setOf(10, 20), desc)
	end), "비교자가 다르면 Union 은 에러")
	assert(not pcall(function()
		return TreeSet.IsSubsetOf(setOf(10, 20), desc)
	end), "비교자가 다르면 IsSubsetOf 도 에러")
end
print("PASS")

print()
print("=== ALL PASS (TreeSet) ===")

return true

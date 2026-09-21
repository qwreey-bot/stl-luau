--!strict
--[[
	HashSet 테스트. 프레임워크 없음 — assert + print.

	⭐ 이 셋은 `HashMap` 위에 얹혀 있으므로 **크기가 안쪽 맵과 어긋나지 않는지**
	를 매 변형마다 봅니다. 집합 연산은 결과의 크기와 내용을 둘 다 봅니다.
]]
local stl = require("../src")
local HashSet = stl.HashSet

type HashSet<T> = stl.HashSet<T>

-- 셋의 내용이 기대한 목록과 같은지(순서 무관).
local function same<T>(actual: HashSet<T>, expected: { T }, label: string)
	assert(actual:Len() == #expected, `{label}: 크기가 {actual:Len()} 인데 {#expected} 를 기대했습니다`)
	for _, item in expected do
		assert(actual:Has(item), `{label}: {tostring(item)} 이 없습니다`)
	end
end

print("=== 1. 생성자와 기본 ===")
do
	const s = HashSet.New() :: HashSet<string>
	assert(s:Len() == 0 and s:Empty(), "New 는 비어 있어야 합니다")
	assert(stl.isHashSet(s), "isHashSet")
	assert(not stl.isHashSet({}), "평범한 테이블은 isHashSet 이 아님")
	assert(not stl.isHashSet(nil), "nil 은 isHashSet 이 아님")

	assert(s:Add("a") == true, "새로 넣으면 true")
	assert(s:Add("a") == false, "이미 있으면 false")
	assert(s:Len() == 1, "중복은 크기를 안 올림")
	assert(s:Has("a") and not s:Has("없음"), "Has")
	assert(s:Remove("a") == true, "정말 지웠으면 true")
	assert(s:Remove("a") == false, "없는 걸 지우면 false")
	assert(s:Len() == 0, "Remove 후 크기")
end
same(HashSet.Of(1, 2, 3), { 1, 2, 3 }, "Of")
same(HashSet.Of(1, 1, 2), { 1, 2 }, "Of 는 중복을 접음")
same(HashSet.Of(), {}, "Of 빈 것")
same(HashSet.FromList({ 1, 2, 2, 3 }), { 1, 2, 3 }, "FromList")
same(HashSet.FromList({}), {}, "FromList 빈 것")
print("PASS")

print("=== 2. Items / Iter / Clear / Clone ===")
do
	const s = HashSet.Of("a", "b", "c")
	assert(#s:Items() == 3, "Items 개수")
	local joined = ""
	for _, item in s:Items() do
		joined ..= item
	end
	assert(#joined == 3, "Items 가 전부 나와야 합니다")

	local iterCount = 0
	for _item in s:Iter() do
		iterCount += 1
	end
	assert(iterCount == 3, "Iter")
	local emptyCount = 0
	for _item in (HashSet.New() :: HashSet<string>):Iter() do
		emptyCount += 1
	end
	assert(emptyCount == 0, "빈 셋의 Iter 는 한 번도 안 돌아야 합니다")

	const cloned = s:Clone()
	cloned:Add("d")
	assert(s:Len() == 3 and cloned:Len() == 4, "Clone 은 독립적이어야 합니다")

	s:Clear()
	assert(s:Len() == 0 and s:Empty(), "Clear")
	assert(not s:Has("a"), "Clear 후 내용이 비어야 합니다")
	s:Add("z")
	assert(s:Len() == 1, "Clear 후 다시 쓸 수 있어야 합니다")
end
print("PASS")

print("=== 3. 집합 연산 ===")
do
	const a = HashSet.Of(1, 2, 3)
	const b = HashSet.Of(3, 4)
	const empty = HashSet.Of() :: HashSet<number>

	same(a:Union(b), { 1, 2, 3, 4 }, "Union")
	same(a:Union(empty), { 1, 2, 3 }, "Union 빈 것")
	same(a:Intersect(b), { 3 }, "Intersect")
	assert(a:Intersect(empty):Empty(), "Intersect 빈 것")
	same(a:Difference(b), { 1, 2 }, "Difference")
	same(b:Difference(a), { 4 }, "Difference 는 방향이 있습니다")
	same(a:Difference(empty), { 1, 2, 3 }, "Difference 빈 것")
	same(a:SymmetricDifference(b), { 1, 2, 4 }, "SymmetricDifference")
	assert(a:SymmetricDifference(a):Empty(), "자기 자신과의 대칭차는 빈 것")

	-- 원본이 안 바뀌어야 합니다
	assert(a:Len() == 3 and b:Len() == 2, "집합 연산은 원본을 안 건드려야 합니다")

	assert(HashSet.Of(1, 2):IsSubsetOf(a), "IsSubsetOf")
	assert(a:IsSubsetOf(a), "자기 자신의 부분집합")
	assert(empty:IsSubsetOf(a), "빈 것은 모든 것의 부분집합")
	assert(not a:IsSubsetOf(b), "IsSubsetOf 아님")
	-- 크기가 커도 원소가 다르면 부분집합이 아니어야 합니다
	assert(not HashSet.Of(9):IsSubsetOf(a), "크기만 작다고 부분집합은 아님")

	assert(HashSet.Of(1):IsDisjointFrom(HashSet.Of(2)), "IsDisjointFrom")
	assert(not a:IsDisjointFrom(b), "겹치면 IsDisjointFrom 아님")
	assert(a:IsDisjointFrom(empty), "빈 것과는 항상 서로소")

	assert(a:Equal(HashSet.Of(3, 2, 1)), "Equal 은 순서 무관")
	assert(not a:Equal(b), "Equal 아님")
	assert(not a:Equal(HashSet.Of(1, 2)), "Equal 크기 다름")
	assert(empty:Equal(HashSet.Of() :: HashSet<number>), "빈 것끼리 Equal")
end
print("PASS")

print("=== 4. 안쪽 맵과 크기가 어긋나지 않는가 ===")
do
	-- ⭐ 셋이 HashMap 위에 얹혀 있으므로, 셋의 크기와 맵의 크기는 항상
	-- 같아야 합니다. Add/Remove 가 맵의 size 를 직접 건드리기 때문에
	-- 여기가 어긋나면 Len() 이 통째로 거짓말을 하게 됩니다.
	const s = HashSet.Of(1, 2, 3)
	assert(s:Len() == s.map:Len(), "셋의 크기와 안쪽 맵의 크기가 같아야 합니다")
	s:Add(4)
	assert(s:Len() == s.map:Len() and s:Len() == 4, "Add 후")
	s:Remove(1)
	assert(s:Len() == s.map:Len() and s:Len() == 3, "Remove 후")
	s:Clear()
	assert(s:Len() == s.map:Len() and s:Len() == 0, "Clear 후")
	-- 집합 연산의 결과도 마찬가지
	const u = HashSet.Of(1, 2):Union(HashSet.Of(2, 3))
	assert(u:Len() == u.map:Len() and u:Len() == 3, "Union 결과의 크기")
	assert(#u:Items() == u:Len(), "Items 개수와 Len 이 같아야 합니다")
end
print("PASS")

print("=== 5. 맵과 어휘가 갈려 있는가 ===")
do
	-- 셋은 Add/Has/Remove, 맵은 Set/Get. 셋에 맵의 어휘가 새면 안 됩니다.
	const s = HashSet.Of(1)
	assert((s :: any).Set == nil, "셋에 Set 이 있으면 안 됩니다")
	assert((s :: any).Get == nil, "셋에 Get 이 있으면 안 됩니다")
	assert((s :: any).Keys == nil, "셋에 Keys 가 있으면 안 됩니다")
end
print("PASS")

print()
print("=== ALL PASS (HashSet) ===")

return true

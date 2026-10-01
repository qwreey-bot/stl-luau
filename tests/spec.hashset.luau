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
	assert(
		HashSet.Len(actual) == #expected,
		`{label}: 크기가 {HashSet.Len(actual)} 인데 {#expected} 를 기대했습니다`
	)
	for _, item in expected do
		assert(HashSet.Has(actual, item), `{label}: {tostring(item)} 이 없습니다`)
	end
end

print("=== 1. 생성자와 기본 ===")
do
	const s = HashSet.New() :: HashSet<string>
	assert(HashSet.Len(s) == 0 and HashSet.Empty(s), "New 는 비어 있어야 합니다")
	assert(stl.isHashSet(s), "isHashSet")
	assert(not stl.isHashSet({}), "평범한 테이블은 isHashSet 이 아님")
	assert(not stl.isHashSet(nil), "nil 은 isHashSet 이 아님")

	assert(HashSet.Add(s, "a") == true, "새로 넣으면 true")
	assert(HashSet.Add(s, "a") == false, "이미 있으면 false")
	assert(HashSet.Len(s) == 1, "중복은 크기를 안 올림")
	assert(HashSet.Has(s, "a") and not HashSet.Has(s, "없음"), "Has")
	assert(HashSet.Remove(s, "a") == true, "정말 지웠으면 true")
	assert(HashSet.Remove(s, "a") == false, "없는 걸 지우면 false")
	assert(HashSet.Len(s) == 0, "Remove 후 크기")
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
	assert(#HashSet.Items(s) == 3, "Items 개수")
	local joined = ""
	for _, item in HashSet.Items(s) do
		joined ..= item
	end
	assert(#joined == 3, "Items 가 전부 나와야 합니다")

	-- ⭐ 두 형태가 다 되어야 합니다 — TreeSet 과 바꿔 끼울 수 있어야 하므로
	-- `for _, item in` 이 되고, 셋다운 `for item in` 도 됩니다.
	local iterCount, iterJoined = 0, ""
	for _, item in HashSet.Iter(s) do
		iterCount += 1
		iterJoined ..= item
	end
	assert(iterCount == 3 and #iterJoined == 3, "Iter (두 변수)")
	local shortCount, shortJoined = 0, ""
	for item in HashSet.Iter(s) do
		shortCount += 1
		shortJoined ..= item
	end
	assert(shortCount == 3 and #shortJoined == 3, "Iter (한 변수)")
	local emptyCount = 0
	for _, _item in HashSet.Iter(HashSet.New() :: HashSet<string>) do
		emptyCount += 1
	end
	assert(emptyCount == 0, "빈 셋의 Iter 는 한 번도 안 돌아야 합니다")

	const cloned = HashSet.Clone(s)
	HashSet.Add(cloned, "d")
	assert(HashSet.Len(s) == 3 and HashSet.Len(cloned) == 4, "Clone 은 독립적이어야 합니다")

	HashSet.Clear(s)
	assert(HashSet.Len(s) == 0 and HashSet.Empty(s), "Clear")
	assert(not HashSet.Has(s, "a"), "Clear 후 내용이 비어야 합니다")
	HashSet.Add(s, "z")
	assert(HashSet.Len(s) == 1, "Clear 후 다시 쓸 수 있어야 합니다")
end
print("PASS")

print("=== 3. 집합 연산 ===")
do
	const a = HashSet.Of(1, 2, 3)
	const b = HashSet.Of(3, 4)
	const empty = HashSet.Of() :: HashSet<number>

	same(HashSet.Union(a, b), { 1, 2, 3, 4 }, "Union")
	same(HashSet.Union(a, empty), { 1, 2, 3 }, "Union 빈 것")
	same(HashSet.Intersect(a, b), { 3 }, "Intersect")
	assert(HashSet.Empty(HashSet.Intersect(a, empty)), "Intersect 빈 것")
	same(HashSet.Difference(a, b), { 1, 2 }, "Difference")
	same(HashSet.Difference(b, a), { 4 }, "Difference 는 방향이 있습니다")
	same(HashSet.Difference(a, empty), { 1, 2, 3 }, "Difference 빈 것")
	same(HashSet.SymmetricDifference(a, b), { 1, 2, 4 }, "SymmetricDifference")
	assert(HashSet.Empty(HashSet.SymmetricDifference(a, a)), "자기 자신과의 대칭차는 빈 것")

	-- 원본이 안 바뀌어야 합니다
	assert(HashSet.Len(a) == 3 and HashSet.Len(b) == 2, "집합 연산은 원본을 안 건드려야 합니다")

	assert(HashSet.IsSubsetOf(HashSet.Of(1, 2), a), "IsSubsetOf")
	assert(HashSet.IsSubsetOf(a, a), "자기 자신의 부분집합")
	assert(HashSet.IsSubsetOf(empty, a), "빈 것은 모든 것의 부분집합")
	assert(not HashSet.IsSubsetOf(a, b), "IsSubsetOf 아님")
	-- 크기가 커도 원소가 다르면 부분집합이 아니어야 합니다
	assert(not HashSet.IsSubsetOf(HashSet.Of(9), a), "크기만 작다고 부분집합은 아님")

	assert(HashSet.IsDisjointFrom(HashSet.Of(1), HashSet.Of(2)), "IsDisjointFrom")
	assert(not HashSet.IsDisjointFrom(a, b), "겹치면 IsDisjointFrom 아님")
	assert(HashSet.IsDisjointFrom(a, empty), "빈 것과는 항상 서로소")

	assert(HashSet.Equal(a, HashSet.Of(3, 2, 1)), "Equal 은 순서 무관")
	assert(not HashSet.Equal(a, b), "Equal 아님")
	assert(not HashSet.Equal(a, HashSet.Of(1, 2)), "Equal 크기 다름")
	assert(HashSet.Equal(empty, HashSet.Of() :: HashSet<number>), "빈 것끼리 Equal")
end
print("PASS")

print("=== 4. 안쪽 맵과 크기가 어긋나지 않는가 ===")
do
	-- ⭐ 셋이 HashMap 위에 얹혀 있으므로, 셋의 크기와 맵의 크기는 항상
	-- 같아야 합니다. Add/Remove 가 맵의 size 를 직접 건드리기 때문에
	-- 여기가 어긋나면 Len() 이 통째로 거짓말을 하게 됩니다.
	const s = HashSet.Of(1, 2, 3)
	assert(HashSet.Len(s) == stl.HashMap.Len(s.map), "셋의 크기와 안쪽 맵의 크기가 같아야 합니다")
	HashSet.Add(s, 4)
	assert(HashSet.Len(s) == stl.HashMap.Len(s.map) and HashSet.Len(s) == 4, "Add 후")
	HashSet.Remove(s, 1)
	assert(HashSet.Len(s) == stl.HashMap.Len(s.map) and HashSet.Len(s) == 3, "Remove 후")
	HashSet.Clear(s)
	assert(HashSet.Len(s) == stl.HashMap.Len(s.map) and HashSet.Len(s) == 0, "Clear 후")
	-- 집합 연산의 결과도 마찬가지
	const u = HashSet.Union(HashSet.Of(1, 2), HashSet.Of(2, 3))
	assert(HashSet.Len(u) == stl.HashMap.Len(u.map) and HashSet.Len(u) == 3, "Union 결과의 크기")
	assert(#HashSet.Items(u) == HashSet.Len(u), "Items 개수와 Len 이 같아야 합니다")
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

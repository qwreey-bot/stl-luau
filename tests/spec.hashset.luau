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

	-- 자기 자신을 돌려줌(2026-10-12, 질문 AM)
	assert(HashSet.Clear(s) == s, "Clear 는 자기 자신을 돌려줌")
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

print("=== M4. Retain (2026-10-07) ===")
do
	const s = HashSet.Of(10, 15, 20, 25)
	local calls = 0
	HashSet.Retain(s, function(item: number): boolean
		calls += 1
		return item % 10 == 0
	end)
	assert(calls == 4, "원소마다 한 번")
	assert(HashSet.Len(s) == 2 and HashSet.Has(s, 10) and HashSet.Has(s, 20) and not HashSet.Has(s, 15), "Retain")
	local counted = 0
	for _ in s.map.data do
		counted += 1
	end
	assert(counted == 2, "실제 원소 수")
	const retained = HashSet.Retain(s, function(_item: number): boolean
		return false
	end)
	assert(retained == s, "Retain 은 자기 자신을 돌려줌")
	assert(HashSet.Len(s) == 0 and HashSet.Empty(s), "전부 지움")
	HashSet.Retain(s, function(_item: number): boolean
		return true
	end)
	assert(HashSet.Len(s) == 0, "빈 셋")

	-- 관측 — 계약 아님(질문 AL 1): 콜백 안에서 같은 셋을 지워도 지금 판은 크기가 맞음
	const evict = HashSet.Of(10, 15, 20, 25)
	HashSet.Retain(evict, function(item: number): boolean
		if item % 10 == 0 then
			HashSet.Remove(evict, item)
			return false
		end
		return true
	end)
	local n = 0
	for _ in evict.map.data do
		n += 1
	end
	assert(HashSet.Len(evict) == 2 and n == 2, `콜백이 지움: Len {HashSet.Len(evict)} 실제 {n}`)
end
print("PASS")

print("=== Iter 는 안쪽 테이블 그대로 — 원소 → 원소 (2026-10-13, 사용자 결정) ===")
do
	-- 안쪽 테이블이 `원소 → 원소` 라 그대로 돌려줘도 순회가 `(item, item)` — 공개 모양은 그대로이고
	-- Luau 가 직접 돌아 10배 빠름(perf 29절). **값이 키와 같다**는 불변식을 모든 생성·변형 경로에서 봅니다
	-- (`true` 를 넣는 자리가 하나라도 남으면 `for _, item in` 과 `FromIter` 가 `true` 를 받음).
	local function checkPairs<T>(set: HashSet<T>, label: string)
		local count = 0
		for key, value in HashSet.Iter(set) do
			assert(key == value, `{label}: 값이 원소가 아님({tostring(key)} → {tostring(value)})`)
			count += 1
		end
		assert(count == HashSet.Len(set), `{label}: 순회 수 {count} 대 Len {HashSet.Len(set)}`)
	end
	const a = HashSet.Of(10, 20, 30)
	const b = HashSet.FromList({ 20, 30, 40 })
	const grown = HashSet.New<<number>>()
	HashSet.Add(grown, 70)
	HashSet.Add(grown, 80)
	HashSet.Add(grown, 70)
	HashSet.Remove(grown, 80)
	HashSet.Add(grown, 90)
	const retained = HashSet.Retain(HashSet.Of(1, 2, 3, 4), function(item: number): boolean
		return item % 2 == 0
	end)
	const cleared = HashSet.Clear(HashSet.Of(5, 6))
	HashSet.Add(cleared, 7)
	const cases: { { label: string, set: HashSet<number> } } = {
		{ label = "Of", set = a },
		{ label = "FromList", set = b },
		{ label = "New + Add/Remove", set = grown },
		{ label = "Clone", set = HashSet.Clone(a) },
		{ label = "Union", set = HashSet.Union(a, b) },
		{ label = "Intersect", set = HashSet.Intersect(a, b) },
		{ label = "Difference", set = HashSet.Difference(a, b) },
		{ label = "SymmetricDifference", set = HashSet.SymmetricDifference(a, b) },
		{ label = "Retain", set = retained },
		{ label = "Clear 뒤 Add", set = cleared },
		{ label = "빈 것", set = HashSet.New<<number>>() },
	}
	for _, case in cases do
		checkPairs(case.set, case.label)
	end
	-- 같은 테이블(사본 아님)이고 함수가 아님
	const iterable, extra = (HashSet.Iter :: any)(a)
	assert(type(iterable) == "table" and extra == nil, "Iter 는 테이블 하나")
	assert(rawequal(iterable, a.map.data) and rawequal(HashSet.Iter(a), HashSet.Iter(a)), "안쪽 테이블 그대로")
	-- ⭐ `Arr.FromIter(HashSet.Iter(s))` 는 원소를 모음(안쪽이 `원소 → true` 였다면 `true` 들이 됐을 것)
	const viaFromIter = stl.Arr.FromIter<<number>>(HashSet.Iter(a))
	assert(viaFromIter.n == 3 and stl.Arr.Sum(viaFromIter) == 60, "FromIter(HashSet.Iter)")
	-- `false` 도 원소가 됨(`Has` 는 nil 이 아닌지를 봄)
	const flags = HashSet.Of(false, true)
	assert(HashSet.Len(flags) == 2 and HashSet.Has(flags, false) and HashSet.Has(flags, true), "false 원소")
	checkPairs(flags, "boolean 셋")
	assert(HashSet.Remove(flags, false) and not HashSet.Has(flags, false) and HashSet.Len(flags) == 1, "false 빼기")
	assert(HashSet.Add(flags, false) and not HashSet.Add(flags, false), "false 다시 넣기")
	const falseArr = stl.Arr.FromIter<<boolean>>(HashSet.Iter(HashSet.Of(false)))
	assert(falseArr.n == 1 and falseArr[1] == false, "FromIter 가 false 원소를 담음")
	-- 문자열·섞인 타입, Items 와 같은 내용
	const words = HashSet.Of("p", "q", "r")
	checkPairs(words, "문자열 셋")
	local joined = {}
	for _, word in HashSet.Iter(words) do
		table.insert(joined, word)
	end
	table.sort(joined)
	const items = HashSet.Items(words)
	table.sort(items)
	assert(
		table.concat(joined, ",") == "p,q,r" and table.concat(items, ",") == "p,q,r",
		"Iter 와 Items 가 같은 내용"
	)
	-- 도는 동안 지금 원소를 지우는 것은 됨(Lua 의 next 규칙 — 관측)
	const draining = HashSet.Of(1, 2, 3, 4, 5)
	for item in HashSet.Iter(draining) do
		HashSet.Remove(draining, item)
	end
	assert(HashSet.Len(draining) == 0 and next(draining.map.data) == nil, "순회 중 지금 원소 지우기")
end
print("PASS")

print()
print("=== ALL PASS (HashSet) ===")

return true

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
	-- 자기 자신을 돌려줌(2026-10-12, 질문 AM — 일곱 컨테이너가 같게)
	assert(TreeSet.Clear(s) == s, "Clear 는 자기 자신을 돌려줌")
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

print("=== M4. LowerItem / HigherItem / PopFirst / PopLast / Retain (2026-10-07) ===")
do
	const s = setOf(30, 10, 20)
	assert(TreeSet.LowerItem(s, 20) == 10 and TreeSet.FloorItem(s, 20) == 20, "LowerItem 엄격")
	assert(TreeSet.HigherItem(s, 20) == 30 and TreeSet.CeilingItem(s, 20) == 20, "HigherItem 엄격")
	assert(TreeSet.LowerItem(s, 10) == nil and TreeSet.HigherItem(s, 30) == nil, "양끝 밖")
	assert(TreeSet.LowerItem(s, 15) == 10 and TreeSet.HigherItem(s, 15) == 20, "사이 값")
	assert(TreeSet.PopFirst(s) == 10 and itemsOf(s) == "20,30", "PopFirst")
	assert(TreeSet.PopLast(s) == 30 and itemsOf(s) == "20", "PopLast")
	assert(TreeSet.PopLast(s) == 20 and TreeSet.Empty(s), "마지막")
	assert(TreeSet.PopFirst(s) == nil and TreeSet.PopLast(s) == nil and TreeSet.Len(s) == 0, "빈 Pop")
	assert(TreeSet.Add(s, 5) and itemsOf(s) == "5", "꺼낸 뒤 Add")

	const r = setOf(40, 10, 30, 20)
	local order = {}
	const retained = TreeSet.Retain(r, function(item: number): boolean
		table.insert(order, item)
		return item >= 25
	end)
	assert(retained == r, "Retain 은 자기 자신을 돌려줌")
	assert(table.concat(order, ",") == "10,20,30,40", "정렬 순서로 부름")
	assert(itemsOf(r) == "30,40" and TreeSet.Len(r) == 2, "Retain")
	-- 꼬리 칸을 비움 — 안 비우면 지운 원소의 참조가 남아 GC 가 못 거둠(3라운드)
	assert(TreeSet.Has(r, 30) and not TreeSet.Has(r, 10), "Retain 뒤 Has")

	-- (콜백 안에서 이 셋을 바꾸는 것은 정의되지 않은 동작 — 질문 AL 1, 테스트하지 않음)
	-- NaN 은 없음 — 빼기 비교자에서도
	const sub = TreeSet.FromList({ 10, 20 }, function(a: number, b: number): number
		return a - b
	end)
	assert(TreeSet.LowerItem(sub, 0 / 0) == nil and TreeSet.HigherItem(sub, 0 / 0) == nil, "Lower/Higher NaN")
end
print("PASS")

print(
	"=== nil·NaN 원소 — 넣기는 에러(메시지는 TreeSet 의 것), 조회·삭제는 없음 (2026-10-12) ==="
)
do
	const nilItem = nil :: any
	const s = TreeSet.New<<number>>(Common.compareNumber)
	-- 재현: 빈 셋에 nil 이 조용히 들어가고 그 뒤 연산이 비교자 안에서 죽었음
	const okNil, errNil = pcall(function()
		TreeSet.Add(s, nilItem)
	end)
	assert(not okNil and string.find(tostring(errNil), "TreeSet: nil item", 1, true), `빈 셋에 nil: {errNil}`)
	assert(TreeSet.Len(s) == 0, "거절 뒤 빈 그대로")
	assert(TreeSet.Add(s, 20) and TreeSet.Add(s, 10) and TreeSet.Len(s) == 2, "거절 뒤에도 멀쩡")
	-- 예전엔 `TreeMap: NaN key` — 사용자는 TreeMap 을 부른 적이 없음
	const okNan, errNan = pcall(function()
		TreeSet.Add(s, 0 / 0)
	end)
	assert(not okNan and string.find(tostring(errNan), "TreeSet: NaN item", 1, true), `NaN 메시지: {errNan}`)
	assert(not string.find(tostring(errNan), "TreeMap", 1, true), "TreeMap 이름이 새지 않음")
	assert(
		not TreeSet.Has(s, nilItem) and not TreeSet.Remove(s, nilItem) and TreeSet.Len(s) == 2,
		"nil 로 조회·삭제"
	)
	assert(TreeSet.FloorItem(s, nilItem) == nil and TreeSet.CeilingItem(s, nilItem) == nil, "Floor/Ceiling nil")
	assert(TreeSet.LowerItem(s, nilItem) == nil and TreeSet.HigherItem(s, nilItem) == nil, "Lower/Higher nil")
	-- 리스트의 nil 은 구멍이라 건너뜀(리스트 진입점 규약) — 에러 아님
	const fromHoles = TreeSet.FromList(table.pack(30, nil, 10) :: any, Common.compareNumber)
	assert(TreeSet.Len(fromHoles) == 2 and TreeSet.First(fromHoles) == 10, "FromList 의 구멍")
end
print("PASS")

print(
	"=== 트리 판만의 것 — 균형 방식 선택, 구조 불변식, FlatSet 과 무작위 대조 (2026-10-13) ==="
)
do
	const FlatSet, Binary = stl.FlatSet, stl.Node.Binary
	const cmp = stl.Common.compareNumber
	local function sound(set: stl.TreeSet<number>, label: string)
		local count, last: number? = 0, nil
		local function walk(node: any, parent: any)
			if node == nil then
				return
			end
			assert(node[4] == parent, `{label}: {node[5]} 의 부모 칸`)
			walk(node[2], node)
			assert(last == nil or last < node[5], `{label}: 순서`)
			last = node[5]
			count += 1
			walk(node[3], node)
		end
		walk(set.map.root, nil)
		assert(count == TreeSet.Len(set), `{label}: 크기 {TreeSet.Len(set)} ~= 노드 수 {count}`)
		assert(Binary.Height(set.map.root :: any) <= 2 * math.log(count + 1, 2) + 1e-9, `{label}: 높이`)
	end
	assert(TreeSet.New<<number>>(cmp).map.balance == stl.RedBlack :: any, "기본 레드블랙")
	assert(TreeSet.New<<number>>(cmp, stl.Avl).map.balance == stl.Avl :: any, "고른 AVL")
	assert(
		TreeSet.FromList({ 30, 10, 20 }, cmp, stl.Avl).map.balance == stl.Avl :: any,
		"FromList 도 방식을 받음"
	)
	-- ⭐ 무작위 대조: 같은 연산 열을 TreeSet(두 방식)과 FlatSet 에, 집합 연산까지
	math.randomseed(20261013)
	local function randomItems(): { number }
		const items: { number } = {}
		for _ = 1, math.random(0, 40) do
			table.insert(items, math.random(0, 50) * 10)
		end
		return items
	end
	local function sameItems(tree: stl.TreeSet<number>, flat: stl.FlatSet<number>, label: string)
		sound(tree, label)
		assert(table.concat(TreeSet.Items(tree), ",") == table.concat(FlatSet.Items(flat), ","), `{label}: 원소`)
	end
	for round = 1, 60 do
		for _, balance in { stl.RedBlack :: any, stl.Avl } do
			const itemsA, itemsB = randomItems(), randomItems()
			const treeA, treeB = TreeSet.FromList(itemsA, cmp, balance), TreeSet.FromList(itemsB, cmp, balance)
			const flatA, flatB = FlatSet.FromList(itemsA, cmp), FlatSet.FromList(itemsB, cmp)
			sameItems(treeA, flatA, "FromList")
			sameItems(TreeSet.Union(treeA, treeB), FlatSet.Union(flatA, flatB), "Union")
			sameItems(TreeSet.Intersect(treeA, treeB), FlatSet.Intersect(flatA, flatB), "Intersect")
			sameItems(TreeSet.Difference(treeA, treeB), FlatSet.Difference(flatA, flatB), "Difference")
			sameItems(
				TreeSet.SymmetricDifference(treeA, treeB),
				FlatSet.SymmetricDifference(flatA, flatB),
				"SymmetricDifference"
			)
			assert(TreeSet.Union(treeA, treeB).map.balance == balance, "집합 연산은 균형 방식을 물려받음")
			assert(TreeSet.IsSubsetOf(treeA, treeB) == FlatSet.IsSubsetOf(flatA, flatB), "IsSubsetOf")
			assert(TreeSet.IsSubsetOf(TreeSet.Intersect(treeA, treeB), treeA), "교집합은 부분집합")
			assert(TreeSet.IsDisjointFrom(treeA, treeB) == FlatSet.IsDisjointFrom(flatA, flatB), "IsDisjointFrom")
			assert(TreeSet.Equal(treeA, treeB) == FlatSet.Equal(flatA, flatB), "Equal")
			assert(TreeSet.Equal(treeA, TreeSet.Clone(treeA)), "사본과 같음")
			-- 넣고 빼기와 경계 조회
			for step = 1, 60 do
				const item = math.random(-1, 51) * 10 + (if math.random() < 0.3 then 5 else 0)
				const op = math.random(1, 6)
				if op <= 2 then
					assert(TreeSet.Add(treeA, item) == FlatSet.Add(flatA, item), "Add 반환")
				elseif op == 3 then
					assert(TreeSet.Remove(treeA, item) == FlatSet.Remove(flatA, item), "Remove 반환")
				elseif op == 4 then
					assert(TreeSet.PopFirst(treeA) == FlatSet.PopFirst(flatA), "PopFirst")
				elseif op == 5 then
					assert(TreeSet.PopLast(treeA) == FlatSet.PopLast(flatA), "PopLast")
				end
				assert(
					TreeSet.Has(treeA, item) == FlatSet.Has(flatA, item) and TreeSet.Len(treeA) == FlatSet.Len(flatA),
					"Has·Len"
				)
				assert(TreeSet.FloorItem(treeA, item) == FlatSet.FloorItem(flatA, item), "FloorItem")
				assert(TreeSet.CeilingItem(treeA, item) == FlatSet.CeilingItem(flatA, item), "CeilingItem")
				assert(TreeSet.LowerItem(treeA, item) == FlatSet.LowerItem(flatA, item), "LowerItem")
				assert(TreeSet.HigherItem(treeA, item) == FlatSet.HigherItem(flatA, item), "HigherItem")
				assert(
					TreeSet.First(treeA) == FlatSet.First(flatA) and TreeSet.Last(treeA) == FlatSet.Last(flatA),
					"First·Last"
				)
			end
			sameItems(treeA, flatA, `넣고 뺀 뒤 {round}`)
			const lo, hi = math.random(0, 25) * 10, math.random(20, 51) * 10
			assert(
				table.concat(TreeSet.RangeItems(treeA, lo, hi), ",")
					== table.concat(FlatSet.RangeItems(flatA, lo, hi), ","),
				"RangeItems"
			)
			const keepEven = function(item: number): boolean
				return (item // 10) % 2 == 0
			end
			sameItems(TreeSet.Retain(treeA, keepEven), FlatSet.Retain(flatA, keepEven), "Retain")
			local seen = 0
			const want = FlatSet.Items(flatA)
			for item, again in TreeSet.Iter(treeA) do
				seen += 1
				assert(item == want[seen] and again == item, "Iter 는 (원소, 원소)")
			end
			assert(seen == #want, "Iter 수")
		end
	end
	-- 종류를 모르는 코드
	const viaTrait = TreeSet.FromList({ 30, 10 }, cmp)
	assert(
		(stl.Trait.ImplOf(stl.Set, viaTrait) :: any).Add == TreeSet.Add :: any and stl.Collection.Len(viaTrait) == 2,
		"트레이트"
	)
end
print("PASS")

print(
	"=== 리뷰 1라운드(2026-10-13) — TreeSet: 집합 연산의 상대 검사 전부, RangeItems 의 끝, 에러 자리의 줄 ==="
)
do
	const cmp = stl.Common.compareNumber
	local where = 0
	const s = TreeSet.FromList({ 10, 20, 30 }, cmp)
	const reversed = TreeSet.FromList({ 10, 20, 30 }, function(x: number, y: number): number
		return cmp(y, x)
	end)
	const other: any = stl.FlatSet.FromList({ 30, 40 }, cmp)
	-- 일곱 연산 전부: 비교자가 다른 함수면 에러, 다른 종류의 셋이면 에러(표면이 같아 섞이기 쉬움 — 조용히 빈 셋으로
	-- 읽히거나 라이브러리 줄에서 죽었음). 사용자 줄
	const ops: { { name: string, call: (any, any) -> any } } = {
		{ name = "Union", call = TreeSet.Union },
		{ name = "Intersect", call = TreeSet.Intersect },
		{ name = "Difference", call = TreeSet.Difference },
		{ name = "SymmetricDifference", call = TreeSet.SymmetricDifference },
		{ name = "IsSubsetOf", call = TreeSet.IsSubsetOf },
		{ name = "IsDisjointFrom", call = TreeSet.IsDisjointFrom },
		{ name = "Equal", call = TreeSet.Equal },
	}
	for _, op in ops do
		const run = op.call
		const okOrder, errOrder = pcall(function()
			where = debug.info(1, "l") + 1
			run(s, reversed)
		end)
		assert(
			not okOrder and string.find(tostring(errOrder), "TreeSet: sets use different comparators", 1, true),
			`{op.name} 비교자: {errOrder}`
		)
		assert(
			string.find(tostring(errOrder), `spec.treeset.luau:{where}:`, 1, true),
			`{op.name} 사용자 줄: {errOrder}`
		)
		for _, bad in { other, nil :: any, 5 :: any, stl.Arr.Of(1) :: any } do
			const okKind, errKind = pcall(function()
				where = debug.info(1, "l") + 1
				run(s, bad)
			end)
			assert(
				not okKind
					and string.find(tostring(errKind), "TreeSet: set operations need another TreeSet, got", 1, true),
				`{op.name} 상대 종류: {errKind}`
			)
			assert(
				string.find(tostring(errKind), `spec.treeset.luau:{where}:`, 1, true),
				`{op.name} 종류 사용자 줄: {errKind}`
			)
		end
		-- (2라운드 리뷰) 섞인 쪽이 **첫 인자**여도 에러 — 둘째만 보던 때는 조용히 틀린 결과(다른 종류의 셋이 빈 셋으로
		-- 읽힘)이거나 라이브러리 줄의 원시 에러였습니다.
		const firsts: { any } = { other, 5, stl.Arr.Of(1), false }
		for _, bad in firsts do
			const okFirst, errFirst = pcall(function()
				where = debug.info(1, "l") + 1
				run(bad, s)
			end)
			assert(
				not okFirst and string.find(tostring(errFirst), "TreeSet: set operations need a TreeSet, got", 1, true),
				`{op.name} 첫 인자의 종류: {errFirst}`
			)
			assert(
				string.find(tostring(errFirst), `spec.treeset.luau:{where}:`, 1, true),
				`{op.name} 첫 인자 사용자 줄: {errFirst}`
			)
		end
		const okNil, errNil = pcall(function()
			where = debug.info(1, "l") + 1
			run(nil :: any, s)
		end)
		assert(
			not okNil and string.find(tostring(errNil), "TreeSet: set operations need a TreeSet, got nil", 1, true),
			`{op.name} 첫 인자 nil: {errNil}`
		)
		assert(
			string.find(tostring(errNil), `spec.treeset.luau:{where}:`, 1, true),
			`{op.name} nil 사용자 줄: {errNil}`
		)
	end
	assert(
		string.find(tostring(select(2, pcall(TreeSet.Union, s, other))), "got FlatSet", 1, true),
		"메시지에 상대의 종류 이름"
	)
	assert(table.concat(TreeSet.Items(s), ",") == "10,20,30", "거절된 연산은 셋을 안 바꿈")

	-- RangeItems: 끝이 nil·NaN 이면 빈 목록(양쪽 다)
	for _, ends in { { 10, nil }, { nil, 30 }, { 10, 0 / 0 }, { 0 / 0, 30 } } :: { { any } } do
		assert(#TreeSet.RangeItems(s, ends[1], ends[2]) == 0, `RangeItems({tostring(ends[1])}, {tostring(ends[2])})`)
	end
	assert(table.concat(TreeSet.RangeItems(s, 10, 20), ",") == "10,20", "정상 구간")

	-- 에러 자리: 메시지와 사용자 줄
	const sites: { { want: string, call: () -> () } } = {
		{
			want = "TreeSet: nil item",
			call = function()
				where = debug.info(1, "l") + 1
				TreeSet.Add(s, nil :: any)
			end,
		},
		{
			want = "TreeSet: NaN item",
			call = function()
				where = debug.info(1, "l") + 1
				TreeSet.Add(s, 0 / 0)
			end,
		},
		{
			want = "TreeSet: NaN item",
			call = function()
				where = debug.info(1, "l") + 1
				TreeSet.FromList({ 1, 0 / 0 }, cmp)
			end,
		},
		{
			want = "TreeSet: New needs a comparator function, got nil",
			call = function()
				where = debug.info(1, "l") + 1
				TreeSet.New(nil :: any)
			end,
		},
		{
			want = "TreeSet: FromList needs a comparator function, got nil",
			call = function()
				where = debug.info(1, "l") + 1
				TreeSet.FromList({ 1 }, nil :: any)
			end,
		},
		{
			want = "TreeSet: New needs a balance scheme",
			call = function()
				where = debug.info(1, "l") + 1
				TreeSet.New(cmp, "avl" :: any)
			end,
		},
		{
			want = "TreeSet: FromList needs a balance scheme",
			call = function()
				where = debug.info(1, "l") + 1
				TreeSet.FromList({ 1 }, cmp, {} :: any)
			end,
		},
	}
	for _, site in sites do
		const ok, err = pcall(site.call)
		assert(not ok and string.find(tostring(err), site.want, 1, true), `{site.want}: {err}`)
		assert(string.find(tostring(err), `spec.treeset.luau:{where}:`, 1, true), `{site.want} 사용자 줄: {err}`)
	end
	const toClear = TreeSet.FromList({ 1, 2 }, cmp)
	assert(stl.Collection.Clear(toClear) == toClear and TreeSet.Len(toClear) == 0, "Collection.Clear")
end
print("PASS")

print()
print("=== ALL PASS (TreeSet) ===")

return true

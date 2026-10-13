--!strict
--[[
	FlatSet 테스트.

	⭐ 집합 연산이 **병합**이라 `HashSet` 과 알고리즘이 완전히 다릅니다.
	그래서 같은 입력에 대해 `HashSet` 과 **답이 같은지 직접 대조**합니다 —
	병합 루프의 인덱스 실수는 눈으로 안 보이기 때문입니다.
]]
local stl = require("../src")
local FlatSet = stl.FlatSet
local Common = stl.Common

type FlatSet<T> = stl.FlatSet<T>

const function itemsOf(s: FlatSet<number>): string
	return table.concat(FlatSet.Items(s), ",")
end
const function setOf(...: number): FlatSet<number>
	return FlatSet.FromList({ ... }, Common.compareNumber)
end

print("=== 1. 정렬 순서와 기본 ===")
do
	const s = FlatSet.New(Common.compareNumber) :: FlatSet<number>
	assert(FlatSet.Empty(s) and FlatSet.Len(s) == 0, "New")
	assert(stl.isFlatSet(s), "isFlatSet")
	assert(not stl.isFlatSet({}), "평범한 테이블은 isFlatSet 이 아님")

	assert(FlatSet.Add(s, 3) == true, "새로 넣으면 true")
	assert(FlatSet.Add(s, 3) == false, "이미 있으면 false")
	FlatSet.Add(s, 1)
	FlatSet.Add(s, 2)
	assert(itemsOf(s) == "1,2,3", `정렬 순서가 아님: {itemsOf(s)}`)
	assert(FlatSet.Len(s) == 3, "크기")
	assert(FlatSet.Has(s, 2) and not FlatSet.Has(s, 9), "Has")
	assert(FlatSet.Remove(s, 2) == true and itemsOf(s) == "1,3", "Remove 후 순서 유지")
	assert(FlatSet.Remove(s, 2) == false, "없는 걸 Remove")
end
assert(itemsOf(setOf(3, 1, 2, 1, 3)) == "1,2,3", "FromList 는 정렬하고 중복을 접음")
assert(FlatSet.Empty(setOf()), "FromList 빈 것")
print("PASS")

print("=== 2. Iter / Clear / Clone ===")
do
	const s = setOf(3, 1, 2)
	local seen = ""
	for _, item in FlatSet.Iter(s) do
		seen ..= tostring(item)
	end
	assert(seen == "123", `Iter 가 정렬 순서가 아님: {seen}`)
	local emptyCount = 0
	for _, _item in FlatSet.Iter(FlatSet.New(Common.compareNumber) :: FlatSet<number>) do
		emptyCount += 1
	end
	assert(emptyCount == 0, "빈 셋의 Iter")

	const cloned = FlatSet.Clone(s)
	FlatSet.Add(cloned, 4)
	assert(FlatSet.Len(s) == 3 and FlatSet.Len(cloned) == 4, "Clone 은 독립적")
	-- 자기 자신을 돌려줌(2026-10-12, 질문 AM — 일곱 컨테이너가 같게)
	assert(FlatSet.Clear(s) == s, "Clear 는 자기 자신을 돌려줌")
	assert(FlatSet.Empty(s) and not FlatSet.Has(s, 1), "Clear")
	FlatSet.Add(s, 9)
	assert(FlatSet.Len(s) == 1, "Clear 후 다시 쓸 수 있어야 합니다")
end
print("PASS")

print("=== 3. 정렬이 있어야만 되는 것들 ===")
do
	const s = setOf(10, 20, 30)
	assert(FlatSet.First(s) == 10 and FlatSet.Last(s) == 30, "First/Last")
	assert(FlatSet.FloorItem(s, 25) == 20 and FlatSet.FloorItem(s, 20) == 20, "FloorItem")
	assert(FlatSet.FloorItem(s, 5) == nil, "FloorItem 전부보다 작음")
	assert(FlatSet.CeilingItem(s, 15) == 20 and FlatSet.CeilingItem(s, 20) == 20, "CeilingItem")
	assert(FlatSet.CeilingItem(s, 99) == nil, "CeilingItem 전부보다 큼")
	assert(table.concat(FlatSet.RangeItems(s, 10, 20), ",") == "10,20", "RangeItems 양끝 포함")
	assert(#FlatSet.RangeItems(s, 25, 15) == 0, "RangeItems 뒤집히면 빈 것")

	const empty = FlatSet.New(Common.compareNumber) :: FlatSet<number>
	assert(FlatSet.First(empty) == nil and FlatSet.Last(empty) == nil, "빈 셋의 First/Last")
end
print("PASS")

print("=== 4. 집합 연산 ===")
do
	const a = setOf(1, 2, 3)
	const b = setOf(3, 4)
	const empty = FlatSet.New(Common.compareNumber) :: FlatSet<number>

	assert(itemsOf(FlatSet.Union(a, b)) == "1,2,3,4", "Union")
	assert(itemsOf(FlatSet.Union(a, empty)) == "1,2,3", "Union 빈 것")
	assert(itemsOf(FlatSet.Union(empty, a)) == "1,2,3", "Union 빈 것이 앞")
	assert(itemsOf(FlatSet.Intersect(a, b)) == "3", "Intersect")
	assert(FlatSet.Empty(FlatSet.Intersect(a, empty)), "Intersect 빈 것")
	assert(itemsOf(FlatSet.Difference(a, b)) == "1,2", "Difference")
	assert(itemsOf(FlatSet.Difference(b, a)) == "4", "Difference 는 방향이 있습니다")
	assert(itemsOf(FlatSet.SymmetricDifference(a, b)) == "1,2,4", "SymmetricDifference")
	assert(FlatSet.Empty(FlatSet.SymmetricDifference(a, a)), "자기 자신과의 대칭차")
	-- 결과도 정렬돼 있어야 합니다
	assert(itemsOf(FlatSet.Union(setOf(5, 1), setOf(3))) == "1,3,5", "Union 결과가 정렬돼야 합니다")
	-- 원본 불변
	assert(FlatSet.Len(a) == 3 and FlatSet.Len(b) == 2, "집합 연산은 원본을 안 건드림")

	assert(FlatSet.IsSubsetOf(setOf(1, 2), a), "IsSubsetOf")
	assert(FlatSet.IsSubsetOf(a, a) and FlatSet.IsSubsetOf(empty, a), "자기 자신 / 빈 것")
	assert(not FlatSet.IsSubsetOf(a, b), "IsSubsetOf 아님")
	assert(not FlatSet.IsSubsetOf(setOf(9), a), "크기만 작다고 부분집합은 아님")
	-- 병합 루프가 b 를 다 써버리는 경계
	assert(not FlatSet.IsSubsetOf(setOf(1, 9), setOf(1, 2)), "b 가 먼저 끝나는 경우")

	assert(FlatSet.IsDisjointFrom(setOf(1), setOf(2)), "IsDisjointFrom")
	assert(not FlatSet.IsDisjointFrom(a, b), "겹치면 아님")
	assert(FlatSet.IsDisjointFrom(a, empty), "빈 것과는 서로소")

	assert(FlatSet.Equal(a, setOf(3, 2, 1)), "Equal 은 순서 무관")
	assert(not FlatSet.Equal(a, b) and not FlatSet.Equal(a, setOf(1, 2)), "Equal 아님")
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

		const ta = FlatSet.FromList(listA, Common.compareNumber)
		const tb = FlatSet.FromList(listB, Common.compareNumber)
		const ha = stl.HashSet.FromList(listA)
		const hb = stl.HashSet.FromList(listB)

		assert(itemsOf(ta) == sorted(stl.HashSet.Items(ha)), "원소 집합이 같아야 합니다")
		assert(
			itemsOf(FlatSet.Union(ta, tb)) == sorted(stl.HashSet.Items(stl.HashSet.Union(ha, hb))),
			"Union 불일치"
		)
		assert(
			itemsOf(FlatSet.Intersect(ta, tb)) == sorted(stl.HashSet.Items(stl.HashSet.Intersect(ha, hb))),
			"Intersect 불일치"
		)
		assert(
			itemsOf(FlatSet.Difference(ta, tb)) == sorted(stl.HashSet.Items(stl.HashSet.Difference(ha, hb))),
			"Difference 불일치"
		)
		assert(
			itemsOf(FlatSet.SymmetricDifference(ta, tb))
				== sorted(stl.HashSet.Items(stl.HashSet.SymmetricDifference(ha, hb))),
			"SymmetricDifference 불일치"
		)
		assert(FlatSet.IsSubsetOf(ta, tb) == stl.HashSet.IsSubsetOf(ha, hb), "IsSubsetOf 불일치")
		assert(FlatSet.IsDisjointFrom(ta, tb) == stl.HashSet.IsDisjointFrom(ha, hb), "IsDisjointFrom 불일치")
		assert(FlatSet.Equal(ta, tb) == stl.HashSet.Equal(ha, hb), "Equal 불일치")
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
	assert(FlatSet.Len(s) == stl.FlatMap.Len(s.map), "셋의 크기와 안쪽 맵의 크기")
	FlatSet.Add(s, 2)
	assert(FlatSet.Len(s) == stl.FlatMap.Len(s.map) and #FlatSet.Items(s) == FlatSet.Len(s), "Add 후")
end
print("PASS")

print("=== 7. 회귀 — 2026-09-30 리뷰 ===")
do
	-- (5) for item in 이 인덱스가 아니라 원소를 돌려줘야 함 — HashSet 과 바꿔 끼울 수 있게
	const s = setOf(10, 20, 30)
	local one = ""
	for item in FlatSet.Iter(s) do
		one ..= tostring(item) .. ","
	end
	assert(one == "10,20,30,", `for item in: {one}`)
	local two = ""
	for _, item in FlatSet.Iter(s) do
		two ..= tostring(item) .. ","
	end
	assert(two == "10,20,30,", `for _, item in: {two}`)

	-- (2) NaN 원소는 거절
	assert(not pcall(function()
		FlatSet.FromList({ 3, 0 / 0, 1 }, Common.compareNumber)
	end), "FromList 가 NaN 을 거절")
	assert(not pcall(function()
		FlatSet.Add(setOf(1), 0 / 0)
	end), "Add 가 NaN 을 거절")

	-- 비교자가 다른 두 셋을 섞으면 곧바로 에러 — 불변식이 깨진 셋이 퍼지지 않게
	const desc = FlatSet.FromList({ 30, 20, 5 }, function(a: number, b: number): number
		return b - a
	end)
	assert(not pcall(function()
		return FlatSet.Union(setOf(10, 20), desc)
	end), "비교자가 다르면 Union 은 에러")
	assert(not pcall(function()
		return FlatSet.IsSubsetOf(setOf(10, 20), desc)
	end), "비교자가 다르면 IsSubsetOf 도 에러")
end
print("PASS")

print("=== M4. LowerItem / HigherItem / PopFirst / PopLast / Retain (2026-10-07) ===")
do
	const s = setOf(30, 10, 20)
	assert(FlatSet.LowerItem(s, 20) == 10 and FlatSet.FloorItem(s, 20) == 20, "LowerItem 엄격")
	assert(FlatSet.HigherItem(s, 20) == 30 and FlatSet.CeilingItem(s, 20) == 20, "HigherItem 엄격")
	assert(FlatSet.LowerItem(s, 10) == nil and FlatSet.HigherItem(s, 30) == nil, "양끝 밖")
	assert(FlatSet.LowerItem(s, 15) == 10 and FlatSet.HigherItem(s, 15) == 20, "사이 값")
	assert(FlatSet.PopFirst(s) == 10 and itemsOf(s) == "20,30", "PopFirst")
	assert(FlatSet.PopLast(s) == 30 and itemsOf(s) == "20", "PopLast")
	assert(FlatSet.PopLast(s) == 20 and FlatSet.Empty(s), "마지막")
	assert(FlatSet.PopFirst(s) == nil and FlatSet.PopLast(s) == nil and FlatSet.Len(s) == 0, "빈 Pop")
	assert(FlatSet.Add(s, 5) and itemsOf(s) == "5", "꺼낸 뒤 Add")

	const r = setOf(40, 10, 30, 20)
	local order = {}
	const retained = FlatSet.Retain(r, function(item: number): boolean
		table.insert(order, item)
		return item >= 25
	end)
	assert(retained == r, "Retain 은 자기 자신을 돌려줌")
	assert(table.concat(order, ",") == "10,20,30,40", "정렬 순서로 부름")
	assert(itemsOf(r) == "30,40" and FlatSet.Len(r) == 2, "Retain")
	-- 꼬리 칸을 비움 — 안 비우면 지운 원소의 참조가 남아 GC 가 못 거둠(3라운드)
	assert(rawget(r.map.records :: any, 3) == nil and rawget(r.map.records :: any, 4) == nil, "Retain 꼬리")
	assert(FlatSet.Has(r, 30) and not FlatSet.Has(r, 10), "Retain 뒤 Has")

	-- (콜백 안에서 이 셋을 바꾸는 것은 정의되지 않은 동작 — 질문 AL 1, 테스트하지 않음)
	-- NaN 은 없음 — 빼기 비교자에서도
	const sub = FlatSet.FromList({ 10, 20 }, function(a: number, b: number): number
		return a - b
	end)
	assert(FlatSet.LowerItem(sub, 0 / 0) == nil and FlatSet.HigherItem(sub, 0 / 0) == nil, "Lower/Higher NaN")
end
print("PASS")

print(
	"=== nil·NaN 원소 — 넣기는 에러(메시지는 FlatSet 의 것), 조회·삭제는 없음 (2026-10-12) ==="
)
do
	const nilItem = nil :: any
	const s = FlatSet.New<<number>>(Common.compareNumber)
	-- 재현: 빈 셋에 nil 이 조용히 들어가고 그 뒤 연산이 비교자 안에서 죽었음
	const okNil, errNil = pcall(function()
		FlatSet.Add(s, nilItem)
	end)
	assert(not okNil and string.find(tostring(errNil), "FlatSet: nil item", 1, true), `빈 셋에 nil: {errNil}`)
	assert(FlatSet.Len(s) == 0, "거절 뒤 빈 그대로")
	assert(FlatSet.Add(s, 20) and FlatSet.Add(s, 10) and FlatSet.Len(s) == 2, "거절 뒤에도 멀쩡")
	-- 예전엔 `FlatMap: NaN key` — 사용자는 FlatMap 을 부른 적이 없음
	const okNan, errNan = pcall(function()
		FlatSet.Add(s, 0 / 0)
	end)
	assert(not okNan and string.find(tostring(errNan), "FlatSet: NaN item", 1, true), `NaN 메시지: {errNan}`)
	assert(not string.find(tostring(errNan), "FlatMap", 1, true), "FlatMap 이름이 새지 않음")
	assert(
		not FlatSet.Has(s, nilItem) and not FlatSet.Remove(s, nilItem) and FlatSet.Len(s) == 2,
		"nil 로 조회·삭제"
	)
	assert(FlatSet.FloorItem(s, nilItem) == nil and FlatSet.CeilingItem(s, nilItem) == nil, "Floor/Ceiling nil")
	assert(FlatSet.LowerItem(s, nilItem) == nil and FlatSet.HigherItem(s, nilItem) == nil, "Lower/Higher nil")
	-- 리스트의 nil 은 구멍이라 건너뜀(리스트 진입점 규약) — 에러 아님
	const fromHoles = FlatSet.FromList(table.pack(30, nil, 10) :: any, Common.compareNumber)
	assert(FlatSet.Len(fromHoles) == 2 and FlatSet.First(fromHoles) == 10, "FromList 의 구멍")
end
print("PASS")

print(
	"=== 리뷰 1라운드(2026-10-13) — FlatSet: 집합 연산의 상대 검사 전부, RangeItems 의 끝, 에러 자리의 줄 ==="
)
do
	const cmp = stl.Common.compareNumber
	local where = 0
	const s = FlatSet.FromList({ 10, 20, 30 }, cmp)
	const reversed = FlatSet.FromList({ 10, 20, 30 }, function(x: number, y: number): number
		return cmp(y, x)
	end)
	const other: any = stl.TreeSet.FromList({ 30, 40 }, cmp)
	-- 일곱 연산 전부: 비교자가 다른 함수면 에러, 다른 종류의 셋이면 에러(표면이 같아 섞이기 쉬움 — 조용히 빈 셋으로
	-- 읽히거나 라이브러리 줄에서 죽었음). 사용자 줄
	const ops: { { name: string, call: (any, any) -> any } } = {
		{ name = "Union", call = FlatSet.Union },
		{ name = "Intersect", call = FlatSet.Intersect },
		{ name = "Difference", call = FlatSet.Difference },
		{ name = "SymmetricDifference", call = FlatSet.SymmetricDifference },
		{ name = "IsSubsetOf", call = FlatSet.IsSubsetOf },
		{ name = "IsDisjointFrom", call = FlatSet.IsDisjointFrom },
		{ name = "Equal", call = FlatSet.Equal },
	}
	for _, op in ops do
		const run = op.call
		const okOrder, errOrder = pcall(function()
			where = debug.info(1, "l") + 1
			run(s, reversed)
		end)
		assert(
			not okOrder and string.find(tostring(errOrder), "FlatSet: sets use different comparators", 1, true),
			`{op.name} 비교자: {errOrder}`
		)
		assert(
			string.find(tostring(errOrder), `spec.flatset.luau:{where}:`, 1, true),
			`{op.name} 사용자 줄: {errOrder}`
		)
		for _, bad in { other, nil :: any, 5 :: any, stl.Arr.Of(1) :: any } do
			const okKind, errKind = pcall(function()
				where = debug.info(1, "l") + 1
				run(s, bad)
			end)
			assert(
				not okKind
					and string.find(tostring(errKind), "FlatSet: set operations need another FlatSet, got", 1, true),
				`{op.name} 상대 종류: {errKind}`
			)
			assert(
				string.find(tostring(errKind), `spec.flatset.luau:{where}:`, 1, true),
				`{op.name} 종류 사용자 줄: {errKind}`
			)
		end
	end
	assert(
		string.find(tostring(select(2, pcall(FlatSet.Union, s, other))), "got TreeSet", 1, true),
		"메시지에 상대의 종류 이름"
	)
	assert(table.concat(FlatSet.Items(s), ",") == "10,20,30", "거절된 연산은 셋을 안 바꿈")

	-- RangeItems: 끝이 nil·NaN 이면 빈 목록(양쪽 다)
	for _, ends in { { 10, nil }, { nil, 30 }, { 10, 0 / 0 }, { 0 / 0, 30 } } :: { { any } } do
		assert(#FlatSet.RangeItems(s, ends[1], ends[2]) == 0, `RangeItems({tostring(ends[1])}, {tostring(ends[2])})`)
	end
	assert(table.concat(FlatSet.RangeItems(s, 10, 20), ",") == "10,20", "정상 구간")

	-- 에러 자리: 메시지와 사용자 줄
	const sites: { { want: string, call: () -> () } } = {
		{
			want = "FlatSet: nil item",
			call = function()
				where = debug.info(1, "l") + 1
				FlatSet.Add(s, nil :: any)
			end,
		},
		{
			want = "FlatSet: NaN item",
			call = function()
				where = debug.info(1, "l") + 1
				FlatSet.Add(s, 0 / 0)
			end,
		},
		{
			want = "FlatSet: NaN item",
			call = function()
				where = debug.info(1, "l") + 1
				FlatSet.FromList({ 1, 0 / 0 }, cmp)
			end,
		},
		{
			want = "FlatSet: New needs a comparator function, got nil",
			call = function()
				where = debug.info(1, "l") + 1
				FlatSet.New(nil :: any)
			end,
		},
		{
			want = "FlatSet: FromList needs a comparator function, got nil",
			call = function()
				where = debug.info(1, "l") + 1
				FlatSet.FromList({ 1 }, nil :: any)
			end,
		},
	}
	for _, site in sites do
		const ok, err = pcall(site.call)
		assert(not ok and string.find(tostring(err), site.want, 1, true), `{site.want}: {err}`)
		assert(string.find(tostring(err), `spec.flatset.luau:{where}:`, 1, true), `{site.want} 사용자 줄: {err}`)
	end
	const toClear = FlatSet.FromList({ 1, 2 }, cmp)
	assert(stl.Collection.Clear(toClear) == toClear and FlatSet.Len(toClear) == 0, "Collection.Clear")
end
print("PASS")

print()
print("=== ALL PASS (FlatSet) ===")

return true

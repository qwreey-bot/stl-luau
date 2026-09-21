--!strict
--[[
	BSearch 테스트.

	⚠️ 이분 탐색은 **경계에서만 틀립니다.** 빈 배열 / 한 개 / 맨 앞보다 작은
	값 / 맨 뒤보다 큰 값 / 중복 / 없는 값 — 매 함수마다 이 여섯을 봅니다.
]]
local stl = require("../src")
local BSearch = stl.BSearch
local Common = stl.Common

const cmp = Common.compareNumber

print("=== 1. LowerBound ===")
do
	const list = { 10, 20, 20, 30 }
	assert(BSearch.LowerBound(list, 4, 10, cmp) == 1, "맨 앞")
	assert(BSearch.LowerBound(list, 4, 20, cmp) == 2, "중복이면 첫 번째")
	assert(BSearch.LowerBound(list, 4, 30, cmp) == 4, "맨 뒤")
	assert(BSearch.LowerBound(list, 4, 5, cmp) == 1, "전부보다 작으면 1")
	assert(BSearch.LowerBound(list, 4, 99, cmp) == 5, "전부보다 크면 count + 1")
	assert(BSearch.LowerBound(list, 4, 15, cmp) == 2, "사이 값은 들어갈 자리")
	assert(BSearch.LowerBound(list, 0, 10, cmp) == 1, "빈 배열은 항상 1")
	assert(BSearch.LowerBound({ 10 }, 1, 10, cmp) == 1, "한 개, 같음")
	assert(BSearch.LowerBound({ 10 }, 1, 11, cmp) == 2, "한 개, 큼")
	assert(BSearch.LowerBound({ 10 }, 1, 9, cmp) == 1, "한 개, 작음")
end
print("PASS")

print("=== 2. UpperBound ===")
do
	const list = { 10, 20, 20, 30 }
	assert(BSearch.UpperBound(list, 4, 10, cmp) == 2, "같은 값 다음 자리")
	assert(BSearch.UpperBound(list, 4, 20, cmp) == 4, "중복이면 마지막 다음")
	assert(BSearch.UpperBound(list, 4, 30, cmp) == 5, "맨 뒤면 count + 1")
	assert(BSearch.UpperBound(list, 4, 5, cmp) == 1, "전부보다 작으면 1")
	assert(BSearch.UpperBound(list, 4, 99, cmp) == 5, "전부보다 크면 count + 1")
	assert(BSearch.UpperBound(list, 0, 10, cmp) == 1, "빈 배열")
	-- LowerBound 와 UpperBound 의 차가 곧 같은 값의 개수여야 합니다
	assert(BSearch.UpperBound(list, 4, 20, cmp) - BSearch.LowerBound(list, 4, 20, cmp) == 2, "중복 개수")
	assert(BSearch.UpperBound(list, 4, 15, cmp) - BSearch.LowerBound(list, 4, 15, cmp) == 0, "없는 값은 0개")
end
print("PASS")

print("=== 3. Find ===")
do
	const list = { 10, 20, 20, 30 }
	assert(BSearch.Find(list, 4, 10, cmp) == 1, "맨 앞")
	assert(BSearch.Find(list, 4, 20, cmp) == 2, "중복이면 첫 번째")
	assert(BSearch.Find(list, 4, 30, cmp) == 4, "맨 뒤")
	assert(BSearch.Find(list, 4, 15, cmp) == nil, "없는 값")
	assert(BSearch.Find(list, 4, 5, cmp) == nil, "전부보다 작음")
	assert(BSearch.Find(list, 4, 99, cmp) == nil, "전부보다 큼")
	assert(BSearch.Find(list, 0, 10, cmp) == nil, "빈 배열")
	assert(BSearch.Find({ 10 }, 1, 10, cmp) == 1, "한 개, 있음")
	assert(BSearch.Find({ 10 }, 1, 11, cmp) == nil, "한 개, 없음")
	-- ⚠️ count 를 줄여 넘기면 그 뒤는 안 봐야 합니다
	assert(BSearch.Find(list, 2, 30, cmp) == nil, "count 밖은 안 봄")
end
print("PASS")

print("=== 4. EqualRange ===")
do
	const list = { 10, 20, 20, 20, 30 }
	do
		const first, last = BSearch.EqualRange(list, 5, 20, cmp)
		assert(first == 2 and last == 4, `EqualRange 중복: {tostring(first)}..{tostring(last)}`)
	end
	do
		const first, last = BSearch.EqualRange(list, 5, 10, cmp)
		assert(first == 1 and last == 1, "EqualRange 한 개")
	end
	do
		const first, last = BSearch.EqualRange(list, 5, 15, cmp)
		assert(first == nil and last == nil, "EqualRange 없는 값")
	end
	do
		const first = BSearch.EqualRange(list, 0, 10, cmp)
		assert(first == nil, "EqualRange 빈 배열")
	end
	do
		const first = BSearch.EqualRange(list, 5, 99, cmp)
		assert(first == nil, "EqualRange 전부보다 큼")
	end
end
print("PASS")

print("=== 5. 원소 타입과 찾는 값의 타입이 달라도 되는가 ===")
do
	-- TreeMap 이 이렇게 씁니다 — 레코드 배열에서 키로 찾기
	type Rec = { key: string, value: number }
	const recs: { Rec } = {
		{ key = "a", value = 1 },
		{ key = "b", value = 2 },
		{ key = "c", value = 3 },
	}
	const byKey = function(element: Rec, target: string): number
		return Common.compareString(element.key, target)
	end
	assert(BSearch.Find(recs, 3, "b", byKey) == 2, "레코드에서 키로 찾기")
	assert(BSearch.Find(recs, 3, "z", byKey) == nil, "없는 키")
	assert(BSearch.LowerBound(recs, 3, "bb", byKey) == 3, "끼워넣을 자리")
end
print("PASS")

print("=== 6. IsSorted ===")
do
	assert(BSearch.IsSorted({ 1, 2, 2, 3 }, 4, cmp), "정렬됨(중복 포함)")
	assert(not BSearch.IsSorted({ 1, 3, 2 }, 3, cmp), "정렬 안 됨")
	assert(BSearch.IsSorted({}, 0, cmp), "빈 배열은 정렬된 것")
	assert(BSearch.IsSorted({ 5 }, 1, cmp), "한 개는 정렬된 것")
	assert(BSearch.IsSorted({ 1, 3, 2 }, 2, cmp), "count 밖은 안 봄")
end
print("PASS")

print("=== 7. 무작위 대조 — 선형 탐색과 답이 같은가 ===")
do
	-- 이분 탐색은 눈으로 보기 어려우니, 정렬된 배열 여러 개에 대해
	-- 선형 탐색과 답을 대조합니다.
	const rng = 12345
	local seed = rng
	const nextRand = function(limit: number): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed % limit
	end
	for _trial = 1, 200 do
		const count = nextRand(20)
		const list = table.create(count) :: { number }
		for idx = 1, count do
			list[idx] = nextRand(15)
		end
		table.sort(list)
		const target = nextRand(15)

		-- 선형으로 구한 기대값
		local expectedLower = count + 1
		for idx = 1, count do
			if list[idx] >= target then
				expectedLower = idx
				break
			end
		end
		local expectedUpper = count + 1
		for idx = 1, count do
			if list[idx] > target then
				expectedUpper = idx
				break
			end
		end

		assert(
			BSearch.LowerBound(list, count, target, cmp) == expectedLower,
			`LowerBound 불일치: count={count} target={target}`
		)
		assert(
			BSearch.UpperBound(list, count, target, cmp) == expectedUpper,
			`UpperBound 불일치: count={count} target={target}`
		)
	end
end
print("PASS")

print()
print("=== ALL PASS (BSearch) ===")

return true

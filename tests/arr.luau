--[[
	src/arr.luau 스모크 테스트.

	실행: luau tests/arr.luau  (또는 luau tests/run.luau 로 전체)
	실패하면 assert 가 그 자리에서 traceback 과 함께 터집니다.
	프레임워크는 쓰지 않습니다 — 이유는 .claude/base/architecture.md 의
	"테스트: assert + print" 절 참고.
]]

local arr = require("../src/arr")

-- 배열 내용을 "[1,2,3]" 형태로 — assert 실패 메시지에 실제 값을 싣기 위함
local function fmt(a): string
	local parts = table.create(a.n)
	for idx = 1, a.n do
		parts[idx] = tostring(a[idx])
	end
	return `[{table.concat(parts, ",")}] (n={a.n})`
end

local function assert_arr(actual, expected, label: string)
	assert(actual:equal(expected), `{label}: expected {fmt(expected)}, got {fmt(actual)}`)
end

print("=== 1. slice_inplace ===")
do
	assert_arr(arr(1, 2, 3, 4, 5):slice_inplace(2, 2), arr(2), "start: 2, last: 2 (len = 1)")
	assert_arr(arr(1, 2, 3, 4, 5):slice_inplace(2, 4), arr(2, 3, 4), "start: 2, last: 4")
	assert_arr(arr(1, 2, 3, 4, 5):slice_inplace(-2, -1), arr(4, 5), "start: -2, last: -1 (end)")
	assert_arr(arr(1, 2, 3, 4, 5):slice_inplace(-2, -2), arr(4), "start: -2, last: -2 (len = 1)")
	assert_arr(arr(1, 2, 3, 4, 5):slice_inplace(-2, -3), arr(), "start: -2, last: -3 (len = 0)")
	assert_arr(arr(1, 2, 3, 4, 5):slice_inplace(-4, -2), arr(2, 3, 4), "start: -4, last: -2")
	print("PASS")
end

print()
print("=== 2. 요소 추가 (push / unshift / insert) ===")
do
	assert_arr(arr(1, 2, 3):push(6), arr(1, 2, 3, 6), "push")
	assert_arr(arr(1, 2, 3):push_many(6, 7), arr(1, 2, 3, 6, 7), "push_many")
	assert_arr(arr(1, 2, 3):push_array(arr(6, 7)), arr(1, 2, 3, 6, 7), "push_array")
	assert_arr(arr(1, 2, 3):unshift(0), arr(0, 1, 2, 3), "unshift")
	assert_arr(arr(1, 2, 3):insert(2, 9), arr(1, 9, 2, 3), "insert")
	print("PASS")
end

print()
print("=== 3. erase_inplace ===")
do
	assert_arr(arr(1, 2, 3, 4, 5):erase_inplace(2, 3), arr(1, 4, 5), "erase_inplace(2, 3)")
	assert_arr(arr(1, 2, 3):erase_inplace(), arr(), "erase_inplace() — 전체 삭제")
	print("PASS")
end

print()
print("=== 4. map / filter / reduce ===")
do
	assert_arr(
		arr(1, 2, 3):map(function(v)
			return v * 2
		end),
		arr(2, 4, 6),
		"map"
	)
	assert_arr(
		arr(1, 2, 3, 4):filter(function(v)
			return v % 2 == 0
		end),
		arr(2, 4),
		"filter"
	)
	local sum = arr(1, 2, 3, 4):reduce(function(acc, v)
		return acc + v
	end, 0)
	assert(sum == 10, `reduce: expected 10, got {sum}`)
	print("PASS")
end

print()
print("=== 5. merge ===")
do
	assert_arr(arr.merge(arr(1, 2), arr(3, 4)), arr(1, 2, 3, 4), "merge")
	assert_arr(arr(1, 2):merge_inplace(arr(3, 4)), arr(1, 2, 3, 4), "merge_inplace")
	print("PASS")
end

print()
print("=== 6. flat / flat_inplace ===")
-- 회귀 테스트: 아래 케이스들은 2026-08-22 이전에 전부 깨져 있었음
-- (defer 부기 오류 / inner_len[1] 오타). 자세한 내용은 git log 참고.
do
	assert_arr(arr(1, 2, 3):flat(), arr(1, 2, 3), "flat — 중첩 없음")
	assert_arr(arr(1, arr(2, 3), 4):flat(), arr(1, 2, 3, 4), "flat — 가운데 중첩")
	assert_arr(arr(1, arr(2), 3):flat(), arr(1, 2, 3), "flat — 길이 1 내부 배열")
	assert_arr(arr(1, arr(), 2):flat(), arr(1, 2), "flat — 빈 내부 배열")
	assert_arr(arr(arr(1), arr(2)):flat(), arr(1, 2), "flat — 전부 중첩")
	assert_arr(arr(arr(1, 2), 3, 4):flat(), arr(1, 2, 3, 4), "flat — 맨 앞 중첩")
	assert_arr(arr():flat(), arr(), "flat — 빈 배열")
	assert_arr(arr(7):flat(), arr(7), "flat — 요소 1개")

	assert_arr(arr(1, arr(2), 3):flat_inplace(), arr(1, 2, 3), "flat_inplace — 길이 1 내부 배열")
	assert_arr(arr(arr(2)):flat_inplace(), arr(2), "flat_inplace — 길이 1 내부 배열만")
	assert_arr(arr(1, arr(2, 3), 4):flat_inplace(), arr(1, 2, 3, 4), "flat_inplace — 가운데 중첩")
	assert_arr(arr(1, arr(), 2):flat_inplace(), arr(1, 2), "flat_inplace — 빈 내부 배열")
	print("PASS")
end

print()
print("=== 7. 조회 계열 (find / count / some / every / sum / prod / join) ===")
do
	local found, at = arr(1, 2, 3, 4):find(function(v)
		return v > 2
	end)
	assert(found == 3 and at == 3, `find: expected (3, 3), got ({found}, {at})`)

	local counted = arr(1, 2, 3, 4):count(function(v)
		return v % 2 == 0
	end)
	assert(counted == 2, `count: expected 2, got {counted}`)

	assert(
		arr(1, 2, 3):every(function(v)
			return v > 0
		end),
		"every: 전부 양수여야 참"
	)
	assert(
		arr(1, 2, 3):some(function(v)
			return v > 2
		end),
		"some: 2보다 큰 요소가 있어야 참"
	)
	assert(arr(1, 2, 3):sum() == 6, "sum")
	assert(arr(2, 3, 4):prod() == 24, "prod")
	assert(arr(1, 2, 3):join("-") == "1-2-3", "join")
	assert(arr():empty(), "empty: 빈 배열")
	assert(arr(1, 2):len() == 2, "len")
	print("PASS")
end

print()
print("=== 8. filter_inplace ===")
-- 회귀 테스트: 2026-08-22 이전엔 전 케이스가 깨져 있었음
-- (arr(1,2,3,4) -> [nil,nil] 처럼). git log 참고.
do
	local even = function(v)
		return v % 2 == 0
	end
	assert_arr(arr(1, 2, 3, 4):filter_inplace(even), arr(2, 4), "filter_inplace — 섞임")
	assert_arr(arr(2, 4, 6):filter_inplace(even), arr(2, 4, 6), "filter_inplace — 전부 통과")
	assert_arr(arr(1, 3, 5):filter_inplace(even), arr(), "filter_inplace — 전부 탈락")
	assert_arr(arr(1, 2, 3, 4, 5, 6):filter_inplace(even), arr(2, 4, 6), "filter_inplace — 6개")
	assert_arr(
		arr():filter_inplace(function()
			return true
		end),
		arr(),
		"filter_inplace — 빈 배열"
	)
	print("PASS")
end

print()
print("=== 9. 생성자 (sized / clone / from_table / clone_from_table) ===")
do
	assert_arr(arr.sized(3, "x"), arr("x", "x", "x"), "sized(3, 'x')")
	-- 회귀 테스트: sized 가 결과가 아니라 공유 인터페이스 테이블에 써서
	-- 프로그램 내 모든 배열을 오염시키던 버그. rawget 으로 실제 소유 여부를 확인한다
	-- (__index 폴백 때문에 일반 인덱싱만으로는 오염을 못 잡음).
	local sized = arr.sized(2, "own")
	assert(rawget(sized, 1) == "own", "sized: 값이 결과 배열 자체에 있어야 함 (__index 폴백이 아니라)")
	assert(arr()[1] == nil, "sized: 새 빈 배열이 오염되지 않아야 함")

	assert_arr(arr(1, 2, 3):clone(), arr(1, 2, 3), "clone")
	assert_arr(arr.from_table({ 1, 2, 3 }), arr(1, 2, 3), "from_table")
	-- 회귀 테스트: clone_from_table 은 return 이 없어 nil 을 돌려줬음
	assert_arr(arr.clone_from_table({ 1, 2, 3 }), arr(1, 2, 3), "clone_from_table")
	print("PASS")
end

print()
print("=== 10. max / min ===")
-- 회귀 테스트: 비교 방향이 뒤집혀 max 가 최소값을, min 이 최대값을 돌려줬음
do
	assert(arr(3, 1, 4, 1, 5):max() == 5, "max")
	assert(arr(3, 1, 4, 1, 5):min() == 1, "min")
	print("PASS")
end

print()
print("=== ALL PASS (arr) ===")

-- tests/run.luau 가 require 로 이 파일을 끌어오므로 반드시 값을 하나 반환해야
-- 합니다 (luau: "module must return a single value"). 직접 실행할 때는 무의미한
-- 반환값이지만, 없으면 run.luau 쪽에서 에러가 납니다.
return true

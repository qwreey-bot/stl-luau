--!strict
--[[
	src/arr.luau 스모크 테스트.

	실행: luau tests/arr.luau  (또는 luau tests/run.luau 로 전체)
	실패하면 assert 가 그 자리에서 traceback 과 함께 터집니다.
	프레임워크는 쓰지 않습니다 — 이유는 .claude/base/architecture.md 의
	"테스트: assert + print" 절 참고.
]]

local arr = require("../src/arr")

-- 배열 내용을 "[1,2,3]" 형태로 — assert 실패 메시지에 실제 값을 싣기 위함
local function fmt(a: arr.Arr<any>): string
	local parts = table.create(a.n)
	for idx = 1, a.n do
		parts[idx] = tostring(a[idx])
	end
	return `[{table.concat(parts, ",")}] (n={a.n})`
end

local function assert_arr(actual: arr.Arr<any>, expected: arr.Arr<any>, label: string)
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
print("=== 11. reverse / reverse_inplace ===")
do
	assert_arr(arr(1, 2, 3, 4, 5):reverse(), arr(5, 4, 3, 2, 1), "reverse (전체)")
	assert_arr(arr(1, 2, 3, 4, 5):reverse(2, 4), arr(4, 3, 2), "reverse (부분 범위만 새 배열로)")
	assert_arr(arr(1, 2, 3, 4, 5):reverse(-2, -1), arr(5, 4), "reverse (음수 인덱스)")
	assert_arr(arr(1):reverse(), arr(1), "reverse (길이 1)")
	assert_arr(arr():reverse(), arr(), "reverse (빈 배열)")

	-- to 를 주면 기본적으로 뒤에 이어붙습니다
	assert_arr(arr(1, 2, 3):reverse(nil, nil, arr(9)), arr(9, 3, 2, 1), "reverse (to 에 이어붙이기)")
	-- to_start 를 명시하면 그 자리부터 **덮어씁니다**(밀어내지 않습니다).
	-- slice 의 to_start 와 다른 의미이니 주의 — .claude/todos.md 참고
	assert_arr(
		arr(1, 2, 3):reverse(nil, nil, arr(9, 9, 9, 9, 9), 2),
		arr(9, 3, 2, 1, 9),
		"reverse (to_start 지정 = 덮어쓰기)"
	)

	-- self 는 건드리지 않아야 합니다
	local origin = arr(1, 2, 3)
	origin:reverse()
	assert_arr(origin, arr(1, 2, 3), "reverse 는 self 를 바꾸지 않음")

	assert_arr(arr(1, 2, 3, 4, 5):reverse_inplace(), arr(5, 4, 3, 2, 1), "reverse_inplace (전체)")
	assert_arr(arr(1, 2, 3, 4, 5):reverse_inplace(2, 4), arr(1, 4, 3, 2, 5), "reverse_inplace (부분)")
	assert_arr(arr(1, 2, 3, 4, 5):reverse_inplace(-3, -1), arr(1, 2, 5, 4, 3), "reverse_inplace (음수 인덱스)")
	print("PASS")
end

print()
print("=== 12. rotate / rotate_inplace ===")
-- 규약: shift 가 양수면 왼쪽으로 회전합니다
do
	assert_arr(arr(1, 2, 3, 4, 5):rotate_inplace(1), arr(2, 3, 4, 5, 1), "rotate_inplace(+1) = 왼쪽")
	assert_arr(arr(1, 2, 3, 4, 5):rotate_inplace(-1), arr(5, 1, 2, 3, 4), "rotate_inplace(-1) = 오른쪽")
	assert_arr(arr(1, 2, 3, 4, 5):rotate_inplace(5), arr(1, 2, 3, 4, 5), "rotate_inplace (길이만큼 = 제자리)")
	assert_arr(arr(1, 2, 3, 4, 5):rotate_inplace(7), arr(3, 4, 5, 1, 2), "rotate_inplace (길이 초과는 모듈러)")
	assert_arr(arr(1, 2, 3, 4, 5):rotate_inplace(1, 2, 4), arr(1, 3, 4, 2, 5), "rotate_inplace (부분 범위)")
	assert_arr(arr(1):rotate_inplace(1), arr(1), "rotate_inplace (길이 1)")
	assert_arr(arr():rotate_inplace(1), arr(), "rotate_inplace (빈 배열)")

	assert_arr(arr(1, 2, 3, 4, 5):rotate(2), arr(3, 4, 5, 1, 2), "rotate (전체)")
	assert_arr(arr(1, 2, 3, 4, 5):rotate(2, 2, 5), arr(4, 5, 2, 3), "rotate (부분 범위만 새 배열로)")
	-- to 를 주면 이어붙인 구간만 회전해야 합니다 (앞의 원소는 그대로)
	assert_arr(arr(1, 2, 3, 4, 5):rotate(2, nil, nil, arr(0)), arr(0, 3, 4, 5, 1, 2), "rotate (to 에 이어붙이기)")

	local origin = arr(1, 2, 3)
	origin:rotate(1)
	assert_arr(origin, arr(1, 2, 3), "rotate 는 self 를 바꾸지 않음")
	print("PASS")
end

print()
print("=== 13. sorted / sort_inplace ===")
do
	assert_arr(arr(3, 1, 4, 1, 5):sorted(), arr(1, 1, 3, 4, 5), "sorted (기본 오름차순)")
	assert_arr(arr():sorted(), arr(), "sorted (빈 배열)")

	-- Comparator<T> 는 boolean 과 number 를 모두 받습니다 (common.compareTo)
	assert_arr(arr(3, 1, 4, 1, 5):sorted(function(a, b)
		return b - a
	end), arr(5, 4, 3, 1, 1), "sorted (number 비교자, 내림차순)")
	-- boolean 비교자는 "a 가 b 보다 크냐" 입니다 (common.compareTo 가 true 를
	-- 1 로 접음) — max/min 과 같은 규약이라 내림차순은 a < b 로 씁니다
	assert_arr(arr(3, 1, 4, 1, 5):sorted(function(a, b)
		return a > b
	end), arr(1, 1, 3, 4, 5), "sorted (boolean 비교자, 오름차순)")
	assert_arr(arr(3, 1, 4, 1, 5):sorted(function(a, b)
		return a < b
	end), arr(5, 4, 3, 1, 1), "sorted (boolean 비교자, 내림차순)")

	local origin = arr(3, 1, 2)
	origin:sorted()
	assert_arr(origin, arr(3, 1, 2), "sorted 는 self 를 바꾸지 않음")

	local in_place = arr(3, 1, 4, 1, 5):sort_inplace()
	assert_arr(in_place, arr(1, 1, 3, 4, 5), "sort_inplace")
	assert(arr.is_arr(in_place), "sort_inplace 후에도 is_arr 여야 함")

	-- 회귀: 1..n 사이에 nil 구멍이 있으면 "attempt to compare nil" 로 터졌음.
	-- 구멍은 정렬 대상에서 빠지고 뒤로 몰리며 n 은 보존됩니다
	local holed = arr.sized(5)
	holed[1], holed[3], holed[5] = 3, 1, 2
	local sorted_holed = holed:sorted()
	assert(sorted_holed.n == 5, "sorted 가 n 을 보존해야 함")
	assert(
		sorted_holed[1] == 1 and sorted_holed[2] == 2 and sorted_holed[3] == 3,
		"sorted 가 구멍을 건너뛰고 정렬해야 함"
	)
	assert(sorted_holed[4] == nil and sorted_holed[5] == nil, "sorted 가 구멍을 뒤로 몰아야 함")
	assert(holed[1] == 3 and holed[2] == nil, "sorted 는 self 를 바꾸지 않음 (구멍 포함)")

	-- 사용자 비교자에는 nil 이 넘어가지 않아야 합니다
	local saw_nil = false
	holed:sorted(function(a, b)
		if a == nil or b == nil then
			saw_nil = true
		end
		return (a :: any) > (b :: any)
	end)
	assert(not saw_nil, "비교자가 nil 을 받으면 안 됨")

	local holed_inplace = arr.sized(4)
	holed_inplace[2], holed_inplace[4] = 5, 1
	holed_inplace:sort_inplace()
	assert(holed_inplace.n == 4, "sort_inplace 가 n 을 보존해야 함")
	assert(
		holed_inplace[1] == 1 and holed_inplace[2] == 5 and holed_inplace[3] == nil and holed_inplace[4] == nil,
		"sort_inplace 가 구멍을 뒤로 몰아야 함"
	)
	print("PASS")
end

print()
print("=== 14. replace / replace_inplace ===")
do
	assert_arr(arr(1, 2, 3, 4, 5):replace(2, 3, arr(9, 9, 9)), arr(1, 9, 9, 9, 4, 5), "replace (더 긴 것으로)")
	assert_arr(arr(1, 2, 3, 4, 5):replace(2, 4, arr(9)), arr(1, 9, 5), "replace (더 짧은 것으로)")
	assert_arr(arr(1, 2, 3, 4, 5):replace(1, 5, arr(9)), arr(9), "replace (전체)")
	assert_arr(arr(1, 2, 3, 4, 5):replace(2, 3, arr()), arr(1, 4, 5), "replace (빈 배열로 = 삭제)")
	assert_arr(arr(1, 2, 3):replace(-1, -1, arr(9)), arr(1, 2, 9), "replace (음수 인덱스)")
	-- start > last 는 빈 구간이므로 그 자리에 삽입만 합니다
	assert_arr(arr(1, 2, 3):replace(2, 1, arr(9)), arr(1, 9, 2, 3), "replace (빈 구간 = 삽입)")

	local origin = arr(1, 2, 3)
	origin:replace(1, 1, arr(9))
	assert_arr(origin, arr(1, 2, 3), "replace 는 self 를 바꾸지 않음")

	assert_arr(arr(1, 2, 3, 4, 5):replace_inplace(2, 3, arr(9, 9, 9)), arr(1, 9, 9, 9, 4, 5), "replace_inplace")
	print("PASS")
end

print()
print("=== 15. erase / erase_inplace ===")
do
	assert_arr(arr(1, 2, 3, 4, 5):erase(2, 3), arr(1, 4, 5), "erase (가운데)")
	assert_arr(arr(1, 2, 3, 4, 5):erase(), arr(), "erase (인자 없음 = 전체)")
	assert_arr(arr(1, 2, 3, 4, 5):erase(-2, -1), arr(1, 2, 3), "erase (음수 인덱스)")

	local origin = arr(1, 2, 3)
	origin:erase(1, 1)
	assert_arr(origin, arr(1, 2, 3), "erase 는 self 를 바꾸지 않음")

	-- 회귀: 뒤집힌(빈) 구간에서 removed 가 음수가 되어 배열이 늘어났음
	assert_arr(arr(1, 2, 3, 4, 5):erase_inplace(3, 1), arr(1, 2, 3, 4, 5), "erase_inplace (빈 구간은 no-op)")
	assert_arr(arr(1, 2, 3, 4, 5):erase_inplace(2, 4), arr(1, 5), "erase_inplace")
	print("PASS")
end

print()
print("=== 16. shuffle / shuffle_inplace ===")
do
	-- rng 를 주입해 결정적으로 검사합니다 (항상 하한을 고르는 rng)
	local function lowest(lo: number, _hi: number): number
		return lo
	end
	assert_arr(arr(1, 2, 3, 4, 5):shuffle_inplace(nil, nil, lowest), arr(2, 3, 4, 5, 1), "shuffle_inplace (결정적 rng)")
	assert_arr(arr(1, 2, 3, 4, 5):shuffle_inplace(2, 4, lowest), arr(1, 3, 4, 2, 5), "shuffle_inplace (부분 범위)")

	local origin = arr(1, 2, 3)
	origin:shuffle(nil, nil, lowest)
	assert_arr(origin, arr(1, 2, 3), "shuffle 은 self 를 바꾸지 않음")

	-- 실제 난수로도 원소 구성(다중집합)과 길이는 보존돼야 합니다
	local shuffled = arr(1, 2, 3, 4, 5):shuffle()
	assert(shuffled.n == 5, "shuffle 이 길이를 보존해야 함")
	assert_arr(shuffled:sorted(), arr(1, 2, 3, 4, 5), "shuffle 이 원소 구성을 보존해야 함")
	print("PASS")
end

print()
print("=== 17. clear 가 __arr__ 태그를 유지하는지 ===")
-- 회귀: table.clear 가 태그까지 지워서 비운 배열이 is_arr 를 통과하지 못했음
do
	local a = arr(1, 2, 3):clear()
	assert(arr.is_arr(a), "clear 후에도 is_arr 여야 함")
	assert(a.n == 0, "clear 후 n 은 0")
	assert(arr.is_arr(arr(1, 2, 3):slice_inplace(-2, -3)), "빈 구간 slice_inplace 후에도 is_arr 여야 함")
	print("PASS")
end
print()
print("=== ALL PASS (arr) ===")

-- tests/run.luau 가 require 로 이 파일을 끌어오므로 반드시 값을 하나 반환해야
-- 합니다 (luau: "module must return a single value"). 직접 실행할 때는 무의미한
-- 반환값이지만, 없으면 run.luau 쪽에서 에러가 납니다.
return true

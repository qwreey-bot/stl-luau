--!strict
-- 재작성 전에 **확정해둔 버그 재현**. 3단계에서 이 케이스들이 통과해야 합니다.
-- 지금은 전부 실패하는 게 정상입니다(고치지 않았으므로).
--   실행: luau .claude/audit/known-bugs/repro.luau
local arr = require("../../../src/arr")

local fails = 0
local function check(label: string, ok: boolean, detail: string?)
	if ok then
		print("  PASS  " .. label)
	else
		fails += 1
		print("  FAIL  " .. label .. (if detail then "  — " .. detail else ""))
	end
end
local function fmt(a): string
	local p = table.create(a.n)
	for i = 1, a.n do p[i] = tostring(a[i]) end
	return "[" .. table.concat(p, ",") .. "] n=" .. a.n
end

print("=== 버그 1: slice 의 to_start 삽입 경로 ===")
print("  to_len=5, to_start=2, move_len=2 → 기존 2..5 를 4..7 로 밀어야 함")
do
	local to = arr(9, 9, 9, 9, 9)
	local src = arr(1, 2)
	local got = src:slice(1, 2, to, 2)
	-- 밀어내고 삽입이라면: [9,1,2,9,9,9,9] (n=7)
	local want = arr(9, 1, 2, 9, 9, 9, 9)
	check("밀어내고 삽입", got:equal(want), "got " .. fmt(got) .. ", want " .. fmt(want))
end

print()
print("=== 버그 2: nil 구멍에서 Max/Min/Sum/Prod ===")
do
	local holed = arr.sized(5)
	holed[1], holed[3], holed[5] = 3, 1, 2
	for _, name in { "max", "min", "sum", "prod" } do
		local ok = pcall(function()
			return (holed :: any)[name](holed)
		end)
		check(name .. " 이 구멍에서 안 터짐", ok)
	end
end

print()
print("=== 대조군: 이미 고친 것들은 통과해야 함 ===")
do
	check("clear 후 is_arr", arr.is_arr(arr(1, 2, 3):clear()))
	check("erase_inplace(3,1) no-op", arr(1, 2, 3, 4, 5):erase_inplace(3, 1):equal(arr(1, 2, 3, 4, 5)))
	local h = arr.sized(3)
	h[1], h[3] = 3, 1
	check("sorted 가 구멍에서 안 터짐", pcall(function() return h:sorted() end))
end

print()
print(string.format("실패 %d건 (재작성 전이므로 버그 2종은 실패가 정상)", fails))
return true

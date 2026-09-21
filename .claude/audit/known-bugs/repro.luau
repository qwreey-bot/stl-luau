--!strict
--[[
	재작성 전에 확정해둔 **버그 재현**. 재작성이 끝나면 **0 실패**여야 합니다.
	실행: `luau .claude/audit/known-bugs/repro.luau`

	[2026-09-22] 새 `src/Arr.luau` 기준으로 옮겼고, **0 실패입니다.**
	옛 API 로 쓰여 있던 판은 git 히스토리에 있습니다.
]]
local stl = require("../../../src")
local Arr = stl.Arr

type Arr<T> = stl.Arr<T>

local fails = 0
local function check(label: string, ok: boolean, detail: string?)
	if ok then
		print("  PASS  " .. label)
	else
		fails += 1
		print("  FAIL  " .. label .. (if detail then "  — " .. detail else ""))
	end
end
local function fmt(a: Arr<number>): string
	local parts = table.create(a.n) :: { string }
	for idx = 1, a.n do
		parts[idx] = tostring(a[idx])
	end
	return "[" .. table.concat(parts, ",") .. "] n=" .. tostring(a.n)
end

print("=== 버그 1: slice 의 to_start 삽입 경로 → 매개변수를 없애서 해소 ===")
print("  `to_start` 는 '밀어내기냐 덮어쓰기냐' 가 갈려 데이터를 잃던 자리였습니다.")
print("  이제 `to` 는 '목적지 뒤에 이어붙이기' 하나만 뜻합니다.")
do
	local to: Arr<number> = Arr.Of(9, 9, 9, 9, 9)
	local got = Arr.Of(1, 2):Slice(1, 2, to)
	local want: Arr<number> = Arr.Of(9, 9, 9, 9, 9, 1, 2)
	check("Slice 의 to 가 뒤에 이어붙임", got:Equal(want), "got " .. fmt(got) .. ", want " .. fmt(want))
	check("to 를 그대로 돌려줌", got == to)
	-- 예전엔 기존 원소를 밀다가 잃었습니다. 이제 아무것도 안 잃어야 합니다.
	check("기존 원소를 하나도 안 잃음", got.n == 7)

	-- 같은 뿌리의 교훈: 삽입 위치의 유효 범위는 원소 위치보다 하나 넓다.
	-- 이걸 놓치면 "맨 뒤에 삽입" 이 원리적으로 불가능해집니다.
	local inserted: Arr<number> = Arr.Of(1, 2):Insert(3, 3)
	check("맨 뒤(n+1)에 삽입이 가능", inserted:Equal(Arr.Of(1, 2, 3)), fmt(inserted))
end

print()
print("=== 버그 2: nil 구멍에서 Max/Min/Sum/Prod ===")
do
	local holed = Arr.Sized(5) :: Arr<number>
	holed[1], holed[3], holed[5] = 3, 1, 2
	check("Max 가 구멍에서 안 터짐", (pcall(function()
		return holed:Max()
	end)))
	check("Min 이 구멍에서 안 터짐", (pcall(function()
		return holed:Min()
	end)))
	check("Sum 이 구멍에서 안 터짐", (pcall(function()
		return holed:Sum()
	end)))
	check("Prod 가 구멍에서 안 터짐", (pcall(function()
		return holed:Prod()
	end)))
	-- 값까지 맞아야 합니다 — 구멍을 건너뛴 결과여야지 0 이나 nil 이면 안 됩니다
	check("Max 값", holed:Max() == 3)
	check("Min 값", holed:Min() == 1)
	check("Sum 값", holed:Sum() == 6)
	check("Prod 값", holed:Prod() == 6)
	check("Join 이 구멍을 건너뜀", holed:Join(",") == "3,1,2")
end

print()
print("=== 대조군: 이미 고쳤던 것들은 계속 통과해야 함 ===")
do
	check("Clear 후 isArr", stl.isArr(Arr.Of(1, 2, 3):Clear()))
	check("Clear 후 다시 담김", Arr.Of(1, 2, 3):Clear():PushBack(7):Equal(Arr.Of(7)))
	local erased: Arr<number> = Arr.Of(1, 2, 3, 4, 5):EraseInplace(3, 1)
	check("EraseInplace(3,1) 는 아무것도 안 함", erased:Equal(Arr.Of(1, 2, 3, 4, 5)), fmt(erased))

	local holed = Arr.Sized(3) :: Arr<number>
	holed[1], holed[3] = 3, 1
	check("Sort 가 구멍에서 안 터짐", (pcall(function()
		return holed:Sort()
	end)))
	local sorted = holed:Sort()
	check("Sort 가 n 을 보존하고 구멍을 뒤로 몲", sorted.n == 3 and sorted[1] == 1 and sorted[2] == 3 and sorted[3] == nil)
end

print()
print(string.format("실패 %d건", fails))
assert(fails == 0, `재현 파일에서 {fails}건 실패 — 재작성이 이 케이스들을 덮지 못했습니다`)
return true

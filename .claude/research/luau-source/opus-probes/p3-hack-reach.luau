--!strict
-- LuauSoundGenericMismatches 땜질(TypeChecker2.cpp:3944-3990)이 닿는 자리와 안 닿는 자리
local function f<T>(x: T, xs: { T })
	local l1: T = 5 -- L1 지역 초기화 → 땜질 밖(testPotentialLiteralIsSubtype) → 0건 예상
	local y: T = x
	y = 5 -- L2 대입 → 땜질 안(1338) → 잡힘 예상
	local function inner(z: T) end
	inner(5) -- L3 호출 인자, 기대 타입이 정확히 T → 잡힘 예상
	local function innerOpt(z: T?) end
	innerOpt(5) -- L4 호출 인자, 기대 타입 T? → 0건 예상
	xs[1] = 5 -- L5 인덱스 대입: 기대 타입 T → ?
	local function nested(): T
		return 5 -- L6 중첩 함수의 return, 기대 T → 잡힘 예상
	end
	local function nestedOpt(): T?
		return 5 -- L7 → 0건 예상
	end
	local tbl: { T } = { 5 } -- L8 표 리터럴 원소 → ?
	return l1, nested, nestedOpt, tbl
end
return f

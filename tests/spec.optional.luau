--!strict
--[[
	Optional 테스트 + Arr 의 구멍 다루기 넷.

	⭐ 이 둘은 checked/unchecked 갈림의 **세 번째 답**이라 같이 봅니다 —
	구멍을 한 번 정리하고 나면 `*Unchecked` 가 안전해지는지까지 확인합니다.
]]
local stl = require("../src")
local Optional = stl.Optional
local Arr = stl.Arr

type Optional<T> = stl.Optional<T>
type Arr<T> = stl.Arr<T>

print("=== 1. 생성과 판별 ===")
do
	const p = Optional.Present(3)
	assert(p.isPresent == true and p.value == 3, "Present")
	assert(Optional.Absent.isPresent == false and Optional.Absent.value == nil, "Absent")
	assert(table.isfrozen(Optional.Absent :: any), "Absent 는 동결된 싱글턴")
	assert(Optional.Of(nil) == Optional.Absent, "Of(nil) 은 Absent 싱글턴")
	const of5 = Optional.Of(5)
	assert(of5.isPresent and Optional.Unwrap(of5) == 5, "Of(값) 은 Present")
	-- "값이 nil 인 Present" 는 Present 로만 만들 수 있습니다
	const presentNil = Optional.Present(nil)
	assert(presentNil.isPresent == true, "Present(nil) 은 Present")
	assert((presentNil :: any) ~= Optional.Absent, "Present(nil) 은 Absent 와 다름")
	-- false 도 값입니다 (nil 과 다름)
	assert(Optional.Of(false).isPresent == true, "Of(false) 는 Present")

	assert(stl.isOptional(p), "isOptional Present")
	assert(stl.isOptional(Optional.Absent), "isOptional Absent")
	assert(not stl.isOptional({}), "빈 테이블은 아님")
	assert(not stl.isOptional(nil), "nil 은 아님")
	assert(not stl.isOptional(3), "숫자는 아님")
	-- (7) 리터럴로 만든 Absent 도 타입상 Optional 이고 UnwrapOr 도 그렇게 다루므로 받는다
	assert(stl.isOptional({ isPresent = false }), "리터럴 Absent 도 Optional")
end
print("PASS")

print("=== 2. 꺼내기 ===")
do
	const p: Optional<number> = Optional.Present(3)
	const a: Optional<number> = Optional.Absent
	assert(Optional.Unwrap(p) == 3, "Unwrap")
	assert(not pcall(Optional.Unwrap, a), "Absent 의 Unwrap 은 에러")
	const ok, err = pcall(Optional.Unwrap, a)
	assert(not ok and string.find(tostring(err), "Unwrap called on Absent", 1, true), "에러 메시지")
	assert(Optional.UnwrapOr(p, 0) == 3, "UnwrapOr Present")
	assert(Optional.UnwrapOr(a, 0) == 0, "UnwrapOr Absent")
	assert(Optional.ToNil(p) == 3 and Optional.ToNil(a) == nil, "ToNil")
	-- 좁히기
	if p.isPresent then
		const v: number = p.value
		assert(v == 3, "좁힌 뒤 값")
	end
end
print("PASS")

print("=== 3. Map ===")
do
	const p: Optional<number> = Optional.Present(3)
	const a: Optional<number> = Optional.Absent
	const mapped = Optional.Map(p, function(v: number): string
		return tostring(v * 2)
	end)
	assert(Optional.Unwrap(mapped) == "6", "Map Present")
	local called = false
	const mappedAbsent = Optional.Map(a, function(v: number): string
		called = true
		return tostring(v)
	end)
	assert(mappedAbsent == Optional.Absent, "Map Absent 는 Absent 싱글턴 그대로")
	assert(not called, "Absent 에는 콜백을 부르지 않음")
end
print("PASS")

print("=== 4. Arr — 구멍 다루기 넷 ===")
do
	-- 구멍이 있는 배열은 타입에도 `?` 가 드러납니다(질문 T (b)).
	const holed = Arr.Sized<<number?>>(5, nil)
	holed[1], holed[3], holed[5] = 10, 30, 50

	-- Compact: 새 배열, 순서 유지, 원본 불변
	const compact = Arr.Compact(holed)
	assert(compact.n == 3 and compact[1] == 10 and compact[2] == 30 and compact[3] == 50, "Compact")
	assert(holed.n == 5 and holed[2] == nil, "Compact 는 원본을 안 건드림")
	assert(Arr.Compact(Arr.Of<<number>>()).n == 0, "빈 것의 Compact")

	-- CompactInplace: 제자리, 꼬리를 비움
	const inplace = Arr.Sized<<number?>>(4, nil)
	inplace[2], inplace[4] = 2, 4
	const same = Arr.CompactInplace(inplace)
	assert(same == inplace, "CompactInplace 는 자기 자신")
	assert(inplace.n == 2 and inplace[1] == 2 and inplace[2] == 4, "CompactInplace 결과")
	assert(inplace[3] == nil and inplace[4] == nil, "CompactInplace 는 꼬리를 비움")

	-- FillHoles: 새 배열, 길이 불변, 원본 불변. 결과 타입에서 `?` 가 빠집니다.
	const fillSource = Arr.Sized<<number?>>(3, nil)
	fillSource[2] = 7
	const filled: Arr<number> = Arr.FillHoles(fillSource, 0)
	assert(filled ~= fillSource, "FillHoles 는 새 배열")
	assert(filled.n == 3 and filled[1] == 0 and filled[2] == 7 and filled[3] == 0, "FillHoles")
	assert(fillSource[1] == nil and fillSource[3] == nil, "FillHoles 는 원본을 안 건드림")
	assert(Arr.FillHoles(Arr.Of<<number?>>(), 0).n == 0, "빈 것의 FillHoles")

	-- FillHolesInplace: 제자리, 길이 불변
	const fill = Arr.Sized<<number?>>(3, nil)
	fill[2] = 7
	assert(Arr.FillHolesInplace(fill, 0) == fill, "FillHolesInplace 는 자기 자신")
	assert(fill.n == 3 and fill[1] == 0 and fill[2] == 7 and fill[3] == 0, "FillHolesInplace")

	-- ToOptionals: 길이 불변, 구멍은 Absent 싱글턴
	const opts = Arr.ToOptionals(holed)
	assert(opts.n == 5, "ToOptionals 는 길이 유지")
	assert(opts[2] == Optional.Absent and opts[4] == Optional.Absent, "구멍은 Absent")
	assert(Optional.Unwrap(opts[1]) == 10 and Optional.Unwrap(opts[5]) == 50, "값은 Present")
end
print("PASS")

print("=== 5. ⭐ 구멍을 정리하면 *Unchecked 가 안전해지는가 ===")
do
	-- 타입은 거짓말하는 쪽(`Arr<number>`)으로 둡니다 — checked 가 **런타임
	-- 그물**로 받아내는지, unchecked 가 문서대로 망가지는지를 보는 절이라서요.
	const holed = (Arr.Sized<<number?>>(5, nil) :: any) :: Arr<number>
	holed[1], holed[3], holed[5] = 3, 1, 2
	-- 정리 전: SumUnchecked 는 터지고 SortInplaceUnchecked 는 구멍에서 터지거나 checked 로 넘어간다
	assert(not pcall(function()
		return Arr.SumUnchecked(holed)
	end), "정리 전 SumUnchecked 는 터짐")

	-- FillHoles 뒤: checked 와 같은 답
	const filled = Arr.FillHoles(holed, 0)
	assert(Arr.SumUnchecked(filled) == Arr.Sum(holed), "FillHoles 뒤 SumUnchecked == Sum")
	assert(Arr.MaxUnchecked(filled) == Arr.Max(holed), "FillHoles 뒤 MaxUnchecked == Max")

	-- Compact 뒤: 정렬까지 checked 와 같은 원소 순서
	const compacted = Arr.Compact(holed)
	const viaUnchecked = Arr.SortUnchecked(compacted)
	const viaChecked = Arr.Sort(holed)
	for idx = 1, viaUnchecked.n do
		assert(viaUnchecked[idx] == viaChecked[idx], `Compact 뒤 SortUnchecked 가 [{idx}] 에서 다름`)
	end

	-- ToOptionals 뒤: 모든 칸이 차 있으므로 # 와 n 이 맞음
	const opts = Arr.ToOptionals(holed)
	assert(#opts == opts.n, "ToOptionals 뒤 # 와 n 이 같음")
end
print("PASS")

print()
print("=== ALL PASS (Optional) ===")

return true

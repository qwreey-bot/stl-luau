--!strict
--[[
	Common 과 내부 입양(Adopt) 문의 테스트.

	작은 어댑터들이라 눈으로 맞아 보이지만, **비교자는 부호 규약이 한 번
	뒤집히면 정렬 전체가 조용히 뒤집힙니다.** 그래서 세 방향을 다 봅니다.
]]
local stl = require("../src")
local Common = stl.Common
local HashMap = stl.HashMap

print("=== 1. 기본 3방향 비교자 ===")
do
	assert(Common.compareNumber(1, 2) < 0, "작으면 음수")
	assert(Common.compareNumber(2, 1) > 0, "크면 양수")
	assert(Common.compareNumber(2, 2) == 0, "같으면 0")
	assert(Common.compareString("a", "b") < 0, "문자열 작음")
	assert(Common.compareString("b", "a") > 0, "문자열 큼")
	assert(Common.compareString("a", "a") == 0, "문자열 같음")
	-- 빈 문자열과 접두사 경계
	assert(Common.compareString("", "a") < 0, "빈 문자열이 앞")
	assert(Common.compareString("ab", "abc") < 0, "접두사가 앞")
end
print("PASS")

print("=== 2. 어댑터 두 방향 ===")
do
	-- 3방향 → 불리언
	const less = Common.lessFrom(Common.compareNumber)
	assert(less(1, 2) == true, "lessFrom: 작으면 참")
	assert(less(2, 1) == false, "lessFrom: 크면 거짓")
	assert(less(2, 2) == false, "lessFrom: 같으면 거짓 (엄격한 앞섬)")
	-- 실제로 table.sort 에 넘어가야 합니다
	const list = { 3, 1, 2 }
	table.sort(list, less)
	assert(table.concat(list, ",") == "1,2,3", "lessFrom 으로 정렬")

	-- 불리언 → 3방향. **같음을 판정하려면 양방향으로 물어야 해서 호출이 2배**
	-- 라는 게 이 어댑터의 요점이므로, 정말 0 이 나오는지를 봅니다.
	local calls = 0
	const counting = function(a: number, b: number): boolean
		calls += 1
		return a < b
	end
	const compare = Common.compareFrom(counting)
	assert(compare(1, 2) < 0, "compareFrom: 작으면 음수")
	assert(compare(2, 1) > 0, "compareFrom: 크면 양수")
	assert(compare(2, 2) == 0, "compareFrom: 같으면 0")
	assert(calls == 5, `호출 횟수: 작음 1 + 큼 2 + 같음 2 = 5 이어야 하는데 {calls}`)

	-- 왕복해도 뜻이 보존돼야 합니다
	const roundTrip = Common.lessFrom(Common.compareFrom(less))
	assert(roundTrip(1, 2) == true and roundTrip(2, 2) == false, "왕복")
	-- 그리고 정렬된 구조에 실제로 꽂혀야 합니다
	const tree = stl.TreeSet.FromList({ 3, 1, 2 }, Common.compareFrom(less))
	assert(table.concat(tree:Items(), ",") == "1,2,3", "compareFrom 으로 TreeSet")
end
print("PASS")

print("=== 3. 입양(Adopt) — 얹히는 구현을 위한 문 ===")
do
	-- 복사하지 않고 크기도 검사하지 않습니다. 호출자 책임입니다.
	const raw: { [string]: number } = { a = 1, b = 2 }
	const adopted = HashMap.Adopt(raw, 2)
	assert(adopted:Len() == 2 and adopted:Get("a") == 1, "Adopt 기본")
	-- 복사하지 않는다는 계약: 원본을 건드리면 같이 보여야 합니다
	raw.c = 3
	assert(adopted:Get("c") == 3, "Adopt 는 복사하지 않습니다")
	-- 그래서 size 가 틀어질 수 있습니다 — 그게 호출자 책임이라는 뜻입니다
	assert(adopted:Len() == 2, "size 는 밖에서 넣은 원소를 모릅니다 (호출자 책임)")
	-- FromTable 은 반대로 복사합니다
	const copied = HashMap.FromTable(raw)
	raw.d = 4
	assert(copied:Get("d") == nil and copied:Len() == 3, "FromTable 은 복사")
end
print("PASS")

print()
print("=== ALL PASS (Common) ===")

return true

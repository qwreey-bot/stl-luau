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
	assert(table.concat(stl.TreeSet.Items(tree), ",") == "1,2,3", "compareFrom 으로 TreeSet")
end
print("PASS")

print("=== 3. 입양(Adopt) — 얹히는 구현을 위한 문 ===")
do
	-- 복사하지 않고 크기도 검사하지 않습니다. 호출자 책임입니다.
	const raw: { [string]: number } = { a = 1, b = 2 }
	const adopted = HashMap.Adopt(raw, 2)
	assert(stl.HashMap.Len(adopted) == 2 and stl.HashMap.Get(adopted, "a") == 1, "Adopt 기본")
	-- 복사하지 않는다는 계약: 원본을 건드리면 같이 보여야 합니다
	raw.c = 3
	assert(stl.HashMap.Get(adopted, "c") == 3, "Adopt 는 복사하지 않습니다")
	-- 그래서 size 가 틀어질 수 있습니다 — 그게 호출자 책임이라는 뜻입니다
	assert(stl.HashMap.Len(adopted) == 2, "size 는 밖에서 넣은 원소를 모릅니다 (호출자 책임)")
	-- FromTable 은 반대로 복사합니다
	const copied = HashMap.FromTable(raw)
	raw.d = 4
	assert(stl.HashMap.Get(copied, "d") == nil and stl.HashMap.Len(copied) == 3, "FromTable 은 복사")
end
print("PASS")

print("=== 에러는 사용자 줄을 가리킨다 — 최적화 수준과 무관하게 (2026-10-02) ===")
do
	-- 손으로 센 level 은 -O2 인라인에서 틀렸습니다(`NthElement` 의 NaN 이 라이브러리 줄).
	-- `Common.raise` 는 라이브러리가 아닌 첫 프레임을 찾아 걷습니다. **정확한 줄**을
	-- 단언합니다 — 파일 이름만 보면 같은 파일의 다른 줄이어도 통과합니다.
	-- check.sh 가 이 파일을 -O2 로도 돌립니다.
	const Arr = stl.Arr
	local function expectLine(label: string, needle: string, run: () -> ()): string
		const ok, err = pcall(run)
		const text = tostring(err)
		assert(not ok, `{label}: 에러가 안 남`)
		assert(string.find(text, needle, 1, true) ~= nil, `{label}: 메시지: {text}`)
		return text
	end
	-- `where = debug.info(1, "l") + 1` 로 바로 다음 줄을 "던져야 할 사용자 줄" 로 적어
	-- 둡니다. 헬퍼 함수로 빼면 -O2 에서 그 헬퍼가 인라인돼 `debug.info(2)` 가 엉뚱한
	-- 프레임을 봤습니다 — 이 테스트가 막으려는 바로 그 함정입니다.
	local where = 0
	const function atUserLine(label: string, text: string)
		assert(string.find(text, `spec.common.luau:{where}:`, 1, true) ~= nil, `{label}: {where} 줄이 아님: {text}`)
	end

	-- 1. 공개 함수가 로컬 헬퍼를 거쳐 던짐(-O2 에서 인라인되던 자리)
	atUserLine(
		"NthElement",
		expectLine("NthElement", "k is NaN", function()
			where = debug.info(1, "l") + 1
			Arr.NthElement(Arr.Of(10, 20), 0 / 0)
		end)
	)
	-- 2. 다른 모듈을 거쳐 던짐(TreeSet → TreeMap). 예전엔 TreeMap 의 줄이었습니다(백로그)
	atUserLine(
		"TreeSet.Add",
		expectLine("TreeSet.Add", "NaN", function()
			const s = stl.TreeSet.New(Common.compareNumber) :: stl.TreeSet<number>
			where = debug.info(1, "l") + 1
			stl.TreeSet.Add(s, 0 / 0)
		end)
	)
	-- 3. 콜백 안의 라이브러리 호출은 **콜백 줄**을 가리킴
	atUserLine(
		"콜백 안",
		expectLine("콜백 안", "At index is NaN", function()
			Arr.Map(Arr.Of(10, 20), function(_v: number, _i: number, _a): number
				where = debug.info(1, "l") + 1
				return Arr.At(Arr.Of(1), 0 / 0) or 0
			end)
		end)
	)
	-- 4. C 함수(table.sort) 너머의 비교자 안
	atUserLine(
		"비교자 안",
		expectLine("비교자 안", "At index is NaN", function()
			Arr.Sort(Arr.Of(3, 1, 2), function(a: number, b: number): boolean
				where = debug.info(1, "l") + 1
				Arr.At(Arr.Of(1), 0 / 0)
				return a < b
			end)
		end)
	)
	-- 5. Optional 은 Common 을 새로 require 함 — 등록이 빠지면 여기서 걸림
	atUserLine(
		"Unwrap",
		expectLine("Unwrap", "Unwrap called on Absent", function()
			where = debug.info(1, "l") + 1
			stl.Optional.Unwrap(stl.Optional.Of(nil :: number?))
		end)
	)
	-- 6. C 함수가 바로 부르면 가리킬 사용자 줄이 없음 — 메시지는 그대로, 위치 접두는 없음
	const ok, err = pcall(Arr.At, Arr.Of(1), 0 / 0)
	assert(not ok and tostring(err) == "Arr: At index is NaN", `C 프레임이 바로 부름: {err}`)
end
print("PASS")

print()
print("=== ALL PASS (Common) ===")

return true

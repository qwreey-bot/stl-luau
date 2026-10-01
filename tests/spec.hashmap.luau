--!strict
--[[
	HashMap 테스트. 프레임워크 없음 — assert + print.

	⚠️ `size` 가 표현의 핵심이므로 **모든 변형 연산마다 크기를 같이 검사**합니다.
	`data` 를 밖에서 건드리면 `size` 가 틀어진다는 계약도 같이 고정합니다.
]]
local stl = require("../src")
local HashMap = stl.HashMap

type HashMap<K, V> = stl.HashMap<K, V>

print("=== 1. 생성자와 기본 ===")
do
	const m = HashMap.New() :: HashMap<string, number>
	assert(HashMap.Len(m) == 0 and HashMap.Empty(m), "New 는 비어 있어야 합니다")
	assert(stl.isHashMap(m), "isHashMap")
	assert(not stl.isHashMap({}), "평범한 테이블은 isHashMap 이 아님")
	assert(not stl.isHashMap(nil), "nil 은 isHashMap 이 아님")

	HashMap.Set(m, "a", 1)
	assert(HashMap.Len(m) == 1, "Set 이 크기를 올려야 합니다")
	HashMap.Set(m, "a", 2)
	assert(HashMap.Len(m) == 1, "같은 키를 덮어쓰면 크기가 그대로여야 합니다")
	assert(HashMap.Get(m, "a") == 2, "덮어쓴 값")
	assert(HashMap.Get(m, "없음") == nil, "없는 키는 nil")
	assert(HashMap.Has(m, "a") and not HashMap.Has(m, "없음"), "Has")
	assert(HashMap.GetOr(m, "없음", 9) == 9, "GetOr 는 없으면 fallback")
	assert(HashMap.GetOr(m, "a", 9) == 2, "GetOr 는 있으면 그 값")
end
do
	-- ⚠️ 리터럴을 바로 넘기면 K/V 가 안 잡힙니다(아래 5절에서 따로 고정).
	const src: { [string]: number } = { a = 1, b = 2 }
	const m = HashMap.FromTable(src)
	assert(HashMap.Len(m) == 2, "FromTable 크기")
	assert(HashMap.Get(m, "b") == 2, "FromTable 값")
	-- FromTable 은 복사입니다 — 원본을 건드려도 size 가 틀어지면 안 됩니다
	const source: { [string]: number } = { a = 1 }
	const copied = HashMap.FromTable(source)
	source.b = 2
	assert(HashMap.Len(copied) == 1, "FromTable 은 복사해야 합니다")
end
print("PASS")

print("=== 2. Remove / Clear / Clone ===")
do
	const src: { [string]: number } = { a = 1, b = 2 }
	const m = HashMap.FromTable(src)
	assert(HashMap.Remove(m, "a") == 1, "Remove 는 지워진 값을 돌려줍니다")
	assert(HashMap.Len(m) == 1, "Remove 가 크기를 내려야 합니다")
	assert(HashMap.Remove(m, "a") == nil, "없는 키를 Remove 하면 nil")
	assert(HashMap.Len(m) == 1, "없는 키 Remove 는 크기를 안 건드려야 합니다")

	const cloned = HashMap.Clone(m)
	HashMap.Set(cloned, "c", 3)
	assert(HashMap.Len(m) == 1 and HashMap.Len(cloned) == 2, "Clone 은 독립적이어야 합니다")

	HashMap.Clear(m)
	assert(HashMap.Len(m) == 0 and HashMap.Empty(m), "Clear")
	assert(HashMap.Get(m, "b") == nil, "Clear 후 내용이 비어야 합니다")
	HashMap.Set(m, "z", 26)
	assert(HashMap.Len(m) == 1, "Clear 후 다시 쓸 수 있어야 합니다")
end
print("PASS")

print("=== 3. Keys / Values / Records / Iter ===")
do
	const src: { [string]: number } = { a = 1, b = 2, c = 3 }
	const m = HashMap.FromTable(src)
	assert(#HashMap.Keys(m) == 3, "Keys 개수")
	assert(#HashMap.Values(m) == 3, "Values 개수")
	assert(#HashMap.Records(m) == 3, "Records 개수")

	-- 순서는 보장하지 않으므로 합으로 확인합니다
	local keySum = ""
	for _, k in HashMap.Keys(m) do
		keySum ..= k
	end
	assert(#keySum == 3, "Keys 가 전부 나와야 합니다")
	local valueSum = 0
	for _, v in HashMap.Values(m) do
		valueSum += v
	end
	assert(valueSum == 6, "Values 합")

	local recSum = 0
	for _, rec in HashMap.Records(m) do
		assert(HashMap.Get(m, rec.key) == rec.value, "Record 의 키와 값이 맞아야 합니다")
		recSum += rec.value
	end
	assert(recSum == 6, "Records 합")

	local iterCount, iterSum = 0, 0
	for _key, value in HashMap.Iter(m) do
		iterCount += 1
		iterSum += value
	end
	assert(iterCount == 3 and iterSum == 6, "Iter")

	const emptyMap = HashMap.New() :: HashMap<string, number>
	local emptyCount = 0
	for _k, _v in HashMap.Iter(emptyMap) do
		emptyCount += 1
	end
	assert(emptyCount == 0, "빈 맵의 Iter 는 한 번도 안 돌아야 합니다")

	-- Records 의 역연산
	const rebuilt = HashMap.FromRecords(HashMap.Records(m))
	assert(HashMap.Len(rebuilt) == 3 and HashMap.Get(rebuilt, "b") == 2, "FromRecords")
	-- 중복 키가 있어도 크기가 부풀지 않아야 합니다
	const dup = HashMap.FromRecords({
		{ key = "x", value = 1 },
		{ key = "x", value = 2 },
	})
	assert(HashMap.Len(dup) == 1 and HashMap.Get(dup, "x") == 2, "FromRecords 중복 키")
end
print("PASS")

print("=== 4. 계약 (MapCore) 과 공용 알고리즘 ===")
do
	const src: { [string]: number } = { a = 1, b = 2 }
	const m = HashMap.FromTable(src)
	-- 구현을 모르는 공용 알고리즘이 계약만으로 동작해야 합니다
	assert(#stl.Algorithm.Keys<<HashMap<string, number>, string, number>>(HashMap, m) == 2, "Algorithm.Keys")
	assert(#stl.Algorithm.Values<<HashMap<string, number>, string, number>>(HashMap, m) == 2, "Algorithm.Values")
end
print("PASS")

print("=== 5. 길이 필드를 덮어쓰는 사고가 안 나는가 ===")
do
	-- ⭐ 래퍼를 쓰는 이유 그 자체입니다. 인스턴스에 size 를 직접 뒀다면
	-- 아래 Set 이 길이 필드를 날렸을 것입니다.
	const m = HashMap.New() :: HashMap<string, number>
	HashMap.Set(m, "size", 999)
	HashMap.Set(m, "data", 111)
	assert(HashMap.Len(m) == 2, `길이 필드가 덮어써졌습니다: {HashMap.Len(m)}`)
	assert(
		HashMap.Get(m, "size") == 999 and HashMap.Get(m, "data") == 111,
		"키로서의 size/data 가 살아 있어야 합니다"
	)
end
print("PASS")

print("=== 6. 테이블 리터럴 함정이 문서대로인가 ===")
do
	-- ⚠️ 런타임은 멀쩡합니다. 문제는 **타입**입니다 — 리터럴을 바로 넘기면
	-- HashMap<unknown, unknown> 이 되고, 그게 조용합니다. 런타임 동작이
	-- 같다는 것만 여기서 고정하고, 타입 쪽은 음성 대조군 스파이크가 봅니다.
	const viaLiteral = HashMap.FromTable({ a = 1 } :: { [string]: number })
	assert(HashMap.Len(viaLiteral) == 1 and HashMap.Get(viaLiteral, "a") == 1, "캐스트하면 정상")
end
print("PASS")

print("=== 7. 회귀 — 2026-09-30 리뷰 ===")
do
	-- (3) Set(k, nil) 은 삭제 — 크기가 틀어지면 안 됨
	const m = HashMap.New<<string, number?>>()
	HashMap.Set(m, "a", nil)
	assert(HashMap.Len(m) == 0 and HashMap.Empty(m), `없는 키에 nil: {HashMap.Len(m)}`)
	HashMap.Set(m, "b", 1)
	HashMap.Set(m, "b", nil)
	assert(HashMap.Len(m) == 0 and not HashMap.Has(m, "b"), `있던 키에 nil 은 삭제: {HashMap.Len(m)}`)
	assert(#HashMap.Records(m) == HashMap.Len(m), "Records 개수와 Len 이 같음")

	const fr = HashMap.FromRecords<<string, number?>>({
		{ key = "x", value = 1 },
		{ key = "x", value = nil },
		{ key = "y", value = nil },
	})
	assert(HashMap.Len(fr) == 0, `FromRecords 의 nil 값: {HashMap.Len(fr)}`)

	-- (4) Set 이 실패하면 크기도 그대로
	const f = HashMap.New<<number, number>>()
	assert(not pcall(function()
		HashMap.Set(f, 0 / 0, 1)
	end), "NaN 키는 Lua 가 거절")
	assert(HashMap.Len(f) == 0, `실패한 Set 뒤 크기: {HashMap.Len(f)}`)
end
print("PASS")

print()
print("=== ALL PASS (HashMap) ===")

return true

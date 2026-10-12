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

	-- 자기 자신을 돌려줌(2026-10-12, 질문 AM — 일곱 컨테이너가 같게)
	assert(HashMap.Clear(m) == m, "Clear 는 자기 자신을 돌려줌")
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
	-- ⭐ Iter 는 **테이블 하나**를 돌려줌(2026-10-12 사용자 결정, 질문 AP 1 — Luau 가 직접 돌아 빠름).
	-- 함수가 아니니 손으로 걸으려면 `next`, 삼중항은 `pairs` 로 — 반환이 읽기 전용 타입이라 캐스트가 듦
	-- (내장 `next`/`pairs` 가 읽기·쓰기 테이블을 요구).
	do
		const iterable, extra = (HashMap.Iter :: any)(m)
		assert(type(iterable) == "table" and extra == nil, "Iter 는 테이블 하나")
		-- **같은 테이블**(사본이 아님 — 사본이면 순회마다 O(n) 할당, 2라운드 리뷰)
		assert(rawequal(HashMap.Iter(m), HashMap.Iter(m)) and rawequal(iterable, m.data), "안쪽 테이블 그대로")
		local seen = 0
		const raw = HashMap.Iter(m) :: any
		local key, value = next(raw)
		while key ~= nil do
			assert(HashMap.Get(m, key) == value, "손으로 걸은 값")
			seen += 1
			key, value = next(raw, key)
		end
		assert(seen == HashMap.Len(m), `손으로 걸은 개수: {seen}`)
		local viaPairs = 0
		for pairKey, pairValue in pairs(raw) do
			assert(HashMap.Get(m, pairKey) == pairValue, "pairs 로 돈 값")
			viaPairs += 1
		end
		assert(viaPairs == HashMap.Len(m), "pairs(HashMap.Iter)")
		const viaFromIter = stl.Arr.FromIter<<number>>(HashMap.Iter(m))
		assert(viaFromIter.n == HashMap.Len(m), "FromIter(HashMap.Iter) 는 값을 모음")
		assert(stl.Arr.Sum(viaFromIter) == 6, "FromIter 가 모은 값의 합")
		-- 도는 동안 있는 키의 값을 Set 으로 바꾸는 것은 됨(새 키를 넣는 것은 UB)
		const doubling = HashMap.FromTable<<string, number>>({ p = 10, q = 20, r = 30 })
		for dKey, dValue in HashMap.Iter(doubling) do
			HashMap.Set(doubling, dKey, dValue * 2)
		end
		assert(HashMap.Get(doubling, "p") == 20 and HashMap.Get(doubling, "r") == 60, "순회 중 값 덮어쓰기")
		assert(HashMap.Len(doubling) == 3, "덮어쓰기는 크기를 안 바꿈")
		-- 숫자 키가 섞여도(배열 부분·해시 부분) 한 번씩
		const mixed = HashMap.New<<number | string, number>>()
		for i = 1, 5 do
			HashMap.Set(mixed, i, i * 100)
		end
		HashMap.Set(mixed, "x", 7)
		HashMap.Set(mixed, 1000, 8)
		local mixedCount, mixedSum = 0, 0
		for _, mValue in HashMap.Iter(mixed) do
			mixedCount += 1
			mixedSum += mValue
		end
		assert(mixedCount == 7 and mixedSum == 1515, `섞인 키: {mixedCount}, {mixedSum}`)
	end
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
	assert(#stl.Algorithm.Keys(m) == 2, "Algorithm.Keys")
	assert(#stl.Algorithm.Values(m) == 2, "Algorithm.Values")
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

print("=== M4. 넣거나 합치기 / Retain (2026-10-07) ===")
do
	-- 크기를 모든 변형마다 같이 봅니다(이 스펙의 규칙)
	local function size(m: HashMap<string, number>, expected: number, label: string)
		local counted = 0
		for _ in m.data do
			counted += 1
		end
		assert(
			HashMap.Len(m) == expected and counted == expected,
			`{label}: size={HashMap.Len(m)} 실제={counted} 기대={expected}`
		)
	end

	-- GetOrInsert: 있으면 그 값(안 바꿈), 없으면 넣고 돌려줌, nil 기본값은 안 넣음
	const m = HashMap.FromTable<<string, number>>({ a = 10 })
	assert(HashMap.GetOrInsert(m, "a", 99) == 10, "있으면 그 값")
	size(m, 1, "있으면 그대로")
	assert(HashMap.GetOrInsert(m, "b", 20) == 20 and HashMap.Get(m, "b") == 20, "없으면 넣음")
	size(m, 2, "넣으면 크기 +1")
	assert(HashMap.GetOrInsert(m, "c", nil :: any) == nil, "nil 기본값")
	size(m, 2, "nil 은 안 넣음")
	assert(not pcall(HashMap.GetOrInsert, HashMap.New<<number, number>>(), 0 / 0, 1), "NaN 키는 Lua 가 거절")

	-- GetOrInsertWith: 없을 때만 make, make 는 키를 받음
	local made = 0
	const make = function(key: string): number
		made += 1
		return #key * 100
	end
	assert(HashMap.GetOrInsertWith(m, "a", make) == 10 and made == 0, "있으면 make 안 부름")
	assert(HashMap.GetOrInsertWith(m, "dddd", make) == 400 and made == 1, "없으면 make(key)")
	size(m, 3, "GetOrInsertWith 크기")
	assert(HashMap.GetOrInsertWith(m, "e", function(_k: string): number
		return nil :: any
	end) == nil, "make 가 nil")
	size(m, 3, "make 가 nil 이면 안 넣음")
	-- make 가 같은 키를 넣어도 크기를 두 번 세지 않음(재귀 메모이즈)
	const memo = HashMap.New<<string, number>>()
	const v = HashMap.GetOrInsertWith(memo, "k", function(key: string): number
		HashMap.Set(memo, key, 1)
		return 2
	end)
	assert(v == 2 and HashMap.Get(memo, "k") == 2, "make 의 반환이 이김")
	size(memo, 1, "make 안의 같은 키")
	-- make 가 같은 키를 넣고 nil 을 돌려주면 맵에 있는 값(2라운드 — 이 경우의 단언이 없었음)
	const memoNil = HashMap.New<<string, number>>()
	assert(HashMap.GetOrInsertWith(memoNil, "k", function(key: string): number
		HashMap.Set(memoNil, key, 5)
		return nil :: any
	end) == 5, "make 가 넣고 nil")
	size(memoNil, 1, "make 가 넣고 nil 의 크기")
	-- 재귀 메모이즈(피보나치) — 다른 키를 넣는 make
	const fibMemo = HashMap.New<<number, number>>()
	local function fib(n: number): number
		if n <= 2 then
			return 1
		end
		return HashMap.GetOrInsertWith(fibMemo, n, function(k: number): number
			return fib(k - 1) + fib(k - 2)
		end)
	end
	assert(fib(30) == 832040 and HashMap.Len(fibMemo) == 28, `fib 메모 크기 {HashMap.Len(fibMemo)}`)

	-- Accumulate: 없으면 value, 있으면 combine(old, value), nil 이면 지움
	const words = HashMap.New<<string, number>>()
	const add = function(old: number, value: number): number
		return old + value
	end
	for _, w in { "x", "y", "x", "x" } do
		HashMap.Accumulate(words, w, 1, add)
	end
	assert(HashMap.Get(words, "x") == 3 and HashMap.Get(words, "y") == 1, "단어 세기")
	size(words, 2, "Accumulate 크기")
	local args = ""
	assert(HashMap.Accumulate(words, "x", 10, function(old: number, value: number): number
		args = `{old},{value}`
		return old * value
	end) == 30, "바뀐 값을 돌려줌")
	assert(args == "3,10", `combine 인자 순서: {args}`)
	assert(HashMap.Accumulate(words, "x", 1, function(_o: number, _v: number): number
		return nil :: any
	end) == nil and not HashMap.Has(words, "x"), "combine 이 nil 이면 지움")
	size(words, 1, "지운 뒤 크기")
	assert(HashMap.Accumulate(words, "z", nil :: any, add) == nil, "없는데 value 가 nil")
	size(words, 1, "nil value 는 안 넣음")

	-- Merge: 새 맵, other 가 이김, 둘 다 그대로
	const left = HashMap.FromTable<<string, number>>({ a = 1, b = 2 })
	const right = HashMap.FromTable<<string, number>>({ b = 20, c = 30 })
	const merged = HashMap.Merge(left, right)
	assert(stl.isHashMap(merged) and merged ~= left and merged.data ~= left.data, "새 맵")
	assert(
		HashMap.Get(merged, "a") == 1 and HashMap.Get(merged, "b") == 20 and HashMap.Get(merged, "c") == 30,
		"other 가 이김"
	)
	size(merged, 3, "Merge 크기")
	size(left, 2, "left 그대로")
	size(right, 2, "right 그대로")
	assert(HashMap.Get(left, "b") == 2, "left 값 그대로")
	size(HashMap.Merge(left, left), 2, "자기 자신과 Merge")
	size(HashMap.Merge(HashMap.New<<string, number>>(), right), 2, "빈 것과")
	-- MergeInplace
	assert(HashMap.MergeInplace(left, right) == left, "MergeInplace 는 자기 자신을 돌려줌")
	assert(HashMap.Get(left, "b") == 20 and HashMap.Get(left, "c") == 30, "MergeInplace 덮어씀")
	size(left, 3, "MergeInplace 크기")
	HashMap.MergeInplace(left, left)
	size(left, 3, "자기 자신과 MergeInplace")
	HashMap.MergeInplace(left, HashMap.New<<string, number>>())
	size(left, 3, "빈 것과 MergeInplace")

	-- Retain: (key, value), 크기
	const r = HashMap.FromTable<<string, number>>({ a = 10, b = 25, c = 30, d = 45 })
	local seenPairs = 0
	HashMap.Retain(r, function(key: string, value: number): boolean
		seenPairs += 1
		assert(HashMap.Get(r, key) == value or HashMap.Get(r, key) == nil, "키·값 짝")
		return value % 10 == 0
	end)
	assert(seenPairs == 4, "모두 한 번씩")
	assert(
		HashMap.Has(r, "a") and HashMap.Has(r, "c") and not HashMap.Has(r, "b") and not HashMap.Has(r, "d"),
		"Retain"
	)
	size(r, 2, "Retain 크기")
	-- 자기 자신을 돌려줌(2026-10-12 — `Arr.Retain` 과 같게, 질문 AM)
	const retained = HashMap.Retain(r, function(_k: string, _v: number): boolean
		return false
	end)
	assert(retained == r, "Retain 은 자기 자신을 돌려줌")
	size(r, 0, "전부 지움")
	HashMap.Retain(r, function(_k: string, _v: number): boolean
		return true
	end)
	size(r, 0, "빈 맵 Retain")

	-- **관측 — 계약 아님**(콜백 안에서 같은 맵을 바꾸는 것은 정의되지 않은 동작, 질문 AL 1): 지금 판은
	-- 콜백이 지워도 크기가 맞습니다(M4 리뷰 1라운드 — 현재 키를 Remove 하고 false 면 두 번 세서
	-- Len 0·실제 2 였음). 구현을 바꿔 이 절이 깨지면 테스트를 고치면 됩니다.
	const cache = HashMap.FromTable<<string, number>>({ a = 1, b = 2, c = 3, d = 4 })
	HashMap.Retain(cache, function(key: string, value: number): boolean
		if value % 2 == 0 then
			HashMap.Remove(cache, key) -- evict 같은 정리 함수가 지우고 false
			return false
		end
		return true
	end)
	size(cache, 2, "콜백이 현재 키를 지움")
	assert(HashMap.Has(cache, "a") and HashMap.Has(cache, "c"), "남은 것")
	-- 아직 안 본 다른 키를 지움(그 키는 콜백에 안 올 수도 있음 — 크기만 맞으면 됨)
	const other = HashMap.FromTable<<string, number>>({ a = 1, b = 2, c = 3, d = 4 })
	HashMap.Retain(other, function(key: string, _value: number): boolean
		if key == "a" or key == "b" then
			HashMap.Remove(other, if key == "a" then "b" else "a")
		end
		return key ~= "c"
	end)
	local remaining = 0
	for _ in other.data do
		remaining += 1
	end
	size(other, remaining, "콜백이 다른 키를 지움")
	assert(not HashMap.Has(other, "c") and HashMap.Has(other, "d"), "술어대로")
end
print("PASS")

print()
print("=== ALL PASS (HashMap) ===")

return true

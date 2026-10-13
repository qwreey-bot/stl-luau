--!strict
--[[
	FlatMap 테스트.

	⭐ 이 컨테이너의 존재 이유가 **순서 보장**이므로, 모든 조회 계열이 정말
	정렬 순서로 나오는지를 매번 봅니다. 그리고 정렬 배열 백엔드라 삽입/삭제가
	뒤를 미는 연산이므로 **맨 앞 / 중간 / 맨 뒤** 를 따로 봅니다.
]]
local stl = require("../src")
local FlatMap = stl.FlatMap
local Common = stl.Common

type FlatMap<K, V> = stl.FlatMap<K, V>

const function keysOf<V>(m: FlatMap<number, V>): string
	return table.concat(FlatMap.Keys(m), ",")
end

print("=== 1. 정렬 순서로 담기는가 ===")
do
	const m = FlatMap.New(Common.compareNumber) :: FlatMap<number, string>
	assert(FlatMap.Empty(m) and FlatMap.Len(m) == 0, "New 는 비어 있어야 합니다")
	assert(stl.isFlatMap(m), "isFlatMap")
	assert(not stl.isFlatMap({}), "평범한 테이블은 isFlatMap 이 아님")

	FlatMap.Set(m, 3, "c")
	FlatMap.Set(m, 1, "a")
	FlatMap.Set(m, 2, "b")
	assert(keysOf(m) == "1,2,3", `정렬 순서가 아님: {keysOf(m)}`)
	assert(table.concat(FlatMap.Values(m), ",") == "a,b,c", "값도 키 순서를 따라야 합니다")
	assert(FlatMap.Len(m) == 3, "크기")

	-- 맨 앞 / 중간 / 맨 뒤 삽입
	FlatMap.Set(m, 0, "z")
	assert(keysOf(m) == "0,1,2,3", "맨 앞 삽입")
	FlatMap.Set(m, 5, "e")
	assert(keysOf(m) == "0,1,2,3,5", "맨 뒤 삽입")
	FlatMap.Set(m, 4, "d")
	assert(keysOf(m) == "0,1,2,3,4,5", "중간 삽입")

	-- 덮어쓰기는 크기를 안 올려야 합니다
	FlatMap.Set(m, 2, "B")
	assert(FlatMap.Len(m) == 6 and FlatMap.Get(m, 2) == "B", "덮어쓰기")
	assert(keysOf(m) == "0,1,2,3,4,5", "덮어쓰기는 순서를 안 건드려야 합니다")
end
print("PASS")

print("=== 2. 조회 ===")
do
	const m = FlatMap.FromRecords({
		{ key = 2, value = "b" },
		{ key = 1, value = "a" },
		{ key = 3, value = "c" },
	}, Common.compareNumber)
	assert(keysOf(m) == "1,2,3", "FromRecords 가 정렬해야 합니다")
	assert(FlatMap.Get(m, 2) == "b" and FlatMap.Get(m, 9) == nil, "Get")
	assert(FlatMap.Has(m, 1) and not FlatMap.Has(m, 9), "Has")
	assert(FlatMap.GetOr(m, 9, "기본") == "기본" and FlatMap.GetOr(m, 1, "기본") == "a", "GetOr")
	assert(#FlatMap.Records(m) == 3 and FlatMap.Records(m)[1].key == 1, "Records 는 정렬 순서")
	-- Records 는 복사여야 합니다 — 받은 쪽이 건드려도 내부가 안 깨져야 합니다
	const snapshot = FlatMap.Records(m)
	table.remove(snapshot)
	assert(FlatMap.Len(m) == 3, "Records 는 복사를 돌려줘야 합니다")

	local iterKeys = ""
	for key, _value in FlatMap.Iter(m) do
		iterKeys ..= tostring(key)
	end
	assert(iterKeys == "123", `Iter 가 정렬 순서가 아님: {iterKeys}`)
	const emptyMap = FlatMap.New(Common.compareNumber) :: FlatMap<number, string>
	local emptyCount = 0
	for _k, _v in FlatMap.Iter(emptyMap) do
		emptyCount += 1
	end
	assert(emptyCount == 0, "빈 맵의 Iter")
end
print("PASS")

print("=== 3. 중복 키는 뒤엣것이 이기는가 ===")
do
	-- table.sort 가 안정 정렬이 아니라 원래 위치를 타이브레이커로 씁니다.
	-- 이게 없으면 어느 쪽이 이길지 정해지지 않습니다.
	const m = FlatMap.FromRecords({
		{ key = 1, value = "처음" },
		{ key = 1, value = "중간" },
		{ key = 1, value = "마지막" },
	}, Common.compareNumber)
	assert(FlatMap.Len(m) == 1, "중복 키는 하나로 접혀야 합니다")
	assert(FlatMap.Get(m, 1) == "마지막", `뒤엣것이 이겨야 합니다: {tostring(FlatMap.Get(m, 1))}`)
	assert(FlatMap.Len(FlatMap.FromRecords({}, Common.compareNumber)) == 0, "빈 입력")
end
print("PASS")

print("=== 4. 정렬이 있어야만 되는 것들 ===")
do
	const m = FlatMap.FromRecords({
		{ key = 10, value = "a" },
		{ key = 20, value = "b" },
		{ key = 30, value = "c" },
	}, Common.compareNumber)
	assert((FlatMap.First(m) :: any).key == 10, "First")
	assert((FlatMap.Last(m) :: any).key == 30, "Last")

	assert(FlatMap.FloorKey(m, 20) == 20, "FloorKey 는 같은 값을 포함")
	assert(FlatMap.FloorKey(m, 25) == 20, "FloorKey 사이 값")
	assert(FlatMap.FloorKey(m, 30) == 30, "FloorKey 맨 뒤")
	assert(FlatMap.FloorKey(m, 5) == nil, "FloorKey 전부보다 작으면 nil")
	assert(FlatMap.FloorKey(m, 99) == 30, "FloorKey 전부보다 크면 마지막")

	assert(FlatMap.CeilingKey(m, 20) == 20, "CeilingKey 는 같은 값을 포함")
	assert(FlatMap.CeilingKey(m, 15) == 20, "CeilingKey 사이 값")
	assert(FlatMap.CeilingKey(m, 10) == 10, "CeilingKey 맨 앞")
	assert(FlatMap.CeilingKey(m, 99) == nil, "CeilingKey 전부보다 크면 nil")
	assert(FlatMap.CeilingKey(m, 5) == 10, "CeilingKey 전부보다 작으면 첫째")

	assert(#FlatMap.RangeRecords(m, 10, 20) == 2, "RangeRecords 양끝 포함")
	assert(#FlatMap.RangeRecords(m, 15, 25) == 1, "RangeRecords 사이")
	assert(#FlatMap.RangeRecords(m, 1, 99) == 3, "RangeRecords 전체")
	assert(#FlatMap.RangeRecords(m, 25, 15) == 0, "RangeRecords 뒤집히면 빈 것")
	assert(#FlatMap.RangeRecords(m, 40, 50) == 0, "RangeRecords 범위 밖")

	const empty = FlatMap.New(Common.compareNumber) :: FlatMap<number, string>
	assert(FlatMap.First(empty) == nil and FlatMap.Last(empty) == nil, "빈 맵의 First/Last")
	assert(FlatMap.FloorKey(empty, 1) == nil and FlatMap.CeilingKey(empty, 1) == nil, "빈 맵의 Floor/Ceiling")
end
print("PASS")

print("=== 5. Remove / Clear / Clone ===")
do
	const m = FlatMap.FromRecords({
		{ key = 1, value = "a" },
		{ key = 2, value = "b" },
		{ key = 3, value = "c" },
	}, Common.compareNumber)
	assert(FlatMap.Remove(m, 2) == "b", "Remove 는 지워진 값을 돌려줍니다")
	assert(keysOf(m) == "1,3", "Remove 후 순서가 유지돼야 합니다")
	assert(FlatMap.Remove(m, 2) == nil and FlatMap.Len(m) == 2, "없는 키 Remove")
	assert(FlatMap.Remove(m, 1) == "a" and keysOf(m) == "3", "맨 앞 Remove")
	assert(FlatMap.Remove(m, 3) == "c" and FlatMap.Empty(m), "마지막 Remove")

	FlatMap.Set(m, 7, "g")
	const cloned = FlatMap.Clone(m)
	FlatMap.Set(cloned, 8, "h")
	FlatMap.Set(cloned, 7, "바뀜")
	assert(FlatMap.Len(m) == 1 and FlatMap.Len(cloned) == 2, "Clone 은 독립적이어야 합니다")
	assert(FlatMap.Get(m, 7) == "g", "Clone 은 레코드도 새로 만들어야 합니다")

	-- 자기 자신을 돌려줌(2026-10-12, 질문 AM — 일곱 컨테이너가 같게)
	assert(FlatMap.Clear(m) == m, "Clear 는 자기 자신을 돌려줌")
	assert(FlatMap.Empty(m) and FlatMap.Get(m, 7) == nil, "Clear")
	FlatMap.Set(m, 1, "다시")
	assert(FlatMap.Len(m) == 1, "Clear 후 다시 쓸 수 있어야 합니다")
end
print("PASS")

print("=== 6. 문자열 키와 계약 ===")
do
	const m = FlatMap.FromRecords({
		{ key = "b", value = 2 },
		{ key = "a", value = 1 },
	}, Common.compareString)
	assert(table.concat(FlatMap.Keys(m), ",") == "a,b", "문자열 비교자")
	-- 구현을 모르는 공용 알고리즘이 계약만으로 동작해야 합니다
	assert(#stl.Map.Keys(m) == 2, "Map.Keys")
	assert(#stl.Map.Values(m) == 2, "Map.Values")
end
print("PASS")

print("=== 7. 회귀 — 2026-09-30 리뷰 ===")
do
	-- (1) 무한대 키: compareNumber 가 a - b 이던 시절 inf - inf = NaN 이라 망가졌음
	const inf = FlatMap.New<<number, string>>(Common.compareNumber)
	FlatMap.Set(inf, math.huge, "a")
	FlatMap.Set(inf, math.huge, "b")
	FlatMap.Set(inf, -math.huge, "m")
	FlatMap.Set(inf, 1, "x")
	assert(FlatMap.Len(inf) == 3, `무한대 키가 중복됨: {FlatMap.Len(inf)}`)
	assert(FlatMap.Get(inf, math.huge) == "b" and FlatMap.Get(inf, -math.huge) == "m", "무한대 키 조회")
	assert(FlatMap.Remove(inf, math.huge) == "b" and FlatMap.Len(inf) == 2, "무한대 키 삭제")

	-- (2) NaN 키는 시끄럽게 거절 — 조용히 넣으면 다른 키까지 망가졌음
	const n = FlatMap.New<<number, string>>(Common.compareNumber)
	FlatMap.Set(n, 1, "one")
	assert(not pcall(function()
		FlatMap.Set(n, 0 / 0, "nan")
	end), "NaN 키는 에러")
	assert(FlatMap.Len(n) == 1 and FlatMap.Get(n, 1) == "one", "거절 뒤에도 멀쩡")
	assert(FlatMap.Get(n, 0 / 0) == nil and not FlatMap.Has(n, 0 / 0), "NaN 으로 조회하면 없음")
	assert(FlatMap.Remove(n, 0 / 0) == nil and FlatMap.Len(n) == 1, "NaN 으로 삭제해도 아무 일 없음")
	assert(not pcall(function()
		FlatMap.FromRecords({ { key = 0 / 0, value = 1 } }, Common.compareNumber)
	end), "FromRecords 도 NaN 을 거절")

	-- (3) Set(k, nil) 은 삭제 — Lua 의 t[k] = nil 과 같음. HashMap 과 같은 규칙
	const z = FlatMap.New<<number, string?>>(Common.compareNumber)
	FlatMap.Set(z, 1, "a")
	FlatMap.Set(z, 1, nil)
	assert(FlatMap.Len(z) == 0 and not FlatMap.Has(z, 1), "Set(k, nil) 은 삭제")
	FlatMap.Set(z, 2, nil)
	assert(FlatMap.Len(z) == 0, "없는 키에 nil 은 아무 일 없음")

	-- Iter 가 키를 인덱스로 쓰던 버그 — 키가 1,2,3 이 아니면 드러남
	const far = FlatMap.New<<number, string>>(Common.compareNumber)
	FlatMap.Set(far, 10, "a")
	FlatMap.Set(far, 20, "b")
	FlatMap.Set(far, 30, "c")
	local joined = ""
	for key, value in FlatMap.Iter(far) do
		joined ..= `{key}={value},`
	end
	assert(joined == "10=a,20=b,30=c,", `키 10/20/30 의 Iter: {joined}`)
	const words = FlatMap.New<<string, number>>(Common.compareString)
	FlatMap.Set(words, "y", 2)
	FlatMap.Set(words, "x", 1)
	local order = ""
	for key in FlatMap.Iter(words) do
		order ..= key
	end
	assert(order == "xy", `문자열 키의 Iter: {order}`)

	-- (6) 내준 레코드를 고쳐도 맵은 멀쩡 — 레코드까지 복사본
	const r = FlatMap.New<<number, string>>(Common.compareNumber)
	FlatMap.Set(r, 1, "a")
	FlatMap.Set(r, 2, "b")
	FlatMap.Set(r, 3, "c")
	FlatMap.Records(r)[1].key = 99
	const firstRec: any = FlatMap.First(r)
	firstRec.key = 50
	FlatMap.RangeRecords(r, 2, 3)[1].value = "Z"
	const lastRec: any = FlatMap.Last(r)
	lastRec.value = "X"
	assert(
		FlatMap.Get(r, 1) == "a" and FlatMap.Get(r, 2) == "b" and FlatMap.Get(r, 3) == "c",
		"레코드를 고쳐도 맵은 그대로"
	)
	assert(FlatMap.Len(r) == 3, "크기도 그대로")
end
print("PASS")

print("=== M4. LowerKey / HigherKey / PopFirst / PopLast / Retain (2026-10-07) ===")
do
	const m = FlatMap.FromRecords({
		{ key = 30, value = "c" },
		{ key = 10, value = "a" },
		{ key = 20, value = "b" },
	}, Common.compareNumber)
	-- 엄격: 같은 키는 안 줌(Floor/Ceiling 과 다름)
	assert(FlatMap.LowerKey(m, 20) == 10 and FlatMap.FloorKey(m, 20) == 20, "LowerKey 엄격")
	assert(FlatMap.HigherKey(m, 20) == 30 and FlatMap.CeilingKey(m, 20) == 20, "HigherKey 엄격")
	assert(FlatMap.LowerKey(m, 25) == 20 and FlatMap.HigherKey(m, 25) == 30, "사이 값")
	assert(FlatMap.LowerKey(m, 10) == nil and FlatMap.HigherKey(m, 30) == nil, "양끝 밖")
	assert(FlatMap.LowerKey(m, 5) == nil and FlatMap.HigherKey(m, 5) == 10, "맨 앞보다 작음")
	assert(FlatMap.LowerKey(m, 99) == 30 and FlatMap.HigherKey(m, 99) == nil, "맨 뒤보다 큼")
	assert(FlatMap.LowerKey(m, 0 / 0) == nil and FlatMap.HigherKey(m, 0 / 0) == nil, "NaN 은 없음")
	const e = FlatMap.New<<number, string>>(Common.compareNumber)
	assert(FlatMap.LowerKey(e, 1) == nil and FlatMap.HigherKey(e, 1) == nil, "빈 맵")

	-- PopFirst / PopLast: 꺼낸 쌍, 크기, 나머지 순서
	const first = FlatMap.PopFirst(m)
	assert(first ~= nil and first.key == 10 and first.value == "a", "PopFirst")
	assert(FlatMap.Len(m) == 2 and keysOf(m) == "20,30", `PopFirst 뒤 {keysOf(m)}`)
	assert(rawget(m.records :: any, 3) == nil, "꼬리 칸 비움")
	const last = FlatMap.PopLast(m)
	assert(last ~= nil and last.key == 30 and last.value == "c", "PopLast")
	assert(FlatMap.Len(m) == 1 and keysOf(m) == "20", "PopLast 뒤")
	assert(rawget(m.records :: any, 2) == nil, "PopLast 꼬리")
	-- 꺼낸 레코드를 고쳐도 맵은 그대로
	last.key = 1
	assert(FlatMap.Get(m, 20) == "b" and FlatMap.Has(m, 1) == false, "꺼낸 레코드는 맵과 무관")
	const only = FlatMap.PopLast(m)
	assert(only ~= nil and only.key == 20 and FlatMap.Empty(m), "마지막 하나")
	assert(FlatMap.PopFirst(m) == nil and FlatMap.PopLast(m) == nil and FlatMap.Len(m) == 0, "빈 Pop")
	-- 꺼낸 뒤에도 정상 동작
	FlatMap.Set(m, 50, "e")
	FlatMap.Set(m, 40, "d")
	assert(keysOf(m) == "40,50" and FlatMap.Get(m, 40) == "d", "꺼낸 뒤 Set")

	-- Retain: 정렬 순서로 부름, (key, value), 남은 것 정렬 유지
	const r = FlatMap.FromRecords({
		{ key = 40, value = "d" },
		{ key = 10, value = "a" },
		{ key = 30, value = "c" },
		{ key = 20, value = "b" },
	}, Common.compareNumber)
	local order = {}
	FlatMap.Retain(r, function(key: number, value: string): boolean
		table.insert(order, `{key}{value}`)
		return key ~= 20 and key ~= 40
	end)
	assert(table.concat(order, ",") == "10a,20b,30c,40d", `Retain 순서 {table.concat(order, ",")}`)
	assert(keysOf(r) == "10,30" and FlatMap.Len(r) == 2, "Retain")
	assert(rawget(r.records :: any, 3) == nil and rawget(r.records :: any, 4) == nil, "Retain 꼬리")
	assert(FlatMap.Get(r, 30) == "c" and FlatMap.Get(r, 20) == nil, "Retain 뒤 조회")
	FlatMap.Set(r, 20, "B")
	assert(keysOf(r) == "10,20,30", "Retain 뒤 삽입 위치")
	const retained = FlatMap.Retain(r, function(_k: number, _v: string): boolean
		return false
	end)
	assert(retained == r, "Retain 은 자기 자신을 돌려줌")
	assert(FlatMap.Empty(r) and rawget(r.records :: any, 1) == nil, "전부 지움")

	-- 콜백 안에서 이 맵에 넣거나 지우는 것은 **정의되지 않은 동작**(2026-10-12 사용자 결정, 질문 AL 1 —
	-- 검사 없음)이라 테스트하지 않습니다. 아래 값만 덮어쓰기(구조를 안 바꿈)가 되는 것도 **관측**입니다.
	const overwrite = FlatMap.FromRecords({ { key = 10, value = "a" } }, Common.compareNumber)
	FlatMap.Retain(overwrite, function(key: number, _v: string): boolean
		FlatMap.Set(overwrite, key, "A")
		return true
	end)
	assert(FlatMap.Get(overwrite, 10) == "A", "값 덮어쓰기")

	-- NaN 은 없음 — 빼기 비교자에서도(1라운드: compareNumber 는 NaN 에 0 이라 가드를 지워도 통과했음,
	-- `a - b` 는 NaN 을 돌려 탐색이 엉뚱한 키를 줌)
	const sub = FlatMap.FromRecords(
		{ { key = 10, value = "a" }, { key = 20, value = "b" } },
		function(a: number, b: number): number
			return a - b
		end
	)
	const nan = 0 / 0
	assert(FlatMap.LowerKey(sub, nan) == nil and FlatMap.HigherKey(sub, nan) == nil, "Lower/Higher NaN")
	assert(FlatMap.FloorKey(sub, nan) == nil and FlatMap.CeilingKey(sub, nan) == nil, "Floor/Ceiling NaN")
	assert(FlatMap.Get(sub, nan) == nil and not FlatMap.Has(sub, nan) and FlatMap.Remove(sub, nan) == nil, "조회 NaN")
	assert(#FlatMap.RangeRecords(sub, nan, 20) == 0 and #FlatMap.RangeRecords(sub, 10, nan) == 0, "구간 NaN")
	assert(FlatMap.Len(sub) == 2, "NaN 조회는 안 바꿈")
end
print("PASS")

print("=== 8. nil 키는 NaN 과 같은 태도 — 넣기는 에러, 조회·삭제는 없음 (2026-10-12) ===")
do
	-- 재현: 빈 맵에서는 비교가 한 번도 안 일어나 `Set(m, nil, v)` 가 조용히 들어갔고, 그 뒤 모든
	-- 연산이 비교자 안(라이브러리 줄)에서 `attempt to compare nil < number` 로 죽었습니다. 타입으로는
	-- 못 넣지만(`K` 가 `number`) 타입 없는 데이터(`t.id` 가 런타임에 nil)로는 들어옵니다.
	const nilKey = nil :: any
	const empty = FlatMap.New<<number, string>>(Common.compareNumber)
	const okEmpty, errEmpty = pcall(function()
		FlatMap.Set(empty, nilKey, "boom")
	end)
	assert(
		not okEmpty and string.find(tostring(errEmpty), "FlatMap: nil key", 1, true),
		`빈 맵에 nil 키: {errEmpty}`
	)
	assert(FlatMap.Len(empty) == 0 and #FlatMap.Records(empty) == 0, "거절 뒤 빈 그대로")
	FlatMap.Set(empty, 5, "five")
	FlatMap.Set(empty, 3, "three")
	assert(FlatMap.Len(empty) == 2 and FlatMap.Get(empty, 3) == "three", "거절 뒤에도 멀쩡")

	-- 원소가 있을 때도 비교자 에러가 아니라 같은 메시지
	const okFull, errFull = pcall(function()
		FlatMap.Set(empty, nilKey, "boom")
	end)
	assert(not okFull and string.find(tostring(errFull), "FlatMap: nil key", 1, true), `찬 맵에 nil 키: {errFull}`)
	-- 값이 nil(삭제)이어도 키가 nil 이면 에러 — HashMap 의 `data[nil] = nil` 과 같음
	assert(not pcall(function()
		FlatMap.Set(empty :: any, nilKey, nil)
	end), "Set(nil, nil) 도 에러")
	assert(FlatMap.Len(empty) == 2, "크기 그대로")

	-- 조회·삭제는 "없음"(HashMap.Get(m, nil) 과 같음) — 비교자를 부르지 않음
	assert(FlatMap.Get(empty, nilKey) == nil and not FlatMap.Has(empty, nilKey), "nil 로 조회")
	-- `GetOr` 도(리뷰 1라운드 — 검사를 지워도 통과했음: nil 은 비교자에서 죽고, NaN 은 compareNumber 가
	-- 0 을 돌려줘 **첫 키의 값**이 나옴). 빼기 비교자 맵에서는 우연히 맞아 compareNumber 맵으로 봅니다.
	assert(FlatMap.GetOr(empty, nilKey, "fb") == "fb", "GetOr nil 은 fallback")
	assert(FlatMap.GetOr(empty, 0 / 0, "fb") == "fb", "GetOr NaN 은 fallback")
	assert(FlatMap.GetOr(empty, 3, "fb") == "three", "GetOr 있는 키")
	assert(FlatMap.FloorKey(empty, 0 / 0) == nil and FlatMap.CeilingKey(empty, 0 / 0) == nil, "Floor/Ceiling NaN")
	assert(FlatMap.Get(empty, 0 / 0) == nil and not FlatMap.Has(empty, 0 / 0), "compareNumber 맵의 NaN 조회")
	assert(FlatMap.Remove(empty, nilKey) == nil and FlatMap.Len(empty) == 2, "nil 로 삭제")
	assert(FlatMap.FloorKey(empty, nilKey) == nil and FlatMap.CeilingKey(empty, nilKey) == nil, "Floor/Ceiling nil")
	assert(FlatMap.LowerKey(empty, nilKey) == nil and FlatMap.HigherKey(empty, nilKey) == nil, "Lower/Higher nil")
	assert(#FlatMap.RangeRecords(empty, nilKey, 9) == 0 and #FlatMap.RangeRecords(empty, 1, nilKey) == 0, "구간 nil")

	-- FromRecords: 키 없는 레코드(`{ value = 1 }`)도 거절
	const okFrom, errFrom = pcall(function()
		FlatMap.FromRecords({ { key = 2, value = "b" }, { value = "x" } :: any }, Common.compareNumber)
	end)
	assert(not okFrom and string.find(tostring(errFrom), "FlatMap: nil key", 1, true), `FromRecords nil 키: {errFrom}`)
	const okOne, errOne = pcall(function()
		FlatMap.FromRecords({ { value = "x" } :: any }, Common.compareNumber)
	end)
	assert(
		not okOne and string.find(tostring(errOne), "FlatMap: nil key", 1, true),
		`FromRecords 하나뿐인 nil 키: {errOne}`
	)
	-- NaN 메시지는 그대로
	const okNan, errNan = pcall(function()
		FlatMap.Set(empty, 0 / 0, "nan")
	end)
	assert(not okNan and string.find(tostring(errNan), "FlatMap: NaN key", 1, true), `NaN 키 메시지: {errNan}`)
end
print("PASS")

print()
print("=== ALL PASS (FlatMap) ===")

return true

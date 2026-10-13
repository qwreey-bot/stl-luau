--!strict
--[[
	TreeMap 테스트.

	⭐ 이 컨테이너의 존재 이유가 **순서 보장**이므로, 모든 조회 계열이 정말
	정렬 순서로 나오는지를 매번 봅니다. 그리고 정렬 배열 백엔드라 삽입/삭제가
	뒤를 미는 연산이므로 **맨 앞 / 중간 / 맨 뒤** 를 따로 봅니다.
]]
local stl = require("../src")
local TreeMap = stl.TreeMap
local Common = stl.Common

type TreeMap<K, V> = stl.TreeMap<K, V>

const function keysOf<V>(m: TreeMap<number, V>): string
	return table.concat(TreeMap.Keys(m), ",")
end

print("=== 1. 정렬 순서로 담기는가 ===")
do
	const m = TreeMap.New(Common.compareNumber) :: TreeMap<number, string>
	assert(TreeMap.Empty(m) and TreeMap.Len(m) == 0, "New 는 비어 있어야 합니다")
	assert(stl.isTreeMap(m), "isTreeMap")
	assert(not stl.isTreeMap({}), "평범한 테이블은 isTreeMap 이 아님")

	TreeMap.Set(m, 3, "c")
	TreeMap.Set(m, 1, "a")
	TreeMap.Set(m, 2, "b")
	assert(keysOf(m) == "1,2,3", `정렬 순서가 아님: {keysOf(m)}`)
	assert(table.concat(TreeMap.Values(m), ",") == "a,b,c", "값도 키 순서를 따라야 합니다")
	assert(TreeMap.Len(m) == 3, "크기")

	-- 맨 앞 / 중간 / 맨 뒤 삽입
	TreeMap.Set(m, 0, "z")
	assert(keysOf(m) == "0,1,2,3", "맨 앞 삽입")
	TreeMap.Set(m, 5, "e")
	assert(keysOf(m) == "0,1,2,3,5", "맨 뒤 삽입")
	TreeMap.Set(m, 4, "d")
	assert(keysOf(m) == "0,1,2,3,4,5", "중간 삽입")

	-- 덮어쓰기는 크기를 안 올려야 합니다
	TreeMap.Set(m, 2, "B")
	assert(TreeMap.Len(m) == 6 and TreeMap.Get(m, 2) == "B", "덮어쓰기")
	assert(keysOf(m) == "0,1,2,3,4,5", "덮어쓰기는 순서를 안 건드려야 합니다")
end
print("PASS")

print("=== 2. 조회 ===")
do
	const m = TreeMap.FromRecords({
		{ key = 2, value = "b" },
		{ key = 1, value = "a" },
		{ key = 3, value = "c" },
	}, Common.compareNumber)
	assert(keysOf(m) == "1,2,3", "FromRecords 가 정렬해야 합니다")
	assert(TreeMap.Get(m, 2) == "b" and TreeMap.Get(m, 9) == nil, "Get")
	assert(TreeMap.Has(m, 1) and not TreeMap.Has(m, 9), "Has")
	assert(TreeMap.GetOr(m, 9, "기본") == "기본" and TreeMap.GetOr(m, 1, "기본") == "a", "GetOr")
	assert(#TreeMap.Records(m) == 3 and TreeMap.Records(m)[1].key == 1, "Records 는 정렬 순서")
	-- Records 는 복사여야 합니다 — 받은 쪽이 건드려도 내부가 안 깨져야 합니다
	const snapshot = TreeMap.Records(m)
	table.remove(snapshot)
	assert(TreeMap.Len(m) == 3, "Records 는 복사를 돌려줘야 합니다")

	local iterKeys = ""
	for key, _value in TreeMap.Iter(m) do
		iterKeys ..= tostring(key)
	end
	assert(iterKeys == "123", `Iter 가 정렬 순서가 아님: {iterKeys}`)
	const emptyMap = TreeMap.New(Common.compareNumber) :: TreeMap<number, string>
	local emptyCount = 0
	for _k, _v in TreeMap.Iter(emptyMap) do
		emptyCount += 1
	end
	assert(emptyCount == 0, "빈 맵의 Iter")
end
print("PASS")

print("=== 3. 중복 키는 뒤엣것이 이기는가 ===")
do
	-- table.sort 가 안정 정렬이 아니라 원래 위치를 타이브레이커로 씁니다.
	-- 이게 없으면 어느 쪽이 이길지 정해지지 않습니다.
	const m = TreeMap.FromRecords({
		{ key = 1, value = "처음" },
		{ key = 1, value = "중간" },
		{ key = 1, value = "마지막" },
	}, Common.compareNumber)
	assert(TreeMap.Len(m) == 1, "중복 키는 하나로 접혀야 합니다")
	assert(TreeMap.Get(m, 1) == "마지막", `뒤엣것이 이겨야 합니다: {tostring(TreeMap.Get(m, 1))}`)
	assert(TreeMap.Len(TreeMap.FromRecords({}, Common.compareNumber)) == 0, "빈 입력")
end
print("PASS")

print("=== 4. 정렬이 있어야만 되는 것들 ===")
do
	const m = TreeMap.FromRecords({
		{ key = 10, value = "a" },
		{ key = 20, value = "b" },
		{ key = 30, value = "c" },
	}, Common.compareNumber)
	assert((TreeMap.First(m) :: any).key == 10, "First")
	assert((TreeMap.Last(m) :: any).key == 30, "Last")

	assert(TreeMap.FloorKey(m, 20) == 20, "FloorKey 는 같은 값을 포함")
	assert(TreeMap.FloorKey(m, 25) == 20, "FloorKey 사이 값")
	assert(TreeMap.FloorKey(m, 30) == 30, "FloorKey 맨 뒤")
	assert(TreeMap.FloorKey(m, 5) == nil, "FloorKey 전부보다 작으면 nil")
	assert(TreeMap.FloorKey(m, 99) == 30, "FloorKey 전부보다 크면 마지막")

	assert(TreeMap.CeilingKey(m, 20) == 20, "CeilingKey 는 같은 값을 포함")
	assert(TreeMap.CeilingKey(m, 15) == 20, "CeilingKey 사이 값")
	assert(TreeMap.CeilingKey(m, 10) == 10, "CeilingKey 맨 앞")
	assert(TreeMap.CeilingKey(m, 99) == nil, "CeilingKey 전부보다 크면 nil")
	assert(TreeMap.CeilingKey(m, 5) == 10, "CeilingKey 전부보다 작으면 첫째")

	assert(#TreeMap.RangeRecords(m, 10, 20) == 2, "RangeRecords 양끝 포함")
	assert(#TreeMap.RangeRecords(m, 15, 25) == 1, "RangeRecords 사이")
	assert(#TreeMap.RangeRecords(m, 1, 99) == 3, "RangeRecords 전체")
	assert(#TreeMap.RangeRecords(m, 25, 15) == 0, "RangeRecords 뒤집히면 빈 것")
	assert(#TreeMap.RangeRecords(m, 40, 50) == 0, "RangeRecords 범위 밖")

	const empty = TreeMap.New(Common.compareNumber) :: TreeMap<number, string>
	assert(TreeMap.First(empty) == nil and TreeMap.Last(empty) == nil, "빈 맵의 First/Last")
	assert(TreeMap.FloorKey(empty, 1) == nil and TreeMap.CeilingKey(empty, 1) == nil, "빈 맵의 Floor/Ceiling")
end
print("PASS")

print("=== 5. Remove / Clear / Clone ===")
do
	const m = TreeMap.FromRecords({
		{ key = 1, value = "a" },
		{ key = 2, value = "b" },
		{ key = 3, value = "c" },
	}, Common.compareNumber)
	assert(TreeMap.Remove(m, 2) == "b", "Remove 는 지워진 값을 돌려줍니다")
	assert(keysOf(m) == "1,3", "Remove 후 순서가 유지돼야 합니다")
	assert(TreeMap.Remove(m, 2) == nil and TreeMap.Len(m) == 2, "없는 키 Remove")
	assert(TreeMap.Remove(m, 1) == "a" and keysOf(m) == "3", "맨 앞 Remove")
	assert(TreeMap.Remove(m, 3) == "c" and TreeMap.Empty(m), "마지막 Remove")

	TreeMap.Set(m, 7, "g")
	const cloned = TreeMap.Clone(m)
	TreeMap.Set(cloned, 8, "h")
	TreeMap.Set(cloned, 7, "바뀜")
	assert(TreeMap.Len(m) == 1 and TreeMap.Len(cloned) == 2, "Clone 은 독립적이어야 합니다")
	assert(TreeMap.Get(m, 7) == "g", "Clone 은 레코드도 새로 만들어야 합니다")

	-- 자기 자신을 돌려줌(2026-10-12, 질문 AM — 일곱 컨테이너가 같게)
	assert(TreeMap.Clear(m) == m, "Clear 는 자기 자신을 돌려줌")
	assert(TreeMap.Empty(m) and TreeMap.Get(m, 7) == nil, "Clear")
	TreeMap.Set(m, 1, "다시")
	assert(TreeMap.Len(m) == 1, "Clear 후 다시 쓸 수 있어야 합니다")
end
print("PASS")

print("=== 6. 문자열 키와 계약 ===")
do
	const m = TreeMap.FromRecords({
		{ key = "b", value = 2 },
		{ key = "a", value = 1 },
	}, Common.compareString)
	assert(table.concat(TreeMap.Keys(m), ",") == "a,b", "문자열 비교자")
	-- 구현을 모르는 공용 알고리즘이 계약만으로 동작해야 합니다
	assert(#stl.Map.Keys(m) == 2, "Map.Keys")
	assert(#stl.Map.Values(m) == 2, "Map.Values")
end
print("PASS")

print("=== 7. 회귀 — 2026-09-30 리뷰 ===")
do
	-- (1) 무한대 키: compareNumber 가 a - b 이던 시절 inf - inf = NaN 이라 망가졌음
	const inf = TreeMap.New<<number, string>>(Common.compareNumber)
	TreeMap.Set(inf, math.huge, "a")
	TreeMap.Set(inf, math.huge, "b")
	TreeMap.Set(inf, -math.huge, "m")
	TreeMap.Set(inf, 1, "x")
	assert(TreeMap.Len(inf) == 3, `무한대 키가 중복됨: {TreeMap.Len(inf)}`)
	assert(TreeMap.Get(inf, math.huge) == "b" and TreeMap.Get(inf, -math.huge) == "m", "무한대 키 조회")
	assert(TreeMap.Remove(inf, math.huge) == "b" and TreeMap.Len(inf) == 2, "무한대 키 삭제")

	-- (2) NaN 키는 시끄럽게 거절 — 조용히 넣으면 다른 키까지 망가졌음
	const n = TreeMap.New<<number, string>>(Common.compareNumber)
	TreeMap.Set(n, 1, "one")
	assert(not pcall(function()
		TreeMap.Set(n, 0 / 0, "nan")
	end), "NaN 키는 에러")
	assert(TreeMap.Len(n) == 1 and TreeMap.Get(n, 1) == "one", "거절 뒤에도 멀쩡")
	assert(TreeMap.Get(n, 0 / 0) == nil and not TreeMap.Has(n, 0 / 0), "NaN 으로 조회하면 없음")
	assert(TreeMap.Remove(n, 0 / 0) == nil and TreeMap.Len(n) == 1, "NaN 으로 삭제해도 아무 일 없음")
	assert(not pcall(function()
		TreeMap.FromRecords({ { key = 0 / 0, value = 1 } }, Common.compareNumber)
	end), "FromRecords 도 NaN 을 거절")

	-- (3) Set(k, nil) 은 삭제 — Lua 의 t[k] = nil 과 같음. HashMap 과 같은 규칙
	const z = TreeMap.New<<number, string?>>(Common.compareNumber)
	TreeMap.Set(z, 1, "a")
	TreeMap.Set(z, 1, nil)
	assert(TreeMap.Len(z) == 0 and not TreeMap.Has(z, 1), "Set(k, nil) 은 삭제")
	TreeMap.Set(z, 2, nil)
	assert(TreeMap.Len(z) == 0, "없는 키에 nil 은 아무 일 없음")

	-- Iter 가 키를 인덱스로 쓰던 버그 — 키가 1,2,3 이 아니면 드러남
	const far = TreeMap.New<<number, string>>(Common.compareNumber)
	TreeMap.Set(far, 10, "a")
	TreeMap.Set(far, 20, "b")
	TreeMap.Set(far, 30, "c")
	local joined = ""
	for key, value in TreeMap.Iter(far) do
		joined ..= `{key}={value},`
	end
	assert(joined == "10=a,20=b,30=c,", `키 10/20/30 의 Iter: {joined}`)
	const words = TreeMap.New<<string, number>>(Common.compareString)
	TreeMap.Set(words, "y", 2)
	TreeMap.Set(words, "x", 1)
	local order = ""
	for key in TreeMap.Iter(words) do
		order ..= key
	end
	assert(order == "xy", `문자열 키의 Iter: {order}`)

	-- (6) 내준 레코드를 고쳐도 맵은 멀쩡 — 레코드까지 복사본
	const r = TreeMap.New<<number, string>>(Common.compareNumber)
	TreeMap.Set(r, 1, "a")
	TreeMap.Set(r, 2, "b")
	TreeMap.Set(r, 3, "c")
	TreeMap.Records(r)[1].key = 99
	const firstRec: any = TreeMap.First(r)
	firstRec.key = 50
	TreeMap.RangeRecords(r, 2, 3)[1].value = "Z"
	const lastRec: any = TreeMap.Last(r)
	lastRec.value = "X"
	assert(
		TreeMap.Get(r, 1) == "a" and TreeMap.Get(r, 2) == "b" and TreeMap.Get(r, 3) == "c",
		"레코드를 고쳐도 맵은 그대로"
	)
	assert(TreeMap.Len(r) == 3, "크기도 그대로")
end
print("PASS")

print("=== M4. LowerKey / HigherKey / PopFirst / PopLast / Retain (2026-10-07) ===")
do
	const m = TreeMap.FromRecords({
		{ key = 30, value = "c" },
		{ key = 10, value = "a" },
		{ key = 20, value = "b" },
	}, Common.compareNumber)
	-- 엄격: 같은 키는 안 줌(Floor/Ceiling 과 다름)
	assert(TreeMap.LowerKey(m, 20) == 10 and TreeMap.FloorKey(m, 20) == 20, "LowerKey 엄격")
	assert(TreeMap.HigherKey(m, 20) == 30 and TreeMap.CeilingKey(m, 20) == 20, "HigherKey 엄격")
	assert(TreeMap.LowerKey(m, 25) == 20 and TreeMap.HigherKey(m, 25) == 30, "사이 값")
	assert(TreeMap.LowerKey(m, 10) == nil and TreeMap.HigherKey(m, 30) == nil, "양끝 밖")
	assert(TreeMap.LowerKey(m, 5) == nil and TreeMap.HigherKey(m, 5) == 10, "맨 앞보다 작음")
	assert(TreeMap.LowerKey(m, 99) == 30 and TreeMap.HigherKey(m, 99) == nil, "맨 뒤보다 큼")
	assert(TreeMap.LowerKey(m, 0 / 0) == nil and TreeMap.HigherKey(m, 0 / 0) == nil, "NaN 은 없음")
	const e = TreeMap.New<<number, string>>(Common.compareNumber)
	assert(TreeMap.LowerKey(e, 1) == nil and TreeMap.HigherKey(e, 1) == nil, "빈 맵")

	-- PopFirst / PopLast: 꺼낸 쌍, 크기, 나머지 순서
	const first = TreeMap.PopFirst(m)
	assert(first ~= nil and first.key == 10 and first.value == "a", "PopFirst")
	assert(TreeMap.Len(m) == 2 and keysOf(m) == "20,30", `PopFirst 뒤 {keysOf(m)}`)
	const last = TreeMap.PopLast(m)
	assert(last ~= nil and last.key == 30 and last.value == "c", "PopLast")
	assert(TreeMap.Len(m) == 1 and keysOf(m) == "20", "PopLast 뒤")
	-- 꺼낸 레코드를 고쳐도 맵은 그대로
	last.key = 1
	assert(TreeMap.Get(m, 20) == "b" and TreeMap.Has(m, 1) == false, "꺼낸 레코드는 맵과 무관")
	const only = TreeMap.PopLast(m)
	assert(only ~= nil and only.key == 20 and TreeMap.Empty(m), "마지막 하나")
	assert(TreeMap.PopFirst(m) == nil and TreeMap.PopLast(m) == nil and TreeMap.Len(m) == 0, "빈 Pop")
	-- 꺼낸 뒤에도 정상 동작
	TreeMap.Set(m, 50, "e")
	TreeMap.Set(m, 40, "d")
	assert(keysOf(m) == "40,50" and TreeMap.Get(m, 40) == "d", "꺼낸 뒤 Set")

	-- Retain: 정렬 순서로 부름, (key, value), 남은 것 정렬 유지
	const r = TreeMap.FromRecords({
		{ key = 40, value = "d" },
		{ key = 10, value = "a" },
		{ key = 30, value = "c" },
		{ key = 20, value = "b" },
	}, Common.compareNumber)
	local order = {}
	TreeMap.Retain(r, function(key: number, value: string): boolean
		table.insert(order, `{key}{value}`)
		return key ~= 20 and key ~= 40
	end)
	assert(table.concat(order, ",") == "10a,20b,30c,40d", `Retain 순서 {table.concat(order, ",")}`)
	assert(keysOf(r) == "10,30" and TreeMap.Len(r) == 2, "Retain")
	assert(TreeMap.Get(r, 30) == "c" and TreeMap.Get(r, 20) == nil, "Retain 뒤 조회")
	TreeMap.Set(r, 20, "B")
	assert(keysOf(r) == "10,20,30", "Retain 뒤 삽입 위치")
	const retained = TreeMap.Retain(r, function(_k: number, _v: string): boolean
		return false
	end)
	assert(retained == r, "Retain 은 자기 자신을 돌려줌")
	assert(TreeMap.Empty(r) and r.root == nil, "전부 지움")

	-- 콜백 안에서 이 맵에 넣거나 지우는 것은 **정의되지 않은 동작**(2026-10-12 사용자 결정, 질문 AL 1 —
	-- 검사 없음)이라 테스트하지 않습니다. 아래 값만 덮어쓰기(구조를 안 바꿈)가 되는 것도 **관측**입니다.
	const overwrite = TreeMap.FromRecords({ { key = 10, value = "a" } }, Common.compareNumber)
	TreeMap.Retain(overwrite, function(key: number, _v: string): boolean
		TreeMap.Set(overwrite, key, "A")
		return true
	end)
	assert(TreeMap.Get(overwrite, 10) == "A", "값 덮어쓰기")

	-- NaN 은 없음 — 빼기 비교자에서도(1라운드: compareNumber 는 NaN 에 0 이라 가드를 지워도 통과했음,
	-- `a - b` 는 NaN 을 돌려 탐색이 엉뚱한 키를 줌)
	const sub = TreeMap.FromRecords(
		{ { key = 10, value = "a" }, { key = 20, value = "b" } },
		function(a: number, b: number): number
			return a - b
		end
	)
	const nan = 0 / 0
	assert(TreeMap.LowerKey(sub, nan) == nil and TreeMap.HigherKey(sub, nan) == nil, "Lower/Higher NaN")
	assert(TreeMap.FloorKey(sub, nan) == nil and TreeMap.CeilingKey(sub, nan) == nil, "Floor/Ceiling NaN")
	assert(TreeMap.Get(sub, nan) == nil and not TreeMap.Has(sub, nan) and TreeMap.Remove(sub, nan) == nil, "조회 NaN")
	assert(#TreeMap.RangeRecords(sub, nan, 20) == 0 and #TreeMap.RangeRecords(sub, 10, nan) == 0, "구간 NaN")
	assert(TreeMap.Len(sub) == 2, "NaN 조회는 안 바꿈")
end
print("PASS")

print("=== 8. nil 키는 NaN 과 같은 태도 — 넣기는 에러, 조회·삭제는 없음 (2026-10-12) ===")
do
	-- 재현: 빈 맵에서는 비교가 한 번도 안 일어나 `Set(m, nil, v)` 가 조용히 들어갔고, 그 뒤 모든
	-- 연산이 비교자 안(라이브러리 줄)에서 `attempt to compare nil < number` 로 죽었습니다. 타입으로는
	-- 못 넣지만(`K` 가 `number`) 타입 없는 데이터(`t.id` 가 런타임에 nil)로는 들어옵니다.
	const nilKey = nil :: any
	const empty = TreeMap.New<<number, string>>(Common.compareNumber)
	const okEmpty, errEmpty = pcall(function()
		TreeMap.Set(empty, nilKey, "boom")
	end)
	assert(
		not okEmpty and string.find(tostring(errEmpty), "TreeMap: nil key", 1, true),
		`빈 맵에 nil 키: {errEmpty}`
	)
	assert(TreeMap.Len(empty) == 0 and #TreeMap.Records(empty) == 0, "거절 뒤 빈 그대로")
	TreeMap.Set(empty, 5, "five")
	TreeMap.Set(empty, 3, "three")
	assert(TreeMap.Len(empty) == 2 and TreeMap.Get(empty, 3) == "three", "거절 뒤에도 멀쩡")

	-- 원소가 있을 때도 비교자 에러가 아니라 같은 메시지
	const okFull, errFull = pcall(function()
		TreeMap.Set(empty, nilKey, "boom")
	end)
	assert(not okFull and string.find(tostring(errFull), "TreeMap: nil key", 1, true), `찬 맵에 nil 키: {errFull}`)
	-- 값이 nil(삭제)이어도 키가 nil 이면 에러 — HashMap 의 `data[nil] = nil` 과 같음
	assert(not pcall(function()
		TreeMap.Set(empty :: any, nilKey, nil)
	end), "Set(nil, nil) 도 에러")
	assert(TreeMap.Len(empty) == 2, "크기 그대로")

	-- 조회·삭제는 "없음"(HashMap.Get(m, nil) 과 같음) — 비교자를 부르지 않음
	assert(TreeMap.Get(empty, nilKey) == nil and not TreeMap.Has(empty, nilKey), "nil 로 조회")
	-- `GetOr` 도(리뷰 1라운드 — 검사를 지워도 통과했음: nil 은 비교자에서 죽고, NaN 은 compareNumber 가
	-- 0 을 돌려줘 **첫 키의 값**이 나옴). 빼기 비교자 맵에서는 우연히 맞아 compareNumber 맵으로 봅니다.
	assert(TreeMap.GetOr(empty, nilKey, "fb") == "fb", "GetOr nil 은 fallback")
	assert(TreeMap.GetOr(empty, 0 / 0, "fb") == "fb", "GetOr NaN 은 fallback")
	assert(TreeMap.GetOr(empty, 3, "fb") == "three", "GetOr 있는 키")
	assert(TreeMap.FloorKey(empty, 0 / 0) == nil and TreeMap.CeilingKey(empty, 0 / 0) == nil, "Floor/Ceiling NaN")
	assert(TreeMap.Get(empty, 0 / 0) == nil and not TreeMap.Has(empty, 0 / 0), "compareNumber 맵의 NaN 조회")
	assert(TreeMap.Remove(empty, nilKey) == nil and TreeMap.Len(empty) == 2, "nil 로 삭제")
	assert(TreeMap.FloorKey(empty, nilKey) == nil and TreeMap.CeilingKey(empty, nilKey) == nil, "Floor/Ceiling nil")
	assert(TreeMap.LowerKey(empty, nilKey) == nil and TreeMap.HigherKey(empty, nilKey) == nil, "Lower/Higher nil")
	assert(#TreeMap.RangeRecords(empty, nilKey, 9) == 0 and #TreeMap.RangeRecords(empty, 1, nilKey) == 0, "구간 nil")

	-- FromRecords: 키 없는 레코드(`{ value = 1 }`)도 거절
	const okFrom, errFrom = pcall(function()
		TreeMap.FromRecords({ { key = 2, value = "b" }, { value = "x" } :: any }, Common.compareNumber)
	end)
	assert(not okFrom and string.find(tostring(errFrom), "TreeMap: nil key", 1, true), `FromRecords nil 키: {errFrom}`)
	const okOne, errOne = pcall(function()
		TreeMap.FromRecords({ { value = "x" } :: any }, Common.compareNumber)
	end)
	assert(
		not okOne and string.find(tostring(errOne), "TreeMap: nil key", 1, true),
		`FromRecords 하나뿐인 nil 키: {errOne}`
	)
	-- NaN 메시지는 그대로
	const okNan, errNan = pcall(function()
		TreeMap.Set(empty, 0 / 0, "nan")
	end)
	assert(not okNan and string.find(tostring(errNan), "TreeMap: NaN key", 1, true), `NaN 키 메시지: {errNan}`)
end
print("PASS")

print(
	"=== 트리 판만의 것 — 균형 방식 선택, 구조 불변식, FlatMap 과 무작위 대조 (2026-10-13) ==="
)
do
	const FlatMap, Binary = stl.FlatMap, stl.Node.Binary
	const cmp = stl.Common.compareNumber
	-- 구조 검사: 부모 칸, 키 순서, size, 그리고 높이가 로그(균형 방식이 일을 했는지 — 2·log2(n+1) 이하)
	local function sound(m: stl.TreeMap<number, number>, label: string)
		local count, last: number? = 0, nil
		local function walk(node: any, parent: any)
			if node == nil then
				return
			end
			assert(node[4] == parent, `{label}: {node[5]} 의 부모 칸`)
			walk(node[2], node)
			assert(last == nil or last < node[5], `{label}: 순서`)
			last = node[5]
			count += 1
			walk(node[3], node)
		end
		walk(m.root, nil)
		assert(count == m.size and TreeMap.Len(m) == count, `{label}: size {m.size} ~= 노드 수 {count}`)
		assert(Binary.Height(m.root :: any) <= 2 * math.log(count + 1, 2) + 1e-9, `{label}: 높이`)
	end
	-- 균형 방식: 기본은 레드블랙, 둘째 인자로 고름
	const rb = TreeMap.New<<number, number>>(cmp)
	const avl = TreeMap.New<<number, number>>(cmp, stl.Avl)
	assert(rb.balance == stl.RedBlack :: any and avl.balance == stl.Avl :: any, "기본 레드블랙 / 고른 AVL")
	for key = 10, 2000, 10 do
		TreeMap.Set(rb, key, key + 1)
		TreeMap.Set(avl, key, key + 1)
	end
	sound(rb, "레드블랙 오름차순 200")
	sound(avl, "AVL 오름차순 200")
	assert((rb.root :: any)[6] == false and type((avl.root :: any)[6]) == "number", "노드가 그 방식의 것")
	assert(TreeMap.Get(rb, 990) == 991 and TreeMap.Get(avl, 990) == 991, "둘 다 조회")
	-- Clone·FromRecords 는 균형 방식을 물려받고 구조가 온전
	const avlCopy = TreeMap.Clone(avl)
	assert(
		avlCopy.balance == stl.Avl :: any and avlCopy.root ~= avl.root,
		"Clone 은 방식을 물려받고 노드는 새로"
	)
	TreeMap.Set(avlCopy, 5, 6)
	TreeMap.Remove(avl, 10)
	sound(avlCopy, "AVL 사본")
	sound(avl, "AVL 원본")
	assert(
		TreeMap.Len(avlCopy) == 201 and TreeMap.Len(avl) == 199 and TreeMap.Has(avlCopy, 10),
		"사본과 원본은 따로"
	)
	const recs: { stl.Record<number, number> } = {}
	for at = 1, 300 do
		recs[at] = { key = ((at * 37) % 150) * 10, value = at }
	end
	for _, balance in { stl.RedBlack :: any, stl.Avl } do
		const built = TreeMap.FromRecords(recs, cmp, balance)
		sound(built, "FromRecords")
		assert(built.balance == balance and TreeMap.Len(built) == 150, `FromRecords 크기 {TreeMap.Len(built)}`)
		-- 지은 뒤에도 평범한 트리
		TreeMap.Set(built, 5, 1)
		TreeMap.Remove(built, 700)
		sound(built, "FromRecords 뒤 고치기")
	end
	-- PopFirst·PopLast 가 구조를 지키며 끝까지
	const popper = TreeMap.Clone(rb)
	local popped = 0
	while not TreeMap.Empty(popper) do
		const rec = if popped % 2 == 0 then TreeMap.PopFirst(popper) else TreeMap.PopLast(popper)
		assert(rec ~= nil and rec.value == rec.key + 1, "꺼낸 쌍")
		popped += 1
		if popped % 17 == 0 then
			sound(popper, `Pop {popped}`)
		end
	end
	assert(popped == 200 and popper.root == nil and TreeMap.PopFirst(popper) == nil, "다 꺼냄")
	-- Retain 이 구조를 지킴(가운데를 많이 지움)
	const kept = TreeMap.Retain(TreeMap.Clone(rb), function(key: number, _value: number): boolean
		return key % 30 == 0
	end)
	sound(kept, "Retain 뒤")
	assert(
		TreeMap.Len(kept) == 66 and TreeMap.Has(kept, 30) and not TreeMap.Has(kept, 40),
		`Retain 크기 {TreeMap.Len(kept)}`
	)

	-- ⭐ 무작위 대조: 같은 연산 열을 TreeMap(두 방식)과 FlatMap 에 — 반환값과 모든 조회가 같아야 함
	math.randomseed(20261013)
	for round = 1, 30 do
		const flat = FlatMap.New<<number, number>>(cmp)
		const trees = { TreeMap.New<<number, number>>(cmp), TreeMap.New<<number, number>>(cmp, stl.Avl) }
		for step = 1, 250 do
			const key = math.random(0, 60) * 10
			const op = math.random(1, 10)
			for _, tree in trees do
				if op <= 4 then
					TreeMap.Set(tree, key, step)
				elseif op <= 6 then
					assert(TreeMap.Remove(tree, key) == FlatMap.Get(flat, key), "Remove 반환")
				elseif op == 7 then
					TreeMap.Set(tree, key, nil :: any)
				elseif op == 8 then
					const want = FlatMap.First(flat)
					const got = TreeMap.PopFirst(tree)
					assert(
						(got == nil) == (want == nil)
							and (got == nil or (got.key == (want :: any).key and got.value == (want :: any).value)),
						"PopFirst"
					)
				elseif op == 9 then
					const want = FlatMap.Last(flat)
					const got = TreeMap.PopLast(tree)
					assert((got == nil) == (want == nil) and (got == nil or got.key == (want :: any).key), "PopLast")
				end
			end
			if op <= 4 then
				FlatMap.Set(flat, key, step)
			elseif op <= 6 then
				FlatMap.Remove(flat, key)
			elseif op == 7 then
				FlatMap.Set(flat, key, nil :: any)
			elseif op == 8 then
				FlatMap.PopFirst(flat)
			elseif op == 9 then
				FlatMap.PopLast(flat)
			end
			const probe = math.random(-1, 61) * 10 + (if math.random() < 0.5 then 5 else 0)
			for _, tree in trees do
				assert(TreeMap.Len(tree) == FlatMap.Len(flat), "크기")
				assert(
					TreeMap.Get(tree, probe) == FlatMap.Get(flat, probe)
						and TreeMap.Has(tree, key) == FlatMap.Has(flat, key),
					"Get·Has"
				)
				assert(TreeMap.FloorKey(tree, probe) == FlatMap.FloorKey(flat, probe), `FloorKey({probe})`)
				assert(TreeMap.CeilingKey(tree, probe) == FlatMap.CeilingKey(flat, probe), `CeilingKey({probe})`)
				assert(TreeMap.LowerKey(tree, probe) == FlatMap.LowerKey(flat, probe), `LowerKey({probe})`)
				assert(TreeMap.HigherKey(tree, probe) == FlatMap.HigherKey(flat, probe), `HigherKey({probe})`)
			end
		end
		for _, tree in trees do
			sound(tree, `무작위 {round}`)
			assert(table.concat(TreeMap.Keys(tree), ",") == table.concat(FlatMap.Keys(flat), ","), "Keys")
			assert(table.concat(TreeMap.Values(tree), ",") == table.concat(FlatMap.Values(flat), ","), "Values")
			const lo, hi = math.random(0, 30) * 10, math.random(20, 61) * 10
			const want, got = FlatMap.RangeRecords(flat, lo, hi), TreeMap.RangeRecords(tree, lo, hi)
			assert(#want == #got, `RangeRecords 수 {#got} ~= {#want}`)
			for at = 1, #want do
				assert(want[at].key == got[at].key and want[at].value == got[at].value, "RangeRecords 내용")
			end
			local seen = 0
			const flatRecords = FlatMap.Records(flat)
			for key, value in TreeMap.Iter(tree) do
				seen += 1
				assert(flatRecords[seen].key == key and flatRecords[seen].value == value, "Iter")
			end
			assert(seen == #flatRecords, "Iter 수")
		end
	end
	-- 종류를 모르는 코드(트레이트 진입점)와 묶기의 목적지로
	assert(table.concat(stl.Map.Keys(rb), ",") == table.concat(TreeMap.Keys(rb), ","), "Map.Keys")
	assert(
		stl.Collection.Len(rb) == 200 and (stl.Trait.ImplOf(stl.Map, rb) :: any).Get == TreeMap.Get :: any,
		"트레이트"
	)
	const grouped = stl.Arr.GroupBy(stl.Arr.Of(11, 25, 12, 31, 27), function(v: number): number
		return v // 10
	end, TreeMap.New<<number, stl.Arr<number>>>(cmp))
	assert(stl.isTreeMap(grouped) and table.concat(TreeMap.Keys(grouped), ",") == "1,2,3", "묶기의 목적지")
	assert((TreeMap.Get(grouped, 2) :: any).n == 2, "묶음 크기")
end
print("PASS")

print(
	"=== 리뷰 1라운드(2026-10-13) — TreeMap: false 값, FromRecords 의 세부, 에러 자리의 줄, 생성자 인자 검사 ==="
)
do
	const cmp = stl.Common.compareNumber
	local where = 0
	-- GetOr 는 값이 false 여도 그 값을(`value or fallback` 로 쓰면 틀림)
	const flags = TreeMap.New<<number, boolean>>(cmp)
	TreeMap.Set(flags, 10, false)
	assert(TreeMap.GetOr(flags, 10, true) == false and TreeMap.GetOr(flags, 20, true) == true, "GetOr 와 false 값")
	assert(
		TreeMap.Has(flags, 10) and TreeMap.Get(flags, 10) == false and TreeMap.Len(flags) == 1,
		"false 값은 있는 값"
	)

	-- FromRecords: 마지막 값이 nil 인 키는 없는 것(`Set` 과 같은 규칙) — 키·값이 같이 당겨지고 크기가 맞음
	const pruned = TreeMap.FromRecords<<number, string>>({
		{ key = 10, value = "a" },
		{ key = 20, value = "b" },
		{ key = 30, value = "c" },
		{ key = 10, value = nil :: any },
	}, cmp)
	assert(
		TreeMap.Len(pruned) == 2 and not TreeMap.Has(pruned, 10),
		`nil 로 끝난 키는 빠짐: {TreeMap.Len(pruned)}`
	)
	assert(TreeMap.Get(pruned, 20) == "b" and TreeMap.Get(pruned, 30) == "c", "남은 키·값이 제 짝")
	assert(table.concat(TreeMap.Keys(pruned), ",") == "20,30", "남은 키")
	-- FromRecords 의 길이 규약: `n` 을 따르고 구멍은 건너뜀, 다른 컨테이너는 에러
	const holed = TreeMap.FromRecords({ { key = 1, value = "a" }, nil, { key = 3, value = "c" }, n = 3 } :: any, cmp)
	assert(table.concat(TreeMap.Keys(holed), ",") == "1,3", "n 을 따르고 구멍은 건너뜀")
	const short = TreeMap.FromRecords(
		{ { key = 1, value = "a" }, { key = 2, value = "b" }, { key = 3, value = "c" }, n = 2 } :: any,
		cmp
	)
	assert(TreeMap.Len(short) == 2 and not TreeMap.Has(short, 3), "n 이 더 짧으면 거기까지")
	assert(
		not pcall(TreeMap.FromRecords, stl.HashMap.New() :: any, cmp),
		"다른 컨테이너는 레코드 목록이 아님"
	)
	-- "뒤엣것이 이긴다" — 큰 입력에서도(`table.sort` 는 안정 정렬이 아니라 타이브레이커가 필요. 작은 입력은
	-- 삽입 정렬 구간이라 타이브레이커 없이도 우연히 맞았음)
	const many: { stl.Record<number, number> } = {}
	for at = 1, 3000 do
		many[at] = { key = (at * 7) % 40, value = at }
	end
	const lastWins = TreeMap.FromRecords(many, cmp)
	assert(TreeMap.Len(lastWins) == 40, "키 40종")
	for key = 0, 39 do
		local want = 0
		for at = 3000, 1, -1 do
			if (at * 7) % 40 == key then
				want = at
				break
			end
		end
		assert(
			TreeMap.Get(lastWins, key) == want,
			`키 {key}: 뒤엣것 {want} 이 아니라 {tostring(TreeMap.Get(lastWins, key))}`
		)
	end

	-- 에러 자리: 메시지와 **사용자 줄**
	const m = TreeMap.New<<number, string>>(cmp)
	const sites: { { want: string, call: () -> () } } = {
		{
			want = "TreeMap: nil key",
			call = function()
				where = debug.info(1, "l") + 1
				TreeMap.Set(m, nil :: any, "x")
			end,
		},
		{
			want = "TreeMap: NaN key",
			call = function()
				where = debug.info(1, "l") + 1
				TreeMap.Set(m, 0 / 0, "x")
			end,
		},
		{
			want = "TreeMap: nil key",
			call = function()
				where = debug.info(1, "l") + 1
				TreeMap.FromRecords({ { key = 1, value = "a" }, { key = nil :: any, value = "b" } }, cmp)
			end,
		},
		{
			want = "TreeMap: New needs a comparator function, got nil",
			call = function()
				where = debug.info(1, "l") + 1
				TreeMap.New(nil :: any)
			end,
		},
		{
			want = "TreeMap: FromRecords needs a comparator function, got string",
			call = function()
				where = debug.info(1, "l") + 1
				TreeMap.FromRecords({}, "compare" :: any)
			end,
		},
		{
			want = "TreeMap: New needs a balance scheme",
			call = function()
				where = debug.info(1, "l") + 1
				TreeMap.New(cmp, "avl" :: any)
			end,
		},
		{
			want = "TreeMap: New needs a balance scheme",
			call = function()
				where = debug.info(1, "l") + 1
				TreeMap.New(cmp, stl.TreeMap :: any)
			end,
		},
		{
			want = "TreeMap: FromRecords needs a balance scheme",
			call = function()
				where = debug.info(1, "l") + 1
				TreeMap.FromRecords({}, cmp, true :: any)
			end,
		},
		{
			want = "TreeMap: FromSorted needs a comparator function, got nil",
			call = function()
				where = debug.info(1, "l") + 1
				TreeMap.FromSorted({ 1 }, { "a" }, 1, nil :: any)
			end,
		},
	}
	for _, site in sites do
		const ok, err = pcall(site.call)
		assert(not ok and string.find(tostring(err), site.want, 1, true), `{site.want}: {err}`)
		assert(string.find(tostring(err), `spec.treemap.luau:{where}:`, 1, true), `{site.want} 사용자 줄: {err}`)
	end
	assert(TreeMap.Len(m) == 0, "거절된 호출은 맵을 안 바꿈")
	-- 종류를 모르는 코드로 비우기
	const toClear = TreeMap.FromRecords({ { key = 1, value = "a" } }, cmp)
	assert(stl.Collection.Clear(toClear) == toClear and TreeMap.Len(toClear) == 0, "Collection.Clear")
end
print("PASS")

do
	assert(
		TreeMap.FromRecords<<number, number>>({}, stl.Common.compareNumber, stl.Avl).balance == stl.Avl :: any,
		"빈 FromRecords 도 균형 방식을 받음"
	)
end

print("=== 가르기·잇기 — SplitOff·Join, 맵·셋 다섯 종류에 같은 시나리오 (2026-10-14) ===")
do
	const cmp = stl.Common.compareNumber
	const FlatMap, TreeSet, FlatSet, Binary = stl.FlatMap, stl.TreeSet, stl.FlatSet, stl.Node.Binary
	-- 트리 판의 구조 검사: 부모 칸, 순서, 노드 수 = size, 높이가 로그
	local function soundTree(root: any, size: number, label: string)
		local count, last: number? = 0, nil
		local function walk(node: any, parent: any)
			if node == nil then
				return
			end
			assert(node[4] == parent, `{label}: {node[5]} 의 부모 칸`)
			walk(node[2], node)
			assert(last == nil or last < node[5], `{label}: 순서`)
			last = node[5]
			count += 1
			walk(node[3], node)
		end
		assert(root == nil or root[4] == nil, `{label}: 뿌리의 부모`)
		walk(root, nil)
		assert(count == size, `{label}: size {size} ~= 노드 수 {count}`)
		assert(Binary.Height(root) <= 2 * math.log(count + 1, 2) + 1e-9, `{label}: 높이 {Binary.Height(root)}`)
	end
	-- 균형 방식의 불변식(3라운드 리뷰의 참고 — 맵 테스트가 "그 방식의 규칙이 지켜지는가" 를 안 봐서, 지우기가 균형
	-- 방식을 무시하고 레드블랙의 것을 불러도 통과했음). 여섯째 칸: 레드블랙은 빨강 여부, AVL 은 높이.
	local function soundRedBlack(root: any, label: string)
		if root == nil then
			return
		end
		assert(root[6] == false, `{label}: 뿌리가 검정이 아님({tostring(root[6])})`)
		local function walk(node: any, parent: any): number
			if node == nil then
				return 1
			end
			assert(type(node[6]) == "boolean", `{label}: {node[5]} 의 색 칸이 불리언이 아님`)
			assert(not (node[6] and parent ~= nil and parent[6]), `{label}: 빨강-빨강 at {node[5]}`)
			const left, right = walk(node[2], node), walk(node[3], node)
			assert(left == right, `{label}: {node[5]} 에서 검정 수 {left} ~= {right}`)
			return left + (if node[6] then 0 else 1)
		end
		walk(root, nil)
	end
	local function soundAvl(root: any, label: string)
		local function walk(node: any): number
			if node == nil then
				return 0
			end
			const left, right = walk(node[2]), walk(node[3])
			assert(math.abs(left - right) <= 1, `{label}: {node[5]} 에서 높이 차 {left - right}`)
			assert(node[6] == math.max(left, right) + 1, `{label}: {node[5]} 의 높이 칸 {tostring(node[6])}`)
			return node[6]
		end
		walk(root)
	end
	-- 배열 판의 구조 검사: 순서, size 밖 칸이 비었는지
	local function soundFlat(map: any, label: string)
		for idx = 2, map.size do
			assert(map.records[idx - 1].key < map.records[idx].key, `{label}: 순서`)
		end
		assert(map.records[map.size + 1] == nil and #map.records == map.size, `{label}: size 밖 칸`)
	end
	type Kind = {
		name: string,
		head: string, -- 에러 메시지의 머리
		noun: string, -- 메시지의 "maps"/"sets"
		each: string, -- "key"/"item"
		new: (compare: any?) -> any,
		put: (c: any, key: number) -> (),
		drop: (c: any, key: number) -> (),
		keys: (c: any) -> { number },
		len: (c: any) -> number,
		splitOff: (c: any, key: any) -> any,
		join: (c: any, other: any) -> any,
		sound: (c: any, label: string) -> (),
		other: () -> any, -- 종류가 다른 것(에러 확인용)
	}
	const kinds: { Kind } = {
		{
			name = "TreeMap(레드블랙)",
			head = "TreeMap",
			noun = "maps",
			each = "key",
			new = function(compare)
				return TreeMap.New(compare or cmp)
			end,
			put = function(c, key)
				TreeMap.Set(c, key, key + 1)
			end,
			drop = function(c, key)
				TreeMap.Remove(c, key)
			end,
			keys = TreeMap.Keys,
			len = TreeMap.Len,
			splitOff = TreeMap.SplitOff,
			join = TreeMap.Join,
			sound = function(c, label)
				soundTree(c.root, c.size, label)
				soundRedBlack(c.root, label)
			end,
			other = function()
				return FlatMap.New(cmp)
			end,
		},
		{
			name = "TreeMap(AVL)",
			head = "TreeMap",
			noun = "maps",
			each = "key",
			new = function(compare)
				return TreeMap.New(compare or cmp, stl.Avl)
			end,
			put = function(c, key)
				TreeMap.Set(c, key, key + 1)
			end,
			drop = function(c, key)
				TreeMap.Remove(c, key)
			end,
			keys = TreeMap.Keys,
			len = TreeMap.Len,
			splitOff = TreeMap.SplitOff,
			join = TreeMap.Join,
			sound = function(c, label)
				soundTree(c.root, c.size, label)
				soundAvl(c.root, label)
			end,
			other = function()
				return TreeSet.New(cmp)
			end,
		},
		{
			name = "FlatMap",
			head = "FlatMap",
			noun = "maps",
			each = "key",
			new = function(compare)
				return FlatMap.New(compare or cmp)
			end,
			put = function(c, key)
				FlatMap.Set(c, key, key + 1)
			end,
			drop = function(c, key)
				FlatMap.Remove(c, key)
			end,
			keys = FlatMap.Keys,
			len = FlatMap.Len,
			splitOff = FlatMap.SplitOff,
			join = FlatMap.Join,
			sound = soundFlat,
			other = function()
				return TreeMap.New(cmp)
			end,
		},
		{
			name = "TreeSet",
			head = "TreeSet",
			noun = "sets",
			each = "item",
			new = function(compare)
				return TreeSet.New(compare or cmp)
			end,
			put = function(c, key)
				TreeSet.Add(c, key)
			end,
			drop = function(c, key)
				TreeSet.Remove(c, key)
			end,
			keys = TreeSet.Items,
			len = TreeSet.Len,
			splitOff = TreeSet.SplitOff,
			join = TreeSet.Join,
			sound = function(c, label)
				soundTree(c.map.root, c.map.size, label)
				soundRedBlack(c.map.root, label)
			end,
			other = function()
				return FlatSet.New(cmp)
			end,
		},
		{
			name = "FlatSet",
			head = "FlatSet",
			noun = "sets",
			each = "item",
			new = function(compare)
				return FlatSet.New(compare or cmp)
			end,
			put = function(c, key)
				FlatSet.Add(c, key)
			end,
			drop = function(c, key)
				FlatSet.Remove(c, key)
			end,
			keys = FlatSet.Items,
			len = FlatSet.Len,
			splitOff = FlatSet.SplitOff,
			join = FlatSet.Join,
			sound = function(c, label)
				soundFlat(c.map, label)
			end,
			other = function()
				return TreeSet.New(cmp)
			end,
		},
	}
	local function list(keys: { number }): string
		return table.concat(keys, ",")
	end
	for _, kind in kinds do
		const name = kind.name
		local function filled(from: number, to: number): any
			const c = kind.new()
			-- 넣는 순서를 흩음(짝수 번째를 뒤에서부터, 그다음 홀수 번째를 앞에서부터)
			for key = to, from, -1 do
				if (key - from) % 2 == 0 then
					kind.put(c, key * 10)
				end
			end
			for key = from, to do
				if (key - from) % 2 == 1 then
					kind.put(c, key * 10)
				end
			end
			return c
		end
		local function expect(c: any, want: string, label: string)
			assert(list(kind.keys(c)) == want, `{name} {label}: {list(kind.keys(c))}, 기대 {want}`)
			kind.sound(c, `{name} {label}`)
		end

		-- (1) SplitOff — 키 사이, 있는 키(그 키는 떼어 낸 쪽으로), 맨 앞보다 작게(전부 떼어 냄), 맨 뒤보다 크게(빈 것), 빈 것
		do
			const low = filled(1, 10)
			const high = kind.splitOff(low, 55)
			expect(low, "10,20,30,40,50", "키 사이: 남은 쪽")
			expect(high, "60,70,80,90,100", "키 사이: 떼어 낸 쪽")
			assert(kind.len(low) == 5 and kind.len(high) == 5, `{name} 크기`)
			-- 둘은 따로 놂: 한쪽을 고쳐도 다른 쪽은 그대로
			kind.put(low, 25)
			kind.drop(high, 80)
			kind.put(high, 85)
			expect(low, "10,20,25,30,40,50", "가른 뒤 남은 쪽을 고침")
			expect(high, "60,70,85,90,100", "가른 뒤 떼어 낸 쪽을 고침")
			const onKey = kind.splitOff(low, 30)
			expect(low, "10,20,25", "있는 키: 남은 쪽")
			expect(onKey, "30,40,50", "있는 키는 떼어 낸 쪽으로")
			const all = kind.splitOff(low, 5)
			expect(low, "", "맨 앞보다 작게: 전부 떼어 냄")
			expect(all, "10,20,25", "맨 앞보다 작게: 떼어 낸 쪽")
			const none = kind.splitOff(all, 999)
			expect(all, "10,20,25", "맨 뒤보다 크게: 그대로")
			expect(none, "", "맨 뒤보다 크게: 빈 것")
			const fromEmpty = kind.splitOff(low, 10)
			expect(fromEmpty, "", "빈 것을 가름")
			-- 딱 하나만 떼어 냄(맨 끝 키에서) / 딱 하나만 남김(둘째 키에서) — 5라운드 리뷰의 테스트 공백
			const five = filled(1, 5)
			const lastOne = kind.splitOff(five, 50)
			expect(five, "10,20,30,40", "하나만 떼어 냄: 남은 쪽")
			expect(lastOne, "50", "하나만 떼어 냄: 떼어 낸 쪽")
			kind.put(lastOne, 60)
			kind.drop(five, 40)
			expect(lastOne, "50,60", "하나짜리에 넣기")
			const rest = kind.splitOff(five, 20)
			expect(five, "10", "하나만 남김: 남은 쪽")
			expect(rest, "20,30", "하나만 남김: 떼어 낸 쪽")
			-- 한쪽이 훨씬 큰 경우(크기를 "작은 쪽만 세서" 정하는 길의 양쪽)
			const big = filled(1, 300)
			const tail = kind.splitOff(big, 2985)
			assert(
				kind.len(big) == 298 and kind.len(tail) == 2,
				`{name} 뒤가 작음: {kind.len(big)}/{kind.len(tail)}`
			)
			kind.sound(big, `{name} 뒤가 작음`)
			const rest = kind.splitOff(big, 25)
			assert(
				kind.len(big) == 2 and kind.len(rest) == 296,
				`{name} 앞이 작음: {kind.len(big)}/{kind.len(rest)}`
			)
			kind.sound(rest, `{name} 앞이 작음`)
		end

		-- (2) Join — 뒤에 잇기. 상대는 빈 것이 됨. 빈 것과 잇기(양쪽), 이은 뒤에도 넣고 빼기
		do
			const low, high = filled(1, 4), filled(5, 9)
			assert(kind.join(low, high) == low, `{name} Join 은 자기 자신을 돌려줌`)
			expect(low, "10,20,30,40,50,60,70,80,90", "Join")
			expect(high, "", "Join 뒤 상대는 빈 것")
			kind.put(high, 7)
			expect(high, "7", "비워진 상대도 다시 쓸 수 있음")
			kind.drop(low, 50)
			kind.put(low, 55)
			expect(low, "10,20,30,40,55,60,70,80,90", "이은 뒤 고침")
			const empty = kind.new()
			kind.join(low, empty)
			expect(low, "10,20,30,40,55,60,70,80,90", "빈 것을 이음")
			kind.join(empty, low)
			expect(empty, "10,20,30,40,55,60,70,80,90", "빈 것에 이음")
			expect(low, "", "빈 것에 이은 뒤 상대")
			-- 가르고 다시 이으면 원래대로
			const again = kind.splitOff(empty, 40)
			kind.join(empty, again)
			expect(empty, "10,20,30,40,55,60,70,80,90", "가르고 다시 이음")
		end

		-- (3) 에러 — 메시지와 사용자 줄. 실패한 뒤 두 쪽 다 그대로
		do
			local where = 0
			const low, high = filled(1, 3), filled(3, 5) -- 30 이 겹침
			const sites: { { want: string, call: () -> () } } = {
				{
					want = `{kind.head}: Join needs every {kind.each} of the second`,
					call = function()
						where = debug.info(1, "l") + 1
						kind.join(low, high)
					end,
				},
				{
					want = `{kind.head}: Join needs every {kind.each} of the second`,
					call = function()
						where = debug.info(1, "l") + 1
						kind.join(high, filled(1, 2)) -- 뒤의 것이 전부 작음
					end,
				},
				{
					want = `{kind.head}: Join needs two different {kind.noun}`,
					call = function()
						where = debug.info(1, "l") + 1
						kind.join(low, low)
					end,
				},
				{
					want = `{kind.head}: Join needs another {kind.head}, got {(stl.Trait.TokenOf(kind.other()) :: any).name}`,
					call = function()
						where = debug.info(1, "l") + 1
						kind.join(low, kind.other())
					end,
				},
				{
					-- 섞인 쪽이 **첫 인자**여도(5라운드 리뷰 — 예전엔 라이브러리 줄의 원시 에러이거나 엉뚱한 메시지)
					want = `{kind.head}: Join needs a {kind.head}, got {(stl.Trait.TokenOf(kind.other()) :: any).name}`,
					call = function()
						where = debug.info(1, "l") + 1
						kind.join(kind.other(), low)
					end,
				},
				{
					want = `{kind.head}: Join needs a {kind.head}, got nil`,
					call = function()
						where = debug.info(1, "l") + 1
						kind.join(nil, low)
					end,
				},
				{
					want = `{kind.head}: Join needs another {kind.head}, got nil`,
					call = function()
						where = debug.info(1, "l") + 1
						kind.join(low, nil)
					end,
				},
				{
					want = `{kind.head}: {kind.noun} use different comparators`,
					call = function()
						where = debug.info(1, "l") + 1
						kind.join(
							low,
							kind.new(function(a: number, b: number): number
								return a - b
							end)
						)
					end,
				},
				{
					want = `{kind.head}: nil {kind.each}`,
					call = function()
						where = debug.info(1, "l") + 1
						kind.splitOff(low, nil)
					end,
				},
				{
					want = `{kind.head}: NaN {kind.each}`,
					call = function()
						where = debug.info(1, "l") + 1
						kind.splitOff(low, 0 / 0)
					end,
				},
			}
			for _, site in sites do
				const ok, err = pcall(site.call)
				assert(not ok and string.find(tostring(err), site.want, 1, true), `{name} {site.want}: {err}`)
				assert(string.find(tostring(err), `spec.treemap.luau:{where}:`, 1, true), `{name} 사용자 줄: {err}`)
				expect(low, "10,20,30", "실패한 뒤 앞의 것")
				expect(high, "30,40,50", "실패한 뒤 뒤의 것")
			end
		end

		-- (4) 무작위: 정렬된 모델과 대조 — 가르고, 양쪽을 고치고, 다시 잇고
		do
			local seed = 4004
			local function rand(limit: number): number
				seed = (seed * 48271) % 2147483647
				return seed % limit
			end
			for round = 1, 8 do
				const whole = kind.new()
				const model: { [number]: boolean } = {}
				local function sorted(from: number, to: number): string
					const keys: { number } = {}
					for key in model do
						if key >= from and key < to then
							table.insert(keys, key)
						end
					end
					table.sort(keys)
					return list(keys)
				end
				for _ = 1, 150 do
					const key = rand(400) * 10
					kind.put(whole, key)
					model[key] = true
				end
				for step = 1, 40 do
					const cut = rand(820) * 5
					const high = kind.splitOff(whole, cut)
					expect(whole, sorted(-1, cut), `무작위 {round}/{step} 남은 쪽`)
					expect(high, sorted(cut, math.huge), `무작위 {round}/{step} 떼어 낸 쪽`)
					-- 양쪽을 고침(각자의 구간 안에서)
					for _ = 1, 8 do
						const lowKey, highKey = rand(math.max(1, cut // 10)) * 10, (cut // 10 + 1 + rand(60)) * 10
						if lowKey < cut then
							if rand(2) == 0 then
								kind.put(whole, lowKey)
								model[lowKey] = true
							else
								kind.drop(whole, lowKey)
								model[lowKey] = nil
							end
						end
						if rand(2) == 0 then
							kind.put(high, highKey)
							model[highKey] = true
						else
							kind.drop(high, highKey)
							model[highKey] = nil
						end
					end
					expect(whole, sorted(-1, cut), `무작위 {round}/{step} 고친 남은 쪽`)
					expect(high, sorted(cut, math.huge), `무작위 {round}/{step} 고친 떼어 낸 쪽`)
					kind.join(whole, high)
					expect(whole, sorted(-1, math.huge), `무작위 {round}/{step} 이은 뒤`)
					assert(kind.len(high) == 0, `{name} 무작위 {round}/{step}: 상대가 안 비었음`)
				end
			end
		end
	end
	-- 균형 방식이 다른 두 TreeMap 은 못 이음(노드의 균형 칸이 서로 다른 뜻)
	local where = 0
	const rbMap, avlMap = TreeMap.New(cmp), TreeMap.New(cmp, stl.Avl)
	TreeMap.Set(rbMap, 10, 1)
	TreeMap.Set(avlMap, 20, 2)
	const okScheme, errScheme = pcall(function()
		where = debug.info(1, "l") + 1
		TreeMap.Join(rbMap, avlMap)
	end)
	assert(
		not okScheme and string.find(tostring(errScheme), "TreeMap: maps use different balance schemes", 1, true),
		`균형 방식: {errScheme}`
	)
	assert(
		string.find(tostring(errScheme), `spec.treemap.luau:{where}:`, 1, true),
		`균형 방식 사용자 줄: {errScheme}`
	)
	const rbSet, avlSet = TreeSet.New(cmp), TreeSet.New(cmp, stl.Avl)
	TreeSet.Add(rbSet, 10)
	TreeSet.Add(avlSet, 20)
	const okSetScheme, errSetScheme = pcall(function()
		where = debug.info(1, "l") + 1
		TreeSet.Join(rbSet, avlSet)
	end)
	assert(
		not okSetScheme and string.find(tostring(errSetScheme), "TreeSet: sets use different balance schemes", 1, true),
		`셋의 균형 방식: {errSetScheme}`
	)
	assert(
		string.find(tostring(errSetScheme), `spec.treemap.luau:{where}:`, 1, true),
		`셋의 균형 방식 사용자 줄: {errSetScheme}`
	)
	-- 떼어 낸 맵은 같은 균형 방식·비교자를 물려받음
	TreeMap.Set(avlMap, 30, 3)
	const avlHigh = TreeMap.SplitOff(avlMap, 25)
	assert(
		avlHigh.balance == stl.Avl :: any and avlHigh.compare == avlMap.compare,
		"떼어 낸 맵의 균형 방식·비교자"
	)
end
print("PASS")

print()
print("=== ALL PASS (TreeMap) ===")

return true

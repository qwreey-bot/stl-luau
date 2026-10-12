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
	assert(#stl.Algorithm.Keys(m) == 2, "Algorithm.Keys")
	assert(#stl.Algorithm.Values(m) == 2, "Algorithm.Values")
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
	assert(rawget(m.records :: any, 3) == nil, "꼬리 칸 비움")
	const last = TreeMap.PopLast(m)
	assert(last ~= nil and last.key == 30 and last.value == "c", "PopLast")
	assert(TreeMap.Len(m) == 1 and keysOf(m) == "20", "PopLast 뒤")
	assert(rawget(m.records :: any, 2) == nil, "PopLast 꼬리")
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
	assert(rawget(r.records :: any, 3) == nil and rawget(r.records :: any, 4) == nil, "Retain 꼬리")
	assert(TreeMap.Get(r, 30) == "c" and TreeMap.Get(r, 20) == nil, "Retain 뒤 조회")
	TreeMap.Set(r, 20, "B")
	assert(keysOf(r) == "10,20,30", "Retain 뒤 삽입 위치")
	const retained = TreeMap.Retain(r, function(_k: number, _v: string): boolean
		return false
	end)
	assert(retained == r, "Retain 은 자기 자신을 돌려줌")
	assert(TreeMap.Empty(r) and rawget(r.records :: any, 1) == nil, "전부 지움")

	-- 콜백 안에서 이 맵에 넣거나 지우는 것은 **정의되지 않은 동작**(2026-10-12 사용자 결정, 질문 AL 1 —
	-- 검사 없음)이라 테스트하지 않습니다. 값만 덮어쓰기(구조를 안 바꿈)는 됩니다.
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

print()
print("=== ALL PASS (TreeMap) ===")

return true

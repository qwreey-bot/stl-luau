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
	return table.concat(m:Keys(), ",")
end

print("=== 1. 정렬 순서로 담기는가 ===")
do
	const m = TreeMap.New(Common.compareNumber) :: TreeMap<number, string>
	assert(m:Empty() and m:Len() == 0, "New 는 비어 있어야 합니다")
	assert(stl.isTreeMap(m), "isTreeMap")
	assert(not stl.isTreeMap({}), "평범한 테이블은 isTreeMap 이 아님")

	m:Set(3, "c")
	m:Set(1, "a")
	m:Set(2, "b")
	assert(keysOf(m) == "1,2,3", `정렬 순서가 아님: {keysOf(m)}`)
	assert(table.concat(m:Values(), ",") == "a,b,c", "값도 키 순서를 따라야 합니다")
	assert(m:Len() == 3, "크기")

	-- 맨 앞 / 중간 / 맨 뒤 삽입
	m:Set(0, "z")
	assert(keysOf(m) == "0,1,2,3", "맨 앞 삽입")
	m:Set(5, "e")
	assert(keysOf(m) == "0,1,2,3,5", "맨 뒤 삽입")
	m:Set(4, "d")
	assert(keysOf(m) == "0,1,2,3,4,5", "중간 삽입")

	-- 덮어쓰기는 크기를 안 올려야 합니다
	m:Set(2, "B")
	assert(m:Len() == 6 and m:Get(2) == "B", "덮어쓰기")
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
	assert(m:Get(2) == "b" and m:Get(9) == nil, "Get")
	assert(m:Has(1) and not m:Has(9), "Has")
	assert(m:GetOr(9, "기본") == "기본" and m:GetOr(1, "기본") == "a", "GetOr")
	assert(#m:Records() == 3 and m:Records()[1].key == 1, "Records 는 정렬 순서")
	-- Records 는 복사여야 합니다 — 받은 쪽이 건드려도 내부가 안 깨져야 합니다
	const snapshot = m:Records()
	table.remove(snapshot)
	assert(m:Len() == 3, "Records 는 복사를 돌려줘야 합니다")

	local iterKeys = ""
	for key, _value in m:Iter() do
		iterKeys ..= tostring(key)
	end
	assert(iterKeys == "123", `Iter 가 정렬 순서가 아님: {iterKeys}`)
	const emptyMap = TreeMap.New(Common.compareNumber) :: TreeMap<number, string>
	local emptyCount = 0
	for _k, _v in emptyMap:Iter() do
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
	assert(m:Len() == 1, "중복 키는 하나로 접혀야 합니다")
	assert(m:Get(1) == "마지막", `뒤엣것이 이겨야 합니다: {tostring(m:Get(1))}`)
	assert(TreeMap.FromRecords({}, Common.compareNumber):Len() == 0, "빈 입력")
end
print("PASS")

print("=== 4. 정렬이 있어야만 되는 것들 ===")
do
	const m = TreeMap.FromRecords({
		{ key = 10, value = "a" },
		{ key = 20, value = "b" },
		{ key = 30, value = "c" },
	}, Common.compareNumber)
	assert((m:First() :: any).key == 10, "First")
	assert((m:Last() :: any).key == 30, "Last")

	assert(m:FloorKey(20) == 20, "FloorKey 는 같은 값을 포함")
	assert(m:FloorKey(25) == 20, "FloorKey 사이 값")
	assert(m:FloorKey(30) == 30, "FloorKey 맨 뒤")
	assert(m:FloorKey(5) == nil, "FloorKey 전부보다 작으면 nil")
	assert(m:FloorKey(99) == 30, "FloorKey 전부보다 크면 마지막")

	assert(m:CeilingKey(20) == 20, "CeilingKey 는 같은 값을 포함")
	assert(m:CeilingKey(15) == 20, "CeilingKey 사이 값")
	assert(m:CeilingKey(10) == 10, "CeilingKey 맨 앞")
	assert(m:CeilingKey(99) == nil, "CeilingKey 전부보다 크면 nil")
	assert(m:CeilingKey(5) == 10, "CeilingKey 전부보다 작으면 첫째")

	assert(#m:RangeRecords(10, 20) == 2, "RangeRecords 양끝 포함")
	assert(#m:RangeRecords(15, 25) == 1, "RangeRecords 사이")
	assert(#m:RangeRecords(1, 99) == 3, "RangeRecords 전체")
	assert(#m:RangeRecords(25, 15) == 0, "RangeRecords 뒤집히면 빈 것")
	assert(#m:RangeRecords(40, 50) == 0, "RangeRecords 범위 밖")

	const empty = TreeMap.New(Common.compareNumber) :: TreeMap<number, string>
	assert(empty:First() == nil and empty:Last() == nil, "빈 맵의 First/Last")
	assert(empty:FloorKey(1) == nil and empty:CeilingKey(1) == nil, "빈 맵의 Floor/Ceiling")
end
print("PASS")

print("=== 5. Remove / Clear / Clone ===")
do
	const m = TreeMap.FromRecords({
		{ key = 1, value = "a" },
		{ key = 2, value = "b" },
		{ key = 3, value = "c" },
	}, Common.compareNumber)
	assert(m:Remove(2) == "b", "Remove 는 지워진 값을 돌려줍니다")
	assert(keysOf(m) == "1,3", "Remove 후 순서가 유지돼야 합니다")
	assert(m:Remove(2) == nil and m:Len() == 2, "없는 키 Remove")
	assert(m:Remove(1) == "a" and keysOf(m) == "3", "맨 앞 Remove")
	assert(m:Remove(3) == "c" and m:Empty(), "마지막 Remove")

	m:Set(7, "g")
	const cloned = m:Clone()
	cloned:Set(8, "h")
	cloned:Set(7, "바뀜")
	assert(m:Len() == 1 and cloned:Len() == 2, "Clone 은 독립적이어야 합니다")
	assert(m:Get(7) == "g", "Clone 은 레코드도 새로 만들어야 합니다")

	m:Clear()
	assert(m:Empty() and m:Get(7) == nil, "Clear")
	m:Set(1, "다시")
	assert(m:Len() == 1, "Clear 후 다시 쓸 수 있어야 합니다")
end
print("PASS")

print("=== 6. 문자열 키와 계약 ===")
do
	const m = TreeMap.FromRecords({
		{ key = "b", value = 2 },
		{ key = "a", value = 1 },
	}, Common.compareString)
	assert(table.concat(m:Keys(), ",") == "a,b", "문자열 비교자")
	-- 구현을 모르는 공용 알고리즘이 계약만으로 동작해야 합니다
	assert(#stl.Algorithm.Keys(m) == 2, "Algorithm.Keys")
	assert(#stl.Algorithm.Values(m) == 2, "Algorithm.Values")
end
print("PASS")

print("=== 7. 회귀 — 2026-09-30 리뷰 ===")
do
	-- (1) 무한대 키: compareNumber 가 a - b 이던 시절 inf - inf = NaN 이라 망가졌음
	const inf = TreeMap.New<<number, string>>(Common.compareNumber)
	inf:Set(math.huge, "a")
	inf:Set(math.huge, "b")
	inf:Set(-math.huge, "m")
	inf:Set(1, "x")
	assert(inf:Len() == 3, `무한대 키가 중복됨: {inf:Len()}`)
	assert(inf:Get(math.huge) == "b" and inf:Get(-math.huge) == "m", "무한대 키 조회")
	assert(inf:Remove(math.huge) == "b" and inf:Len() == 2, "무한대 키 삭제")

	-- (2) NaN 키는 시끄럽게 거절 — 조용히 넣으면 다른 키까지 망가졌음
	const n = TreeMap.New<<number, string>>(Common.compareNumber)
	n:Set(1, "one")
	assert(not pcall(function()
		n:Set(0 / 0, "nan")
	end), "NaN 키는 에러")
	assert(n:Len() == 1 and n:Get(1) == "one", "거절 뒤에도 멀쩡")
	assert(n:Get(0 / 0) == nil and not n:Has(0 / 0), "NaN 으로 조회하면 없음")
	assert(n:Remove(0 / 0) == nil and n:Len() == 1, "NaN 으로 삭제해도 아무 일 없음")
	assert(not pcall(function()
		TreeMap.FromRecords({ { key = 0 / 0, value = 1 } }, Common.compareNumber)
	end), "FromRecords 도 NaN 을 거절")

	-- (3) Set(k, nil) 은 삭제 — Lua 의 t[k] = nil 과 같음. HashMap 과 같은 규칙
	const z = TreeMap.New<<number, string?>>(Common.compareNumber)
	z:Set(1, "a")
	z:Set(1, nil)
	assert(z:Len() == 0 and not z:Has(1), "Set(k, nil) 은 삭제")
	z:Set(2, nil)
	assert(z:Len() == 0, "없는 키에 nil 은 아무 일 없음")

	-- Iter 가 키를 인덱스로 쓰던 버그 — 키가 1,2,3 이 아니면 드러남
	const far = TreeMap.New<<number, string>>(Common.compareNumber)
	far:Set(10, "a")
	far:Set(20, "b")
	far:Set(30, "c")
	local joined = ""
	for key, value in far:Iter() do
		joined ..= `{key}={value},`
	end
	assert(joined == "10=a,20=b,30=c,", `키 10/20/30 의 Iter: {joined}`)
	const words = TreeMap.New<<string, number>>(Common.compareString)
	words:Set("y", 2)
	words:Set("x", 1)
	local order = ""
	for key in words:Iter() do
		order ..= key
	end
	assert(order == "xy", `문자열 키의 Iter: {order}`)

	-- (6) 내준 레코드를 고쳐도 맵은 멀쩡 — 레코드까지 복사본
	const r = TreeMap.New<<number, string>>(Common.compareNumber)
	r:Set(1, "a")
	r:Set(2, "b")
	r:Set(3, "c")
	r:Records()[1].key = 99
	const firstRec: any = r:First()
	firstRec.key = 50
	r:RangeRecords(2, 3)[1].value = "Z"
	const lastRec: any = r:Last()
	lastRec.value = "X"
	assert(r:Get(1) == "a" and r:Get(2) == "b" and r:Get(3) == "c", "레코드를 고쳐도 맵은 그대로")
	assert(r:Len() == 3, "크기도 그대로")
end
print("PASS")

print()
print("=== ALL PASS (TreeMap) ===")

return true

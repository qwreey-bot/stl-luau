--!strict
--[[
	Arr 테스트.

	프레임워크 없음 — `assert` + `print` 입니다. 실패하면 그 자리에서 터지고
	luau 가 exit 1 로 끝납니다.

	⭐ **경계 케이스를 반드시 같이 고정합니다.** 이 저장소는 범위를 벗어나도
	예외를 던지지 않고 조용히 clamp 하는 Lua 관례를 따르므로, 테스트가 없으면
	"조용히 아무것도 안 함" 과 "조용히 망가짐" 을 구분할 수 없습니다. 매 절에
	빈 것 / 1개 / 뒤집힌 구간 / 범위 초과 / 음수 인덱스를 넣으세요.
]]
local stl = require("../src")
local Arr = stl.Arr
local Common = stl.Common

type Arr<T> = stl.Arr<T>
type ArrView<T> = stl.ArrView<T>

-- 배열의 내용이 기대한 목록과 같은지. `n` 도 같이 봅니다.
local function same<T>(actual: Arr<T>, expected: { T }, label: string)
	assert(actual.n == #expected, `{label}: n 이 {actual.n} 인데 {#expected} 를 기대했습니다`)
	for idx = 1, #expected do
		assert(
			actual[idx] == expected[idx],
			`{label}: [{idx}] 이 {tostring(actual[idx])} 인데 {tostring(expected[idx])} 를 기대했습니다`
		)
	end
end

-- 빈 배열은 원소 타입을 추론할 수 없어 `Arr<unknown>` 이 됩니다. 테스트에서는
-- 타입이 박힌 빈 배열이 필요하므로 `Sized(0, 씨앗)` 으로 만듭니다.
local function emptyNum(): Arr<number>
	return Arr.Sized(0, 0)
end

print("=== 1. 생성자 ===")
same(Arr.Of(1, 2, 3), { 1, 2, 3 }, "Of")
assert(emptyNum().n == 0, "Of 빈 것")
assert(Arr.Of(1, nil, 3).n == 3, "Of 는 인자 사이의 nil 을 보존해야 합니다")
same(Arr.Sized(3, 0), { 0, 0, 0 }, "Sized")
assert(Arr.Sized(0, 0).n == 0, "Sized 0")
do
	-- 구멍으로 시작하려면 타입에 드러냅니다(질문 T (b)). 칸은 전부 구멍이고
	-- 콜백 계열은 그걸 `nil` 로 받습니다 — 타입이 `number?` 라 건전합니다.
	const holes = Arr.Sized<<number?>>(3, nil)
	assert(holes.n == 3 and holes[1] == nil and holes[3] == nil, "Sized 구멍")
	const seen = Arr.Map(holes, function(v: number?): number
		return if v == nil then -1 else v
	end)
	same(seen, { -1, -1, -1 }, "구멍은 콜백에 nil 로 넘어감")
end
same(Arr.FromTable({ 4, 5 }), { 4, 5 }, "FromTable")
same(Arr.CloneFromTable({ 6, 7 }), { 6, 7 }, "CloneFromTable")
same(
	Arr.FromFunc(3, function(i)
		return i * i
	end),
	{ 1, 4, 9 },
	"FromFunc"
)
same(Arr.Concat(Arr.Of(1), Arr.Of(2, 3), emptyNum()), { 1, 2, 3 }, "Concat")
same(Arr.Concat(), {}, "Concat 인자 없음")
same(Arr.Range(1, 5), { 1, 2, 3, 4, 5 }, "Range")
same(Arr.Range(5, 1), {}, "Range 방향이 안 맞으면 빈 것")
same(Arr.Range(1, 7, 3), { 1, 4, 7 }, "Range step")
same(Arr.Range(3, 3), { 3 }, "Range 한 칸")
assert(not pcall(Arr.Range, 1, 5, 0), "Range step 0 은 에러여야 합니다")
-- FromTable 은 입양(복사 안 함), CloneFromTable 은 복사
local adopted = { 1, 2 }
local viaAdopt = Arr.FromTable(adopted)
adopted[1] = 99
assert(viaAdopt[1] == 99, "FromTable 은 원본 테이블을 입양해야 합니다")
local cloned = { 1, 2 }
local viaClone = Arr.CloneFromTable(cloned)
cloned[1] = 99
assert(viaClone[1] == 1, "CloneFromTable 은 복사해야 합니다")
-- Sized 의 fill 공유 함정이 문서대로인지
local shared = Arr.Sized(2, {} :: { number })
assert(shared[1] == shared[2], "Sized 의 fill 은 같은 참조를 공유합니다(문서화된 동작)")
print("PASS")

print("=== 2. 술어와 조회 ===")
assert(stl.isArr(Arr.Of(1)), "isArr")
assert(not stl.isArr({ 1, 2 }), "평범한 테이블은 isArr 가 아님")
assert(not stl.isArr(nil), "nil 은 isArr 가 아님")
assert(not stl.isArr(42), "숫자는 isArr 가 아님")
assert(Arr.Of(1, 2):Len() == 2, "Len")
assert(emptyNum():Empty(), "Empty")
assert(not Arr.Of(1):Empty(), "Empty 아님")
assert(Arr.Of(1, 2, 3):Join("-") == "1-2-3", "Join")
assert(emptyNum():Join("-") == "", "Join 빈 것")
assert(Arr.Of(1):Join("-") == "1", "Join 한 개")
assert(Arr.Of(1, 2, 3):Equal(Arr.Of(1, 2, 3)), "Equal")
assert(not Arr.Of(1, 2):Equal(Arr.Of(1, 2, 3)), "Equal 길이 다름")
assert(not Arr.Of(1, 2):Equal(Arr.Of(1, 9)), "Equal 내용 다름")
do
	local a, b, c = Arr.Of(1, 2, 3):Unpack()
	assert(a == 1 and b == 2 and c == 3, "Unpack")
end
print("PASS")

print("=== 3. 계약 (ListCore) 과 Iter ===")
do
	local a = Arr.Of(10, 20, 30)
	assert(a:FirstIndex() == 1 and a:LastIndex() == 3, "First/LastIndex")
	assert(a:NextIndex(1) == 2 and a:NextIndex(3) == nil, "NextIndex")
	assert(a:PrevIndex(3) == 2 and a:PrevIndex(1) == nil, "PrevIndex")
	assert(a:Get(2) == 20 and a:Get(9) == nil, "Get")
	assert(emptyNum():FirstIndex() == nil, "빈 것의 FirstIndex 는 nil")

	local seenIdx, seenSum = 0, 0
	for i, v in a:Iter() do
		seenIdx += i
		seenSum += v
	end
	assert(seenIdx == 6 and seenSum == 60, "Iter 가 전부 돌아야 합니다")
	local emptyCount = 0
	for _i, _v in emptyNum():Iter() do
		emptyCount += 1
	end
	assert(emptyCount == 0, "빈 것의 Iter 는 한 번도 안 돌아야 합니다")

	-- 공용 알고리즘이 구현을 모른 채 계약만으로 동작하는지
	assert(stl.Algorithm.IndexOf(a, 20) == 2, "Algorithm.IndexOf")
	assert(stl.Algorithm.IndexOf(a, 99) == nil, "Algorithm.IndexOf 없음")
	assert(stl.Algorithm.Count(a) == 3, "Algorithm.Count")
end
print("PASS")

print("=== 4. 추가 (PushBack / PushFront / Insert) ===")
same(Arr.Of(1):PushBack(2), { 1, 2 }, "PushBack")
same(Arr.Of(1):PushBackMany(2, 3), { 1, 2, 3 }, "PushBackMany")
same(Arr.Of(1):PushBackMany(), { 1 }, "PushBackMany 인자 없음")
same(Arr.Of(1):PushBackArray(Arr.Of(2, 3)), { 1, 2, 3 }, "PushBackArray")
same(Arr.Of(1):PushBackArray(emptyNum()), { 1 }, "PushBackArray 빈 것")
same(Arr.Of(2):PushFront(1), { 1, 2 }, "PushFront")
same(Arr.Of(3):PushFrontMany(1, 2), { 1, 2, 3 }, "PushFrontMany 는 인자 순서를 보존")
same(Arr.Of(3):PushFrontArray(Arr.Of(1, 2)), { 1, 2, 3 }, "PushFrontArray")
same(emptyNum():PushFront(1), { 1 }, "빈 것에 PushFront")
-- ⭐ 삽입 위치의 유효 범위는 1 .. n+1 — 맨 뒤 삽입이 표현 가능해야 합니다
same(Arr.Of(1, 3):Insert(2, 2), { 1, 2, 3 }, "Insert 중간")
same(Arr.Of(1, 2):Insert(3, 3), { 1, 2, 3 }, "Insert 맨 뒤 (n+1)")
same(Arr.Of(1, 2):Insert(99, 3), { 1, 2, 3 }, "Insert 범위 초과는 맨 뒤로 clamp")
same(Arr.Of(2, 3):Insert(1, 1), { 1, 2, 3 }, "Insert 맨 앞")
same(Arr.Of(2, 3):Insert(-99, 1), { 1, 2, 3 }, "Insert 음수 초과는 맨 앞으로 clamp")
same(Arr.Of(1, 3):Insert(-1, 2), { 1, 2, 3 }, "Insert 음수는 끝에서부터")
same(emptyNum():Insert(1, 1), { 1 }, "빈 것에 Insert")
same(Arr.Of(1, 4):InsertMany(2, 2, 3), { 1, 2, 3, 4 }, "InsertMany")
same(Arr.Of(1, 4):InsertArray(2, Arr.Of(2, 3)), { 1, 2, 3, 4 }, "InsertArray")
same(Arr.Of(1):InsertMany(1), { 1 }, "InsertMany 인자 없음")
print("PASS")

print("=== 5. 복제 / 비우기 / 채우기 ===")
do
	local a = Arr.Of(1, 2, 3)
	local b = a:Clone()
	b[1] = 99
	assert(a[1] == 1, "Clone 은 독립적이어야 합니다")
	same(b, { 99, 2, 3 }, "Clone 내용")

	local c = Arr.Of(1, 2, 3):Clear()
	assert(c.n == 0, "Clear 는 n 을 0 으로")
	assert(c[1] == nil, "Clear 는 내용을 지움")
	-- ⭐ table.clear 로 지우면 태그까지 날아가 isArr 를 통과 못 하던 버그
	assert(stl.isArr(c), "Clear 후에도 isArr 여야 합니다")
	same(c:PushBack(7), { 7 }, "Clear 후 다시 쓸 수 있어야 합니다")
end
same(Arr.Sized(3, 0):Fill(9), { 9, 9, 9 }, "Fill 전체")
same(Arr.Of(1, 2, 3):Fill(9, 2), { 1, 9, 9 }, "Fill start 부터")
same(Arr.Of(1, 2, 3):Fill(9, 2, 2), { 1, 9, 3 }, "Fill 한 칸")
same(Arr.Of(1, 2, 3):Fill(9, 3, 1), { 1, 2, 3 }, "Fill 뒤집힌 구간은 아무것도 안 함")
same(Arr.Of(1, 2, 3):Fill(9, -1), { 1, 2, 9 }, "Fill 음수 start")
same(Arr.Of(1, 2, 3):Fill(9, 1, 99), { 9, 9, 9 }, "Fill 범위 초과는 clamp")
print("PASS")

print("=== 5b. At — 음수를 받는 단일 조회 ===")
do
	const a = Arr.Of(10, 20, 30)
	assert(a:At(1) == 10 and a:At(3) == 30, "At 양수")
	assert(Arr.At(a, -1) == 30 and Arr.At(a, -3) == 10, "At 음수는 뒤에서")
	-- 범위 밖은 clamp 하지 않고 nil — 단일 조회라 "가장 가까운 것" 은 거짓말입니다
	assert(a:At(0) == nil and a:At(4) == nil and a:At(-4) == nil, "At 범위 밖은 nil")
	-- 소수는 구간 규약처럼 0 쪽으로 자릅니다
	assert(a:At(2.7) == 20 and a:At(-1.5) == 30, "At 소수는 0 쪽으로")
	assert(emptyNum():At(1) == nil and emptyNum():At(-1) == nil, "빈 것의 At")
	-- 구멍은 nil 로 — 타입이 T? 라 정직합니다
	assert(Arr.Of<<number?>>(10, nil, 30):At(-2) == nil, "At 구멍")
end
print("PASS")

print("=== 6. 구간 — Slice / Erase / Splice ===")
same(Arr.Of(1, 2, 3, 4):Slice(2, 3), { 2, 3 }, "Slice 닫힌 구간")
same(Arr.Of(1, 2, 3, 4):Slice(), { 1, 2, 3, 4 }, "Slice 인자 없으면 전체")
same(Arr.Of(1, 2, 3, 4):Slice(-2), { 3, 4 }, "Slice 음수 start")
same(Arr.Of(1, 2, 3, 4):Slice(2, -1), { 2, 3, 4 }, "Slice 음수 last")
same(Arr.Of(1, 2, 3, 4):Slice(3, 2), {}, "Slice 뒤집힌 구간은 빈 결과")
same(Arr.Of(1, 2, 3, 4):Slice(0, 99), { 1, 2, 3, 4 }, "Slice 범위 초과는 clamp")
same(emptyNum():Slice(1, 3), {}, "빈 것의 Slice")
-- to 는 "목적지 뒤에 이어붙이기" 입니다
same(Arr.Of(3, 4):Slice(1, 2, Arr.Of(1, 2)), { 1, 2, 3, 4 }, "Slice to 는 뒤에 이어붙임")
same(Arr.Of(1, 2, 3, 4):SliceInplace(2, 3), { 2, 3 }, "SliceInplace")
same(Arr.Of(1, 2, 3):SliceInplace(3, 1), {}, "SliceInplace 뒤집힌 구간은 비움")

same(Arr.Of(1, 2, 3, 4):Erase(2, 3), { 1, 4 }, "Erase")
same(Arr.Of(1, 2, 3):Erase(3, 1), { 1, 2, 3 }, "Erase 뒤집힌 구간은 그대로")
same(Arr.Of(1, 2, 3):Erase(), {}, "Erase 인자 없으면 전부")
same(Arr.Of(1, 2, 3, 4):EraseInplace(2, 3), { 1, 4 }, "EraseInplace")
-- ⭐ 가드가 없으면 배열이 오히려 늘어나던 버그
do
	local a = Arr.Of(1, 2, 3):EraseInplace(3, 1)
	assert(a.n == 3, `EraseInplace 뒤집힌 구간에서 n 이 {a.n} 으로 늘어났습니다`)
end
same(Arr.Of(1, 2, 3):EraseInplace(), {}, "EraseInplace 전부")
same(Arr.Of(1, 2, 3):EraseInplace(-1), { 1, 2 }, "EraseInplace 음수")

same(Arr.Of(1, 2, 3, 4):Splice(2, 3, Arr.Of(9)), { 1, 9, 4 }, "Splice 줄어듦")
same(Arr.Of(1, 2, 4):Splice(2, 2, Arr.Of(8, 9)), { 1, 8, 9, 4 }, "Splice 늘어남")
same(Arr.Of(1, 2, 3):Splice(2, 2, emptyNum()), { 1, 3 }, "Splice 빈 것으로 = 삭제")
same(Arr.Of(1, 2, 3, 4):SpliceInplace(2, 3, Arr.Of(9)), { 1, 9, 4 }, "SpliceInplace 줄어듦")
same(Arr.Of(1, 2, 4):SpliceInplace(2, 2, Arr.Of(8, 9)), { 1, 8, 9, 4 }, "SpliceInplace 늘어남")
print("PASS")

print("=== 7. 순서 — Reverse / Rotate / Shuffle / Sort ===")
same(Arr.Of(1, 2, 3):Reverse(), { 3, 2, 1 }, "Reverse")
same(Arr.Of(1, 2, 3, 4):Reverse(2, 3), { 1, 3, 2, 4 }, "Reverse 구간")
same(Arr.Of(1):Reverse(), { 1 }, "Reverse 한 개")
same(emptyNum():Reverse(), {}, "Reverse 빈 것")
do
	local a = Arr.Of(1, 2, 3)
	local b = a:Reverse()
	assert(a[1] == 1, "Reverse 는 원본을 건드리지 않아야 합니다")
	same(b, { 3, 2, 1 }, "Reverse 결과")
end
same(Arr.Of(1, 2, 3):ReverseInplace(), { 3, 2, 1 }, "ReverseInplace")
-- 양수 shift 가 왼쪽 회전 (std::rotate 방향)
same(Arr.Of(1, 2, 3, 4):Rotate(1), { 2, 3, 4, 1 }, "Rotate 왼쪽")
same(Arr.Of(1, 2, 3, 4):Rotate(-1), { 4, 1, 2, 3 }, "Rotate 음수는 오른쪽")
same(Arr.Of(1, 2, 3, 4):Rotate(4), { 1, 2, 3, 4 }, "Rotate 한 바퀴")
same(Arr.Of(1, 2, 3, 4):Rotate(5), { 2, 3, 4, 1 }, "Rotate 는 나머지만 의미")
same(Arr.Of(1, 2, 3, 4):Rotate(1, 2, 3), { 1, 3, 2, 4 }, "Rotate 구간")
same(Arr.Of(1):Rotate(1), { 1 }, "Rotate 한 개")
same(emptyNum():Rotate(1), {}, "Rotate 빈 것")
do
	-- rng 를 주입해 결정적으로 만듭니다
	local a = Arr.Of(1, 2, 3, 4, 5)
	local b = a:Shuffle(nil, nil, function(min: number, _max: number)
		return min
	end)
	assert(b.n == 5, "Shuffle 은 길이를 보존")
	assert(a:Sort():Equal(b:Sort()), "Shuffle 은 원소 집합을 보존")
	assert(a[1] == 1, "Shuffle 은 원본을 건드리지 않아야 합니다")
end
same(Arr.Of(3, 1, 2):Sort(), { 1, 2, 3 }, "Sort 기본")
same(
	Arr.Of(3, 1, 2):Sort(function(a: number, b: number)
		return a > b
	end),
	{ 3, 2, 1 },
	"Sort 불리언 비교자"
)
same(Arr.Of(3, 1, 2):Sort(Common.lessFrom(Common.compareNumber)), { 1, 2, 3 }, "Sort 3방향 어댑터")
same(emptyNum():Sort(), {}, "Sort 빈 것")
same(Arr.Of(1):Sort(), { 1 }, "Sort 한 개")
same(Arr.Of(3, 1, 2):SortInplace(), { 1, 2, 3 }, "SortInplace")
-- ⭐ 구멍은 정렬 대상에서 빠지고 뒤로 몰리며 n 은 보존됩니다
do
	local holey: Arr<number> = Arr.Of(3, nil :: any, 1)
	local sorted = holey:Sort()
	assert(sorted.n == 3, "Sort 는 n 을 보존")
	assert(sorted[1] == 1 and sorted[2] == 3 and sorted[3] == nil, "Sort 는 구멍을 뒤로 몰아야 합니다")
end
print("PASS")

print("=== 8. 스트림 — Map / Filter / Flat / Drain ===")
same(
	Arr.Of(1, 2, 3):Map(function(v: number)
		return v * 2
	end),
	{ 2, 4, 6 },
	"Map"
)
same(
	emptyNum():Map(function(v: number)
		return v
	end),
	{},
	"Map 빈 것"
)
same(
	-- 콜백 주석이 필요합니다 — 셋째 인자가 `ArrView<any>` 라 `to` 와 함께
	-- 넘기면 `T` 를 붙잡을 단서가 없습니다(질문 V 의 대가).
	Arr.Of(1, 2):Map(function(v: number)
		return v
	end, Arr.Of(0)),
	{ 0, 1, 2 },
	"Map to 는 뒤에 이어붙임"
)
-- Map 은 콜백에 (원소, 위치, 뷰) 를 줍니다
same(
	Arr.Of(10, 20):Map(function(v: number, idx: number, arr: ArrView<number>)
		return v + idx + arr.n
	end),
	{ 13, 24 },
	"Map 콜백 인자"
)
same(
	Arr.Of(1, 2, 3):MapInplace(function(v: number)
		return v * 10
	end),
	{ 10, 20, 30 },
	"MapInplace"
)
same(
	Arr.Of(1, 2, 3, 4):Filter(function(v: number)
		return v % 2 == 0
	end),
	{ 2, 4 },
	"Filter"
)
same(
	Arr.Of(1, 2, 3, 4):Retain(function(v: number)
		return v % 2 == 0
	end),
	{ 2, 4 },
	"Retain"
)
same(
	Arr.Of(1, 2, 3):Retain(function()
		return false
	end),
	{},
	"Retain 전부 버림"
)
do
	local nested = Arr.Of(1, Arr.Of(2, 3) :: any, 4)
	const flat = nested:Flat() :: Arr<number>
	same(flat, { 1, 2, 3, 4 }, "Flat")
end
do
	local nested = Arr.Of(emptyNum() :: any, 1, Arr.Of(2) :: any)
	const flat = nested:Flat() :: Arr<number>
	same(flat, { 1, 2 }, "Flat 빈 중첩")
end
do
	local nested = Arr.Of(1, Arr.Of(2, 3) :: any, 4)
	const flat = nested:FlatInplace() :: Arr<number>
	same(flat, { 1, 2, 3, 4 }, "FlatInplace")
end
do
	local nested = Arr.Of(emptyNum() :: any, 1)
	const flat = nested:FlatInplace() :: Arr<number>
	same(flat, { 1 }, "FlatInplace 빈 중첩")
end
same(
	Arr.Of(1, 2):Flatmap(function(v: number)
		return v, v * 10
	end),
	{ 1, 10, 2, 20 },
	"Flatmap"
)
same(
	Arr.Of(1, 2):FlatmapInplace(function(v: number)
		return v, v * 10
	end),
	{ 1, 10, 2, 20 },
	"FlatmapInplace"
)
do
	local a = Arr.Of(1, 2, 3)
	local seen = 0
	a:Drain(function(v: number)
		seen += v
		return nil
	end)
	assert(seen == 6, "Drain 은 전부 순회")
	assert(a.n == 0 and a[1] == nil, "Drain 은 비워야 합니다")
end
same(Arr.Of(1):ConcatInplace(Arr.Of(2), Arr.Of(3, 4)), { 1, 2, 3, 4 }, "ConcatInplace")
same(Arr.Of(1):ConcatInplace(), { 1 }, "ConcatInplace 인자 없음")
print("PASS")

print("=== 9. 조건 조회 — Count / Find / Some / Every ===")
assert(Arr.Of(1, 2, 3, 4):Count(function(v: number)
	return v % 2 == 0
end) == 2, "Count")
do
	local item, idx = Arr.Of(1, 2, 3):Find(function(v)
		return v > 1
	end)
	assert(item == 2 and idx == 2, "Find")
	local none, noneIdx = Arr.Of(1):Find(function()
		return false
	end)
	assert(none == nil and noneIdx == nil, "Find 없음")
end
assert(
	Arr.Of(1, 2):Some(function(v)
		return v == 2
	end),
	"Some"
)
assert(not Arr.Of(1, 2):Some(function(v)
	return v == 9
end), "Some 없음")
assert(
	Arr.Of(2, 4):Every(function(v: number)
		return v % 2 == 0
	end),
	"Every"
)
assert(not Arr.Of(2, 3):Every(function(v: number)
	return v % 2 == 0
end), "Every 아님")
assert(
	emptyNum():Every(function(v: number)
		return false
	end),
	"빈 것의 Every 는 공허 참"
)
assert(not Arr.Of(1, 2, 3):Some(function(v)
	return v == 1
end, 2), "Some 구간 — start 앞의 원소는 안 봐야 합니다")
assert(
	Arr.Of(1, 2, 3):Some(function(v)
		return v == 3
	end, 2),
	"Some 구간 — start 뒤의 원소는 봐야 합니다"
)
assert(not Arr.Of(1, 2, 3):Every(function(v)
	return v == 1
end, 2), "Every 구간")
print("PASS")

print("=== 10. 집계 — Max / Min / Sum / Prod ===")
assert(Arr.Of(3, 1, 2):Max() == 3, "Max")
assert(Arr.Of(3, 1, 2):Min() == 1, "Min")
assert(emptyNum():Max() == nil, "빈 것의 Max 는 nil")
assert(emptyNum():Min() == nil, "빈 것의 Min 은 nil")
assert(Arr.Of(1):Max() == 1, "Max 한 개")
assert(Arr.Of("b", "a"):Max() == "b", "Max 는 문자열에도 동작")
assert(Arr.Of(3, 1, 2):Max(function(a: number, b: number)
	return a > b
end) == 1, "Max 비교자를 뒤집으면 최소가 나옴")
assert(Arr.Of(1, 2, 3):Sum() == 6, "Sum")
assert(emptyNum():Sum() == 0, "빈 것의 Sum 은 0")
assert(Arr.Of(1, 2):Sum(10) == 13, "Sum 씨앗")
assert(Arr.Of(2, 3):Prod() == 6, "Prod")
assert(emptyNum():Prod() == 1, "빈 것의 Prod 는 1")
-- ⭐ 구멍에서 터지지 않아야 합니다
do
	local holey: Arr<number> = Arr.Of(1, nil :: any, 3)
	assert(holey:Sum() == 4, "Sum 은 구멍을 건너뜀")
	assert(holey:Prod() == 3, "Prod 는 구멍을 건너뜀")
	assert(holey:Max() == 3, "Max 는 구멍을 건너뜀")
	assert(holey:Min() == 1, "Min 은 구멍을 건너뜀")
	assert(holey:Join("-") == "1-3", "Join 은 구멍을 건너뜀")
end
print("PASS")

print("=== 11. 접기 — Fold / FoldRight / Reduce / FoldUntil ===")
assert(Arr.Of(1, 2, 3):Fold(0, function(acc, v)
	return acc + v
end) == 6, "Fold")
assert(emptyNum():Fold(7, function(acc: number, v: number)
	return acc + v
end) == 7, "빈 것의 Fold 는 초기값")
assert(Arr.Of("a", "b", "c"):FoldRight("", function(acc, v)
	return acc .. v
end) == "cba", "FoldRight 는 오른쪽부터")
assert(Arr.Of(1, 2, 3):Reduce(function(a, b)
	return a + b
end) == 6, "Reduce")
assert(Arr.Of(5):Reduce(function(a, b)
	return a + b
end) == 5, "Reduce 한 개는 그 원소")
assert(emptyNum():Reduce(function(a: number, b: number)
	return a + b
end) == nil, "빈 것의 Reduce 는 nil")
do
	local acc, stopped = Arr.Of(1, 2, 3, 4):FoldUntil(0, function(a: number, v: number)
		return a + v, v >= 3
	end)
	assert(acc == 6 and stopped == 3, `FoldUntil: acc={acc} stopped={tostring(stopped)}`)
	local full, notStopped = Arr.Of(1, 2):FoldUntil(0, function(a, v)
		return a + v, false
	end)
	assert(full == 3 and notStopped == nil, "완주하면 둘째가 nil")
end
print("PASS")

print("=== 12. 체이닝과 뷰 ===")
do
	-- 3단 타입 변환 체이닝
	local result = Arr.Of(1, 2, 3)
		:Map(function(v)
			return tostring(v)
		end)
		:Map(function(s: string)
			return #s
		end)
		:Filter(function(n)
			return n == 1
		end)
	same(result, { 1, 1, 1 }, "3단 체이닝")
	-- 콜백 안에서 뷰 메소드
	local viewed = Arr.Of(1, 2):Map(function(v: number, idx: number, arr: ArrView<number>)
		return v + arr:Len() + arr:Slice(1, idx):Len()
	end)
	same(viewed, { 4, 6 }, "콜백 안에서 뷰 메소드")
end
print("PASS")

print("=== 13. FromIter / 제자리 순서 연산 ===")
do
	-- 값이 둘이면 둘째가 값, 하나면 그것이 값입니다.
	-- ⚠️ 이터레이터를 any 로 받으므로 원소 타입은 캐스트로 적어야 합니다.
	same(Arr.FromIter(ipairs({ 10, 20, 30 })) :: Arr<number>, { 10, 20, 30 }, "FromIter(ipairs)")
	const dict: { [string]: number } = { only = 7 }
	same(Arr.FromIter(pairs(dict)) :: Arr<number>, { 7 }, "FromIter(pairs) 는 값을 모음")
	same(Arr.FromIter(string.gmatch("a bb ccc", "%a+")) :: Arr<string>, { "a", "bb", "ccc" }, "FromIter(gmatch)")
	same(Arr.FromIter(ipairs({})) :: Arr<number>, {}, "FromIter 빈 것")
end
do
	-- 제자리 판은 자기 자신을 돌려주고 원본이 바뀌어야 합니다.
	const a: Arr<number> = Arr.Of(1, 2, 3, 4)
	const rotated = a:RotateInplace(1)
	assert(rotated == a, "RotateInplace 는 자기 자신을 돌려줍니다")
	same(a, { 2, 3, 4, 1 }, "RotateInplace 왼쪽")
	a:RotateInplace(-1)
	same(a, { 1, 2, 3, 4 }, "RotateInplace 음수는 오른쪽")
	a:RotateInplace(1, 2, 3)
	same(a, { 1, 3, 2, 4 }, "RotateInplace 구간")
	same(Arr.Of(1):RotateInplace(1), { 1 }, "RotateInplace 한 개")
	same(emptyNum():RotateInplace(1), {}, "RotateInplace 빈 것")

	const b: Arr<number> = Arr.Of(1, 2, 3, 4, 5)
	const shuffled = b:ShuffleInplace(nil, nil, function(min: number, _max: number)
		return min
	end)
	assert(shuffled == b, "ShuffleInplace 는 자기 자신을 돌려줍니다")
	assert(b.n == 5, "ShuffleInplace 는 길이를 보존")
	same(b:Sort(), { 1, 2, 3, 4, 5 }, "ShuffleInplace 는 원소 집합을 보존")
	same(emptyNum():ShuffleInplace(), {}, "ShuffleInplace 빈 것")
end
print("PASS")

print("=== 14. ⚠️ unchecked 계열 ===")
do
	-- 구멍이 없으면 checked 와 **같은 답**이 나와야 합니다.
	const dense: Arr<number> = Arr.Of(3, 1, 2)
	assert(dense:SumUnchecked() == dense:Sum(), "SumUnchecked 는 같은 답")
	assert(dense:ProdUnchecked() == dense:Prod(), "ProdUnchecked 는 같은 답")
	assert(dense:MaxUnchecked() == dense:Max(), "MaxUnchecked 는 같은 답")
	assert(dense:MinUnchecked() == dense:Min(), "MinUnchecked 는 같은 답")
	assert(dense:SortUnchecked():Equal(dense:Sort()), "SortUnchecked 는 같은 답")
	assert(dense:SumUnchecked(10) == 16, "SumUnchecked 씨앗")
	assert(dense:ProdUnchecked(2) == 12, "ProdUnchecked 씨앗")

	-- 비교자를 준 경로도 같아야 합니다
	const desc = function(a: number, b: number): boolean
		return a > b
	end
	assert(dense:MaxUnchecked(desc) == dense:Max(desc), "MaxUnchecked 비교자")
	assert(dense:MinUnchecked(desc) == dense:Min(desc), "MinUnchecked 비교자")
	same(dense:SortUnchecked(desc), { 3, 2, 1 }, "SortUnchecked 비교자")

	-- 빈 것과 한 개
	assert(emptyNum():MaxUnchecked() == nil, "빈 것의 MaxUnchecked")
	assert(emptyNum():MinUnchecked() == nil, "빈 것의 MinUnchecked")
	assert(emptyNum():SumUnchecked() == 0, "빈 것의 SumUnchecked")
	assert(emptyNum():ProdUnchecked() == 1, "빈 것의 ProdUnchecked")
	assert(Arr.Of(5):MaxUnchecked() == 5, "한 개의 MaxUnchecked")
	same(emptyNum():SortUnchecked(), {}, "빈 것의 SortUnchecked")

	-- 제자리 판은 자기 자신을 돌려줍니다
	const target: Arr<number> = Arr.Of(3, 1, 2)
	assert(target:SortInplaceUnchecked() == target, "SortInplaceUnchecked 는 자기 자신")
	same(target, { 1, 2, 3 }, "SortInplaceUnchecked 결과")

	-- ⚠️ **구멍이 있을 때 문서대로 망가지는지**를 고정합니다. 이걸 고정해두지
	-- 않으면 나중에 누가 "안전하게" 고쳐서 unchecked 의 존재 이유가 사라집니다.
	const holed = (Arr.Sized<<number?>>(3, nil) :: any) :: Arr<number>
	holed[1], holed[3] = 1, 3
	assert(not pcall(function()
		return holed:SumUnchecked()
	end), "SumUnchecked 는 구멍에서 터져야 합니다")
	assert(not pcall(function()
		return holed:MaxUnchecked()
	end), "MaxUnchecked 는 구멍에서 터져야 합니다")
	-- 반면 checked 는 멀쩡해야 합니다
	assert(holed:Sum() == 4 and holed:Max() == 3, "checked 는 구멍에서 멀쩡")
	-- 정렬만은 터지지 않고 **조용히** 다르게 동작합니다 — 그게 가장 위험한 점
	const holedSorted = (Arr.Sized<<number?>>(3, nil) :: any) :: Arr<number>
	holedSorted[1], holedSorted[3] = 1, 3
	assert(
		pcall(function()
			return holedSorted:SortInplaceUnchecked()
		end),
		"SortInplaceUnchecked 는 구멍에서도 터지지 않습니다 (조용히 다름)"
	)
end
print("PASS")

print("=== 15. 원소가 유니온인 배열 ===")
do
	-- ⭐ self 를 전체형으로 받던 시절엔 이 절 전체가 타입 에러였습니다(spikes/46).
	local maybe = Arr.Of<<number?>>(1, nil, 3)
	assert(maybe.n == 3, "n 은 구멍을 포함")
	const kept = maybe:Filter(function(v: number?)
		return v ~= nil
	end)
	assert(kept.n == 2, "Filter 가 구멍을 거름")
	const filled = maybe:Map(function(v: number?): number
		return v or 0
	end)
	same(filled, { 1, 0, 3 }, "Map 으로 구멍을 메움")
	assert(maybe:Count(function(v: number?)
		return v == nil
	end) == 1, "Count")
end
print("PASS")

print("=== 16. 회귀 — 2026-09-30 리뷰 ===")
do
	-- (1) Splice 의 시작점이 n+1 을 넘으면 n 바깥에 쓰던 것 — 삽입 위치처럼 1..n+1 로
	same(Arr.Of(1, 2, 3):Splice(10, 12, Arr.Of(9)), { 1, 2, 3, 9 }, "Splice 시작점이 n+1 초과")
	do
		const a: Arr<number> = Arr.Of(1, 2, 3)
		a:SpliceInplace(5, 4, Arr.Of(9))
		same(a, { 1, 2, 3, 9 }, "SpliceInplace 시작점이 n+1 초과")
		assert(a[5] == nil, "n 밖에 남은 값이 없어야 함")
	end
	same(Arr.Of(1, 2, 3):Splice(4, 3, Arr.Of(9)), { 1, 2, 3, 9 }, "Splice 시작점이 정확히 n+1")

	-- (3) 정수가 아닌 인덱스는 Luau 처럼 0 쪽으로 자른다 (string.sub("abc", 1.5) == "abc")
	same(Arr.Of(1, 2, 3, 4):Rotate(1.5), { 2, 3, 4, 1 }, "Rotate 1.5 는 1")
	same(Arr.Of(1, 2, 3, 4, 5):Rotate(2.5), { 3, 4, 5, 1, 2 }, "Rotate 2.5 는 2")
	same(Arr.Of(1, 2, 3, 4):Slice(1.5, 3.9), { 1, 2, 3 }, "Slice 소수 구간")
	same(Arr.Of(1, 2, 3, 4):Slice(-1.5), { 4 }, "Slice 음수 소수는 0 쪽으로(-1)")
	same(Arr.Of(1, 3):Insert(1.9, 0), { 0, 1, 3 }, "Insert 소수 위치")
	assert(not pcall(function()
		return Arr.Of(1, 2):Rotate(math.huge)
	end), "Rotate 무한대는 에러")

	-- (4) Range 는 Lua 의 for 와 같게 — 소수 step 에서 끝점이 빠질 수 있음(문서화)
	assert(Arr.Range(0, 0.3, 0.1).n == 3, "Range(0, 0.3, 0.1) 은 for 루프처럼 3개")
	assert(not pcall(Arr.Range, 1, 5, math.huge), "무한대 step 은 에러")
	assert(not pcall(Arr.Range, 1, 5, 0 / 0), "NaN step 은 에러")
end
print("PASS")

print("=== 17. 정렬 가족 ===")
do
	type Rec = { k: number, id: number }
	local function byK(a: Rec, b: Rec): boolean
		return a.k < b.k
	end
	-- 대조 기준: 원래 위치를 타이브레이커로 쓴 table.sort = 안정 정렬의 정의
	local function stableRef(list: { Rec }): { Rec }
		const copy = table.clone(list)
		table.sort(copy, function(a: Rec, b: Rec): boolean
			if a.k ~= b.k then
				return a.k < b.k
			end
			return a.id < b.id
		end)
		return copy
	end
	local function randomRecs(size: number, keyRange: number): Arr<Rec>
		const out = Arr.Of<<Rec>>()
		for id = 1, size do
			out:PushBack({ k = math.random(1, keyRange), id = id * 10 })
		end
		return out
	end
	local function randomNums(size: number, range: number): Arr<number>
		const out = Arr.Of<<number>>()
		for _ = 1, size do
			out:PushBack(math.random(1, range) * 10)
		end
		return out
	end
	local function sortedCopy(a: Arr<number>): { number }
		const copy = table.move(a, 1, a.n, 1, {}) :: { number }
		table.sort(copy)
		return copy
	end
	-- 구멍을 꼬리로 보낸 결과는 `n` 이 값 개수보다 큽니다 — 앞부분만 봅니다.
	local function samePrefix(actual: any, expected: { any }, label: string)
		for idx = 1, #expected do
			assert(actual[idx] == expected[idx], `{label}: [{idx}] 이 {tostring(actual[idx])}`)
		end
	end
	local function sameList(actual: { number }, expected: { number }, label: string)
		assert(#actual == #expected, `{label}: 길이`)
		for idx = 1, #expected do
			assert(actual[idx] == expected[idx], `{label}: [{idx}]`)
		end
	end
	math.randomseed(20260930)

	-- StableSort: 같은 k 끼리 입력 순서 — 삽입정렬 바닥(<24)과 병합 둘 다 지나게
	const recs = Arr.Of<<Rec>>({ k = 2, id = 10 }, { k = 1, id = 20 }, { k = 2, id = 30 }, { k = 1, id = 40 })
	const stable = recs:StableSort(byK)
	assert(stable[1].id == 20 and stable[2].id == 40 and stable[3].id == 10 and stable[4].id == 30, "StableSort 안정")
	assert(recs[1].id == 10, "StableSort 는 원본을 안 건드림")
	for _ = 1, 300 do
		const input = randomRecs(math.random(0, 120), math.random(1, 6))
		const expected = stableRef(table.move(input, 1, input.n, 1, {}) :: { Rec })
		const got = Arr.StableSort(input, byK)
		assert(got.n == input.n, "StableSort 길이")
		for idx = 1, input.n do
			assert(got[idx] == expected[idx], "StableSort 무작위 대조")
		end
	end
	same(Arr.Of(30, 10, 20):StableSort(), { 10, 20, 30 }, "StableSort 기본 비교자")
	same(emptyNum():StableSort(), {}, "StableSort 빈 것")
	-- 이미 정렬된 입력(병합 생략 경로)과 역순
	const ascending = Arr.Range(1, 200)
	same(ascending:StableSort(), table.move(ascending, 1, 200, 1, {}), "StableSort 이미 정렬")
	same(Arr.Range(200, 1, -1):StableSort(), table.move(ascending, 1, 200, 1, {}), "StableSort 역순")
	-- 구멍은 꼬리로, n 은 그대로
	const holed = Arr.Of<<number?>>(30, nil, 10, nil, 20)
	const holedSorted = holed:StableSort()
	assert(holedSorted.n == 5 and holedSorted[1] == 10 and holedSorted[3] == 30, "StableSort 구멍")
	assert(holedSorted[4] == nil and holedSorted[5] == nil, "StableSort 구멍은 꼬리로")
	const inplace = Arr.Of(30, 10, 20)
	assert(inplace:StableSortInplace() == inplace, "StableSortInplace 는 자기 자신")
	same(inplace, { 10, 20, 30 }, "StableSortInplace")
	const holedIn = Arr.Of<<number?>>(nil, 20, nil, 10)
	holedIn:StableSortInplace()
	assert(holedIn.n == 4 and holedIn[1] == 10 and holedIn[2] == 20 and holedIn[3] == nil, "StableSortInplace 구멍")

	-- SortBy: 키는 값마다 한 번, 안정, 구멍엔 키를 안 부름
	local calls = 0
	const words = Arr.Of<<string?>>("ccc", "a", nil, "bb", "dd")
	const byLen = words:SortBy(function(w: string?): number
		calls += 1
		return #(w :: string)
	end)
	assert(calls == 4, `SortBy 키는 값마다 한 번 ({calls})`)
	samePrefix(byLen, { "a", "bb", "dd", "ccc" }, "SortBy 안정(bb 가 dd 앞)")
	assert(byLen.n == 5 and byLen[5] == nil, "SortBy 구멍은 꼬리로")
	same(
		Arr.SortBy(Arr.Of(10, 30, 20), function(v: number): number
			return v
		end, function(a: number, b: number): boolean
			return a > b
		end),
		{ 30, 20, 10 },
		"SortBy 키 비교자(내림차순)"
	)
	for _ = 1, 100 do
		const input = randomRecs(math.random(0, 80), math.random(1, 5))
		const expected = stableRef(table.move(input, 1, input.n, 1, {}) :: { Rec })
		const got = input:SortBy(function(r: Rec): number
			return r.k
		end)
		for idx = 1, input.n do
			assert(got[idx] == expected[idx], "SortBy 무작위 대조")
		end
	end
	const byInplace = Arr.Of(30, 10, 20)
	assert(byInplace:SortByInplace(function(v: number): number
		return -v
	end) == byInplace, "SortByInplace 는 자기 자신")
	same(byInplace, { 30, 20, 10 }, "SortByInplace")

	-- NthElement: 모든 k 를 정렬 결과와 대조, 음수, 범위 밖, 원본 불변
	for _ = 1, 100 do
		const input = randomNums(math.random(1, 60), math.random(1, 30))
		const ref = sortedCopy(input)
		const before = table.move(input, 1, input.n, 1, {}) :: { number }
		for k = 1, input.n do
			assert(input:NthElement(k) == ref[k], "NthElement 대조")
			assert(input:NthElement(-k) == ref[input.n - k + 1], "NthElement 음수")
		end
		same(input, before, "NthElement 는 원본을 안 건드림")
	end
	const five = Arr.Of(50, 10, 40, 20, 30)
	assert(
		five:NthElement(0) == nil and five:NthElement(6) == nil and five:NthElement(-6) == nil,
		"NthElement 범위 밖"
	)
	assert(emptyNum():NthElement(1) == nil, "NthElement 빈 것")
	assert(Arr.Of<<number?>>(30, nil, 10, 20):NthElement(3) == 30, "NthElement 는 구멍을 뺀 순위")
	assert(five:NthElement((five:Len() + 1) // 2) == 30, "NthElement 중앙값")

	-- NthElementInplace: k 자리 값이 맞고 왼쪽 ≤, 오른쪽 ≥
	for _ = 1, 100 do
		const input = randomNums(math.random(1, 60), math.random(1, 30))
		const ref = sortedCopy(input)
		const k = math.random(1, input.n)
		assert(input:NthElementInplace(k) == input, "NthElementInplace 는 자기 자신")
		assert(input[k] == ref[k], "NthElementInplace k 자리")
		for idx = 1, k - 1 do
			assert(input[idx] <= input[k], "NthElementInplace 왼쪽 ≤")
		end
		for idx = k + 1, input.n do
			assert(input[idx] >= input[k], "NthElementInplace 오른쪽 ≥")
		end
		sameList(sortedCopy(input), ref, "NthElementInplace 는 원소 구성을 안 바꿈")
	end
	const holedNth = Arr.Of<<number?>>(nil, 30, nil, 10, 20)
	holedNth:NthElementInplace(2)
	assert(
		holedNth.n == 5 and holedNth[2] == 20 and holedNth[4] == nil and holedNth[5] == nil,
		"NthElementInplace 구멍"
	)

	-- PartialSort: 정렬 결과의 앞 k 개와 같음
	for _ = 1, 100 do
		const input = randomNums(math.random(0, 80), math.random(1, 40))
		const ref = sortedCopy(input)
		const k = math.random(0, input.n + 3)
		const got = input:PartialSort(k)
		assert(got.n == math.min(k, input.n), "PartialSort 길이")
		for idx = 1, got.n do
			assert(got[idx] == ref[idx], "PartialSort 대조")
		end
	end
	same(
		Arr.Of(10, 50, 30, 40, 20):PartialSort(2, function(a: number, b: number): boolean
			return a > b
		end),
		{ 50, 40 },
		"PartialSort 뒤집은 비교자 = 가장 큰 k 개"
	)
	assert(Arr.Of(10, 20):PartialSort(0).n == 0 and Arr.Of(10, 20):PartialSort(-1).n == 0, "PartialSort k ≤ 0")
	const partialHoles = Arr.Of<<number?>>(30, nil, 10, 20):PartialSort(2)
	assert(partialHoles.n == 2, "PartialSort 는 값만 셈")
	samePrefix(partialHoles, { 10, 20 }, "PartialSort 구멍은 건너뜀")

	-- PartialSortInplace: 앞 k 칸이 정렬되어 맞고, 원소 구성은 그대로
	for _ = 1, 100 do
		const input = randomNums(math.random(0, 80), math.random(1, 40))
		const ref = sortedCopy(input)
		const k = math.random(0, input.n + 3)
		assert(input:PartialSortInplace(k) == input, "PartialSortInplace 는 자기 자신")
		for idx = 1, math.min(k, input.n) do
			assert(input[idx] == ref[idx], "PartialSortInplace 앞 k 칸")
		end
		sameList(sortedCopy(input), ref, "PartialSortInplace 는 원소 구성을 안 바꿈")
	end
	const holedPartial = Arr.Of<<number?>>(40, nil, 10, 30, nil, 20)
	holedPartial:PartialSortInplace(2)
	assert(holedPartial.n == 6 and holedPartial[1] == 10 and holedPartial[2] == 20, "PartialSortInplace 구멍")
	assert(holedPartial[5] == nil and holedPartial[6] == nil, "PartialSortInplace 구멍은 꼬리로")

	-- MergeSorted: 이어붙여 정렬한 것과 같고, 같은 순위면 self 쪽이 먼저
	for _ = 1, 100 do
		const left = Arr.SortInplace(randomNums(math.random(0, 40), 20))
		const right = Arr.SortInplace(randomNums(math.random(0, 40), 20))
		const got = left:MergeSorted(right)
		const ref = sortedCopy(Arr.Concat(left, right))
		assert(got.n == #ref, "MergeSorted 길이")
		samePrefix(got, ref, "MergeSorted 대조")
	end
	const leftRecs = Arr.Of<<Rec>>({ k = 1, id = 10 }, { k = 2, id = 20 })
	const rightRecs = Arr.Of<<Rec>>({ k = 1, id = 30 }, { k = 2, id = 40 })
	const mergedRecs = leftRecs:MergeSorted(rightRecs, byK)
	assert(
		mergedRecs[1].id == 10 and mergedRecs[2].id == 30 and mergedRecs[3].id == 20 and mergedRecs[4].id == 40,
		"MergeSorted 안정(self 먼저)"
	)
	const mergedHoles = Arr.MergeSorted(Arr.Of<<number?>>(nil, 10, nil, 30), Arr.Of<<number?>>(20, nil))
	assert(mergedHoles.n == 3, "MergeSorted 는 구멍을 건너뛰어 조밀함")
	samePrefix(mergedHoles, { 10, 20, 30 }, "MergeSorted 구멍")
	same(emptyNum():MergeSorted(emptyNum()), {}, "MergeSorted 빈 것")

	-- IsSorted
	assert(Arr.Of(10, 20, 20, 30):IsSorted(), "IsSorted 같은 값 허용")
	assert(not Arr.Of(10, 30, 20):IsSorted(), "IsSorted 아님")
	assert(Arr.Of<<number?>>(10, nil, 20):IsSorted(), "IsSorted 구멍 건너뜀")
	assert(emptyNum():IsSorted() and Arr.Of(10):IsSorted(), "IsSorted 빈 것·하나")
	assert(
		Arr.Of(30, 20, 10):IsSorted(function(a: number, b: number): boolean
			return a > b
		end),
		"IsSorted 비교자"
	)
end
print("PASS")

print()
print("=== ALL PASS (Arr) ===")

return true

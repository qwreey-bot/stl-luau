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
assert(Arr.Len(Arr.Of(1, 2)) == 2, "Len")
assert(Arr.Empty(emptyNum()), "Empty")
assert(not Arr.Empty(Arr.Of(1)), "Empty 아님")
assert(Arr.Join(Arr.Of(1, 2, 3), "-") == "1-2-3", "Join")
assert(Arr.Join(emptyNum(), "-") == "", "Join 빈 것")
assert(Arr.Join(Arr.Of(1), "-") == "1", "Join 한 개")
assert(Arr.Equal(Arr.Of(1, 2, 3), Arr.Of(1, 2, 3)), "Equal")
assert(not Arr.Equal(Arr.Of(1, 2), Arr.Of(1, 2, 3)), "Equal 길이 다름")
assert(not Arr.Equal(Arr.Of(1, 2), Arr.Of(1, 9)), "Equal 내용 다름")
do
	local a, b, c = Arr.Unpack(Arr.Of(1, 2, 3))
	assert(a == 1 and b == 2 and c == 3, "Unpack")
end
print("PASS")

print("=== 3. 계약 (ListCore) 과 Iter ===")
do
	local a = Arr.Of(10, 20, 30)
	assert(Arr.FirstIndex(a) == 1 and Arr.LastIndex(a) == 3, "First/LastIndex")
	assert(Arr.NextIndex(a, 1) == 2 and Arr.NextIndex(a, 3) == nil, "NextIndex")
	assert(Arr.PrevIndex(a, 3) == 2 and Arr.PrevIndex(a, 1) == nil, "PrevIndex")
	assert(Arr.Get(a, 2) == 20 and Arr.Get(a, 9) == nil, "Get")
	assert(Arr.FirstIndex(emptyNum()) == nil, "빈 것의 FirstIndex 는 nil")

	local seenIdx, seenSum = 0, 0
	for i, v in Arr.Iter(a) do
		seenIdx += i
		seenSum += v
	end
	assert(seenIdx == 6 and seenSum == 60, "Iter 가 전부 돌아야 합니다")
	local emptyCount = 0
	for _i, _v in Arr.Iter(emptyNum()) do
		emptyCount += 1
	end
	assert(emptyCount == 0, "빈 것의 Iter 는 한 번도 안 돌아야 합니다")

	-- 공용 알고리즘이 구현을 모른 채 계약만으로 동작하는지
	assert(stl.Algorithm.IndexOf(Arr, a, 20) == 2, "Algorithm.IndexOf")
	assert(stl.Algorithm.IndexOf(Arr, a, 99) == nil, "Algorithm.IndexOf 없음")
	assert(stl.Algorithm.Count(Arr, a) == 3, "Algorithm.Count")
end
print("PASS")

print("=== 4. 추가 (PushBack / PushFront / Insert) ===")
same(Arr.PushBack(Arr.Of(1), 2), { 1, 2 }, "PushBack")
same(Arr.PushBackMany(Arr.Of(1), 2, 3), { 1, 2, 3 }, "PushBackMany")
same(Arr.PushBackMany(Arr.Of(1)), { 1 }, "PushBackMany 인자 없음")
same(Arr.PushBackArray(Arr.Of(1), Arr.Of(2, 3)), { 1, 2, 3 }, "PushBackArray")
same(Arr.PushBackArray(Arr.Of(1), emptyNum()), { 1 }, "PushBackArray 빈 것")
same(Arr.PushFront(Arr.Of(2), 1), { 1, 2 }, "PushFront")
same(Arr.PushFrontMany(Arr.Of(3), 1, 2), { 1, 2, 3 }, "PushFrontMany 는 인자 순서를 보존")
same(Arr.PushFrontArray(Arr.Of(3), Arr.Of(1, 2)), { 1, 2, 3 }, "PushFrontArray")
same(Arr.PushFront(emptyNum(), 1), { 1 }, "빈 것에 PushFront")
-- ⭐ 삽입 위치의 유효 범위는 1 .. n+1 — 맨 뒤 삽입이 표현 가능해야 합니다
same(Arr.Insert(Arr.Of(1, 3), 2, 2), { 1, 2, 3 }, "Insert 중간")
same(Arr.Insert(Arr.Of(1, 2), 3, 3), { 1, 2, 3 }, "Insert 맨 뒤 (n+1)")
same(Arr.Insert(Arr.Of(1, 2), 99, 3), { 1, 2, 3 }, "Insert 범위 초과는 맨 뒤로 clamp")
same(Arr.Insert(Arr.Of(2, 3), 1, 1), { 1, 2, 3 }, "Insert 맨 앞")
same(Arr.Insert(Arr.Of(2, 3), -99, 1), { 1, 2, 3 }, "Insert 음수 초과는 맨 앞으로 clamp")
same(Arr.Insert(Arr.Of(1, 3), -1, 2), { 1, 2, 3 }, "Insert 음수는 끝에서부터")
same(Arr.Insert(emptyNum(), 1, 1), { 1 }, "빈 것에 Insert")
same(Arr.InsertMany(Arr.Of(1, 4), 2, 2, 3), { 1, 2, 3, 4 }, "InsertMany")
same(Arr.InsertArray(Arr.Of(1, 4), 2, Arr.Of(2, 3)), { 1, 2, 3, 4 }, "InsertArray")
same(Arr.InsertMany(Arr.Of(1), 1), { 1 }, "InsertMany 인자 없음")
print("PASS")

print("=== 5. 복제 / 비우기 / 채우기 ===")
do
	local a = Arr.Of(1, 2, 3)
	local b = Arr.Clone(a)
	b[1] = 99
	assert(a[1] == 1, "Clone 은 독립적이어야 합니다")
	same(b, { 99, 2, 3 }, "Clone 내용")

	local c = Arr.Clear(Arr.Of(1, 2, 3))
	assert(c.n == 0, "Clear 는 n 을 0 으로")
	assert(c[1] == nil, "Clear 는 내용을 지움")
	-- ⭐ table.clear 로 지우면 태그까지 날아가 isArr 를 통과 못 하던 버그
	assert(stl.isArr(c), "Clear 후에도 isArr 여야 합니다")
	same(Arr.PushBack(c, 7), { 7 }, "Clear 후 다시 쓸 수 있어야 합니다")
end
same(Arr.Fill(Arr.Sized(3, 0), 9), { 9, 9, 9 }, "Fill 전체")
same(Arr.Fill(Arr.Of(1, 2, 3), 9, 2), { 1, 9, 9 }, "Fill start 부터")
same(Arr.Fill(Arr.Of(1, 2, 3), 9, 2, 2), { 1, 9, 3 }, "Fill 한 칸")
same(Arr.Fill(Arr.Of(1, 2, 3), 9, 3, 1), { 1, 2, 3 }, "Fill 뒤집힌 구간은 아무것도 안 함")
same(Arr.Fill(Arr.Of(1, 2, 3), 9, -1), { 1, 2, 9 }, "Fill 음수 start")
same(Arr.Fill(Arr.Of(1, 2, 3), 9, 1, 99), { 9, 9, 9 }, "Fill 범위 초과는 clamp")
print("PASS")

print("=== 5b. At — 음수를 받는 단일 조회 ===")
do
	const a = Arr.Of(10, 20, 30)
	assert(Arr.At(a, 1) == 10 and Arr.At(a, 3) == 30, "At 양수")
	assert(Arr.At(a, -1) == 30 and Arr.At(a, -3) == 10, "At 음수는 뒤에서")
	-- 범위 밖은 clamp 하지 않고 nil — 단일 조회라 "가장 가까운 것" 은 거짓말입니다
	assert(Arr.At(a, 0) == nil and Arr.At(a, 4) == nil and Arr.At(a, -4) == nil, "At 범위 밖은 nil")
	-- 소수는 구간 규약처럼 0 쪽으로 자릅니다
	assert(Arr.At(a, 2.7) == 20 and Arr.At(a, -1.5) == 30, "At 소수는 0 쪽으로")
	assert(Arr.At(emptyNum(), 1) == nil and Arr.At(emptyNum(), -1) == nil, "빈 것의 At")
	-- 구멍은 nil 로 — 타입이 T? 라 정직합니다
	assert(Arr.At(Arr.Of<<number?>>(10, nil, 30), -2) == nil, "At 구멍")
end
print("PASS")

print("=== 6. 구간 — Slice / Erase / Splice ===")
same(Arr.Slice(Arr.Of(1, 2, 3, 4), 2, 3), { 2, 3 }, "Slice 닫힌 구간")
same(Arr.Slice(Arr.Of(1, 2, 3, 4)), { 1, 2, 3, 4 }, "Slice 인자 없으면 전체")
same(Arr.Slice(Arr.Of(1, 2, 3, 4), -2), { 3, 4 }, "Slice 음수 start")
same(Arr.Slice(Arr.Of(1, 2, 3, 4), 2, -1), { 2, 3, 4 }, "Slice 음수 last")
same(Arr.Slice(Arr.Of(1, 2, 3, 4), 3, 2), {}, "Slice 뒤집힌 구간은 빈 결과")
same(Arr.Slice(Arr.Of(1, 2, 3, 4), 0, 99), { 1, 2, 3, 4 }, "Slice 범위 초과는 clamp")
same(Arr.Slice(emptyNum(), 1, 3), {}, "빈 것의 Slice")
-- to 는 "목적지 뒤에 이어붙이기" 입니다
same(Arr.Slice(Arr.Of(3, 4), 1, 2, Arr.Of(1, 2)), { 1, 2, 3, 4 }, "Slice to 는 뒤에 이어붙임")
same(Arr.SliceInplace(Arr.Of(1, 2, 3, 4), 2, 3), { 2, 3 }, "SliceInplace")
same(Arr.SliceInplace(Arr.Of(1, 2, 3), 3, 1), {}, "SliceInplace 뒤집힌 구간은 비움")

same(Arr.Erase(Arr.Of(1, 2, 3, 4), 2, 3), { 1, 4 }, "Erase")
same(Arr.Erase(Arr.Of(1, 2, 3), 3, 1), { 1, 2, 3 }, "Erase 뒤집힌 구간은 그대로")
same(Arr.Erase(Arr.Of(1, 2, 3)), {}, "Erase 인자 없으면 전부")
same(Arr.EraseInplace(Arr.Of(1, 2, 3, 4), 2, 3), { 1, 4 }, "EraseInplace")
-- ⭐ 가드가 없으면 배열이 오히려 늘어나던 버그
do
	local a = Arr.EraseInplace(Arr.Of(1, 2, 3), 3, 1)
	assert(a.n == 3, `EraseInplace 뒤집힌 구간에서 n 이 {a.n} 으로 늘어났습니다`)
end
same(Arr.EraseInplace(Arr.Of(1, 2, 3)), {}, "EraseInplace 전부")
same(Arr.EraseInplace(Arr.Of(1, 2, 3), -1), { 1, 2 }, "EraseInplace 음수")

same(Arr.Splice(Arr.Of(1, 2, 3, 4), 2, 3, Arr.Of(9)), { 1, 9, 4 }, "Splice 줄어듦")
same(Arr.Splice(Arr.Of(1, 2, 4), 2, 2, Arr.Of(8, 9)), { 1, 8, 9, 4 }, "Splice 늘어남")
same(Arr.Splice(Arr.Of(1, 2, 3), 2, 2, emptyNum()), { 1, 3 }, "Splice 빈 것으로 = 삭제")
same(Arr.SpliceInplace(Arr.Of(1, 2, 3, 4), 2, 3, Arr.Of(9)), { 1, 9, 4 }, "SpliceInplace 줄어듦")
same(Arr.SpliceInplace(Arr.Of(1, 2, 4), 2, 2, Arr.Of(8, 9)), { 1, 8, 9, 4 }, "SpliceInplace 늘어남")
print("PASS")

print("=== 7. 순서 — Reverse / Rotate / Shuffle / Sort ===")
same(Arr.Reverse(Arr.Of(1, 2, 3)), { 3, 2, 1 }, "Reverse")
same(Arr.Reverse(Arr.Of(1, 2, 3, 4), 2, 3), { 1, 3, 2, 4 }, "Reverse 구간")
same(Arr.Reverse(Arr.Of(1)), { 1 }, "Reverse 한 개")
same(Arr.Reverse(emptyNum()), {}, "Reverse 빈 것")
do
	local a = Arr.Of(1, 2, 3)
	local b = Arr.Reverse(a)
	assert(a[1] == 1, "Reverse 는 원본을 건드리지 않아야 합니다")
	same(b, { 3, 2, 1 }, "Reverse 결과")
end
same(Arr.ReverseInplace(Arr.Of(1, 2, 3)), { 3, 2, 1 }, "ReverseInplace")
-- 양수 shift 가 왼쪽 회전 (std::rotate 방향)
same(Arr.Rotate(Arr.Of(1, 2, 3, 4), 1), { 2, 3, 4, 1 }, "Rotate 왼쪽")
same(Arr.Rotate(Arr.Of(1, 2, 3, 4), -1), { 4, 1, 2, 3 }, "Rotate 음수는 오른쪽")
same(Arr.Rotate(Arr.Of(1, 2, 3, 4), 4), { 1, 2, 3, 4 }, "Rotate 한 바퀴")
same(Arr.Rotate(Arr.Of(1, 2, 3, 4), 5), { 2, 3, 4, 1 }, "Rotate 는 나머지만 의미")
same(Arr.Rotate(Arr.Of(1, 2, 3, 4), 1, 2, 3), { 1, 3, 2, 4 }, "Rotate 구간")
same(Arr.Rotate(Arr.Of(1), 1), { 1 }, "Rotate 한 개")
same(Arr.Rotate(emptyNum(), 1), {}, "Rotate 빈 것")
do
	-- rng 를 주입해 결정적으로 만듭니다
	local a = Arr.Of(1, 2, 3, 4, 5)
	local b = Arr.Shuffle(a, nil, nil, function(min: number, _max: number)
		return min
	end)
	assert(b.n == 5, "Shuffle 은 길이를 보존")
	assert(Arr.Equal(Arr.Sort(a), Arr.Sort(b)), "Shuffle 은 원소 집합을 보존")
	assert(a[1] == 1, "Shuffle 은 원본을 건드리지 않아야 합니다")
end
same(Arr.Sort(Arr.Of(3, 1, 2)), { 1, 2, 3 }, "Sort 기본")
same(
	Arr.Sort(Arr.Of(3, 1, 2), function(a: number, b: number)
		return a > b
	end),
	{ 3, 2, 1 },
	"Sort 불리언 비교자"
)
same(Arr.Sort(Arr.Of(3, 1, 2), Common.lessFrom(Common.compareNumber)), { 1, 2, 3 }, "Sort 3방향 어댑터")
same(Arr.Sort(emptyNum()), {}, "Sort 빈 것")
same(Arr.Sort(Arr.Of(1)), { 1 }, "Sort 한 개")
same(Arr.SortInplace(Arr.Of(3, 1, 2)), { 1, 2, 3 }, "SortInplace")
-- ⭐ 구멍은 정렬 대상에서 빠지고 뒤로 몰리며 n 은 보존됩니다
do
	local holey: Arr<number> = Arr.Of(3, nil :: any, 1)
	local sorted = Arr.Sort(holey)
	assert(sorted.n == 3, "Sort 는 n 을 보존")
	assert(sorted[1] == 1 and sorted[2] == 3 and sorted[3] == nil, "Sort 는 구멍을 뒤로 몰아야 합니다")
end
print("PASS")

print("=== 8. 스트림 — Map / Filter / Flat / Drain ===")
same(
	Arr.Map(Arr.Of(1, 2, 3), function(v: number)
		return v * 2
	end),
	{ 2, 4, 6 },
	"Map"
)
same(
	Arr.Map(emptyNum(), function(v: number)
		return v
	end),
	{},
	"Map 빈 것"
)
same(
	-- 콜백 주석이 필요합니다 — 셋째 인자가 `ArrView<unknown>` 이라 `to` 와 함께
	-- 넘기면 `T` 를 붙잡을 단서가 없습니다(질문 V 의 대가).
	Arr.Map(Arr.Of(1, 2), function(v: number)
		return v
	end, Arr.Of(0)),
	{ 0, 1, 2 },
	"Map to 는 뒤에 이어붙임"
)
-- Map 은 콜백에 (원소, 위치, 뷰) 를 줍니다
same(
	Arr.Map(Arr.Of(10, 20), function(v: number, idx: number, arr: ArrView<unknown>)
		return v + idx + arr.n
	end),
	{ 13, 24 },
	"Map 콜백 인자"
)
same(
	Arr.MapInplace(Arr.Of(1, 2, 3), function(v: number)
		return v * 10
	end),
	{ 10, 20, 30 },
	"MapInplace"
)
same(
	Arr.Filter(Arr.Of(1, 2, 3, 4), function(v: number)
		return v % 2 == 0
	end),
	{ 2, 4 },
	"Filter"
)
same(
	Arr.Retain(Arr.Of(1, 2, 3, 4), function(v: number)
		return v % 2 == 0
	end),
	{ 2, 4 },
	"Retain"
)
same(
	Arr.Retain(Arr.Of(1, 2, 3), function()
		return false
	end),
	{},
	"Retain 전부 버림"
)
do
	local nested = Arr.Of(1, Arr.Of(2, 3) :: any, 4)
	const flat = Arr.Flat(nested) :: Arr<number>
	same(flat, { 1, 2, 3, 4 }, "Flat")
end
do
	local nested = Arr.Of(emptyNum() :: any, 1, Arr.Of(2) :: any)
	const flat = Arr.Flat(nested) :: Arr<number>
	same(flat, { 1, 2 }, "Flat 빈 중첩")
end
do
	local nested = Arr.Of(1, Arr.Of(2, 3) :: any, 4)
	const flat = Arr.FlatInplace(nested) :: Arr<number>
	same(flat, { 1, 2, 3, 4 }, "FlatInplace")
end
do
	local nested = Arr.Of(emptyNum() :: any, 1)
	const flat = Arr.FlatInplace(nested) :: Arr<number>
	same(flat, { 1 }, "FlatInplace 빈 중첩")
end
same(
	Arr.Flatmap(Arr.Of(1, 2), function(v: number)
		return v, v * 10
	end),
	{ 1, 10, 2, 20 },
	"Flatmap"
)
same(
	Arr.FlatmapInplace(Arr.Of(1, 2), function(v: number)
		return v, v * 10
	end),
	{ 1, 10, 2, 20 },
	"FlatmapInplace"
)
do
	local a = Arr.Of(1, 2, 3)
	local seen = 0
	Arr.Drain(a, function(v: number)
		seen += v
		return nil
	end)
	assert(seen == 6, "Drain 은 전부 순회")
	assert(a.n == 0 and a[1] == nil, "Drain 은 비워야 합니다")
end
same(Arr.ConcatInplace(Arr.Of(1), Arr.Of(2), Arr.Of(3, 4)), { 1, 2, 3, 4 }, "ConcatInplace")
same(Arr.ConcatInplace(Arr.Of(1)), { 1 }, "ConcatInplace 인자 없음")
print("PASS")

print("=== 9. 조건 조회 — Count / Find / Some / Every ===")
assert(Arr.Count(Arr.Of(1, 2, 3, 4), function(v: number)
	return v % 2 == 0
end) == 2, "Count")
do
	local item, idx = Arr.Find(Arr.Of(1, 2, 3), function(v)
		return v > 1
	end)
	assert(item == 2 and idx == 2, "Find")
	local none, noneIdx = Arr.Find(Arr.Of(1), function()
		return false
	end)
	assert(none == nil and noneIdx == nil, "Find 없음")
end
assert(
	Arr.Some(Arr.Of(1, 2), function(v)
		return v == 2
	end),
	"Some"
)
assert(not Arr.Some(Arr.Of(1, 2), function(v)
	return v == 9
end), "Some 없음")
assert(
	Arr.Every(Arr.Of(2, 4), function(v: number)
		return v % 2 == 0
	end),
	"Every"
)
assert(not Arr.Every(Arr.Of(2, 3), function(v: number)
	return v % 2 == 0
end), "Every 아님")
assert(
	Arr.Every(emptyNum(), function(v: number)
		return false
	end),
	"빈 것의 Every 는 공허 참"
)
assert(not Arr.Some(Arr.Of(1, 2, 3), function(v)
	return v == 1
end, 2), "Some 구간 — start 앞의 원소는 안 봐야 합니다")
assert(
	Arr.Some(Arr.Of(1, 2, 3), function(v)
		return v == 3
	end, 2),
	"Some 구간 — start 뒤의 원소는 봐야 합니다"
)
assert(not Arr.Every(Arr.Of(1, 2, 3), function(v)
	return v == 1
end, 2), "Every 구간")
print("PASS")

print("=== 10. 집계 — Max / Min / Sum / Prod ===")
assert(Arr.Max(Arr.Of(3, 1, 2)) == 3, "Max")
assert(Arr.Min(Arr.Of(3, 1, 2)) == 1, "Min")
assert(Arr.Max(emptyNum()) == nil, "빈 것의 Max 는 nil")
assert(Arr.Min(emptyNum()) == nil, "빈 것의 Min 은 nil")
assert(Arr.Max(Arr.Of(1)) == 1, "Max 한 개")
assert(Arr.Max(Arr.Of("b", "a")) == "b", "Max 는 문자열에도 동작")
assert(Arr.Max(Arr.Of(3, 1, 2), function(a: number, b: number)
	return a > b
end) == 1, "Max 비교자를 뒤집으면 최소가 나옴")
assert(Arr.Sum(Arr.Of(1, 2, 3)) == 6, "Sum")
assert(Arr.Sum(emptyNum()) == 0, "빈 것의 Sum 은 0")
assert(Arr.Sum(Arr.Of(1, 2), 10) == 13, "Sum 씨앗")
assert(Arr.Prod(Arr.Of(2, 3)) == 6, "Prod")
assert(Arr.Prod(emptyNum()) == 1, "빈 것의 Prod 는 1")
-- ⭐ 구멍에서 터지지 않아야 합니다
do
	local holey: Arr<number> = Arr.Of(1, nil :: any, 3)
	assert(Arr.Sum(holey) == 4, "Sum 은 구멍을 건너뜀")
	assert(Arr.Prod(holey) == 3, "Prod 는 구멍을 건너뜀")
	assert(Arr.Max(holey) == 3, "Max 는 구멍을 건너뜀")
	assert(Arr.Min(holey) == 1, "Min 은 구멍을 건너뜀")
	assert(Arr.Join(holey, "-") == "1-3", "Join 은 구멍을 건너뜀")
end
print("PASS")

print("=== 11. 접기 — Fold / FoldRight / Reduce / FoldUntil ===")
assert(Arr.Fold(Arr.Of(1, 2, 3), 0, function(acc, v)
	return acc + v
end) == 6, "Fold")
assert(Arr.Fold(emptyNum(), 7, function(acc: number, v: number)
	return acc + v
end) == 7, "빈 것의 Fold 는 초기값")
assert(Arr.FoldRight(Arr.Of("a", "b", "c"), "", function(acc, v)
	return acc .. v
end) == "cba", "FoldRight 는 오른쪽부터")
assert(Arr.Reduce(Arr.Of(1, 2, 3), function(a, b)
	return a + b
end) == 6, "Reduce")
assert(Arr.Reduce(Arr.Of(5), function(a, b)
	return a + b
end) == 5, "Reduce 한 개는 그 원소")
assert(Arr.Reduce(emptyNum(), function(a: number, b: number)
	return a + b
end) == nil, "빈 것의 Reduce 는 nil")
do
	local acc, stopped = Arr.FoldUntil(Arr.Of(1, 2, 3, 4), 0, function(a: number, v: number)
		return a + v, v >= 3
	end)
	assert(acc == 6 and stopped == 3, `FoldUntil: acc={acc} stopped={tostring(stopped)}`)
	local full, notStopped = Arr.FoldUntil(Arr.Of(1, 2), 0, function(a, v)
		return a + v, false
	end)
	assert(full == 3 and notStopped == nil, "완주하면 둘째가 nil")
end
print("PASS")

print("=== 12. 문장으로 이어 쓰기와 뷰 ===")
do
	-- 3단 타입 변환을 문장으로 이어 씁니다(질문 AB — 체이닝 대신 정식 모양)
	const texts = Arr.Map(Arr.Of(1, 2, 3), function(v: number): string
		return tostring(v)
	end)
	const lengths = Arr.Map(texts, function(s: string): number
		return #s
	end)
	const result = Arr.Filter(lengths, function(n: number): boolean
		return n == 1
	end)
	same(result, { 1, 1, 1 }, "3단 변환")
	-- 콜백의 셋째 인자는 **원본 배열**을 읽기 전용으로 본 것입니다(메소드 없음).
	-- 원소까지 읽어 확인합니다 — 길이만 보면 다른 테이블을 넘겨도 통과했습니다.
	const source = Arr.Of(10, 20)
	local viewed = Arr.Map(source, function(v: number, idx: number, arr: ArrView<unknown>)
		assert(arr[idx] == v and rawequal(arr, source), "셋째 인자는 원본 배열")
		return v + arr.n + idx
	end)
	same(viewed, { 13, 24 }, "콜백의 셋째 인자")
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
	const rotated = Arr.RotateInplace(a, 1)
	assert(rotated == a, "RotateInplace 는 자기 자신을 돌려줍니다")
	same(a, { 2, 3, 4, 1 }, "RotateInplace 왼쪽")
	Arr.RotateInplace(a, -1)
	same(a, { 1, 2, 3, 4 }, "RotateInplace 음수는 오른쪽")
	Arr.RotateInplace(a, 1, 2, 3)
	same(a, { 1, 3, 2, 4 }, "RotateInplace 구간")
	same(Arr.RotateInplace(Arr.Of(1), 1), { 1 }, "RotateInplace 한 개")
	same(Arr.RotateInplace(emptyNum(), 1), {}, "RotateInplace 빈 것")

	const b: Arr<number> = Arr.Of(1, 2, 3, 4, 5)
	const shuffled = Arr.ShuffleInplace(b, nil, nil, function(min: number, _max: number)
		return min
	end)
	assert(shuffled == b, "ShuffleInplace 는 자기 자신을 돌려줍니다")
	assert(b.n == 5, "ShuffleInplace 는 길이를 보존")
	same(Arr.Sort(b), { 1, 2, 3, 4, 5 }, "ShuffleInplace 는 원소 집합을 보존")
	same(Arr.ShuffleInplace(emptyNum()), {}, "ShuffleInplace 빈 것")
end
print("PASS")

print("=== 14. ⚠️ unchecked 계열 ===")
do
	-- 구멍이 없으면 checked 와 **같은 답**이 나와야 합니다.
	const dense: Arr<number> = Arr.Of(3, 1, 2)
	assert(Arr.SumUnchecked(dense) == Arr.Sum(dense), "SumUnchecked 는 같은 답")
	assert(Arr.ProdUnchecked(dense) == Arr.Prod(dense), "ProdUnchecked 는 같은 답")
	assert(Arr.MaxUnchecked(dense) == Arr.Max(dense), "MaxUnchecked 는 같은 답")
	assert(Arr.MinUnchecked(dense) == Arr.Min(dense), "MinUnchecked 는 같은 답")
	assert(Arr.Equal(Arr.SortUnchecked(dense), Arr.Sort(dense)), "SortUnchecked 는 같은 답")
	assert(Arr.SumUnchecked(dense, 10) == 16, "SumUnchecked 씨앗")
	assert(Arr.ProdUnchecked(dense, 2) == 12, "ProdUnchecked 씨앗")

	-- 비교자를 준 경로도 같아야 합니다
	const desc = function(a: number, b: number): boolean
		return a > b
	end
	assert(Arr.MaxUnchecked(dense, desc) == Arr.Max(dense, desc), "MaxUnchecked 비교자")
	assert(Arr.MinUnchecked(dense, desc) == Arr.Min(dense, desc), "MinUnchecked 비교자")
	same(Arr.SortUnchecked(dense, desc), { 3, 2, 1 }, "SortUnchecked 비교자")

	-- 빈 것과 한 개
	assert(Arr.MaxUnchecked(emptyNum()) == nil, "빈 것의 MaxUnchecked")
	assert(Arr.MinUnchecked(emptyNum()) == nil, "빈 것의 MinUnchecked")
	assert(Arr.SumUnchecked(emptyNum()) == 0, "빈 것의 SumUnchecked")
	assert(Arr.ProdUnchecked(emptyNum()) == 1, "빈 것의 ProdUnchecked")
	assert(Arr.MaxUnchecked(Arr.Of(5)) == 5, "한 개의 MaxUnchecked")
	same(Arr.SortUnchecked(emptyNum()), {}, "빈 것의 SortUnchecked")

	-- 제자리 판은 자기 자신을 돌려줍니다
	const target: Arr<number> = Arr.Of(3, 1, 2)
	assert(Arr.SortInplaceUnchecked(target) == target, "SortInplaceUnchecked 는 자기 자신")
	same(target, { 1, 2, 3 }, "SortInplaceUnchecked 결과")

	-- ⚠️ **구멍이 있을 때 문서대로 망가지는지**를 고정합니다. 이걸 고정해두지
	-- 않으면 나중에 누가 "안전하게" 고쳐서 unchecked 의 존재 이유가 사라집니다.
	const holed = (Arr.Sized<<number?>>(3, nil) :: any) :: Arr<number>
	holed[1], holed[3] = 1, 3
	assert(not pcall(function()
		return Arr.SumUnchecked(holed)
	end), "SumUnchecked 는 구멍에서 터져야 합니다")
	assert(not pcall(function()
		return Arr.MaxUnchecked(holed)
	end), "MaxUnchecked 는 구멍에서 터져야 합니다")
	-- 반면 checked 는 멀쩡해야 합니다
	assert(Arr.Sum(holed) == 4 and Arr.Max(holed) == 3, "checked 는 구멍에서 멀쩡")
	-- 정렬은 터지지 않습니다. (M0 6라운드부터) `#` 와 `n` 이 어긋나면 checked 판으로
	-- 넘어가 결과도 맞습니다 — `#` 검사는 O(log n), 정렬 대비 0.3%(perf 17절). 구멍 검사
	-- O(n) 을 건너뛰는 unchecked 의 존재 이유는 그대로입니다.
	const holedSorted = (Arr.Sized<<number?>>(3, nil) :: any) :: Arr<number>
	holedSorted[1], holedSorted[3] = 1, 3
	assert(
		pcall(function()
			return Arr.SortInplaceUnchecked(holedSorted)
		end),
		"꼬리 구멍(# ≠ n)이면 SortInplaceUnchecked 는 checked 로 넘어가 터지지 않습니다"
	)
end
print("PASS")

print("=== 15. 원소가 유니온인 배열 ===")
do
	-- ⭐ self 를 전체형으로 받던 시절엔 이 절 전체가 타입 에러였습니다(spikes/46).
	local maybe = Arr.Of<<number?>>(1, nil, 3)
	assert(maybe.n == 3, "n 은 구멍을 포함")
	const kept = Arr.Filter(maybe, function(v: number?)
		return v ~= nil
	end)
	assert(kept.n == 2, "Filter 가 구멍을 거름")
	const filled = Arr.Map(maybe, function(v: number?): number
		return v or 0
	end)
	same(filled, { 1, 0, 3 }, "Map 으로 구멍을 메움")
	assert(Arr.Count(maybe, function(v: number?)
		return v == nil
	end) == 1, "Count")
end
print("PASS")

print("=== 16. 회귀 — 2026-09-30 리뷰 ===")
do
	-- (1) Splice 의 시작점이 n+1 을 넘으면 n 바깥에 쓰던 것 — 삽입 위치처럼 1..n+1 로
	same(Arr.Splice(Arr.Of(1, 2, 3), 10, 12, Arr.Of(9)), { 1, 2, 3, 9 }, "Splice 시작점이 n+1 초과")
	do
		const a: Arr<number> = Arr.Of(1, 2, 3)
		Arr.SpliceInplace(a, 5, 4, Arr.Of(9))
		same(a, { 1, 2, 3, 9 }, "SpliceInplace 시작점이 n+1 초과")
		assert(a[5] == nil, "n 밖에 남은 값이 없어야 함")
	end
	same(Arr.Splice(Arr.Of(1, 2, 3), 4, 3, Arr.Of(9)), { 1, 2, 3, 9 }, "Splice 시작점이 정확히 n+1")

	-- (3) 정수가 아닌 인덱스는 Luau 처럼 0 쪽으로 자른다 (string.sub("abc", 1.5) == "abc")
	same(Arr.Rotate(Arr.Of(1, 2, 3, 4), 1.5), { 2, 3, 4, 1 }, "Rotate 1.5 는 1")
	same(Arr.Rotate(Arr.Of(1, 2, 3, 4, 5), 2.5), { 3, 4, 5, 1, 2 }, "Rotate 2.5 는 2")
	same(Arr.Slice(Arr.Of(1, 2, 3, 4), 1.5, 3.9), { 1, 2, 3 }, "Slice 소수 구간")
	same(Arr.Slice(Arr.Of(1, 2, 3, 4), -1.5), { 4 }, "Slice 음수 소수는 0 쪽으로(-1)")
	same(Arr.Insert(Arr.Of(1, 3), 1.9, 0), { 0, 1, 3 }, "Insert 소수 위치")
	assert(not pcall(function()
		return Arr.Rotate(Arr.Of(1, 2), math.huge)
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
			Arr.PushBack(out, { k = math.random(1, keyRange), id = id * 10 })
		end
		return out
	end
	local function randomNums(size: number, range: number): Arr<number>
		const out = Arr.Of<<number>>()
		for _ = 1, size do
			Arr.PushBack(out, math.random(1, range) * 10)
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
	const stable = Arr.StableSort(recs, byK)
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
	same(Arr.StableSort(Arr.Of(30, 10, 20)), { 10, 20, 30 }, "StableSort 기본 비교자")
	same(Arr.StableSort(emptyNum()), {}, "StableSort 빈 것")
	-- 이미 정렬된 입력(병합 생략 경로)과 역순
	const ascending = Arr.Range(1, 200)
	same(Arr.StableSort(ascending), table.move(ascending, 1, 200, 1, {}), "StableSort 이미 정렬")
	same(Arr.StableSort(Arr.Range(200, 1, -1)), table.move(ascending, 1, 200, 1, {}), "StableSort 역순")
	-- 구멍은 꼬리로, n 은 그대로
	const holed = Arr.Of<<number?>>(30, nil, 10, nil, 20)
	const holedSorted = Arr.StableSort(holed)
	assert(holedSorted.n == 5 and holedSorted[1] == 10 and holedSorted[3] == 30, "StableSort 구멍")
	assert(holedSorted[4] == nil and holedSorted[5] == nil, "StableSort 구멍은 꼬리로")
	const inplace = Arr.Of(30, 10, 20)
	assert(Arr.StableSortInplace(inplace) == inplace, "StableSortInplace 는 자기 자신")
	same(inplace, { 10, 20, 30 }, "StableSortInplace")
	const holedIn = Arr.Of<<number?>>(nil, 20, nil, 10)
	Arr.StableSortInplace(holedIn)
	assert(holedIn.n == 4 and holedIn[1] == 10 and holedIn[2] == 20 and holedIn[3] == nil, "StableSortInplace 구멍")
	-- [4] 는 입력에서 값(10)이던 칸 — 꼬리를 정말 비웠는지는 여기서만 보입니다
	assert(holedIn[4] == nil, "StableSortInplace 는 꼬리를 비움")
	-- "이미 순서면 병합 생략" 이 살아 있는지: 정렬된 입력에서 비교가 n 에 가깝게
	local compares = 0
	Arr.StableSort(Arr.Range(1, 200), function(a: number, b: number): boolean
		compares += 1
		return a < b
	end)
	assert(compares < 2 * 200, `정렬된 입력의 StableSort 비교 횟수 {compares}`)

	-- SortBy: 키는 값마다 한 번, 안정, 구멍엔 키를 안 부름
	local calls = 0
	const words = Arr.Of<<string?>>("ccc", "a", nil, "bb", "dd")
	const byLen = Arr.SortBy(words, function(w: string?): number
		calls += 1
		return #(w :: string)
	end)
	assert(calls == 4, `SortBy 키는 값마다 한 번 ({calls})`)
	samePrefix(byLen, { "a", "bb", "dd", "ccc" }, "SortBy 키 순서")
	-- 안정성은 입력 순서가 사전순과 **반대**일 때만 보입니다
	samePrefix(
		Arr.SortBy(Arr.Of("dd", "bb", "a"), function(w: string): number
			return #w
		end),
		{ "a", "dd", "bb" },
		"SortBy 안정(dd 가 bb 앞 — 입력 순서)"
	)
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
		const got = Arr.SortBy(input, function(r: Rec): number
			return r.k
		end)
		for idx = 1, input.n do
			assert(got[idx] == expected[idx], "SortBy 무작위 대조")
		end
	end
	const byInplace = Arr.Of(30, 10, 20)
	assert(Arr.SortByInplace(byInplace, function(v: number): number
		return -v
	end) == byInplace, "SortByInplace 는 자기 자신")
	same(byInplace, { 30, 20, 10 }, "SortByInplace")
	const byHoled = Arr.Of<<number?>>(30, nil, 10)
	Arr.SortByInplace(byHoled, function(v: number?): number
		return v :: number
	end)
	assert(
		byHoled.n == 3 and byHoled[1] == 10 and byHoled[2] == 30 and byHoled[3] == nil,
		"SortByInplace 구멍은 꼬리로"
	)

	-- NthElement: 모든 k 를 정렬 결과와 대조, 음수, 범위 밖, 원본 불변
	for _ = 1, 100 do
		const input = randomNums(math.random(1, 60), math.random(1, 30))
		const ref = sortedCopy(input)
		const before = table.move(input, 1, input.n, 1, {}) :: { number }
		for k = 1, input.n do
			assert(Arr.NthElement(input, k) == ref[k], "NthElement 대조")
			assert(Arr.NthElement(input, -k) == ref[input.n - k + 1], "NthElement 음수")
		end
		same(input, before, "NthElement 는 원본을 안 건드림")
	end
	const five = Arr.Of(50, 10, 40, 20, 30)
	assert(
		Arr.NthElement(five, 0) == nil and Arr.NthElement(five, 6) == nil and Arr.NthElement(five, -6) == nil,
		"NthElement 범위 밖"
	)
	assert(Arr.NthElement(emptyNum(), 1) == nil, "NthElement 빈 것")
	assert(Arr.NthElement(Arr.Of<<number?>>(30, nil, 10, 20), 3) == 30, "NthElement 는 구멍을 뺀 순위")
	-- 음수도 구멍을 뺀 개수 기준 — n 기준이면 -1 이 한 칸 어긋납니다
	assert(
		Arr.NthElement(Arr.Of<<number?>>(30, nil, 10, 20), -1) == 30,
		"NthElement 음수는 구멍을 뺀 개수 기준"
	)
	assert(Arr.NthElement(Arr.Of<<number?>>(30, nil, 10, 20), -3) == 10, "NthElement 음수 끝")
	assert(Arr.NthElement(five, (Arr.Len(five) + 1) // 2) == 30, "NthElement 중앙값")

	-- NthElementInplace: k 자리 값이 맞고 왼쪽 ≤, 오른쪽 ≥
	for _ = 1, 100 do
		const input = randomNums(math.random(1, 60), math.random(1, 30))
		const ref = sortedCopy(input)
		const k = math.random(1, input.n)
		assert(Arr.NthElementInplace(input, k) == input, "NthElementInplace 는 자기 자신")
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
	Arr.NthElementInplace(holedNth, 2)
	assert(
		holedNth.n == 5 and holedNth[2] == 20 and holedNth[4] == nil and holedNth[5] == nil,
		"NthElementInplace 구멍"
	)
	const holedNthNeg = Arr.Of<<number?>>(nil, 30, nil, 10, 20)
	Arr.NthElementInplace(holedNthNeg, -1)
	assert(holedNthNeg[3] == 30, "NthElementInplace 음수는 구멍을 뺀 개수 기준")
	-- 범위 밖 k 는 구멍만 치웁니다(문서화된 동작)
	const holedNthOut = Arr.Of<<number?>>(nil, 20, nil, 10)
	Arr.NthElementInplace(holedNthOut, 99)
	assert(holedNthOut[1] ~= nil and holedNthOut[2] ~= nil, "NthElementInplace 범위 밖: 값은 앞으로")
	assert(
		holedNthOut[3] == nil and holedNthOut[4] == nil and holedNthOut.n == 4,
		"NthElementInplace 범위 밖: 구멍은 꼬리로"
	)

	-- PartialSort: 정렬 결과의 앞 k 개와 같음
	for _ = 1, 100 do
		const input = randomNums(math.random(0, 80), math.random(1, 40))
		const ref = sortedCopy(input)
		const k = math.random(0, input.n + 3)
		const got = Arr.PartialSort(input, k)
		assert(got.n == math.min(k, input.n), "PartialSort 길이")
		for idx = 1, got.n do
			assert(got[idx] == ref[idx], "PartialSort 대조")
		end
	end
	same(
		Arr.PartialSort(Arr.Of(10, 50, 30, 40, 20), 2, function(a: number, b: number): boolean
			return a > b
		end),
		{ 50, 40 },
		"PartialSort 뒤집은 비교자 = 가장 큰 k 개"
	)
	assert(
		Arr.PartialSort(Arr.Of(10, 20), 0).n == 0 and Arr.PartialSort(Arr.Of(10, 20), -1).n == 0,
		"PartialSort k ≤ 0"
	)
	const partialHoles = Arr.PartialSort(Arr.Of<<number?>>(30, nil, 10, 20), 2)
	assert(partialHoles.n == 2, "PartialSort 는 값만 셈")
	samePrefix(partialHoles, { 10, 20 }, "PartialSort 구멍은 건너뜀")

	-- PartialSortInplace: 앞 k 칸이 정렬되어 맞고, 원소 구성은 그대로
	for _ = 1, 100 do
		const input = randomNums(math.random(0, 80), math.random(1, 40))
		const ref = sortedCopy(input)
		const k = math.random(0, input.n + 3)
		assert(Arr.PartialSortInplace(input, k) == input, "PartialSortInplace 는 자기 자신")
		for idx = 1, math.min(k, input.n) do
			assert(input[idx] == ref[idx], "PartialSortInplace 앞 k 칸")
		end
		sameList(sortedCopy(input), ref, "PartialSortInplace 는 원소 구성을 안 바꿈")
	end
	const holedPartial = Arr.Of<<number?>>(40, nil, 10, 30, nil, 20)
	Arr.PartialSortInplace(holedPartial, 2)
	assert(holedPartial.n == 6 and holedPartial[1] == 10 and holedPartial[2] == 20, "PartialSortInplace 구멍")
	assert(holedPartial[5] == nil and holedPartial[6] == nil, "PartialSortInplace 구멍은 꼬리로")

	-- MergeSorted: 이어붙여 정렬한 것과 같고, 같은 순위면 self 쪽이 먼저
	for _ = 1, 100 do
		const left = Arr.SortInplace(randomNums(math.random(0, 40), 20))
		const right = Arr.SortInplace(randomNums(math.random(0, 40), 20))
		const got = Arr.MergeSorted(left, right)
		const ref = sortedCopy(Arr.Concat(left, right))
		assert(got.n == #ref, "MergeSorted 길이")
		samePrefix(got, ref, "MergeSorted 대조")
	end
	const leftRecs = Arr.Of<<Rec>>({ k = 1, id = 10 }, { k = 2, id = 20 })
	const rightRecs = Arr.Of<<Rec>>({ k = 1, id = 30 }, { k = 2, id = 40 })
	const mergedRecs = Arr.MergeSorted(leftRecs, rightRecs, byK)
	assert(
		mergedRecs[1].id == 10 and mergedRecs[2].id == 30 and mergedRecs[3].id == 20 and mergedRecs[4].id == 40,
		"MergeSorted 안정(self 먼저)"
	)
	const mergedHoles = Arr.MergeSorted(Arr.Of<<number?>>(nil, 10, nil, 30), Arr.Of<<number?>>(20, nil))
	assert(mergedHoles.n == 3, "MergeSorted 는 구멍을 건너뛰어 조밀함")
	samePrefix(mergedHoles, { 10, 20, 30 }, "MergeSorted 구멍")
	same(Arr.MergeSorted(emptyNum(), emptyNum()), {}, "MergeSorted 빈 것")

	-- IsSorted
	assert(Arr.IsSorted(Arr.Of(10, 20, 20, 30)), "IsSorted 같은 값 허용")
	assert(not Arr.IsSorted(Arr.Of(10, 30, 20)), "IsSorted 아님")
	assert(Arr.IsSorted(Arr.Of<<number?>>(10, nil, 20)), "IsSorted 구멍 건너뜀")
	-- 구멍에서 비교를 끊으면(prev 리셋) 이게 통과해 버립니다
	assert(not Arr.IsSorted(Arr.Of<<number?>>(20, nil, 10)), "IsSorted 는 구멍 너머로 비교")
	assert(Arr.IsSorted(emptyNum()) and Arr.IsSorted(Arr.Of(10)), "IsSorted 빈 것·하나")
	assert(
		Arr.IsSorted(Arr.Of(30, 20, 10), function(a: number, b: number): boolean
			return a > b
		end),
		"IsSorted 비교자"
	)
end
print("PASS")

print("=== 17c. SortInplaceUnchecked 는 n 밖의 값을 끌어오지 않는다 (M0 6라운드) ===")
do
	-- (b) n 없는 대입 구멍 테이블: FromTable 은 # 로 n=1 을 잡고 raw[3] 은 n 밖에 남음
	const sparse = {} :: { number }
	sparse[1] = 10
	sparse[3] = 30
	const a = Arr.FromTable(sparse)
	Arr.PushBack(a, 20)
	Arr.SortInplaceUnchecked(a, function(x: number, y: number): boolean
		return x > y
	end)
	assert(a.n == 2 and a[1] == 20 and a[2] == 10, "n 밖의 30 을 끌어와 10 을 잃으면 안 됨")
	-- (a) n 이 있고 n 뒤 값이 해시부에 — 비우기 루프가 # 경계에 막힘
	const hashTail = { n = 2 } :: any
	hashTail[1], hashTail[2], hashTail[5], hashTail[7] = 10, 20, 50, 70
	const b = Arr.FromTable(hashTail)
	Arr.PushBack(b, 30)
	Arr.PushBack(b, 40)
	Arr.SortInplaceUnchecked(b)
	same(b, { 10, 20, 30, 40 }, "n 밖의 해시부 값이 정렬에 섞이면 안 됨")
end
print("PASS")

print("=== 17b. FromTable 은 평범한 테이블만 입양 (M0 리뷰) ===")
do
	-- 입양한 테이블의 메타테이블이 남으면 범위 밖 조회가 메타메소드 값을 주고
	-- 쓰기가 사용자 `__newindex` 를 타며, 1.59배 인덱싱 세금도 다시 붙습니다.
	-- "인스턴스는 평범한 테이블" 전제를 지키려 거부하고 `CloneFromTable` 로 안내합니다.
	const withMeta = setmetatable({ 10, 20 }, {
		__index = function()
			return 99
		end,
	}) :: { number }
	const ok, err = pcall(function()
		Arr.FromTable(withMeta)
	end)
	assert(not ok and string.find(tostring(err), "CloneFromTable", 1, true) ~= nil, `FromTable 메타테이블: {err}`)
	assert(string.find(tostring(err), "spec.arr", 1, true) ~= nil, "에러는 사용자 줄")
	-- 복사판은 됩니다(복사본은 평범한 테이블)
	const copied = Arr.CloneFromTable(withMeta)
	assert(getmetatable(copied) == nil and copied.n == 2 and copied[1] == 10, "CloneFromTable 은 평범한 테이블")

	-- 이미 Arr 인 것을 다시 입양하면 `#` 로 원본의 `n` 을 덮어써 구멍 뒤가 사라졌음
	-- (M0 2라운드 — M0 이전부터). 거부하고 원본은 그대로.
	const already = Arr.Of<<number?>>(10, nil, 30)
	const ok2, err2 = pcall(function()
		Arr.FromTable(already :: any)
	end)
	assert(not ok2 and string.find(tostring(err2), "already", 1, true) ~= nil, `FromTable 이미 Arr: {err2}`)
	assert(already.n == 3, "원본의 n 은 그대로")
	-- 동결된 테이블은 입양할 수 없습니다(태그·n 을 못 씀) — 라이브러리 줄의
	-- "readonly table" 대신 사용자 줄에서 안내
	const ok3, err3 = pcall(function()
		Arr.FromTable(table.freeze({ 10, 20 }))
	end)
	assert(not ok3 and string.find(tostring(err3), "CloneFromTable", 1, true) ~= nil, `FromTable 동결: {err3}`)
	assert(string.find(tostring(err3), "spec.arr", 1, true) ~= nil, "동결 에러는 사용자 줄")
end
print("PASS")

print("=== 18. 회귀 — 2026-09-30 리뷰 (M1·M2·구멍) ===")
do
	-- (1) quickselect 가 "정렬된 배열 끝에 최솟값" 같은 흔한 모양에서 O(n²) 였음.
	--     시간 대신 비교 횟수로 잽니다(이차면 n=2000 에서 수십만 번).
	local function countingLess(): ((number, number) -> boolean, () -> number)
		local calls = 0
		return function(a: number, b: number): boolean
			calls += 1
			return a < b
		end, function(): number
			return calls
		end
	end
	const size = 2000
	local function minBack(): Arr<number>
		const a = Arr.Range(1, size - 1)
		Arr.PushBack(a, 0)
		return a
	end
	local function maxFront(): Arr<number>
		const a = Arr.Of(size)
		Arr.PushBackArray(a, Arr.Range(1, size - 1))
		return a
	end
	const makers: { () -> Arr<number> } = { minBack, maxFront }
	for _, make in makers do
		for _, run in
			{
				function(a: Arr<number>, lt: (number, number) -> boolean)
					assert(
						Arr.NthElement(a, size // 2, lt) == size // 2 - (if a[1] == 1 then 1 else 0),
						"NthElement 값"
					)
				end,
				function(a: Arr<number>, lt: (number, number) -> boolean)
					Arr.NthElementInplace(a, size // 2, lt)
				end,
				function(a: Arr<number>, lt: (number, number) -> boolean)
					Arr.PartialSortInplace(a, size // 2, lt)
				end,
			}
		do
			const lt, calls = countingLess()
			run(make(), lt)
			assert(calls() < 60 * size, `선택이 이차로 떨어짐: 비교 {calls()} 번`)
		end
	end

	-- (1b) 흔한 모양은 피벗 후보를 1/4·1/2·3/4 로 옮겨 풀었지만, 어떤 피벗 규칙이든
	--      이차로 끌어내리는 입력이 있습니다. McIlroy 의 적대적 비교자("A Killer
	--      Adversary for Quicksort")로 **예산 폴백**을 강제로 태웁니다 — 폴백이 없으면
	--      n=4000 에서 비교 300만 번(751n), 있으면 약 70n 이었습니다(실측).
	--      끝난 뒤 적대자가 아직 정하지 않은 원소(gas)에 **서로 다른** 순위를 줘야
	--      정확성까지 봅니다 — gas 끼리 동률로 두면 폴백이 아무것도 안 해도 통과했습니다
	--      (2라운드 리뷰가 돌연변이로 재현). gas 는 어떤 solid 보다 크다고만 답했고 gas
	--      끼리는 답한 적이 없으니, solid 뒤에 아무 순서로 붙여도 모든 대답과 맞습니다.
	local function adversaryFor(n: number): ((number, number) -> boolean, () -> number, () -> { number })
		const gas = n + 1
		const rank = table.create(n, gas) :: { number }
		local solid, candidate, calls = 0, 0, 0
		local function adversary(x: number, y: number): boolean
			calls += 1
			if rank[x] == gas and rank[y] == gas then
				if x == candidate then
					rank[x] = solid
				else
					rank[y] = solid
				end
				solid += 1
			end
			if rank[x] == gas then
				candidate = x
			elseif rank[y] == gas then
				candidate = y
			end
			return rank[x] < rank[y]
		end
		local function settle(): { number }
			for id = n, 1, -1 do
				if rank[id] == gas then
					rank[id] = solid
					solid += 1
				end
			end
			return rank
		end
		return adversary, function(): number
			return calls
		end, settle
	end
	do
		const n = 4000
		const k = n // 2
		-- 값 판: 돌려준 값이 완성된 순서에서 정확히 k 번째(순위 k-1)
		const adversary, calls, settle = adversaryFor(n)
		const picked = Arr.NthElement(Arr.Range(1, n), k, adversary) :: number
		assert(calls() < 150 * n, `적대적 입력에서 선택이 이차로 떨어짐: 비교 {calls()} 번`)
		assert(settle()[picked] == k - 1, "적대적 입력에서 NthElement 가 k 번째가 아님")

		-- 제자리 판: 순열 보존 + k 자리 + 분할 성질
		const adversary2, calls2, settle2 = adversaryFor(n)
		const arr = Arr.NthElementInplace(Arr.Range(1, n), k, adversary2)
		assert(calls2() < 150 * n, `적대적 입력에서 NthElementInplace 가 이차: {calls2()}`)
		const rank = settle2()
		const seen = table.create(n, false)
		for idx = 1, n do
			const id = arr[idx]
			assert(id ~= nil and not seen[id], "NthElementInplace 가 원소를 잃거나 겹침")
			seen[id] = true
		end
		assert(arr.n == n and rank[arr[k]] == k - 1, "NthElementInplace 의 k 자리")
		for idx = 1, n do
			if idx < k then
				assert(rank[arr[idx]] < rank[arr[k]], "NthElementInplace 왼쪽")
			elseif idx > k then
				assert(rank[arr[idx]] > rank[arr[k]], "NthElementInplace 오른쪽")
			end
		end
	end

	-- (2) PartialSort 가 k 로 버퍼를 할당해 math.huge 에서 크래시, 큰 k 에서 느렸음
	same(Arr.PartialSort(Arr.Of(50, 30, 10, 40, 20), math.huge), { 10, 20, 30, 40, 50 }, "PartialSort(math.huge)")
	same(Arr.PartialSort(Arr.Of(50, 30, 10), 1e8), { 10, 30, 50 }, "PartialSort(1e8)")

	-- (3) 엄격하지 않은 비교자(<=)에서 선택이 범위를 넘어 달렸음 — nil 을 받아도
	--     에러가 안 나는 비교자면 무한 루프. 이제 분명한 에러로 멈춥니다.
	local function nonStrict(a: number?, b: number?): boolean
		return (a or 0) <= (b or 0)
	end
	for _, run in
		{
			function()
				Arr.PartialSortInplace(Arr.Of(30, 30, 30, 30, 30), 2, nonStrict)
			end,
			function()
				Arr.NthElement(Arr.Of(30, 30), 1, nonStrict)
			end,
			-- 힙·table.sort 경로는 스캔이 없어 조용히 틀렸음(2라운드) — 진입 검사로 일관되게
			function()
				Arr.PartialSort(Arr.Of(60, 30, 20, 10, 40, 50), 4, nonStrict)
			end,
			function()
				Arr.PartialSortInplace(Arr.Of(60, 30, 20, 10, 40, 50), 6, nonStrict)
			end,
		}
	do
		const ok, err = pcall(run :: () -> ())
		assert(not ok and string.find(tostring(err), "strict", 1, true) ~= nil, `엄격하지 않은 비교자: {err}`)
	end

	-- (4) Shuffle 에 실수를 돌려주는 rng(Roblox Random:NextNumber 모양)를 주면
	--     구멍과 데이터 유실이 조용히 생겼음. 1차에서 0 쪽으로 잘라 가뒀더니
	--     이번엔 `idx` 가 영영 안 뽑혀 **사톨로 순열**(24개 중 6개만)로 치우쳤음
	--     (2라운드 리뷰) — 조용히 치우치느니 계약 위반을 에러로 알립니다.
	const badRngs: { (number, number) -> number } = {
		function(lo: number, hi: number): number
			return lo + (hi - lo) * 0.5
		end,
		function(_lo: number, hi: number): number
			return hi + 1
		end,
		function(_lo: number, _hi: number): number
			return 0 / 0
		end,
	}
	for _, rng in badRngs do
		const ok, err = pcall(function()
			Arr.Shuffle(Arr.Of(10, 20, 30, 40), nil, nil, rng)
		end)
		assert(not ok and string.find(tostring(err), "rng", 1, true) ~= nil, `rng 계약 위반: {err}`)
	end
	-- 정수 rng 는 그대로(Random:NextInteger 모양)
	const fixed = Arr.Shuffle(Arr.Of(10, 20, 30, 40), nil, nil, function(lo: number, _hi: number): number
		return lo
	end)
	assert(fixed.n == 4 and Arr.Join(Arr.Sort(fixed), ",") == "10,20,30,40", "정수 rng 는 순열")

	-- (5) Sized/FromFunc 의 소수 길이가 안 잘려 n 이 3.5 가 되고 값이 사라졌음
	const sized = Arr.Sized(2.5, 0)
	Arr.PushBack(sized, 7)
	assert(sized.n == 3 and Arr.Join(sized, ",") == "0,0,7", "Sized 소수 길이는 0 쪽으로")
	assert(Arr.FromFunc(2.9, function(i: number): number
		return i * 10
	end).n == 2, "FromFunc 소수 길이")
	assert(not pcall(Arr.Sized, -1, 0), "Sized 음수 길이는 에러")
	assert(
		not pcall(Arr.Sized, math.huge, 0),
		"Sized 무한 길이는 에러(table.create 의 엉뚱한 에러 대신)"
	)
	assert(not pcall(Arr.FromFunc, -1, function(i: number): number
		return i
	end), "FromFunc 음수 길이는 에러")

	-- (6) 구간 인자에 NaN — table.move 의 엉뚱한 에러나 조용한 무동작 대신 분명한 에러
	for _, run in
		{
			function()
				Arr.Slice(Arr.Of(10, 20), 0 / 0)
			end,
			function()
				Arr.Splice(Arr.Of(10, 20), 1, 0 / 0, Arr.Of(30))
			end,
			function()
				Arr.Some(Arr.Of(10, 20), function(v: number): boolean
					return v > 0
				end, 0 / 0)
			end,
		}
	do
		const ok, err = pcall(run :: () -> ())
		assert(not ok and string.find(tostring(err), "NaN", 1, true) ~= nil, `NaN 구간: {err}`)
	end

	-- (7) 에러는 **사용자 호출 줄**을 가리켜야 합니다 — 새 배열판(Reverse/Rotate/
	--     Shuffle)은 `XxxInplace(Clone(self))` 를 거쳐 한 프레임 깊어져 라이브러리
	--     줄을 가리켰음(2라운드 리뷰). 그리고 k 의 NaN 도 구간 NaN 과 같은 정책으로.
	const nanCalls: { () -> () } = {
		function()
			Arr.Reverse(Arr.Of(10, 20), 0 / 0)
		end,
		function()
			Arr.Rotate(Arr.Of(10, 20), 1, 0 / 0)
		end,
		function()
			Arr.Shuffle(Arr.Of(10, 20), 0 / 0)
		end,
		function()
			Arr.Reverse(Arr.Of(10, 20), 0 / 0)
		end,
		function()
			Arr.Slice(Arr.Of(10, 20), 0 / 0)
		end,
		function()
			Arr.NthElement(Arr.Of(10, 20), 0 / 0)
		end,
		function()
			Arr.PartialSort(Arr.Of(10, 20), 0 / 0)
		end,
		function()
			Arr.NthElementInplace(Arr.Of(10, 20), 0 / 0)
		end,
		function()
			Arr.PartialSortInplace(Arr.Of(10, 20), 0 / 0)
		end,
	}
	for _, run in nanCalls do
		const ok, err = pcall(run)
		assert(not ok and string.find(tostring(err), "NaN", 1, true) ~= nil, `NaN 인자: {err}`)
		assert(string.find(tostring(err), "spec.arr", 1, true) ~= nil, `에러가 사용자 줄이 아님: {err}`)
	end

	-- (8) 3라운드 리뷰. 메시지와 **사용자 줄**을 같이 봅니다 — 메시지만 보면 에러
	--     수준(level)이 틀려도, `table.create` 가 대신 터져도 통과했습니다.
	local function expectError(label: string, needle: string, run: () -> ())
		const ok, err = pcall(run)
		const text = tostring(err)
		assert(not ok, `{label}: 에러가 안 남`)
		assert(string.find(text, needle, 1, true) ~= nil, `{label}: 메시지에 "{needle}" 없음: {text}`)
		assert(string.find(text, "spec.arr", 1, true) ~= nil, `{label}: 사용자 줄이 아님: {text}`)
	end
	-- 삽입 위치의 NaN: InsertArray 는 값이 음수 키로 조용히 사라졌고(버그), Insert/
	-- InsertMany 는 라이브러리 줄의 "table index is NaN" 이었음
	expectError("Insert NaN", "NaN", function()
		Arr.Insert(Arr.Of(10, 20, 30), 0 / 0, 99)
	end)
	expectError("InsertMany NaN", "NaN", function()
		Arr.InsertMany(Arr.Of(10, 20, 30), 0 / 0, 98, 99)
	end)
	expectError("InsertArray NaN", "NaN", function()
		Arr.InsertArray(Arr.Of(10, 20, 30), 0 / 0, Arr.Of(98, 99))
	end)
	-- 에러 수준을 지키는 줄들(돌연변이로 level 을 바꿔도 통과하던 것)
	expectError("Rotate shift", "finite", function()
		Arr.Rotate(Arr.Of(10, 20, 30), math.huge)
	end)
	expectError("RotateInplace shift", "finite", function()
		Arr.RotateInplace(Arr.Of(10, 20, 30), 0 / 0)
	end)
	expectError("Shuffle rng", "rng", function()
		Arr.Shuffle(Arr.Of(10, 20, 30), nil, nil, function(lo: number, _hi: number): number
			return lo + 0.5
		end)
	end)
	expectError("엄격성", "strict", function()
		Arr.NthElement(Arr.Of(30, 10, 20), 2, function(a: number, b: number): boolean
			return a <= b
		end)
	end)
	expectError("Sized 무한", "length", function()
		Arr.Sized(math.huge, 0)
	end)
	expectError("Sized 너무 김", "length", function()
		Arr.Sized(1e300, 0)
	end)
	expectError("FromFunc 무한", "length", function()
		Arr.FromFunc(math.huge, function(i: number): number
			return i
		end)
	end)
	-- Range: from/to 의 NaN·무한과 step 에러도 사용자 줄에서
	expectError("Range to 무한", "Range", function()
		Arr.Range(1, math.huge)
	end)
	expectError("Range from NaN", "Range", function()
		Arr.Range(0 / 0, 5)
	end)
	expectError("Range step 0", "Range", function()
		Arr.Range(1, 5, 0)
	end)
	-- 두 검사를 구분합니다 — inf 는 "too long" 으로도 걸려 끝점 검사를 못 지켰음(4라운드)
	expectError("Range to NaN", "bounds", function()
		Arr.Range(1, 0 / 0)
	end)
	expectError("Range 너무 김", "too long", function()
		Arr.Range(1, 1e300)
	end)
	-- 아주 큰 shift: Luau 의 `%` 는 a - floor(a/b)*b 라 |a| 가 2^53 근처를 넘으면
	-- 틀린 나머지(범위 밖 포함)가 나와 0 이하 키에 쓰고 뒤에 구멍을 냈음(4라운드, 버그)
	const bigShift = Arr.Range(1, 11)
	Arr.RotateInplace(bigShift, 1e17)
	assert(bigShift.n == 11 and bigShift[0] == nil and bigShift[11] ~= nil, "큰 shift 가 배열을 망가뜨림")
	-- 기대 나머지는 구현(math.fmod)과 **독립적으로** 정수 산술로 계산한 상수입니다
	-- (5라운드 리뷰가 Python 으로 확인): 1e17 mod 11 = 10, 1e300 mod 11 = 7,
	-- -2^53 = -9007199254740992 ≡ -2 ≡ 3 (mod 5).
	same(bigShift, Arr.Rotate(Arr.Range(1, 11), 10) :: any, "큰 shift 는 정확한 나머지만큼")
	same(
		Arr.Rotate(Arr.Of(10, 20, 30, 40, 50), -2 ^ 53),
		Arr.Rotate(Arr.Of(10, 20, 30, 40, 50), 3) :: any,
		"-2^53 mod 5 = 3"
	)
	same(Arr.Rotate(Arr.Range(1, 11), 1e300), Arr.Rotate(Arr.Range(1, 11), 7) :: any, "1e300 도 정확한 나머지")

	-- 빈 구간이어도 shift 는 검사합니다(구간 NaN 이 빈 배열에서도 에러인 것과 같게)
	expectError("빈 배열 Rotate NaN", "finite", function()
		Arr.Rotate(Arr.Of<<number>>(), 0 / 0)
	end)
	-- At 의 NaN 도 같은 정책(조용한 nil 대신 에러)
	expectError("At NaN", "NaN", function()
		Arr.At(Arr.Of(10, 20), 0 / 0)
	end)

	-- 진입 검사가 **비교가 필요 없는 호출**까지 깨뜨리던 회귀(3라운드): 비교할 수
	-- 없는 원소라도 비교가 안 일어나면 전처럼 동작해야 합니다(`Sort` 와 같게).
	const lonely = {}
	assert(Arr.NthElement(Arr.Of(lonely), 1) == lonely, "원소 하나의 NthElement 는 비교 없음")
	assert(Arr.NthElement(Arr.Of({}, {}), 5) == nil, "범위 밖 k 는 비교 없음")
	assert(Arr.PartialSort(Arr.Of({}, {}), 0).n == 0, "PartialSort(0) 은 비교 없음")
	assert(Arr.PartialSort(Arr.Of(true), 1).n == 1, "원소 하나의 PartialSort 는 비교 없음")
	assert(Arr.NthElementInplace(Arr.Of(lonely), 1)[1] == lonely, "원소 하나의 NthElementInplace")
	assert(Arr.PartialSortInplace(Arr.Of(lonely), 1)[1] == lonely, "원소 하나의 PartialSortInplace")

	-- n 이 -0 이 되던 것(`Sized(-0.5)` → `tostring(n) == "-0"`)
	assert(tostring(Arr.Sized(-0.5, 1).n) == "0", "길이는 +0")
end
print("PASS")

print("=== 19. 회귀 — 2026-10-02 Gemini(agy) 사냥 ===")
do
	-- (1) FromIter 가 "값이 하나인가 둘인가" 를 둘째 값의 nil 로 갈라, `(index, nil)` 을
	--     내는 순회자(`Arr.Iter` 의 구멍)에서 **인덱스를 값으로** 담았음 — 조용한 오염.
	--     반환 개수로 가릅니다.
	const holed = Arr.Of<<number?>>(10, nil, 30)
	const back = Arr.FromIter(Arr.Iter(holed))
	assert(back.n == 3 and back[1] == 10 and back[2] == nil and back[3] == 30, `Iter 왕복: {back[2]}`)
	-- 값이 하나인 순회자(string.gmatch)와 둘인 순회자(ipairs)는 그대로
	-- 값이 하나인 순회자가 state·control 을 제대로 받는지(3라운드 — gmatch 는 둘 다 무시해
	-- 루프를 나눈 뒤 이 경로의 `key = a`·state 전달을 지키는 테스트가 없었음)
	const upto = function(limit: number, i: number): number?
		if i < limit then
			return i + 1
		end
		return nil
	end
	const counted = Arr.FromIter(upto, 3, 0)
	assert(counted.n == 3 and counted[1] == 1 and counted[2] == 2 and counted[3] == 3, `upto: n={counted.n}`)
	-- 키·값이 false 여도 순회의 끝이 아님(4라운드 — 끝 판정을 `not a` 로 바꿔도 통과했음).
	-- 값 둘: 첫 키와 중간 키가 false. 값 하나: false 로 시작하고 중간에도 false.
	-- (키가 false 면 다음 호출에 키를 못 쓰니 위치는 클로저가 셉니다.)
	local twoStep = 0
	const twoFalse = Arr.FromIter(function(): (any, any)
		twoStep += 1
		if twoStep == 1 then
			return false, 7
		elseif twoStep == 2 then
			return true, 8
		elseif twoStep == 3 then
			return false, 9
		end
		return nil, nil
	end)
	assert(
		twoFalse.n == 3 and twoFalse[1] == 7 and twoFalse[2] == 8 and twoFalse[3] == 9,
		`값 둘, 키 false: n={twoFalse.n}`
	)
	const oneFalse = Arr.FromIter(coroutine.wrap(function()
		coroutine.yield(false)
		coroutine.yield(true)
		coroutine.yield(false)
		coroutine.yield(true)
	end))
	assert(
		oneFalse.n == 4 and oneFalse[1] == false and oneFalse[2] == true and oneFalse[3] == false,
		`값 하나, false: n={oneFalse.n}`
	)
	const words = Arr.FromIter(string.gmatch("ab cd", "%a+"))
	assert(words.n == 2 and words[1] == "ab" and words[2] == "cd", "gmatch")
	const pairsOf = Arr.FromIter(ipairs({ 10, 20 }))
	assert(pairsOf.n == 2 and pairsOf[1] == 10 and pairsOf[2] == 20, "ipairs")
	-- 구멍 자리표시자가 새지 않음 — 첫 원소가 구멍, 전부 구멍, 구멍이 많은 것
	const firstHole = Arr.FromIter(Arr.Iter(Arr.Of<<number?>>(nil, 20, nil)))
	assert(firstHole.n == 3 and firstHole[1] == nil and firstHole[2] == 20 and firstHole[3] == nil, "첫 구멍")
	-- 첫 원소만 구멍(뒤 구멍이 정리를 대신 켜 주지 못하게), 진짜 false 는 구멍이 아님
	-- (2라운드 리뷰 — 이 둘이 없어 돌연변이가 살아남았음)
	const onlyFirst = Arr.FromIter(Arr.Iter(Arr.Of<<number?>>(nil, 20)))
	assert(onlyFirst.n == 2 and onlyFirst[1] == nil and onlyFirst[2] == 20, `첫 원소만 구멍: {onlyFirst[1]}`)
	const falses = Arr.FromIter(Arr.Iter(Arr.Of<<boolean?>>(false, nil, false)))
	assert(falses.n == 3 and falses[1] == false and falses[2] == nil and falses[3] == false, "false 는 값")
	const allHoles = Arr.FromIter(Arr.Iter(Arr.Sized<<number?>>(4, nil)))
	assert(allHoles.n == 4 and allHoles[1] == nil and allHoles[4] == nil, "전부 구멍")
	const sparse = Arr.Sized<<number?>>(9, nil)
	for idx = 1, 9, 3 do
		sparse[idx] = idx * 10
	end
	const sparseBack = Arr.FromIter(Arr.Iter(sparse))
	for idx = 1, 9 do
		assert(sparseBack[idx] == sparse[idx], `많은 구멍 {idx}: {sparseBack[idx]}`)
	end

	-- (2) FromTable 의 "n 밖 raw 칸 비우기" — `#` 가 닿는 데까지가 약속입니다. 구멍 뒤·큰
	--     키처럼 `#` 가 안 닿는 n 밖 키는 계약 밖(전부 지우면 입양이 복사보다 느려져
	--     되돌림, perf 20절) — CloneFromTable 은 1..n 만 복사하니 거기선 깨끗합니다.
	const tail = Arr.FromTable({ n = 1, 10, 20, 30 } :: any)
	assert(tail.n == 1 and rawget(tail :: any, 2) == nil and rawget(tail :: any, 3) == nil, "# 가 닿는 n 밖")
	const sparseClone = Arr.CloneFromTable({ n = 1, [1] = 10, [3] = 30, [100] = 9 } :: any)
	assert(
		rawget(sparseClone :: any, 3) == nil and rawget(sparseClone :: any, 100) == nil,
		"희소 테이블은 Clone 이 깨끗"
	)
	-- 구멍 든 1..n 은 그대로(구멍은 원소 자리)
	const inner = Arr.FromTable({ n = 3, [1] = 1, [3] = 3 } :: any)
	assert(inner.n == 3 and inner[1] == 1 and inner[2] == nil and inner[3] == 3, "n 안의 구멍")
end
print("PASS")

print()
print("=== ALL PASS (Arr) ===")

return true

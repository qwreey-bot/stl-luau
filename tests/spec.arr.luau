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
same(Arr.Adopt({ 4, 5 }), { 4, 5 }, "Adopt")
same(Arr.FromTable({ 6, 7 }), { 6, 7 }, "FromTable")
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
-- Adopt 은 입양(복사 안 함), FromTable 은 복사
local adopted = { 1, 2 }
local viaAdopt = Arr.Adopt(adopted)
adopted[1] = 99
assert(viaAdopt[1] == 99, "Adopt 은 원본 테이블을 입양해야 합니다")
local cloned = { 1, 2 }
local viaClone = Arr.FromTable(cloned)
cloned[1] = 99
assert(viaClone[1] == 1, "FromTable 은 복사해야 합니다")
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
	assert(stl.List.IndexOf(a, 20) == 2, "List.IndexOf")
	assert(stl.List.IndexOf(a, 99) == nil, "List.IndexOf 없음")
	assert(stl.List.Count(a) == 3, "List.Count")
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
assert(Arr.Reduce(Arr.Of(1, 2, 3), function(a: number, b: number)
	return a + b
end) == 6, "Reduce")
assert(Arr.Reduce(Arr.Of(5), function(a: number, b: number)
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
	-- **꼬리** 구멍(`[3]` 만 비움) — 경계가 2 하나뿐이라 `#` 가 어느 버전에서든 2(≠ n). 예전엔 가운데 구멍
	-- (`[1], [3]` 만 참)으로 적었는데, 그건 경계가 1·3 둘이라 `#` 가 아무거나 돌려줘도 되고(Lua 규격) luau 0.742 는 3 을
	-- 돌려줘 `# == n` — 그물에 안 걸려 정렬이 구멍에서 터졌습니다(2026-10-14 버전 올리기). 가운데 구멍에서 터지는 것은
	-- unchecked 의 계약 안(위의 SumUnchecked 와 같음).
	const holedSorted = (Arr.Sized<<number?>>(3, nil) :: any) :: Arr<number>
	holedSorted[1], holedSorted[2] = 2, 1
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
	-- (b) n 없는 대입 구멍 테이블: Adopt 은 # 로 n=1 을 잡고 raw[3] 은 n 밖에 남음
	const sparse = {} :: { number }
	sparse[1] = 10
	sparse[3] = 30
	const a = Arr.Adopt(sparse)
	Arr.PushBack(a, 20)
	Arr.SortInplaceUnchecked(a, function(x: number, y: number): boolean
		return x > y
	end)
	assert(a.n == 2 and a[1] == 20 and a[2] == 10, "n 밖의 30 을 끌어와 10 을 잃으면 안 됨")
	-- (a) n 이 있고 n 뒤 값이 해시부에 — 비우기 루프가 # 경계에 막힘
	const hashTail = { n = 2 } :: any
	hashTail[1], hashTail[2], hashTail[5], hashTail[7] = 10, 20, 50, 70
	const b = Arr.Adopt(hashTail)
	Arr.PushBack(b, 30)
	Arr.PushBack(b, 40)
	Arr.SortInplaceUnchecked(b)
	same(b, { 10, 20, 30, 40 }, "n 밖의 해시부 값이 정렬에 섞이면 안 됨")
end
print("PASS")

print("=== 17b. Adopt 은 평범한 테이블만 입양 (M0 리뷰) ===")
do
	-- 입양한 테이블의 메타테이블이 남으면 범위 밖 조회가 메타메소드 값을 주고
	-- 쓰기가 사용자 `__newindex` 를 타며, 1.59배 인덱싱 세금도 다시 붙습니다.
	-- "인스턴스는 평범한 테이블" 전제를 지키려 거부하고 `FromTable` 로 안내합니다.
	const withMeta = setmetatable({ 10, 20 }, {
		__index = function()
			return 99
		end,
	}) :: { number }
	const ok, err = pcall(function()
		Arr.Adopt(withMeta)
	end)
	assert(not ok and string.find(tostring(err), "FromTable", 1, true) ~= nil, `Adopt 메타테이블: {err}`)
	assert(string.find(tostring(err), "spec.arr", 1, true) ~= nil, "에러는 사용자 줄")
	-- 복사판은 됩니다(복사본은 평범한 테이블)
	const copied = Arr.FromTable(withMeta)
	assert(getmetatable(copied) == nil and copied.n == 2 and copied[1] == 10, "FromTable 은 평범한 테이블")

	-- 이미 Arr 인 것을 다시 입양하면 `#` 로 원본의 `n` 을 덮어써 구멍 뒤가 사라졌음
	-- (M0 2라운드 — M0 이전부터). 거부하고 원본은 그대로.
	const already = Arr.Of<<number?>>(10, nil, 30)
	const ok2, err2 = pcall(function()
		Arr.Adopt(already :: any)
	end)
	assert(not ok2 and string.find(tostring(err2), "already", 1, true) ~= nil, `Adopt 이미 Arr: {err2}`)
	assert(already.n == 3, "원본의 n 은 그대로")
	-- 동결된 테이블은 입양할 수 없습니다(태그·n 을 못 씀) — 라이브러리 줄의
	-- "readonly table" 대신 사용자 줄에서 안내
	const ok3, err3 = pcall(function()
		Arr.Adopt(table.freeze({ 10, 20 }))
	end)
	assert(not ok3 and string.find(tostring(err3), "FromTable", 1, true) ~= nil, `Adopt 동결: {err3}`)
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
	-- 값을 셋 이상 내면 둘째가 원소(5라운드 — `returned >= 2` 를 `== 2` 로 바꿔도 통과했음).
	-- 구멍 하나를 섞어 그 경로도.
	local threeStep = 0
	const three = Arr.FromIter(function(): (any, any, any)
		threeStep += 1
		if threeStep == 1 then
			return "a", 1, "x"
		elseif threeStep == 2 then
			return "b", nil, "y"
		elseif threeStep == 3 then
			return "c", 3, "z"
		end
		return nil, nil, nil
	end)
	assert(three.n == 3 and three[1] == 1 and three[2] == nil and three[3] == 3, `값 셋: {three[1]}, {three[2]}`)
	-- 빈 순회: 끝 모양이 셋(값 0개 — ipairs, nil 하나 — next/pairs, nil 둘 — Arr.Iter). 6라운드 —
	-- `firstA == nil` 을 `returned == 0` 으로 바꿔도 ipairs 만으로는 못 갈랐음.
	assert(Arr.FromIter(pairs({})).n == 0, "빈 pairs")
	-- 테이블을 그대로(2026-10-12 — `HashMap.Iter` 가 안쪽 테이블을 돌려주게 되면서): 값을 모음
	const fromDict = Arr.FromIter<<number>>({ p = 70, q = 80 })
	assert(fromDict.n == 2 and Arr.Sum(fromDict) == 150, "FromIter(사전 테이블) 은 값을 모음")
	assert(Arr.FromIter<<number>>({ 70, 80, 90 }).n == 3, "FromIter(배열 테이블)")
	assert(Arr.FromIter({}).n == 0, "FromIter(빈 테이블)")
	-- ⭐ 회귀(2라운드 리뷰): 맵에 `"__type"` 이라는 **키**가 있어도 됨 — 컨테이너 검사가 `__type` 이
	-- nil 이 아닌지만 봐서 `HashMap` 의 안쪽 테이블(사용자 데이터)에 걸렸음. 거절하는 것은 이 사본의
	-- **타입 토큰**이 붙은 테이블뿐.
	const tagged = stl.HashMap.New<<string, any>>()
	stl.HashMap.Set(tagged, "__type", "user")
	stl.HashMap.Set(tagged, "id", 7)
	const taggedValues = Arr.FromIter<<any>>(stl.HashMap.Iter(tagged))
	assert(taggedValues.n == 2 and Arr.Contains(taggedValues, "user") and Arr.Contains(taggedValues, 7), "__type 키")
	assert(Arr.FromIter<<any>>({ __type = "user", id = 7 }).n == 2, "__type 문자열 값을 가진 사전")
	assert(Arr.FromIter<<any>>({ __type = false, id = 7 }).n == 2, "__type = false 인 사전")
	assert(Arr.FromIter<<any>>({ __type = { name = "Arr" }, id = 7 }).n == 2, "토큰 모양일 뿐인 __type")
	-- ⭐ 회귀(2라운드 리뷰): 호출 가능한 테이블(`__call`)은 순회 **함수**로 — 사전으로 읽혀 `[x]` 가 됐음.
	-- `for v in callable` 과 같은 뜻. `__iter` 도 따름.
	local calls = 0
	const callable = setmetatable({ tag = "x" }, {
		__call = function(): number?
			calls += 1
			return if calls <= 3 then calls * 10 else nil
		end,
	})
	same(Arr.FromIter<<number>>(callable), { 10, 20, 30 }, "FromIter(__call 테이블)")
	const iterable = setmetatable({ tag = "x" }, {
		__iter = function(self: any)
			return ipairs({ 70, 80, self.tag })
		end,
	})
	same(Arr.FromIter<<any>>(iterable), { 70, 80, "x" }, "FromIter(__iter 테이블)")
	-- 값을 **하나만** 내는 `__iter` — 함수 순회자와 같은 값 규칙(하나면 그것). `__iter` 분기를 지우고
	-- `for _, v in 테이블` 에 맡기면 전부 nil 이 됨(3라운드 리뷰: 위 테스트는 값 둘짜리라 못 가렸음)
	const single = setmetatable({ items = { "p", "q", "r" } }, {
		__iter = function(self: any)
			local at = 0
			return function(): string?
				at += 1
				return self.items[at]
			end
		end,
	})
	same(Arr.FromIter<<string>>(single), { "p", "q", "r" }, "FromIter(값 하나짜리 __iter)")
	-- 둘 다 있으면 Luau 의 for-in 처럼 `__iter` 쪽
	const both = setmetatable({}, {
		__iter = function()
			return ipairs({ "from-iter" })
		end,
		__call = function(): string?
			return nil
		end,
	})
	same(Arr.FromIter<<string>>(both), { "from-iter" }, "FromIter(__iter 와 __call 둘 다)")
	-- ⭐ 보호된 메타테이블(`__metatable`) — 들여다볼 수 없으니 **예전처럼 함수로** 부름(3라운드 리뷰:
	-- 사전으로 읽는 갈래로 떨어졌는데 그 `for … in` 이 숨은 `__call` 을 따라가 값 하나짜리는 전부 nil,
	-- state·control 은 버려졌음 — 테이블을 받기 전에는 됐던 것)
	for _, lock in { "The metatable is locked", false, 5 } :: { any } do
		const locked = setmetatable({ tag = "x" }, {
			__metatable = lock,
			__call = function(_self: any, limit: number, at: number): number?
				return if at < limit then at + 1 else nil
			end,
		})
		same(Arr.FromIter<<number>>(locked, 3, 0), { 1, 2, 3 }, `FromIter(잠근 __call, {tostring(lock)})`)
		const lockedPairs = setmetatable({}, {
			__metatable = lock,
			__call = function(_self: any, limit: number, at: number): (number?, number?)
				if at < limit then
					return at + 1, (at + 1) * 100
				end
				return nil, nil
			end,
		})
		same(Arr.FromIter<<number>>(lockedPairs, 3, 0), { 100, 200, 300 }, "FromIter(잠근 __call, 값 둘)")
	end
	-- `__metatable` 이 **테이블**이면 진짜 메타테이블과 구분할 수 없음 — 사전으로(raw 키-값) 읽음.
	-- 숨은 `__iter` 를 따라가지 않음(따라가면 값 하나짜리가 nil 로 찬 배열이 됐음). 관측.
	const disguised = setmetatable({ p = 70 }, {
		__metatable = {},
		__iter = function()
			return function(): string?
				return nil
			end
		end,
	})
	same(Arr.FromIter<<number>>(disguised), { 70 }, "FromIter(테이블로 가린 메타테이블) 은 raw 사전")
	-- 메타테이블이 있어도 `__iter`·`__call` 이 없으면 사전(raw 키-값)
	const proxied = setmetatable({ p = 70 }, {
		__index = function(): number
			return 99
		end,
	})
	same(Arr.FromIter<<number>>(proxied), { 70 }, "FromIter(__index 만 있는 테이블)")
	-- 값이 false 여도 담음(값은 nil 일 수 없으니 구멍은 안 생김)
	const flags = Arr.FromIter<<boolean>>({ a = false, b = false })
	assert(flags.n == 2 and flags[1] == false and flags[2] == false, "FromIter(false 값들)")
	-- 컨테이너 자체는 거절(그 종류의 Iter 를 넘겨야 함) — 다른 종류도
	const userKind = stl.Trait.Stamp({ items = {} }, stl.Trait.NewToken("UserKind"))
	const lockedArr = setmetatable(Arr.Of(1, 2) :: any, { __metatable = "locked" })
	const callableArr = setmetatable(Arr.Of(1, 2) :: any, { __call = function() end })
	for _, container in
		{
			Arr.Of(1, 2),
			stl.HashMap.New(),
			stl.CircularDeque.Of(1),
			stl.Heap.New(function(a: number, b: number): boolean
				return a < b
			end),
			stl.Fut.Resolved(1),
			userKind,
			lockedArr,
			callableArr,
		} :: { any }
	do
		const okContainer, errContainer = pcall(function()
			Arr.FromIter(container)
		end)
		assert(
			not okContainer and string.find(tostring(errContainer), "FromIter got a container", 1, true),
			`컨테이너를 FromIter 에: {errContainer}`
		)
	end
	assert(Arr.FromIter(Arr.Iter(Arr.Of<<number>>())).n == 0, "빈 Arr.Iter")
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

	-- (2) Adopt 의 "n 밖 raw 칸 비우기" — `#` 가 닿는 데까지가 약속입니다. 구멍 뒤·큰
	--     키처럼 `#` 가 안 닿는 n 밖 키는 계약 밖(전부 지우면 입양이 복사보다 느려져
	--     되돌림, perf 20절) — FromTable 은 1..n 만 복사하니 거기선 깨끗합니다.
	const tail = Arr.Adopt({ n = 1, 10, 20, 30 } :: any)
	assert(tail.n == 1 and rawget(tail :: any, 2) == nil and rawget(tail :: any, 3) == nil, "# 가 닿는 n 밖")
	const sparseClone = Arr.FromTable({ n = 1, [1] = 10, [3] = 30, [100] = 9 } :: any)
	assert(
		rawget(sparseClone :: any, 3) == nil and rawget(sparseClone :: any, 100) == nil,
		"희소 테이블은 Clone 이 깨끗"
	)
	-- 구멍 든 1..n 은 그대로(구멍은 원소 자리)
	const inner = Arr.Adopt({ n = 3, [1] = 1, [3] = 3 } :: any)
	assert(inner.n == 3 and inner[1] == 1 and inner[2] == nil and inner[3] == 3, "n 안의 구멍")
end
print("PASS")

print("=== 20. M3 — 꺼내기 / 값 조회 / 집계 (2026-10-07) ===")
do
	-- PopBack / PopFront: 꺼낸 값, 빈 배열은 nil 이고 그대로(질문 AI)
	const a = Arr.Of(10, 20, 30)
	assert(Arr.PopBack(a) == 30, "PopBack 값")
	same(a, { 10, 20 }, "PopBack 뒤")
	assert(rawget(a :: any, 3) == nil, "PopBack 은 칸을 비움")
	assert(Arr.PopFront(a) == 10, "PopFront 값")
	same(a, { 20 }, "PopFront 뒤")
	assert(rawget(a :: any, 2) == nil, "PopFront 는 꼬리 칸을 비움")
	assert(Arr.PopFront(a) == 20 and a.n == 0 and rawget(a :: any, 1) == nil, "하나에서 PopFront")
	assert(Arr.PopBack(a) == nil and a.n == 0, "빈 PopBack")
	assert(Arr.PopFront(a) == nil and a.n == 0, "빈 PopFront")
	-- 구멍을 꺼내도 nil — 길이는 줄어듦(빈 것과 가르는 건 Len)
	const holed = Arr.Of<<number?>>(10, nil)
	assert(Arr.PopBack(holed) == nil and holed.n == 1, "구멍 PopBack")
	const holedFront = Arr.Of<<number?>>(nil, 20, nil, 40)
	assert(Arr.PopFront(holedFront) == nil and holedFront.n == 3, "구멍 PopFront")
	assert(holedFront[1] == 20 and holedFront[2] == nil and holedFront[3] == 40, "구멍 PopFront 뒤 위치")
	assert(rawget(holedFront :: any, 4) == nil, "구멍 PopFront 꼬리")
	-- 꺼낸 뒤에도 태그·n 이 살아 이어 쓸 수 있음
	Arr.PushBack(a, 7)
	same(a, { 7 }, "꺼낸 뒤 PushBack")

	-- SwapRemove: 마지막으로 메움, At 규약(음수·소수·범위 밖 nil)
	const sw = Arr.Of(10, 20, 30, 40)
	assert(Arr.SwapRemove(sw, 2) == 20, "SwapRemove 값")
	same(sw, { 10, 40, 30 }, "SwapRemove 메움")
	assert(rawget(sw :: any, 4) == nil, "SwapRemove 꼬리 칸")
	assert(Arr.SwapRemove(sw, -1) == 30, "SwapRemove 음수 = 마지막")
	same(sw, { 10, 40 }, "마지막을 지우면 메울 것 없음")
	assert(Arr.SwapRemove(sw, 1.9) == 10, "소수는 0 쪽")
	same(sw, { 40 }, "소수 뒤")
	-- 음수 소수도 0 쪽(-1.5 → -1 = 마지막) — floor 로 자르면 -2 가 됨(1라운드 리뷰)
	const swNeg = Arr.Of(10, 20, 30)
	assert(Arr.SwapRemove(swNeg, -1.5) == 30, "음수 소수는 0 쪽")
	same(swNeg, { 10, 20 }, "음수 소수 뒤")
	assert(Arr.SwapRemove(sw, 2) == nil and sw.n == 1, "범위 밖(뒤)")
	assert(Arr.SwapRemove(sw, 0) == nil and sw.n == 1, "0 은 범위 밖")
	assert(Arr.SwapRemove(sw, -2) == nil and sw.n == 1, "범위 밖(음수)")
	assert(Arr.SwapRemove(sw, math.huge) == nil and Arr.SwapRemove(sw, -math.huge) == nil, "무한대는 범위 밖")
	assert(Arr.SwapRemove(sw, 1) == 40 and sw.n == 0 and rawget(sw :: any, 1) == nil, "하나에서")
	assert(Arr.SwapRemove(sw, 1) == nil, "빈 SwapRemove")
	assert(not pcall(Arr.SwapRemove, Arr.Of(1), 0 / 0), "NaN 은 에러")
	-- 메우는 원소가 구멍이어도 자리를 지킴
	const swHole = Arr.Of<<number?>>(10, 20, nil)
	assert(Arr.SwapRemove(swHole, 1) == 10 and swHole.n == 2, "구멍으로 메움")
	assert(swHole[1] == nil and swHole[2] == 20, "구멍으로 메운 위치")

	-- FindLast: 뒤에서 처음, 위치까지
	const f = Arr.Of(10, 25, 30, 45, 50)
	const odd = function(v: number): boolean
		return v % 2 == 1
	end
	const lastOdd, lastIdx = Arr.FindLast(f, odd)
	assert(lastOdd == 45 and lastIdx == 4, `FindLast: {lastOdd} {lastIdx}`)
	const firstOdd, firstIdx = Arr.Find(f, odd)
	assert(firstOdd == 25 and firstIdx == 2, "Find 와 다른 답")
	const none, noneIdx = Arr.FindLast(f, function(v: number): boolean
		return v > 100
	end)
	assert(none == nil and noneIdx == nil, "FindLast 없음")
	assert(select("#", Arr.FindLast(emptyNum(), odd)) == 2, "빈 FindLast 도 둘")
	-- 콜백은 원소·위치·배열을 받고 구멍은 nil 로
	local seen = {}
	Arr.FindLast(Arr.Of<<number?>>(10, nil, 30), function(v: number?, i: number, arr: ArrView<unknown>): boolean
		table.insert(seen, `{tostring(v)}@{i}/{arr.n}`)
		return false
	end)
	assert(table.concat(seen, ",") == "30@3/3,nil@2/3,10@1/3", table.concat(seen, ","))

	-- IndexOf / LastIndexOf / Contains: == 비교
	const v = Arr.Of(10, 20, 10, 30)
	assert(Arr.IndexOf(v, 10) == 1 and Arr.LastIndexOf(v, 10) == 3, "처음·마지막")
	assert(Arr.IndexOf(v, 30) == 4 and Arr.LastIndexOf(v, 30) == 4, "하나뿐")
	assert(Arr.IndexOf(v, 99) == nil and Arr.LastIndexOf(v, 99) == nil, "없음")
	assert(Arr.Contains(v, 20) and not Arr.Contains(v, 99), "Contains")
	assert(not Arr.Contains(emptyNum(), 0) and Arr.IndexOf(emptyNum(), 0) == nil, "빈 배열")
	-- 위치를 값으로 착각하지 않음(값 10, 20 이 위치 1, 2 와 다름)
	assert(Arr.IndexOf(Arr.Of(2, 1), 1) == 2, "값과 위치가 다른 배열")
	-- nil 은 구멍을 찾음, NaN 은 못 찾음
	const h = Arr.Of<<number?>>(10, nil, 30, nil)
	assert(Arr.IndexOf(h, nil) == 2 and Arr.LastIndexOf(h, nil) == 4 and Arr.Contains(h, nil), "구멍 찾기")
	assert(not Arr.Contains(Arr.Of(10, 20), nil :: any), "구멍 없는 배열엔 nil 없음")
	const nan = 0 / 0
	assert(not Arr.Contains(Arr.Of(1, nan), nan) and Arr.IndexOf(Arr.Of(nan), nan) == nil, "NaN 은 못 찾음")
	-- 테이블은 정체성
	const t1, t2 = { 1 }, { 1 }
	assert(Arr.IndexOf(Arr.Of(t1, t2), t2) == 2, "테이블 정체성")
	-- n 밖은 안 봄
	const shrunk = Arr.Of(10, 20, 30)
	Arr.PopBack(shrunk)
	rawset(shrunk :: any, 3, 30)
	assert(not Arr.Contains(shrunk, 30) and Arr.LastIndexOf(shrunk, 30) == nil, "n 밖 칸")
	assert(Arr.FindLast(shrunk, function(x: number): boolean
		return x == 30
	end) == nil, "FindLast 도 n 밖 안 봄")

	-- MinMax: Min·Max 와 같은 답, 구멍 건너뜀, 같은 값이면 처음 것
	const mm = Arr.Of(30, 10, 50, 20)
	const lo, hi = Arr.MinMax(mm)
	assert(lo == 10 and hi == 50, `MinMax: {lo} {hi}`)
	const elo, ehi = Arr.MinMax(emptyNum())
	assert(elo == nil and ehi == nil, "빈 MinMax")
	const one1, one2 = Arr.MinMax(Arr.Of(7))
	assert(one1 == 7 and one2 == 7, "하나")
	const hlo, hhi = Arr.MinMax(Arr.Of<<number?>>(nil, 30, nil, 10, nil) :: any)
	assert(hlo == 10 and hhi == 30, "구멍 건너뜀")
	const allHole1, allHole2 = Arr.MinMax(Arr.Of<<number?>>(nil, nil) :: any)
	assert(allHole1 == nil and allHole2 == nil, "구멍뿐")
	-- 같은 값이면 처음 것(정체성으로 확인)
	const ka, kb, kc = { k = 1, id = "a" }, { k = 1, id = "b" }, { k = 1, id = "c" }
	const byK = function(x: { k: number, id: string }, y: { k: number, id: string }): boolean
		return x.k < y.k
	end
	const tlo, thi = Arr.MinMax(Arr.Of(ka, kb, kc), byK)
	assert(tlo == ka and thi == ka, "같은 값은 처음 것")
	assert(Arr.Min(Arr.Of(ka, kb, kc), byK) == ka and Arr.Max(Arr.Of(ka, kb, kc), byK) == ka, "Min·Max 도 처음 것")
	-- 비교자 방향을 뒤집으면 뒤바뀜
	const desc = function(x: number, y: number): boolean
		return x > y
	end
	const dlo, dhi = Arr.MinMax(mm, desc)
	assert(dlo == 50 and dhi == 10, "비교자")
	-- 큰 값이 먼저 와도(작은 쪽 갱신 뒤 큰 쪽을 건너뛰는 elseif 가 틀리지 않게)
	const up1, up2 = Arr.MinMax(Arr.Of(5, 1, 9, 0, 12, -3))
	assert(up1 == -3 and up2 == 12, "갱신 교대")

	-- MaxBy / MinBy: 키는 원소당 한 번, 같은 키는 처음 것, 구멍엔 key 를 안 부름
	const words = Arr.Of("ccc", "a", "bb", "ddd", "e")
	local keyCalls = 0
	const len = function(w: string): number
		keyCalls += 1
		return #w
	end
	assert(Arr.MaxBy(words, len) == "ccc", "MaxBy 처음 것")
	assert(keyCalls == 5, `키 호출 {keyCalls}`)
	keyCalls = 0
	assert(Arr.MinBy(words, len) == "a", "MinBy 처음 것")
	assert(keyCalls == 5, `키 호출 {keyCalls}`)
	assert(Arr.MaxBy(Arr.Sized(0, ""), len) == nil and Arr.MinBy(Arr.Sized(0, ""), len) == nil, "빈 것")
	keyCalls = 0
	const holedWords = Arr.Of<<string?>>(nil, "bb", nil, "a")
	assert(Arr.MaxBy(holedWords :: any, len) == "bb" and keyCalls == 2, "구멍엔 key 안 부름")
	-- 키 비교자
	const byLenDesc = function(x: number, y: number): boolean
		return x > y
	end
	assert(Arr.MaxBy(words, len, byLenDesc) == "a", "MaxBy 비교자")
	assert(Arr.MinBy(words, len, byLenDesc) == "ccc", "MinBy 비교자")
	-- 키가 원소와 다른 순서(값 10, 20, 30 의 키가 거꾸로)
	const negKey = function(x: number): number
		return -x
	end
	assert(Arr.MaxBy(Arr.Of(20, 10, 30), negKey) == 10 and Arr.MinBy(Arr.Of(20, 10, 30), negKey) == 30, "키 순서")
end
print("PASS")

print("=== 21. M3 — 나누기 / 거르기 / 짝 / 조각 (2026-10-07) ===")
do
	const even = function(v: number): boolean
		return v % 2 == 0
	end
	-- Partition: 두 새 배열, 입력 순서, 콜백은 원소당 한 번
	const p = Arr.Of(10, 15, 20, 25, 30)
	local calls = 0
	const yes, no = Arr.Partition(p, function(v: number): boolean
		calls += 1
		return v % 10 == 0
	end)
	same(yes, { 10, 20, 30 }, "Partition 참")
	same(no, { 15, 25 }, "Partition 거짓")
	assert(calls == 5, "콜백 한 번씩")
	same(p, { 10, 15, 20, 25, 30 }, "원본 그대로")
	assert(Arr.isArr(yes) and Arr.isArr(no), "둘 다 Arr")
	const ey, en = Arr.Partition(emptyNum(), even)
	assert(ey.n == 0 and en.n == 0 and ey ~= en, "빈 Partition 은 서로 다른 둘")
	const hy, hn = Arr.Partition(Arr.Of<<number?>>(10, nil, 30), function(v: number?): boolean
		return v == nil
	end)
	assert(hy.n == 1 and hy[1] == nil and hn.n == 2 and hn[1] == 10 and hn[2] == 30, "구멍은 콜백에 nil")

	-- TakeWhile / DropWhile (+Inplace): 처음 깨진 곳까지, 그 뒤는 안 봄
	const tw = Arr.Of(10, 20, 35, 40, 50)
	local twCalls = 0
	const evenCounted = function(v: number): boolean
		twCalls += 1
		return v % 2 == 0
	end
	same(Arr.TakeWhile(tw, evenCounted), { 10, 20 }, "TakeWhile")
	assert(twCalls == 3, `깨진 뒤는 안 봄: {twCalls}`)
	same(Arr.DropWhile(tw, even), { 35, 40, 50 }, "DropWhile")
	same(
		Arr.TakeWhile(tw, function(_v: number): boolean
			return true
		end),
		{ 10, 20, 35, 40, 50 },
		"전부 참"
	)
	same(
		Arr.DropWhile(tw, function(_v: number): boolean
			return true
		end),
		{},
		"전부 참이면 Drop 은 빔"
	)
	same(
		Arr.TakeWhile(tw, function(_v: number): boolean
			return false
		end),
		{},
		"처음부터 거짓"
	)
	same(
		Arr.DropWhile(tw, function(_v: number): boolean
			return false
		end),
		{ 10, 20, 35, 40, 50 },
		"처음부터 거짓이면 Drop 은 전부"
	)
	same(Arr.TakeWhile(emptyNum(), even), {}, "빈 TakeWhile")
	same(Arr.DropWhile(emptyNum(), even), {}, "빈 DropWhile")
	same(tw, { 10, 20, 35, 40, 50 }, "새 배열판은 원본 그대로")
	-- 제자리
	const twi = Arr.Of(10, 20, 35, 40)
	assert(Arr.TakeWhileInplace(twi, even) == twi, "같은 테이블")
	same(twi, { 10, 20 }, "TakeWhileInplace")
	assert(rawget(twi :: any, 3) == nil and rawget(twi :: any, 4) == nil, "꼬리 비움")
	const dwi = Arr.Of(10, 20, 35, 40)
	assert(Arr.DropWhileInplace(dwi, even) == dwi, "같은 테이블")
	same(dwi, { 35, 40 }, "DropWhileInplace")
	assert(rawget(dwi :: any, 3) == nil and rawget(dwi :: any, 4) == nil, "꼬리 비움")
	const dwiAll = Arr.Of(10, 20)
	same(Arr.DropWhileInplace(dwiAll, even), {}, "전부 버림")
	assert(rawget(dwiAll :: any, 1) == nil, "전부 버리면 칸도 빔")
	const dwiNone = Arr.Of(15, 20)
	same(Arr.DropWhileInplace(dwiNone, even), { 15, 20 }, "안 버림")
	-- 구멍: 콜백이 nil 을 받고, 구멍도 옮겨짐
	const twh = Arr.Of<<number?>>(10, nil, 30, 45)
	const notOdd = function(v: number?): boolean
		return v == nil or v % 2 == 0
	end
	const takenH = Arr.TakeWhile(twh, notOdd)
	assert(takenH.n == 3 and takenH[2] == nil and takenH[3] == 30, "구멍 Take")
	const droppedH = Arr.DropWhile(Arr.Of<<number?>>(10, 15, nil, 30), even :: any)
	assert(droppedH.n == 3 and droppedH[1] == 15 and droppedH[2] == nil and droppedH[3] == 30, "구멍 Drop")

	-- Dedup (+Inplace): 이웃만, kept 와 비교
	same(Arr.Dedup(Arr.Of(10, 10, 20, 10, 10, 30, 30)), { 10, 20, 10, 30 }, "Dedup 이웃만")
	same(Arr.Dedup(emptyNum()), {}, "빈 Dedup")
	same(Arr.Dedup(Arr.Of(10)), { 10 }, "하나")
	same(Arr.Dedup(Arr.Of(10, 10, 10)), { 10 }, "전부 같음")
	-- eq 는 (마지막으로 남긴 것, 다음) — 차이 5 이내면 같다고 보면 10, 14, 18 은 10 하나로(이웃끼리 비교였다면 다 하나)
	const near = function(kept: number, item: number): boolean
		return math.abs(kept - item) <= 5
	end
	same(Arr.Dedup(Arr.Of(10, 14, 18, 22)), { 10, 14, 18, 22 }, "기본 == 는 다 다름")
	same(Arr.Dedup(Arr.Of(10, 14, 18, 22), near), { 10, 18 }, "eq 는 남긴 것과 비교")
	local eqArgs = {}
	Arr.Dedup(Arr.Of(10, 20, 30), function(kept: number, item: number): boolean
		table.insert(eqArgs, `{kept}-{item}`)
		return false
	end)
	assert(table.concat(eqArgs, ",") == "10-20,20-30", table.concat(eqArgs, ","))
	-- 구멍은 이웃이면 하나로, NaN 은 안 줄어듦
	const dh = Arr.Dedup(Arr.Of<<number?>>(nil, nil, 10, nil, nil))
	assert(dh.n == 3 and dh[1] == nil and dh[2] == 10 and dh[3] == nil, "구멍 Dedup")
	assert(Arr.Dedup(Arr.Of(0 / 0, 0 / 0)).n == 2, "NaN 은 안 줄어듦")
	-- 제자리
	const di = Arr.Of(10, 10, 20, 20, 20, 30)
	assert(Arr.DedupInplace(di) == di, "같은 테이블")
	same(di, { 10, 20, 30 }, "DedupInplace")
	for idx = 4, 6 do
		assert(rawget(di :: any, idx) == nil, `꼬리 {idx}`)
	end
	same(Arr.DedupInplace(emptyNum()), {}, "빈 DedupInplace")

	-- Unique (+Inplace): 처음 것, 해시, nil 은 하나, NaN 은 각각
	same(Arr.Unique(Arr.Of(30, 10, 30, 20, 10)), { 30, 10, 20 }, "Unique 처음 것")
	same(Arr.Unique(emptyNum()), {}, "빈 Unique")
	const uh = Arr.Unique(Arr.Of<<number?>>(nil, 10, nil, 10, 20))
	assert(uh.n == 3 and uh[1] == nil and uh[2] == 10 and uh[3] == 20, "구멍은 첫 것만")
	assert(Arr.Unique(Arr.Of(0 / 0, 1, 0 / 0)).n == 3, "NaN 은 각각")
	assert(Arr.Unique(Arr.Of(0, -0)).n == 1, "0 과 -0 은 같음")
	same(Arr.Unique(Arr.Of(true, false, true, false)), { true, false }, "false 도 키")
	-- key: 원소당 한 번, 구멍에도 부름
	local ukCalls = 0
	const byTen = function(x: number?): number?
		ukCalls += 1
		return if x == nil then nil else x // 10
	end
	const uk = Arr.Unique(Arr.Of<<number?>>(11, 15, nil, 23, 19, nil), byTen)
	assert(uk.n == 3 and uk[1] == 11 and uk[2] == nil and uk[3] == 23, "Unique key")
	assert(ukCalls == 6, `key 호출 {ukCalls}`)
	-- key 가 nil·NaN 을 돌려줘도
	const ukNil = Arr.Unique(Arr.Of(10, 20, 30), function(_x: number): number?
		return nil
	end)
	same(ukNil, { 10 }, "key 가 전부 nil 이면 하나")
	same(
		Arr.Unique(Arr.Of(10, 20), function(_x: number): number
			return 0 / 0
		end),
		{ 10, 20 },
		"key 가 NaN 이면 각각"
	)
	-- 테이블은 정체성
	const ta, tb = { 1 }, { 1 }
	assert(Arr.Unique(Arr.Of(ta, tb, ta)).n == 2, "테이블 정체성")
	-- 제자리
	const ui = Arr.Of(30, 10, 30, 20, 10)
	assert(Arr.UniqueInplace(ui) == ui, "같은 테이블")
	same(ui, { 30, 10, 20 }, "UniqueInplace")
	assert(rawget(ui :: any, 4) == nil and rawget(ui :: any, 5) == nil, "꼬리 비움")

	-- Scan: init 미포함, 길이 n(질문 AI)
	const add = function(acc: number, x: number): number
		return acc + x
	end
	same(Arr.Scan(Arr.Of(10, 20, 30), 0, add), { 10, 30, 60 }, "누적합")
	same(Arr.Scan(Arr.Of(10, 20, 30), 5, add), { 15, 35, 65 }, "init 은 담지 않음")
	same(Arr.Scan(emptyNum(), 0, add), {}, "빈 Scan")
	-- 타입이 바뀜, 콜백은 (acc, 원소, 위치, 배열)
	const labels = Arr.Scan(
		Arr.Of(10, 20),
		"",
		function(acc: string, x: number, i: number, arr: ArrView<unknown>): string
			return `{acc}{x}@{i}/{arr.n};`
		end
	)
	same(labels, { "10@1/2;", "10@1/2;20@2/2;" }, "Scan 타입 변화")
	-- 구멍은 콜백에 nil
	const sh = Arr.Scan(Arr.Of<<number?>>(10, nil, 30), 0, function(acc: number, x: number?): number
		return acc + (x or 100)
	end)
	same(sh, { 10, 110, 140 }, "구멍 Scan")

	-- Zip / ZipWith: 짧은 쪽에 맞춤
	const za = Arr.Of(10, 20, 30)
	const zb = Arr.Of("x", "y")
	const z = Arr.Zip(za, zb)
	assert(z.n == 2 and z[1].first == 10 and z[1].second == "x" and z[2].first == 20 and z[2].second == "y", "Zip")
	assert(z[1] ~= z[2], "짝은 칸마다 새 테이블")
	assert(Arr.Zip(zb, za).n == 2 and Arr.Zip(zb, za)[2].second == 20, "뒤집어도 짧은 쪽")
	assert(Arr.Zip(za, Arr.Sized(0, "")).n == 0, "한쪽이 비면 빔")
	const zh = Arr.Zip(Arr.Of<<number?>>(nil, 20), Arr.Of("x", "y"))
	assert(zh.n == 2 and zh[1].first == nil and zh[1].second == "x", "구멍은 짝에 그대로")
	const zw = Arr.ZipWith(za, zb, function(n: number, s: string, i: number): string
		return `{s}{n}#{i}`
	end)
	same(zw, { "x10#1", "y20#2" }, "ZipWith")
	same(
		Arr.ZipWith(za, za, function(x: number, y: number): number
			return x * y
		end),
		{ 100, 400, 900 },
		"자기 자신과"
	)
	same(
		Arr.ZipWith(emptyNum(), za, function(x: number, y: number): number
			return x + y
		end),
		{},
		"빈 ZipWith"
	)

	-- Chunks: 마지막은 짧을 수 있음, 사본
	const c = Arr.Of(10, 20, 30, 40, 50)
	const ch = Arr.Chunks(c, 2)
	assert(ch.n == 3, `조각 수 {ch.n}`)
	same(ch[1], { 10, 20 }, "조각 1")
	same(ch[2], { 30, 40 }, "조각 2")
	same(ch[3], { 50 }, "마지막 조각은 짧음")
	assert(Arr.isArr(ch[1]) and Arr.isArr(ch), "조각도 Arr")
	ch[1][1] = 99
	assert(c[1] == 10, "조각은 사본")
	same(Arr.Chunks(c, 5)[1], { 10, 20, 30, 40, 50 }, "딱 맞음")
	assert(Arr.Chunks(c, 5).n == 1 and Arr.Chunks(c, 1).n == 5, "크기 5·1")
	assert(Arr.Chunks(c, 99).n == 1 and Arr.Chunks(c, math.huge).n == 1, "길이보다 큼·무한대")
	same(Arr.Chunks(c, math.huge)[1], { 10, 20, 30, 40, 50 }, "무한대는 전부 한 조각")
	same(Arr.Chunks(c, 2.9)[1], { 10, 20 }, "소수는 0 쪽")
	assert(Arr.Chunks(emptyNum(), 3).n == 0, "빈 Chunks")
	assert(
		not pcall(Arr.Chunks, c, 0) and not pcall(Arr.Chunks, c, 0.5) and not pcall(Arr.Chunks, c, -1),
		"1 보다 작으면 에러"
	)
	assert(not pcall(Arr.Chunks, c, 0 / 0), "NaN 은 에러")
	assert(not pcall(Arr.Chunks, emptyNum(), 0), "빈 배열이어도 크기는 검사")
	const chh = Arr.Chunks(Arr.Of<<number?>>(10, nil, nil, 40), 2)
	assert(chh.n == 2 and chh[1].n == 2 and chh[1][2] == nil and chh[2].n == 2 and chh[2][1] == nil, "구멍 조각")

	-- Windows: 겹치는 창, 사본, 길이보다 크면 빔
	const w = Arr.Windows(Arr.Of(10, 20, 30, 40), 3)
	assert(w.n == 2, `창 수 {w.n}`)
	same(w[1], { 10, 20, 30 }, "창 1")
	same(w[2], { 20, 30, 40 }, "창 2")
	w[1][2] = 99
	assert(w[2][1] == 20, "창은 서로 다른 사본")
	assert(Arr.Windows(Arr.Of(10, 20), 3).n == 0, "길이보다 크면 빔")
	assert(Arr.Windows(Arr.Of(10, 20), math.huge).n == 0, "무한대도 빔")
	assert(Arr.Windows(Arr.Of(10, 20), 2).n == 1 and Arr.Windows(Arr.Of(10, 20), 1).n == 2, "딱 맞음·1")
	assert(Arr.Windows(emptyNum(), 1).n == 0, "빈 Windows")
	assert(not pcall(Arr.Windows, Arr.Of(1), 0) and not pcall(Arr.Windows, Arr.Of(1), 0 / 0), "크기 검사")
	const wh = Arr.Windows(Arr.Of<<number?>>(10, nil, 30), 2)
	assert(wh.n == 2 and wh[1].n == 2 and wh[1][2] == nil and wh[2][1] == nil and wh[2][2] == 30, "구멍 창")
end
print("PASS")

print("=== 22. M3 — 무작위 대조 (2026-10-07) ===")
do
	-- 눈으로 안 보이는 것은 대조로: 단순한 정의(이중 루프·Filter 두 번·Slice·Fold)와 비교합니다.
	math.randomseed(20261007)
	for _round = 1, 300 do
		const len = math.random(0, 12)
		const raw = {}
		for idx = 1, len do
			-- 값 범위를 좁게 — 중복·이웃 중복이 자주 나오게. 구멍도 섞음
			raw[idx] = if math.random() < 0.15 then nil else math.random(1, 5) * 10
		end
		const a = Arr.Adopt<<number?>>(table.move(raw, 1, len, 1, { n = len } :: any) :: any)
		assert(a.n == len, "대조 입력 길이")

		-- Unique ↔ 이중 루프
		const expectUnique = {}
		local eu = 0
		for idx = 1, len do
			local dup = false
			for j = 1, idx - 1 do
				if a[j] == a[idx] then
					dup = true
					break
				end
			end
			if not dup then
				eu += 1
				expectUnique[eu] = a[idx]
			end
		end
		const u = Arr.Unique(a)
		assert(u.n == eu, `Unique 길이 {u.n} ~= {eu}`)
		for idx = 1, eu do
			assert(u[idx] == expectUnique[idx], `Unique [{idx}]`)
		end

		-- Dedup ↔ 이웃 비교
		const d = Arr.Dedup(a)
		local ed = 0
		for idx = 1, len do
			if idx == 1 or a[idx] ~= a[idx - 1] then
				ed += 1
				assert(d[ed] == a[idx], `Dedup [{ed}]`)
			end
		end
		assert(d.n == ed, "Dedup 길이")
		-- 제자리 판은 새 배열판과 같은 결과
		const di = Arr.DedupInplace(Arr.Clone(a))
		const ui = Arr.UniqueInplace(Arr.Clone(a))
		assert(Arr.Equal(di, d) and Arr.Equal(ui, u), "제자리 판")
		for idx = di.n + 1, len do
			assert(rawget(di :: any, idx) == nil, "Dedup 꼬리")
		end

		-- Partition ↔ Filter 두 번
		const big = function(x: number?): boolean
			return x ~= nil and x >= 30
		end
		const yes, no = Arr.Partition(a, big)
		assert(Arr.Equal(yes, Arr.Filter(a, big)), "Partition 참")
		assert(
			Arr.Equal(
				no,
				Arr.Filter(a, function(x: number?): boolean
					return not big(x)
				end)
			),
			"Partition 거짓"
		)

		-- TakeWhile ++ DropWhile = 원본, 제자리 판도 같음
		const small = function(x: number?): boolean
			return x == nil or x < 40
		end
		const taken, dropped = Arr.TakeWhile(a, small), Arr.DropWhile(a, small)
		assert(Arr.Equal(Arr.Concat(taken, dropped), a), "Take ++ Drop")
		assert(Arr.Equal(Arr.TakeWhileInplace(Arr.Clone(a), small), taken), "TakeWhileInplace")
		assert(Arr.Equal(Arr.DropWhileInplace(Arr.Clone(a), small), dropped), "DropWhileInplace")

		-- Chunks 를 이으면 원본, Windows 는 Slice 와 같음
		const size = math.random(1, 5)
		const chunks = Arr.Chunks(a, size)
		const joined = Arr.Sized<<number?>>(0, nil)
		for idx = 1, chunks.n do
			assert(chunks[idx].n == size or (idx == chunks.n and chunks[idx].n <= size), "조각 크기")
			Arr.PushBackArray(joined, chunks[idx])
		end
		assert(Arr.Equal(joined, a), "Chunks 를 이으면 원본")
		const windows = Arr.Windows(a, size)
		assert(windows.n == math.max(0, len - size + 1), "창 수")
		for idx = 1, windows.n do
			assert(Arr.Equal(windows[idx], Arr.Slice(a, idx, idx + size - 1)), "창 = Slice")
		end

		-- MinMax ↔ Min, Max (구멍 건너뜀)
		const dense = Arr.Compact(a)
		const lo, hi = Arr.MinMax(dense)
		assert(lo == Arr.Min(dense) and hi == Arr.Max(dense), "MinMax = Min, Max")

		-- Scan 의 마지막 = Fold, 각 칸 = 앞부분의 Fold
		const plus = function(acc: number, x: number?): number
			return acc + (x or 0)
		end
		const scanned = Arr.Scan(a, 0, plus)
		assert(scanned.n == len, "Scan 길이")
		for idx = 1, len do
			assert(scanned[idx] == Arr.Fold(Arr.Slice(a, 1, idx), 0, plus), "Scan = 앞부분 Fold")
		end

		-- IndexOf/LastIndexOf/Contains ↔ Find/FindLast
		const target = math.random(1, 5) * 10
		const isTarget = function(x: number?): boolean
			return x == target
		end
		const _, fi = Arr.Find(a, isTarget)
		const _, li = Arr.FindLast(a, isTarget)
		assert(Arr.IndexOf(a, target) == fi and Arr.LastIndexOf(a, target) == li, "IndexOf = Find")
		assert(Arr.Contains(a, target) == (fi ~= nil), "Contains")
	end
end
print("PASS")

print(
	"=== 23. 묶기 — GroupBy / CountBy / KeyBy, 목적지 맵을 셋째 인자로 (M4 → 2026-10-13 질문 AR) ==="
)
do
	const HashMap, FlatMap = stl.HashMap, stl.FlatMap
	type ArrOf<T> = stl.Arr<T>
	const words = Arr.Of("apple", "bob", "avocado", "cat", "banana")
	local keyCalls = 0
	const first = function(w: string): string
		keyCalls += 1
		return string.sub(w, 1, 1)
	end
	const dest = HashMap.New<<string, ArrOf<string>>>()
	const g = Arr.GroupBy(words, first, dest)
	assert(g == dest, "넣은 목적지를 그대로 돌려줌")
	assert(keyCalls == 5, "키는 원소당 한 번")
	assert(stl.isHashMap(g) and HashMap.Len(g) == 3, `무리 수 {HashMap.Len(g)}`)
	same(HashMap.Get(g, "a") :: any, { "apple", "avocado" }, "무리 a — 입력 순서")
	same(HashMap.Get(g, "b") :: any, { "bob", "banana" }, "무리 b")
	same(HashMap.Get(g, "c") :: any, { "cat" }, "무리 c")
	assert(Arr.isArr(HashMap.Get(g, "a")), "무리는 Arr")
	-- 이어 쓸 수 있는 맵(크기가 맞음)
	HashMap.Set(g, "z", Arr.Of("zoo"))
	assert(HashMap.Len(g) == 4, "GroupBy 결과 크기")
	assert(
		HashMap.Len(Arr.GroupBy(Arr.Sized(0, ""), first, HashMap.New<<string, ArrOf<string>>>())) == 0,
		"빈 GroupBy"
	)
	-- ⭐ 이미 채워진 맵이면 이어 모음: 있던 무리에는 뒤에 붙이고 새 키만 크기를 올림
	Arr.GroupBy(Arr.Of("zebra", "ant", "dog"), first, g)
	same(HashMap.Get(g, "z") :: any, { "zoo", "zebra" }, "있던 무리에 붙임")
	same(HashMap.Get(g, "a") :: any, { "apple", "avocado", "ant" }, "있던 무리에 붙임(a)")
	assert(HashMap.Len(g) == 5 and HashMap.Has(g, "d"), `이어 모은 뒤 크기 {HashMap.Len(g)}`)

	const c = Arr.CountBy(words, first, HashMap.New<<string, number>>())
	assert(HashMap.Get(c, "a") == 2 and HashMap.Get(c, "b") == 2 and HashMap.Get(c, "c") == 1, "CountBy")
	assert(HashMap.Len(c) == 3, "CountBy 크기")
	assert(HashMap.Len(Arr.CountBy(Arr.Sized(0, ""), first, HashMap.New<<string, number>>())) == 0, "빈 CountBy")
	Arr.CountBy(Arr.Of("axe", "dig"), first, c)
	assert(HashMap.Get(c, "a") == 3 and HashMap.Get(c, "d") == 1 and HashMap.Len(c) == 4, "CountBy 이어 세기")

	const k = Arr.KeyBy(words, first, HashMap.New<<string, string>>())
	assert(HashMap.Get(k, "a") == "avocado" and HashMap.Get(k, "b") == "banana", "KeyBy 는 나중 것")
	assert(HashMap.Len(k) == 3, "KeyBy 크기")
	Arr.KeyBy(Arr.Of("alpha", "delta"), first, k)
	assert(
		HashMap.Get(k, "a") == "alpha" and HashMap.Get(k, "d") == "delta" and HashMap.Len(k) == 4,
		"KeyBy 덮어쓰기·추가"
	)

	-- 구멍: GroupBy·CountBy 는 key 를 부르고(nil 을 받음) 담음, KeyBy 는 건너뜀(맵은 nil 값을 못 담음)
	const holed = Arr.Of<<number?>>(10, nil, 30, nil)
	const parity = function(v: number?): string
		return if v == nil then "hole" else "num"
	end
	const hg = Arr.GroupBy(holed, parity, HashMap.New<<string, ArrOf<number?>>>())
	const holes = HashMap.Get(hg, "hole") :: any
	assert(holes.n == 2 and holes[1] == nil and holes[2] == nil, "구멍 무리")
	same(HashMap.Get(hg, "num") :: any, { 10, 30 }, "숫자 무리")
	assert(HashMap.Get(Arr.CountBy(holed, parity, HashMap.New<<string, number>>()), "hole") == 2, "구멍도 셈")
	local keyByCalls = 0
	const lastWins = Arr.KeyBy(Arr.Of<<number?>>(10, nil, 30, nil), function(_v: number?): string
		keyByCalls += 1
		return "same"
	end, HashMap.New<<string, number?>>())
	assert(
		HashMap.Get(lastWins, "same") == 30 and HashMap.Len(lastWins) == 1,
		"구멍은 건너뜀 — 나중 값이 남음"
	)
	assert(keyByCalls == 2, `구멍엔 key 를 안 부름: {keyByCalls}`)

	-- ⭐ 목적지가 정렬 맵: 묶음끼리의 순서는 맵의 것, 타입도 넣은 그대로
	const sorted = Arr.GroupBy(words, first, FlatMap.New<<string, ArrOf<string>>>(stl.Common.compareString))
	assert(stl.isFlatMap(sorted), "FlatMap 에 모음")
	assert(table.concat(FlatMap.Keys(sorted), ",") == "a,b,c", "키 순서")
	same(FlatMap.Get(sorted, "a") :: any, { "apple", "avocado" }, "FlatMap 무리 a")
	const sortedCounts = Arr.CountBy(words, first, FlatMap.New<<string, number>>(stl.Common.compareString))
	assert(
		FlatMap.Get(sortedCounts, "a") == 2 and FlatMap.Get(sortedCounts, "c") == 1 and FlatMap.Len(sortedCounts) == 3,
		"FlatMap CountBy"
	)
	const sortedKeyed = Arr.KeyBy(words, first, FlatMap.New<<string, string>>(stl.Common.compareString))
	assert(FlatMap.Get(sortedKeyed, "b") == "banana" and FlatMap.Len(sortedKeyed) == 3, "FlatMap KeyBy")

	-- ⭐ "두 키가 같은가" 는 목적지 맵이 정함: 대소문자를 무시하는 비교자의 맵에서는 한 묶음(AR — 알고리즘이
	-- 임시 사전에 `==` 로 모았다 옮기는 안은 여기서 묶음 넷·중복 키가 됐음)
	const foldCase = function(x: string, y: string): number
		return stl.Common.compareString(string.lower(x), string.lower(y))
	end
	const whole = function(w: string): string
		return w
	end
	const mixed = Arr.Of("Apple", "apple", "banana", "APPLE")
	const folded = Arr.GroupBy(mixed, whole, FlatMap.New<<string, ArrOf<string>>>(foldCase))
	assert(FlatMap.Len(folded) == 2, `대소문자 무시 묶음 수 {FlatMap.Len(folded)}`)
	same(FlatMap.Get(folded, "apple") :: any, { "Apple", "apple", "APPLE" }, "비교자상 같은 키는 한 묶음")
	assert(FlatMap.Get(Arr.CountBy(mixed, whole, FlatMap.New<<string, number>>(foldCase)), "aPPle") == 3, "CountBy 도")
	const foldedKeyed = Arr.KeyBy(mixed, whole, FlatMap.New<<string, string>>(foldCase))
	assert(FlatMap.Len(foldedKeyed) == 2 and FlatMap.Get(foldedKeyed, "apple") == "APPLE", "KeyBy 도 — 나중 것")

	-- ⭐ 사용자 맵(Map 트레이트만 구현 — Collection 도 아님)도 목적지가 됨
	type Bag<V> = {
		read __type: stl.TraitToken<any>,
		read __mapKey: string,
		read __mapValue: V,
		read __mapMut: (string, V) -> (string, V),
		slots: { [string]: V },
		sets: number,
	}
	const BagKind = stl.Trait.NewToken("Bag")
	stl.Trait.Impl(stl.Map, BagKind, {
		Get = function(bag: Bag<any>, key: string): any
			return bag.slots[key]
		end,
		Set = function(bag: Bag<any>, key: string, value: any)
			bag.sets += 1
			bag.slots[key] = value
		end,
		Has = function(bag: Bag<any>, key: string): boolean
			return bag.slots[key] ~= nil
		end,
		Remove = function(bag: Bag<any>, key: string): any
			const prev = bag.slots[key]
			bag.slots[key] = nil
			return prev
		end,
		Iter = function(bag: Bag<any>): { read [string]: any }
			return bag.slots
		end,
	})
	const function newBag<V>(): Bag<V>
		return { __type = BagKind, slots = {}, sets = 0 } :: any
	end
	const bag = Arr.GroupBy(words, first, newBag<<ArrOf<string>>>())
	same(bag.slots.a :: any, { "apple", "avocado" }, "사용자 맵 무리 a")
	assert(bag.sets == 3, `GroupBy 는 새 키에만 Set: {bag.sets}`)
	const countBag = Arr.CountBy(words, first, newBag<<number>>())
	assert(countBag.slots.a == 2 and countBag.slots.b == 2 and countBag.slots.c == 1, "사용자 맵 CountBy")
	const keyBag = Arr.KeyBy(words, first, newBag<<string>>())
	assert(keyBag.slots.a == "avocado" and keyBag.sets == 5, "사용자 맵 KeyBy — 원소마다 Set")

	-- ⭐ 구멍과 false 원소는 **목적지가 달라도 같은 규칙**(일반 경로 — 맵의 Get/Set — 에도 지름길과 같은 처리가
	-- 따로 있음: 구멍을 건너뛰거나 구멍에 키를 부르는 실수가 지름길 쪽 테스트로는 안 잡혔음, 리뷰)
	const holedWords = Arr.Of<<string?>>("apple", nil, "bob", nil)
	const holeKey = function(w: string?): string
		return if w == nil then "hole" else string.sub(w, 1, 1)
	end
	const holedTree =
		Arr.GroupBy(holedWords, holeKey, stl.TreeMap.New<<string, ArrOf<string?>>>(stl.Common.compareString))
	assert(
		(stl.TreeMap.Get(holedTree, "hole") :: any).n == 2 and stl.TreeMap.Len(holedTree) == 3,
		"일반 경로 GroupBy 도 구멍을 담음"
	)
	const holedCounts = Arr.CountBy(holedWords, holeKey, stl.TreeMap.New<<string, number>>(stl.Common.compareString))
	assert(
		stl.TreeMap.Get(holedCounts, "hole") == 2 and stl.TreeMap.Get(holedCounts, "a") == 1,
		"일반 경로 CountBy 도 구멍을 셈"
	)
	local generalKeyCalls = 0
	const holedKeyed = Arr.KeyBy(holedWords, function(w: string?): string
		generalKeyCalls += 1
		return holeKey(w)
	end, stl.TreeMap.New<<string, string?>>(stl.Common.compareString))
	assert(
		generalKeyCalls == 2 and stl.TreeMap.Len(holedKeyed) == 2 and not stl.TreeMap.Has(holedKeyed, "hole"),
		"일반 경로 KeyBy 는 구멍을 건너뜀"
	)
	const flags = Arr.Of(false, true, false)
	const flagKey = function(v: boolean): string
		return tostring(v)
	end
	const hashFlags = Arr.KeyBy(flags, flagKey, HashMap.New<<string, boolean>>())
	const treeFlags = Arr.KeyBy(flags, flagKey, stl.TreeMap.New<<string, boolean>>(stl.Common.compareString))
	assert(
		HashMap.Get(hashFlags, "false") == false and HashMap.Len(hashFlags) == 2,
		"KeyBy 는 false 원소를 담음(지름길)"
	)
	assert(
		stl.TreeMap.Has(treeFlags, "false") and stl.TreeMap.Get(treeFlags, "false") == false,
		"KeyBy 는 false 원소를 담음(일반 경로)"
	)

	-- ⭐ 키 함수가 도중에 던져도 넘긴 맵의 크기는 맞음(지름길이 크기를 끝에 한 번 쓰면 틀어졌음, AR)
	const partial = HashMap.New<<string, ArrOf<string>>>()
	const okThrow = pcall(function()
		Arr.GroupBy(words, function(w: string): string
			if w == "cat" then
				error("boom")
			end
			return string.sub(w, 1, 1)
		end, partial)
	end)
	local seen = 0
	for _ in HashMap.Iter(partial) do
		seen += 1
	end
	assert(
		not okThrow and seen == 2 and HashMap.Len(partial) == 2,
		`던진 뒤 크기 {HashMap.Len(partial)} / 실제 {seen}`
	)
	const partialCounts = HashMap.New<<string, number>>()
	pcall(function()
		Arr.CountBy(words, function(w: string): string
			if w == "banana" then
				error("boom")
			end
			return string.sub(w, 1, 1)
		end, partialCounts)
	end)
	assert(HashMap.Len(partialCounts) == 3 and HashMap.Get(partialCounts, "b") == 1, "CountBy 던진 뒤 크기")
	const partialKeyed = HashMap.New<<string, string>>()
	pcall(function()
		Arr.KeyBy(words, function(w: string): string
			if w == "cat" then
				error("boom")
			end
			return string.sub(w, 1, 1)
		end, partialKeyed)
	end)
	assert(HashMap.Len(partialKeyed) == 2 and HashMap.Get(partialKeyed, "a") == "avocado", "KeyBy 던진 뒤 크기")

	-- 키가 nil·NaN 이면 에러(메시지·줄은 spec.common)
	assert(not pcall(Arr.GroupBy, Arr.Of(10), function(_v: number): any
		return nil
	end, HashMap.New() :: any), "nil 키")
	assert(not pcall(Arr.CountBy, Arr.Of(10), function(_v: number): number
		return 0 / 0
	end, HashMap.New() :: any), "NaN 키")
	assert(not pcall(Arr.KeyBy, Arr.Of(10), function(_v: number): any
		return nil
	end, HashMap.New() :: any), "KeyBy nil 키")

	-- 목적지가 맵이 아니면(빠뜨림 포함) 사용자 줄 에러 — 셋 다
	local where = 0
	const badDests: { { fn: (any, any, any) -> any, name: string } } = {
		{ fn = Arr.GroupBy, name = "GroupBy" },
		{ fn = Arr.CountBy, name = "CountBy" },
		{ fn = Arr.KeyBy, name = "KeyBy" },
	}
	for _, case in badDests do
		const run = case.fn
		const okNil, errNil = pcall(function()
			where = debug.info(1, "l") + 1
			run(words, first, nil)
		end)
		assert(
			not okNil
				and string.find(
					tostring(errNil),
					`Map: Arr.{case.name} needs a Map (got nil without a type token)`,
					1,
					true
				)
				and string.find(tostring(errNil), `spec.arr.luau:{where}:`, 1, true),
			`목적지 빠뜨림: {errNil}`
		)
		const okArr, errArr = pcall(function()
			where = debug.info(1, "l") + 1
			run(words, first, Arr.Of(1))
		end)
		assert(
			not okArr
				and string.find(
					tostring(errArr),
					`Map: Arr.{case.name} needs a Map — Arr does not implement Map`,
					1,
					true
				)
				and string.find(tostring(errArr), `spec.arr.luau:{where}:`, 1, true),
			`목적지가 맵 아님: {errArr}`
		)
	end

	-- 무작위 대조: 무리를 이으면 원본 다중집합, CountBy = 무리 길이, 그리고 **목적지 셋(HashMap·FlatMap·사용자 맵)이 같은 답**
	math.randomseed(4)
	for _round = 1, 100 do
		const len = math.random(0, 15)
		const a = Arr.FromFunc(len, function(_i: number): number
			return math.random(1, 4) * 10
		end)
		const byTens = function(v: number): number
			return v // 10
		end
		const groups = Arr.GroupBy(a, byTens, HashMap.New<<number, ArrOf<number>>>())
		const counts = Arr.CountBy(a, byTens, HashMap.New<<number, number>>())
		const treeGroups = Arr.GroupBy(a, byTens, FlatMap.New<<number, ArrOf<number>>>(stl.Common.compareNumber))
		const treeCounts = Arr.CountBy(a, byTens, FlatMap.New<<number, number>>(stl.Common.compareNumber))
		const treeKeyed = Arr.KeyBy(a, byTens, FlatMap.New<<number, number>>(stl.Common.compareNumber))
		const bagGroups = Arr.GroupBy(a, byTens :: any, newBag<<any>>())
		local total = 0
		for key, group in HashMap.Iter(groups) do
			assert(HashMap.Get(counts, key) == group.n, "CountBy = 무리 길이")
			assert(FlatMap.Get(treeCounts, key) == group.n, "FlatMap CountBy 가 같음")
			const treeGroup = FlatMap.Get(treeGroups, key) :: any
			const bagGroup = (bagGroups.slots :: any)[key]
			assert(treeGroup.n == group.n and bagGroup.n == group.n, "목적지가 달라도 무리 크기가 같음")
			for idx = 1, group.n do
				assert(byTens(group[idx]) == key, "같은 무리는 같은 키")
				assert(
					treeGroup[idx] == group[idx] and bagGroup[idx] == group[idx],
					"목적지가 달라도 무리 내용·순서가 같음"
				)
			end
			total += group.n
		end
		assert(total == len and HashMap.Len(groups) == HashMap.Len(counts), "무리 합 = 길이")
		assert(FlatMap.Len(treeGroups) == HashMap.Len(groups), "FlatMap 묶음 수가 같음")
		const keyed = Arr.KeyBy(a, byTens, HashMap.New<<number, number>>())
		assert(FlatMap.Len(treeKeyed) == HashMap.Len(keyed), "KeyBy 크기가 같음")
		for key, item in HashMap.Iter(keyed) do
			const _, lastIdx = Arr.FindLast(a, function(v: number): boolean
				return byTens(v) == key
			end)
			assert(a[lastIdx :: number] == item, "KeyBy 는 마지막")
			assert(FlatMap.Get(treeKeyed, key) == item, "FlatMap KeyBy 가 같음")
		end
	end
end
print("PASS")

print()
print("=== ALL PASS (Arr) ===")

return true

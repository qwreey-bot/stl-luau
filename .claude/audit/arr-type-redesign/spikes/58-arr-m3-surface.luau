--!strict
--[[
	M3 — Arr 빈 조각의 타입 (2026-10-07).

	지키는 성질: 꺼내기·찾기·집계는 **`?` 를 돌려줌**(비었을 수 있음), 쓰는 함수(`Pop*`·
	`SwapRemove`·`*Inplace`)는 **읽기 전용 참조를 안 받음**(AC — 쓰기는 `ArrData`), 짝·누적·조각은
	**원소 타입을 정확히** 옮김(`Pair<T, U>`·`Arr<U>`·`Arr<Arr<T>>`), 콜백 파라미터는 원소 타입으로
	검사됨.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 19 + CANARY 1)
]]
local stl = require("../../../../src")
local Arr = stl.Arr
type Arr<T> = stl.Arr<T>
type Base = { name: string }
type Derived = { name: string, age: number }

local nums = Arr.Of(10, 20, 30)
local strs = Arr.Of("x", "y")
local people: Arr<Derived> = Arr.Of({ name = "a", age = 1 })

--[[ POS ]]
local popped: number? = Arr.PopBack(nums)
local front: number? = Arr.PopFront(nums)
local swapped: number? = Arr.SwapRemove(nums, 1)
local hasNil: boolean = Arr.Contains<<number?>>(nums, nil) -- 읽기는 공변(AC)
local where: number? = Arr.IndexOf(nums, 20)
local lastFound: Derived?, lastIdx: number? = Arr.FindLast(people, function(p: Derived): boolean
	return p.age > 0
end)
local lo: number?, hi: number? = Arr.MinMax(nums)
local oldest: Base? = Arr.MaxBy<<Base, number>>(people, function(p)
	return #p.name
end)
local evens: Arr<number>, odds: Arr<number> = Arr.Partition(nums, function(v: number): boolean
	return v % 2 == 0
end)
local deduped: Arr<number> = Arr.Dedup(nums)
local uniq: Arr<Derived> = Arr.Unique(people, function(p: Derived): string
	return p.name
end)
local prefix: Arr<number> = Arr.Scan(nums, 0, function(acc: number, v: number): number
	return acc + v
end)
local labels: Arr<string> = Arr.Scan(nums, "", function(acc: string, v: number): string
	return acc .. tostring(v)
end)
local zipped: Arr<stl.Pair<number, string>> = Arr.Zip(nums, strs)
local firstOfPair: number = zipped[1].first
local joined: Arr<string> = Arr.ZipWith(nums, strs, function(n: number, s: string, _i: number): string
	return s .. n
end)
local chunks: Arr<Arr<number>> = Arr.Chunks(nums, 2)
local holedChunks: Arr<Arr<number?>> = Arr.Windows(Arr.Of<<number?>>(1, nil), 1)
local taken: Arr<number> = Arr.TakeWhileInplace(nums, function(v: number): boolean
	return v < 30
end)

--[[ NEG — `?` 를 지킴 ]]
local negPop: number = Arr.PopBack(nums)
local negSwap: number = Arr.SwapRemove(nums, 1)
local negIndex: number = Arr.IndexOf(nums, 10)
local negMin: number = (Arr.MinMax(nums))
local negMaxBy: number = Arr.MaxBy(nums, function(v: number): number
	return v
end)

--[[ NEG — 쓰는 함수는 읽기 전용 참조를 안 받음(AC) ]]
local function borrowPop(list: stl.ArrRead<number>)
	return Arr.PopBack(list)
end
local function borrowSwap(list: stl.ArrRead<number>)
	return Arr.SwapRemove(list, 1)
end
local function borrowDedup(list: stl.ArrRead<number>)
	return Arr.DedupInplace(list)
end
local function borrowUnique(list: stl.ArrRead<number>)
	return Arr.UniqueInplace(list)
end
local function borrowDrop(list: stl.ArrRead<number>)
	return Arr.DropWhileInplace(list, function(v: number): boolean
		return v > 0
	end)
end

--[[ NEG — 원소 타입을 정확히 옮김 ]]
local negZip: Arr<stl.Pair<number, number>> = Arr.Zip(nums, strs)
local negScan: Arr<number> = Arr.Scan(nums, "", function(acc: string, v: number): string
	return acc .. tostring(v)
end)
local negChunks: Arr<number> = Arr.Chunks(nums, 2)
local negPartition: Arr<string> = (Arr.Partition(nums, function(v: number): boolean
	return v > 0
end))

--[[ NEG — 콜백 파라미터는 원소 타입으로 검사 ]]
local negZipWith = Arr.ZipWith(nums, strs, function(n: number, s: number, _i: number): number
	return n + s
end)
local negUnique = Arr.Unique(nums, function(s: string): string
	return s
end)
local negDedup = Arr.Dedup(nums, function(a: string, b: string): boolean
	return a == b
end)

--[[ NEG — 구멍 든 배열에 좁은 콜백(구멍은 T? — 집계가 구멍을 건너뛰어도 타입은 T? 를 요구) ]]
local holedNums = Arr.Of<<number?>>(10, nil)
local negHoledPartition = Arr.Partition(holedNums, function(v: number): boolean
	return v > 0
end)
local negHoledMaxBy = Arr.MaxBy(holedNums, function(v: number): number
	return v
end)

local canary: string = 42

return {
	popped,
	front,
	swapped,
	hasNil,
	where,
	lastFound,
	lastIdx,
	lo,
	hi,
	oldest,
	evens,
	odds,
	deduped,
	uniq,
	prefix,
	labels,
	firstOfPair,
	joined,
	chunks,
	holedChunks,
	taken,
	negPop,
	negSwap,
	negIndex,
	negMin,
	negMaxBy,
	borrowPop,
	borrowSwap,
	borrowDedup,
	borrowUnique,
	borrowDrop,
	negZip,
	negScan,
	negChunks,
	negPartition,
	negZipWith,
	negUnique,
	negDedup,
	negHoledPartition,
	negHoledMaxBy,
	canary,
}

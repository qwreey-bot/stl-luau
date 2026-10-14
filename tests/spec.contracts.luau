--!strict
--[[
	계약 테스트 — **구현을 모르는 코드가 정말 돌아가는가.**

	`Types` 의 계약 셋(`ListCore` / `MapCore` / `SetCore`)은 **함수 묶음**입니다
	(2026-10-01, 질문 AB). 컨테이너는 메타테이블 없는 평범한 테이블이라 메소드가
	없고, 디스패치는 **구현 함수 묶음을 컨테이너와 같이 넘기는** 모양입니다 —
	모듈 테이블이 그대로 구현체입니다(`exerciseMap(stl.HashMap, m, …)`).

	⭐ 여기서 가장 중요한 것은 **런타임이 아니라 타입**입니다. 이 파일이
	`--!strict` 로 진단 0건이라는 사실 자체가 "계약이 정말 섰다" 는 증거입니다.
	같은 함수에 `HashMap` 과 `FlatMap` 을 넣었을 때 타입 에러가 나면 계약이
	선 게 아닙니다.
]]
local stl = require("../src")
local Common = stl.Common
-- `Arr` 의 리스트 프리미티브 다섯만 든 표 — 다른 토큰에 `List` 를 등록해 보는 테스트들이 씁니다. 모듈 테이블을
-- 통째로 넘기면 에러입니다(트레이트가 모르는 이름 — 2026-10-13, 질문 AS).
local arrListCore: any = {
	Get = stl.Arr.Get,
	FirstIndex = stl.Arr.FirstIndex,
	LastIndex = stl.Arr.LastIndex,
	NextIndex = stl.Arr.NextIndex,
	PrevIndex = stl.Arr.PrevIndex,
}

type ListCore<C, E, I> = stl.ListCore<C, E, I>
type MapCore<C, K, V> = stl.MapCore<C, K, V>
type SetCore<C, T> = stl.SetCore<C, T>

--[[ 계약만 아는 함수들. 어떤 구현이 오는지 전혀 모릅니다. ]]

-- 순차 컨테이너: 위치 타입 `I` 가 무엇인지도 모른 채 순회합니다.
local function sumThroughContract<C, I>(ops: ListCore<C, number, I>, list: C): number
	local total = 0
	local idx = ops.FirstIndex(list)
	while idx ~= nil do
		total += ops.Get(list, idx) :: number
		idx = ops.NextIndex(list, idx)
	end
	return total
end

-- 맵: 넣고 빼고 세어봅니다.
local function fillAndCount<C, V>(ops: MapCore<C, string, V>, map: C, value: V): number
	ops.Set(map, "하나", value)
	ops.Set(map, "둘", value)
	ops.Set(map, "하나", value) -- 덮어쓰기
	-- 세는 것은 `Iter` 로(2026-10-13 — `Records` 는 계약에서 빠졌음). 계약을 거친 루프 변수는 타입이
	-- 없어(유니온 순회) 주석을 답니다.
	local count = 0
	for _key: string in ops.Iter(map) do
		count += 1
	end
	return count
end

-- 셋: 넣고 확인하고 뺍니다.
local function exerciseSet<C, T>(ops: SetCore<C, T>, set: C, a: T, b: T): string
	local added = ops.Add(set, a)
	local again = ops.Add(set, a)
	ops.Add(set, b)
	local hasA = ops.Has(set, a)
	local removed = ops.Remove(set, a)
	local hasAfter = ops.Has(set, a)
	return `{added},{again},{hasA},{removed},{hasAfter},{#ops.Items(set)}`
end

print("=== 1. ListCore — Arr 가 만족하는가 ===")
do
	const a = stl.Arr.Of(10, 20, 30)
	assert(sumThroughContract(stl.Arr, a) == 60, "계약을 통한 합")
	assert(sumThroughContract(stl.Arr, stl.Arr.Of<<number>>()) == 0, "빈 것")
	-- 공용 알고리즘도 계약만 압니다
	assert(stl.List.IndexOf(a, 20) == 2, "List.IndexOf")
	assert(stl.List.Count(a) == 3, "List.Count")
end
print("PASS")

print("=== 2. ⭐ MapCore — HashMap 과 FlatMap 을 바꿔 끼울 수 있는가 ===")
do
	-- **같은 함수**에 두 구현을 넣습니다. 타입이 갈리면 여기서 진단이 납니다.
	type H = stl.HashMap<string, number>
	type T = stl.FlatMap<string, number>
	const hash = stl.HashMap.New<<string, number>>()
	const tree = stl.FlatMap.New<<string, number>>(Common.compareString)

	-- ⚠️ 계약을 받는 함수는 **타입 인자를 알려줍니다** — 원소 타입을 함수 묶음
	-- (제네릭 함수들)에서도 끌어오며 `unknown` 이 섞입니다(typing-limits).
	assert(fillAndCount<<H, number>>(stl.HashMap, hash, 1) == 2, "HashMap 을 계약으로")
	assert(fillAndCount<<T, number>>(stl.FlatMap, tree, 1) == 2, "FlatMap 을 계약으로")
	assert(stl.HashMap.Len(hash) == stl.FlatMap.Len(tree), "둘의 크기가 같아야 합니다")

	-- 공용 알고리즘도 양쪽에서 같아야 합니다
	assert(#stl.Map.Keys(hash) == #stl.Map.Keys(tree), "Map.Keys")
	assert(#stl.Map.Values(hash) == #stl.Map.Values(tree), "Map.Values")

	-- 계약 자리에 모듈을 담아 두고 나중에 쓰는 것도 돼야 합니다
	const hashOps: MapCore<H, string, number> = stl.HashMap
	const treeOps: MapCore<T, string, number> = stl.FlatMap
	assert(
		hashOps.Get(hash, "하나") == 1 and treeOps.Get(tree, "하나") == 1,
		"계약 자리에 담긴 뒤에도 동작"
	)
end
print("PASS")

print("=== 3. ⭐ SetCore — HashSet 과 FlatSet 을 바꿔 끼울 수 있는가 ===")
do
	const hash = stl.HashSet.New<<number>>()
	const tree = stl.FlatSet.New<<number>>(Common.compareNumber)

	const hashResult = exerciseSet<<stl.HashSet<number>, number>>(stl.HashSet, hash, 10, 20)
	const treeResult = exerciseSet<<stl.FlatSet<number>, number>>(stl.FlatSet, tree, 10, 20)
	assert(hashResult == "true,false,true,true,false,1", `HashSet 결과: {hashResult}`)
	-- **두 구현이 글자 하나까지 같은 답을 내야 합니다**
	assert(hashResult == treeResult, `구현마다 답이 다릅니다: {hashResult} vs {treeResult}`)
end
print("PASS")

print("=== 4. ⭐ 메타테이블이 없다 — 데이터는 엔티티, 함수는 서비스 ===")
do
	-- 모든 인스턴스가 평범한 테이블이어야 합니다(질문 AB). 메타테이블이 붙으면
	-- 원소 인덱싱에 1.59배 세금이 붙습니다(perf 16절).
	const samples: { { name: string, instance: any, is: (any) -> boolean } } = {
		{ name = "Arr", instance = stl.Arr.Of(1), is = stl.isArr },
		{ name = "HashMap", instance = stl.HashMap.New(), is = stl.isHashMap },
		{ name = "HashSet", instance = stl.HashSet.New(), is = stl.isHashSet },
		{ name = "FlatMap", instance = stl.FlatMap.New(Common.compareNumber), is = stl.isFlatMap },
		{ name = "FlatSet", instance = stl.FlatSet.New(Common.compareNumber), is = stl.isFlatSet },
		{ name = "TreeMap", instance = stl.TreeMap.New(Common.compareNumber), is = stl.isTreeMap },
		{ name = "TreeSet", instance = stl.TreeSet.New(Common.compareNumber), is = stl.isTreeSet },
		{
			name = "Heap",
			instance = stl.Heap.New(function(a: number, b: number)
				return a < b
			end),
			is = stl.isHeap,
		},
		{ name = "Fut", instance = stl.Fut.Resolved(), is = stl.isFut },
		{ name = "CircularDeque", instance = stl.CircularDeque.Of(1), is = stl.isCircularDeque },
		{ name = "LinkedDeque", instance = stl.LinkedDeque.Of(1), is = stl.isLinkedDeque },
	}
	for _, sample in samples do
		assert(getmetatable(sample.instance) == nil, `{sample.name} 에 메타테이블이 붙어 있습니다`)
		-- 판별은 태그 필드로 — 그리고 서로 헷갈리지 않아야 합니다
		for _, other in samples do
			assert(
				other.is(sample.instance) == (other == sample),
				`{other.name} 술어가 {sample.name} 를 잘못 판별`
			)
		end
		assert(not sample.is({}), `{sample.name} 술어가 빈 테이블을 받아들임`)
	end
	-- 맵 키로 태그 이름을 써도 태그가 덮이지 않습니다(키·값은 `data` 안에 삽니다)
	const m = stl.HashMap.New<<string, number>>()
	stl.HashMap.Set(m, "__type", 1)
	assert(stl.isHashMap(m) and stl.HashMap.Len(m) == 1, "태그 이름을 키로 써도 안전")
end
print("PASS")

print("=== 5. ⭐ 모든 생성·반환 경로가 태그를 붙이는가 (M0 리뷰) ===")
do
	-- 태그가 빠진 결과는 술어가 거짓이고, `Arr.Flat` 은 그 배열을 펼치지 않고,
	-- `Fut.Chain`/`Fut.All` 은 그 Fut 을 거부합니다. 반환 경로 **전부**를 봅니다
	-- (예전 "네임스페이스와 메소드는 같은 함수" 절의 새 구조 짝).
	const Arr, HashMap, HashSet, FlatMap, FlatSet, Heap, Fut =
		stl.Arr, stl.HashMap, stl.HashSet, stl.FlatMap, stl.FlatSet, stl.Heap, stl.Fut
	local function a(): stl.Arr<number>
		return Arr.Of(30, 10, 20)
	end
	local function id(v: number): number
		return v
	end
	local function lt(x: number, y: number): boolean
		return x < y
	end
	local function even(v: number): boolean
		return v % 2 == 0
	end
	const arrResults: { [string]: any } = {
		Of = a(),
		Sized = Arr.Sized(2, 0),
		Adopt = Arr.Adopt({ 1, 2 }),
		FromTable = Arr.FromTable({ 1, 2 }),
		FromIter = Arr.FromIter<<number>>(ipairs({ 1, 2 })),
		-- 테이블을 받는 갈래는 따로 돌려줌(4라운드 리뷰 — 토큰 없는 결과를 `any` 로 만들어도 통과했음)
		FromIterTable = Arr.FromIter<<number>>({ 1, 2 }),
		FromFunc = Arr.FromFunc(2, id),
		Concat = Arr.Concat(a(), a()),
		Range = Arr.Range(1, 3),
		FillHoles = Arr.FillHoles(Arr.Of<<number?>>(1, nil), 0),
		FillHolesInplace = Arr.FillHolesInplace(a(), 0),
		Compact = Arr.Compact(a()),
		CompactInplace = Arr.CompactInplace(a()),
		ToOptionals = Arr.ToOptionals(a()),
		PushBack = Arr.PushBack(a(), 1),
		PushBackMany = Arr.PushBackMany(a(), 1, 2),
		PushBackArray = Arr.PushBackArray(a(), a()),
		PushFront = Arr.PushFront(a(), 1),
		PushFrontMany = Arr.PushFrontMany(a(), 1, 2),
		PushFrontArray = Arr.PushFrontArray(a(), a()),
		Insert = Arr.Insert(a(), 1, 5),
		InsertMany = Arr.InsertMany(a(), 1, 5, 6),
		InsertArray = Arr.InsertArray(a(), 1, a()),
		Clone = Arr.Clone(a()),
		Clear = Arr.Clear(a()),
		Fill = Arr.Fill(a(), 0),
		Slice = Arr.Slice(a(), 1, 2),
		SliceTo = Arr.Slice(a(), 1, 2, Arr.Of(0)),
		SliceInplace = Arr.SliceInplace(a(), 1, 2),
		Erase = Arr.Erase(a(), 1, 1),
		EraseInplace = Arr.EraseInplace(a(), 1, 1),
		Splice = Arr.Splice(a(), 1, 1, a()),
		SpliceInplace = Arr.SpliceInplace(a(), 1, 1, a()),
		Reverse = Arr.Reverse(a()),
		ReverseInplace = Arr.ReverseInplace(a()),
		Rotate = Arr.Rotate(a(), 1),
		RotateInplace = Arr.RotateInplace(a(), 1),
		Shuffle = Arr.Shuffle(a()),
		ShuffleInplace = Arr.ShuffleInplace(a()),
		Sort = Arr.Sort(a()),
		SortInplace = Arr.SortInplace(a()),
		SortUnchecked = Arr.SortUnchecked(a()),
		SortInplaceUnchecked = Arr.SortInplaceUnchecked(a()),
		StableSort = Arr.StableSort(a()),
		StableSortInplace = Arr.StableSortInplace(a()),
		SortBy = Arr.SortBy(a(), id),
		SortByInplace = Arr.SortByInplace(a(), id),
		NthElementInplace = Arr.NthElementInplace(a(), 2),
		PartialSort = Arr.PartialSort(a(), 2),
		PartialSortInplace = Arr.PartialSortInplace(a(), 2),
		MergeSorted = Arr.MergeSorted(Arr.Of(1, 3), Arr.Of(2), lt),
		Map = Arr.Map(a(), id),
		MapTo = Arr.Map(a(), id, Arr.Of(0)),
		MapInplace = Arr.MapInplace(a(), id),
		Filter = Arr.Filter(a(), even),
		Retain = Arr.Retain(a(), even),
		Flat = Arr.Flat<<number>>(Arr.Of(a(), a())),
		FlatInplace = Arr.FlatInplace<<number>>(Arr.Of(a(), a())),
		Flatmap = Arr.Flatmap(a(), function(v: number): ...number
			return v, v
		end),
		FlatmapInplace = Arr.FlatmapInplace(a(), function(v: number): ...number
			return v, v
		end),
		Drain = Arr.Drain(a(), id),
		ConcatInplace = Arr.ConcatInplace(a(), a()),
		-- M3(2026-10-07)
		PartitionYes = (Arr.Partition(a(), even)),
		PartitionNo = select(2, Arr.Partition(a(), even)),
		TakeWhile = Arr.TakeWhile(a(), even),
		TakeWhileInplace = Arr.TakeWhileInplace(a(), even),
		DropWhile = Arr.DropWhile(a(), even),
		DropWhileInplace = Arr.DropWhileInplace(a(), even),
		Dedup = Arr.Dedup(a()),
		DedupInplace = Arr.DedupInplace(a()),
		Unique = Arr.Unique(a()),
		UniqueInplace = Arr.UniqueInplace(a()),
		Scan = Arr.Scan(a(), 0, function(acc: number, v: number): number
			return acc + v
		end),
		Zip = Arr.Zip(a(), a()),
		ZipWith = Arr.ZipWith(a(), a(), function(x: number, y: number): number
			return x + y
		end),
		Chunks = Arr.Chunks(a(), 2),
		ChunksEmpty = Arr.Chunks(Arr.Sized(0, 0), 2),
		ChunksInner = Arr.Chunks(a(), 2)[1],
		Windows = Arr.Windows(a(), 2),
		WindowsEmpty = Arr.Windows(a(), 9),
		WindowsInner = Arr.Windows(a(), 2)[1],
		-- M4(2026-10-07) — 무리도 Arr
		GroupByInner = stl.HashMap.Get(Arr.GroupBy(a(), id, stl.HashMap.New() :: any), 30),
	}
	for name, result in arrResults do
		assert(stl.isArr(result), `Arr.{name} 결과에 태그가 없습니다`)
		assert(getmetatable(result) == nil, `Arr.{name} 결과에 메타테이블이 있습니다`)
	end

	const hm = HashMap.New<<string, number>>()
	HashMap.Set(hm, "x", 1)
	const mapResults: { [string]: any } = {
		New = hm,
		FromTable = HashMap.FromTable<<string, number>>({ x = 1 }),
		FromTableArr = HashMap.FromTable(Arr.Of(10, 20) :: any), -- Arr 갈래(9라운드 — 이 반환 경로만 비어 있었음)
		FromRecords = HashMap.FromRecords({ { key = "x", value = 1 } }),
		Adopt = HashMap.Adopt({ x = 1 }, 1),
		Clone = HashMap.Clone(hm),
		Clear = HashMap.Clear(HashMap.Clone(hm)),
		Retain = HashMap.Retain(HashMap.Clone(hm), function(_k: string, _v: number): boolean
			return true
		end),
		MergeInplace = HashMap.MergeInplace(HashMap.Clone(hm), hm),
		Merge = HashMap.Merge(hm, hm),
		GroupBy = Arr.GroupBy(a(), id, HashMap.New() :: any),
		CountBy = Arr.CountBy(a(), id, HashMap.New() :: any),
		KeyBy = Arr.KeyBy(a(), id, HashMap.New() :: any),
	}
	for name, result in mapResults do
		assert(stl.isHashMap(result), `HashMap.{name} 결과에 태그가 없습니다`)
	end

	const hs = HashSet.Of(1, 2)
	const setResults: { [string]: any } = {
		New = HashSet.New<<number>>(),
		Of = hs,
		FromList = HashSet.FromList({ 1, 2 }),
		Clone = HashSet.Clone(hs),
		Clear = HashSet.Clear(HashSet.Clone(hs)),
		Union = HashSet.Union(hs, hs),
		Intersect = HashSet.Intersect(hs, hs),
		Difference = HashSet.Difference(hs, hs),
		SymmetricDifference = HashSet.SymmetricDifference(hs, hs),
	}
	for name, result in setResults do
		assert(stl.isHashSet(result), `HashSet.{name} 결과에 태그가 없습니다`)
	end

	const tm = FlatMap.New<<number, number>>(Common.compareNumber)
	const treeMapResults: { [string]: any } = {
		New = tm,
		FromRecords = FlatMap.FromRecords({ { key = 1, value = 1 } }, Common.compareNumber),
		Adopt = FlatMap.Adopt({ { key = 1, value = 1 } }, 1, Common.compareNumber),
		Clone = FlatMap.Clone(tm),
		Clear = FlatMap.Clear(FlatMap.Clone(tm)),
	}
	for name, result in treeMapResults do
		assert(stl.isFlatMap(result), `FlatMap.{name} 결과에 태그가 없습니다`)
	end

	const ts = FlatSet.FromList({ 1, 2 }, Common.compareNumber)
	const treeSetResults: { [string]: any } = {
		New = FlatSet.New<<number>>(Common.compareNumber),
		FromList = ts,
		Clone = FlatSet.Clone(ts),
		Clear = FlatSet.Clear(FlatSet.Clone(ts)),
		Union = FlatSet.Union(ts, ts),
		Intersect = FlatSet.Intersect(ts, ts),
		Difference = FlatSet.Difference(ts, ts),
		SymmetricDifference = FlatSet.SymmetricDifference(ts, ts),
	}
	for name, result in treeSetResults do
		assert(stl.isFlatSet(result), `FlatSet.{name} 결과에 태그가 없습니다`)
	end

	const hp = Heap.FromList({ 3, 1 }, lt)
	const heapResults: { [string]: any } = {
		New = Heap.New(lt),
		FromList = hp,
		Clone = Heap.Clone(hp),
		Clear = Heap.Clear(Heap.Clone(hp)),
	}
	for name, result in heapResults do
		assert(stl.isHeap(result), `Heap.{name} 결과에 태그가 없습니다`)
	end

	-- LinkedDeque(2026-10-13) — 모든 생성·반환 경로가 토큰을 붙이는지
	const linked = stl.LinkedDeque.Of(1, 2)
	const linkedResults: { [string]: any } = {
		New = stl.LinkedDeque.New<<number>>(),
		FromList = stl.LinkedDeque.FromList({ 1, 2 }),
		Of = linked,
		Clone = stl.LinkedDeque.Clone(linked),
		Clear = stl.LinkedDeque.Clear(stl.LinkedDeque.Of(1)),
		PushBack = stl.LinkedDeque.PushBack(stl.LinkedDeque.Of(1), 2),
		PushFront = stl.LinkedDeque.PushFront(stl.LinkedDeque.Of(1), 2),
		TraitPushBack = stl.Deque.PushBack(stl.LinkedDeque.Of(1), 2),
	}
	for name, result in linkedResults do
		assert(stl.isLinkedDeque(result), `LinkedDeque.{name} 결과에 태그가 없습니다`)
		assert(getmetatable(result) == nil, `LinkedDeque.{name} 결과에 메타테이블이 있습니다`)
	end
	assert(stl.isArr(stl.LinkedDeque.ToArr(linked)), "LinkedDeque.ToArr 는 Arr")

	-- CircularDeque(M5, 2026-10-07)
	const dq = stl.CircularDeque.Of(1, 2)
	const dequeResults: { [string]: any } = {
		New = stl.CircularDeque.New<<number>>(),
		NewCapacity = stl.CircularDeque.New<<number>>(10),
		FromList = stl.CircularDeque.FromList({ 1, 2 }),
		Of = dq,
		Clone = stl.CircularDeque.Clone(dq),
		Clear = stl.CircularDeque.Clear(stl.CircularDeque.Of(1)),
		PushBack = stl.CircularDeque.PushBack(stl.CircularDeque.Of(1), 2),
		PushFront = stl.CircularDeque.PushFront(stl.CircularDeque.Of(1), 2),
	}
	for name, result in dequeResults do
		assert(stl.isCircularDeque(result), `CircularDeque.{name} 결과에 태그가 없습니다`)
		assert(getmetatable(result) == nil, `CircularDeque.{name} 결과에 메타테이블이 있습니다`)
	end
	assert(stl.isArr(stl.CircularDeque.ToArr(dq)), "CircularDeque.ToArr 는 Arr")

	const one = Fut.Resolved(1)
	const futResults: { [string]: any } = {
		New = Fut.New(function(resolve: (number) -> ())
			resolve(1)
		end),
		Resolved = one,
		Rejected = Fut.Rejected<<(number)>>("x"),
		Async = Fut.Async(function(): number
			return 1
		end)(),
		AndThen = Fut.AndThen(one, function(v: number): number
			return v
		end),
		Chain = Fut.Chain(one, function(v: number)
			return Fut.Resolved(v)
		end),
		Catch = Fut.Catch(Fut.Rejected<<(number)>>("x"), function(): number
			return 0
		end),
		All = Fut.All({ one, one }),
	}
	for name, result in futResults do
		assert(stl.isFut(result), `Fut.{name} 결과에 태그가 없습니다`)
	end
	-- 태그가 빠지면 실제로 틀어지는 두 자리를 직접 봅니다
	const chained = Fut.Chain(one, function(v: number)
		return Fut.AndThen(Fut.Resolved(v), function(w: number): number
			return w + 1
		end)
	end)
	assert(
		Fut.Status(chained) == "Resolved" and Fut.Await(chained) == 2,
		"Chain 이 AndThen 결과를 Fut 으로 받음"
	)
	const allArr = Fut.Await(Fut.All({ one, one }))
	assert(stl.isArr(allArr), "Fut.All 결과는 태그 붙은 Arr")
	assert(Arr.Flat<<number>>(Arr.Of(Arr.Map(a(), id))).n == 3, "Flat 이 Map 결과를 배열로 펼침")
end
print("PASS")

print("=== 6. ⭐ 술어는 타입 토큰 하나를 본다 (2026-10-06, Trait) ===")
do
	-- 위조는 막지 않습니다(사용자 결정) — 토큰을 베껴 넣으면 그 종류입니다. 대신
	-- **우연**은 막힙니다: 모양만 같은 테이블, 옛 문자열 태그, 직렬화했다 되읽은 것
	-- (토큰의 정체성을 잃음)은 그 종류가 아닙니다.
	const predicates: { { name: string, is: (any) -> boolean, token: any } } = {
		{ name = "Arr", is = stl.isArr, token = stl.Arr.Token },
		{ name = "HashMap", is = stl.isHashMap, token = stl.HashMap.Token },
		{ name = "HashSet", is = stl.isHashSet, token = stl.HashSet.Token },
		{ name = "FlatMap", is = stl.isFlatMap, token = stl.FlatMap.Token },
		{ name = "FlatSet", is = stl.isFlatSet, token = stl.FlatSet.Token },
		{ name = "Heap", is = stl.isHeap, token = stl.Heap.Token },
		{ name = "Fut", is = stl.isFut, token = stl.Fut.Token },
		{ name = "CircularDeque", is = stl.isCircularDeque, token = stl.CircularDeque.Token },
		{ name = "LinkedDeque", is = stl.isLinkedDeque, token = stl.LinkedDeque.Token },
		{ name = "TreeMap", is = stl.isTreeMap, token = stl.TreeMap.Token },
		{ name = "TreeSet", is = stl.isTreeSet, token = stl.TreeSet.Token },
	}
	const oldTags = {
		"__arr__",
		"__hashmap__",
		"__hashset__",
		"__treemap__",
		"__treeset__",
		"__heap__",
		"__fut__",
		"__deque__",
		"__linkeddeque__",
		"__nodetreemap__",
		"__nodetreeset__",
	}
	for _, case in predicates do
		assert(case.token.name == case.name, `{case.name} 의 토큰 이름이 {tostring(case.token.name)}`)
	end
	for idx, case in predicates do
		-- 테이블이 아닌 것·토큰 없는 것·옛 문자열 태그·이름만 같은 다른 토큰은 아님
		for _, v in { nil, 1, "x", true, {}, { n = 0 }, { [oldTags[idx]] = true } } :: { any } do
			assert(not case.is(v), `{case.name}: {typeof(v)} 를 받아들임`)
		end
		assert(not case.is({ __type = stl.Trait.NewToken(case.name) }), `{case.name}: 이름만 같은 토큰`)
		assert(not case.is({ __type = { name = case.name } }), `{case.name}: 직렬화했다 되읽은 토큰`)
		-- 토큰을 베껴 넣으면 그 종류(위조는 계약 밖 — 막지 않음)
		assert(case.is({ __type = case.token }), `{case.name}: 토큰을 가진 테이블`)
		-- 다른 종류의 토큰은 아님(교차)
		for jdx, other in predicates do
			if jdx ~= idx then
				assert(not case.is({ __type = other.token }), `{case.name} 술어가 {other.name} 토큰을 받음`)
			end
		end
	end
	-- Optional 은 태그 유니온이라 토큰이 없습니다 — 교차만
	const present = stl.Optional.Present(1)
	for _, case in predicates do
		assert(not case.is(present), `{case.name} 술어가 Optional 을 받아들임`)
	end
	assert(stl.isOptional(present) and not stl.isOptional(stl.Arr.Of(1)), "Optional 술어")
	-- ⭐ 바깥에서 자기 트레이트를 만들어 우리 Arr·HashMap 에 붙이기 — 한 종류가 여러
	-- 트레이트를 구현(문자열 태그 하나로는 하드코딩이 필요했던 것)
	type Show = { read Show: (any) -> string }
	const ShowTrait = stl.Trait.New<<Show>>("Show")
	stl.Trait.Impl(ShowTrait, stl.Arr.Token, {
		Show = function(a: any): string
			return `Arr({a.n})`
		end,
	})
	const showArr = stl.Trait.ImplOf(ShowTrait, stl.Arr.Of(1, 2))
	assert(showArr ~= nil and showArr.Show(stl.Arr.Of(1, 2)) == "Arr(2)", "사용자 트레이트를 Arr 에")
	-- (2026-10-13: List 는 기본 구현을 가진 트레이트가 돼 완성 표가 모듈과 다른 표 — 함수로 견줍니다)
	const arrList = stl.Trait.ImplOf(stl.List, stl.Arr.Of(1))
	assert(arrList ~= nil and arrList.Get == stl.Arr.Get and arrList.Fold == stl.Arr.Fold, "Arr 은 List 도 그대로")
	assert(stl.Trait.ImplOf(ShowTrait, stl.HashMap.New()) == nil, "등록 안 한 종류는 nil")
	for _, v in { nil, 1, "x", {} } :: { any } do
		assert(stl.Trait.ImplOf(ShowTrait, v) == nil, `{typeof(v)} 는 안전하게 nil`)
		assert(stl.Trait.Implements(ShowTrait, v) == false, `{typeof(v)} 는 안전하게 false(Implements)`)
	end
	-- Count: 술어 없으면 전체, 있으면 참인 것만(AE) — Arr 와 List 진입점이 같은 뜻
	const counted = stl.Arr.Of(1, 2, 3, 4)
	const isEven = function(v: number): boolean
		return v % 2 == 0
	end
	assert(stl.Arr.Count(counted) == 4 and stl.List.Count(counted) == 4, "Count 전체")
	assert(stl.Arr.Count(counted, isEven) == 2 and stl.List.Count(counted, isEven) == 2, "Count 술어")
	-- (8라운드) 값과 위치가 다르고 참·거짓이 반반이 아닌 데이터 — 조건을 뒤집거나 위치를 넘기는
	-- 실수가 위 데이터로는 같은 답이었음
	const tens = stl.Arr.Of(10, 20, 30)
	const over15 = function(v: number): boolean
		return v > 15
	end
	assert(stl.List.Count(tens, over15) == 2 and stl.Arr.Count(tens, over15) == 2, "Count 술어(값 ≠ 위치)")
	-- IndexOf 는 **처음** 위치 — 중복과 구멍(8라운드: 마지막 위치를 돌려줘도 통과했음)
	assert(stl.List.IndexOf(stl.Arr.Of(10, 20, 20), 20) == 2, "IndexOf 중복은 처음")
	assert(stl.List.IndexOf(stl.Arr.Of<<number?>>(10, nil, 30, nil), nil) == 2, "IndexOf 첫 구멍")
	-- Fut.All 에 Fut 이 아닌 원소 → 던지지 않고 Rejected(8라운드 참고: 라이브러리 줄에서 던질 수 있었음)
	assert(stl.Fut.Status(stl.Fut.All({ stl.Fut.Resolved(1), 2 :: any })) == "Rejected", "All 의 Fut 아닌 원소")
	-- 술어 없는 Count 는 **구멍도 자리로** 셉니다(7라운드 — "nil 아닌 것만" 으로 잘못 세도 통과했음)
	for _, holed in { stl.Arr.Of<<number?>>(1, nil, 3), stl.Arr.Sized<<number?>>(3, nil) } :: { any } do
		assert(stl.Arr.Count(holed) == holed.n and stl.List.Count(holed) == holed.n, `구멍 든 Count: n={holed.n}`)
	end
	-- ⭐ 내장 종류 × 내장 트레이트 전수(리뷰 1라운드 — Set 등록을 빼도 아무것도 안 잡혔음)
	const T = stl.Trait
	const samples: { { name: string, value: any, list: any, map: any, set: any } } = {
		{ name = "Arr", value = stl.Arr.Of(1), list = stl.Arr, map = nil, set = nil },
		{ name = "HashMap", value = stl.HashMap.New(), list = nil, map = stl.HashMap, set = nil },
		{ name = "FlatMap", value = stl.FlatMap.New(Common.compareNumber), list = nil, map = stl.FlatMap, set = nil },
		{ name = "HashSet", value = stl.HashSet.New(), list = nil, map = nil, set = stl.HashSet },
		{ name = "FlatSet", value = stl.FlatSet.New(Common.compareNumber), list = nil, map = nil, set = stl.FlatSet },
		{ name = "TreeMap", value = stl.TreeMap.New(Common.compareNumber), list = nil, map = stl.TreeMap, set = nil },
		{ name = "TreeSet", value = stl.TreeSet.New(Common.compareNumber), list = nil, map = nil, set = stl.TreeSet },
		{
			name = "Heap",
			value = stl.Heap.New(function(a: number, b: number): boolean
				return a < b
			end),
			list = nil,
			map = nil,
			set = nil,
		},
		{ name = "Fut", value = stl.Fut.Resolved(1), list = nil, map = nil, set = nil },
		{ name = "CircularDeque", value = stl.CircularDeque.Of(1), list = stl.CircularDeque, map = nil, set = nil },
		{ name = "LinkedDeque", value = stl.LinkedDeque.Of(1), list = stl.LinkedDeque, map = nil, set = nil },
	}
	for _, case in samples do
		-- List 의 완성 표는 "모듈이 준 것 + 기본 구현" — 모듈의 프리미티브가 그대로 들어 있는지로 봅니다
		const listImpl = T.ImplOf(stl.List, case.value)
		assert((listImpl ~= nil) == (case.list ~= nil), `{case.name} 의 List 구현 유무`)
		if listImpl ~= nil then
			assert(
				listImpl.Get == case.list.Get and listImpl.NextIndex == case.list.NextIndex,
				`{case.name} 의 List 구현`
			)
			assert(
				type(listImpl.Fold) == "function" and type(listImpl.Every) == "function",
				`{case.name} 의 기본 구현`
			)
		end
		-- 구현 표는 **넘긴 것만 든 표**입니다(2026-10-13, 질문 AS) — 모듈 테이블이 아니라 그 트레이트의 함수만.
		const mapImpl: any, setImpl: any = T.ImplOf(stl.Map, case.value), T.ImplOf(stl.Set, case.value)
		assert((mapImpl ~= nil) == (case.map ~= nil), `{case.name} 의 Map 구현 여부`)
		if mapImpl ~= nil then
			assert(mapImpl.Get == case.map.Get and mapImpl.Iter == case.map.Iter, `{case.name} 의 Map 구현`)
			assert(
				mapImpl ~= case.map and mapImpl.Len == nil and mapImpl.Keys == nil,
				`{case.name}: Map 표에 다른 함수가 섞임`
			)
		end
		assert((setImpl ~= nil) == (case.set ~= nil), `{case.name} 의 Set 구현 여부`)
		if setImpl ~= nil then
			assert(setImpl.Add == case.set.Add and setImpl.Items == case.set.Items, `{case.name} 의 Set 구현`)
			assert(
				setImpl ~= case.set and setImpl.Len == nil and setImpl.Union == nil,
				`{case.name}: Set 표에 다른 함수가 섞임`
			)
		end
		assert(T.Implements(stl.List, case.value) == (case.list ~= nil), `{case.name} Implements List`)
		assert(T.TokenOf(case.value) == (stl :: any)[case.name].Token, `{case.name} 의 TokenOf`)
	end
	-- TokenOf 는 토큰이 아닌 `__type`(숫자·문자열·아무 테이블)을 토큰으로 돌려주지 않음
	for _, bogus in { 5, true, "Player", 0 / 0, {}, table.freeze({ name = "Arr" }) } :: { any } do
		assert(T.TokenOf({ __type = bogus }) == nil, `토큰 아닌 __type: {tostring(bogus)}`)
	end
	-- Stamp 로 사용자 값에 토큰
	const MyKind = T.NewToken("MyKind")
	const stamped = T.Stamp({}, MyKind)
	assert(T.TokenOf(stamped) == MyKind and not stl.isArr(stamped), "Stamp")
	-- 공용 알고리즘의 에러는 토큰 아닌 `__type` 에서도 규약대로(리뷰 1라운드 — 라이브러리 줄에서
	-- `attempt to index number with 'name'` 이었음)
	for _, bogus in { 5, true, "Player", 0 / 0 } :: { any } do
		const ok, err = pcall(function()
			stl.List.IndexOf({ __type = bogus } :: any, 1)
		end)
		assert(not ok and string.find(tostring(err), "needs a List", 1, true) ~= nil, `에러 메시지: {err}`)
		assert(string.find(tostring(err), "spec.contracts", 1, true) ~= nil, `사용자 줄이 아님: {err}`)
	end
	-- API 경계: 토큰이 아닌 것(얼었어도), 트레이트가 아닌 것, 이름이 문자열이 아닌 것, 같은 토큰을
	-- 두 번 — 전부 사용자 줄 에러(리뷰 1라운드)
	const boundary: { { name: string, run: () -> (), needle: string? } } = {
		{
			name = "얼린 아무 테이블",
			run = function()
				T.Impl(stl.List, table.freeze({}) :: any, stl.Arr)
			end,
		},
		{
			name = "토큰 모음 테이블",
			run = function()
				T.Impl(stl.List, { Arr = stl.Arr.Token } :: any, stl.Arr)
			end,
		},
		{
			name = "트레이트가 아님(Impl)",
			run = function()
				T.Impl(nil :: any, MyKind, {})
			end,
		},
		{
			name = "트레이트가 아님(ImplOf)",
			run = function()
				T.ImplOf(nil :: any, stl.Arr.Of(1))
			end,
		},
		{
			name = "트레이트가 아님(Implements)",
			run = function()
				T.Implements(nil :: any, stl.Arr.Of(1))
			end,
		},
		{
			name = "이름이 문자열이 아님",
			run = function()
				T.NewToken(nil :: any)
			end,
		},
		{
			name = "같은 토큰을 두 번(내장 덮어쓰기)",
			run = function()
				T.Impl(stl.List, stl.Arr.Token, {} :: any)
			end,
		},
		{
			-- 다 갖춘 구현으로도(2라운드 리뷰: 위는 `{}` 라, 중복 검사를 지워도 필수 함수 검사가 대신
			-- 걸려 통과했음 — 지운 사본에서는 가짜 구현이 Arr 의 List 구현을 덮어 IndexOf 가 틀렸음)
			name = "같은 토큰을 두 번(다 갖춘 구현)",
			needle = "Arr already implements List",
			run = function()
				T.Impl(stl.List, stl.Arr.Token, table.clone(stl.Arr) :: any)
			end,
		},
		{
			name = "구현이 nil",
			run = function()
				T.Impl(stl.List, MyKind, nil :: any)
			end,
		},
	}
	for _, case in boundary do
		const ok, err = pcall(case.run)
		assert(not ok, `{case.name}: 에러가 안 남`)
		assert(string.find(tostring(err), "Trait:", 1, true) ~= nil, `{case.name}: 규약 메시지가 아님: {err}`)
		const needle = case.needle
		assert(needle == nil or string.find(tostring(err), needle, 1, true) ~= nil, `{case.name}: {err}`)
		assert(
			string.find(tostring(err), "spec.contracts", 1, true) ~= nil,
			`{case.name}: 사용자 줄이 아님: {err}`
		)
	end
	assert(
		(T.ImplOf(stl.List, stl.Arr.Of(1)) :: any).Get == stl.Arr.Get,
		"덮어쓰기 시도 뒤에도 내장 그대로"
	)
	-- 리스트·사전을 받는 진입점에 **다른 종류의 컨테이너**를 넘기면 조용히 비거나(`n` 이 없어
	-- `#` 가 0) 내부 필드가 키로 쏟아졌음(Gemini 트레이트 검토 — CircularDeque 가 들어오면 바로 남) →
	-- 사용자 줄 에러. `Arr` 은 그대로 리스트로 받습니다.
	const wrongInputs: { { name: string, run: () -> () } } = {
		{
			name = "HashSet.FromList(HashMap)",
			run = function()
				stl.HashSet.FromList(stl.HashMap.New() :: any)
			end,
		},
		{
			name = "Arr.FromTable(FlatSet)",
			run = function()
				stl.Arr.FromTable(stl.FlatSet.New(Common.compareNumber) :: any)
			end,
		},
		{
			name = "HashMap.FromTable(HashSet)",
			run = function()
				stl.HashMap.FromTable(stl.HashSet.Of(1) :: any)
			end,
		},
		{
			name = "Fut.All(HashMap)",
			run = function()
				stl.Fut.All(stl.HashMap.New() :: any)
			end,
		},
	}
	for _, case in wrongInputs do
		const ok, err = pcall(case.run)
		assert(not ok, `{case.name}: 에러가 안 남`)
		assert(
			string.find(tostring(err), "spec.contracts", 1, true) ~= nil,
			`{case.name}: 사용자 줄이 아님: {err}`
		)
	end
	assert(stl.HashSet.Len(stl.HashSet.FromList(stl.Arr.Of(1, 2))) == 2, "Arr 은 리스트로 받음")
	-- (2라운드) 두 진입점이 같은 규칙: **등록 안 된 `__type`**(다른 사본의 컨테이너, 되읽은 것)도
	-- 리스트·사전이 아님 — FromTable 은 내부 필드를 쏟았고 listLength 는 거절해 엇갈렸음
	const foreignToken = table.freeze({ name = "HashSet" })
	const foreignSet = { __type = foreignToken, map = {} }
	const foreignRuns: { () -> () } = {
		function()
			stl.HashMap.FromTable(foreignSet :: any)
		end,
		function()
			stl.HashSet.FromList(foreignSet :: any)
		end,
		function()
			stl.HashMap.FromTable({ 1, 2, __type = "x" } :: any)
		end,
		function()
			stl.HashSet.FromList({ 1, 2, __type = "x" } :: any)
		end,
		-- (3라운드) 컨테이너 자리에 nil·숫자 — 라이브러리 줄의 rawget 에러가 되면 안 됨
		function()
			stl.List.IndexOf(nil :: any, 1)
		end,
		function()
			stl.Map.Keys(5 :: any)
		end,
	}
	for _, run in foreignRuns do
		const ok, err = pcall(run)
		assert(not ok and string.find(tostring(err), "spec.contracts", 1, true) ~= nil, `등록 안 된 __type: {err}`)
	end
	-- 메시지가 상황을 맞게 말함(2라운드 — 반대로 안내했음): 같은 사본의 다른 종류 / 다른 사본(되읽음) /
	-- 토큰 없음. 깨진 `n` 의 Arr 은 "Arr 인데 n 이 이상함" 으로, 내부 모듈 이름(Common) 없이.
	local function errOf(run: () -> ()): string
		const ok, err = pcall(run)
		assert(not ok, "에러가 나야 함")
		return tostring(err)
	end
	const sameCopy = errOf(function()
		stl.List.IndexOf(stl.HashMap.New() :: any, 1)
	end)
	assert(string.find(sameCopy, "HashMap does not implement List", 1, true) ~= nil, sameCopy)
	assert(string.find(sameCopy, "another copy", 1, true) == nil, `같은 사본인데 사본 안내: {sameCopy}`)
	const otherCopy = errOf(function()
		stl.List.IndexOf({ __type = table.freeze({ name = "Arr" }) } :: any, 1)
	end)
	assert(string.find(otherCopy, "another copy", 1, true) ~= nil, `다른 사본 안내가 없음: {otherCopy}`)
	const noToken = errOf(function()
		stl.List.IndexOf({} :: any, 1)
	end)
	assert(string.find(noToken, "without a type token", 1, true) ~= nil, noToken)
	const brokenN = stl.Arr.Of(1, 2) :: any
	brokenN.n = nil
	const brokenMsg = errOf(function()
		stl.HashSet.FromList(brokenN)
	end)
	assert(string.find(brokenMsg, "invalid n", 1, true) ~= nil, `깨진 n 메시지: {brokenMsg}`)
	assert(string.find(brokenMsg, "Common:", 1, true) == nil, `내부 모듈 이름: {brokenMsg}`)
	-- (6라운드) 유효한 경계값 — 빈 Arr(`n = 0`, `-0`)는 모든 리스트 진입점이 받아야 함(`>= 0` 을
	-- `> 0` 으로 바꿔도 통과했음)
	const emptyArr = stl.Arr.Of<<number>>()
	const negZero = stl.Arr.Of<<number>>() :: any
	negZero.n = -0
	for _, empty in { emptyArr, negZero } :: { any } do
		assert(stl.HashSet.Len(stl.HashSet.FromList(empty)) == 0, "빈 Arr → HashSet")
		assert(stl.FlatSet.Len(stl.FlatSet.FromList(empty, Common.compareNumber)) == 0, "빈 Arr → FlatSet")
		assert(stl.Arr.FromTable(empty).n == 0, "빈 Arr → FromTable")
		assert(stl.Fut.Status(stl.Fut.All(empty)) == "Resolved", "빈 Arr → Fut.All")
	end
	-- (AC 리뷰) 길이 정책 [0, 2^26] — 정수지만 너무 큰 n 은 어떤 진입점도 받지 않음(예전엔 FromTable 이
	-- n = 2^27 인 Arr 를 입양하고 다른 진입점은 위치 없는 table overflow 였음)
	const huge = { n = 2 ^ 27, 1 }
	for _, run in
		{
			function()
				stl.Arr.Adopt(huge :: any)
			end,
			function()
				stl.Arr.FromTable(huge :: any)
			end,
			function()
				stl.HashSet.FromList(huge :: any)
			end,
		} :: { () -> () }
	do
		const msg = errOf(run)
		assert(string.find(msg, "2^26", 1, true) or string.find(msg, "67108864", 1, true), `너무 큰 n: {msg}`)
		assert(string.find(msg, "spec.contracts", 1, true) ~= nil, `너무 큰 n 의 줄: {msg}`)
	end
	-- 길이 경계: 2^26 은 받고(할당 없이 입양), 2^26 + 1 은 거절(AC 2라운드 — `>` 를 `>=` 로 바꿔도 통과했음)
	assert(stl.Arr.Adopt({ n = 2 ^ 26 } :: any).n == 2 ^ 26, "길이 2^26 은 받음")
	const overCap = errOf(function()
		stl.Arr.Adopt({ n = 2 ^ 26 + 1 } :: any)
	end)
	assert(string.find(overCap, "list length must be in", 1, true) ~= nil, `2^26 + 1: {overCap}`)
	-- (5라운드) "깨진 n" 은 nil 만이 아님 — 음수·소수·무한·NaN·문자열 전부(조건 하나만 빠져도 `#` 로
	-- 조용히 읽었음)
	for _, badN in { -1, 1.5, math.huge, 0 / 0, "2" } :: { any } do
		const broken = stl.Arr.Of(10, 20, 30) :: any
		broken.n = badN
		const msg = errOf(function()
			stl.HashSet.FromList(broken)
		end)
		assert(
			string.find(msg, "invalid n", 1, true) and string.find(msg, "spec.contracts", 1, true),
			`깨진 n {tostring(badN)}: {msg}`
		)
	end
	-- 다른 종류는 "Arr 인데 n 이 이상함" 이 아니라 "리스트가 아님 — HashMap"(3라운드)
	const kindMsg = errOf(function()
		stl.HashSet.FromList(stl.HashMap.New() :: any)
	end)
	assert(
		string.find(kindMsg, "expected a list", 1, true) and string.find(kindMsg, "HashMap", 1, true),
		`다른 종류 메시지: {kindMsg}`
	)
	-- 다른 사본의 Arr(유효한 n): 리스트 진입점은 위치로 받고, 사전 진입점(FromTable)은 거절 —
	-- 의도된 비대칭(3라운드, conventions 리스트 길이 규약). FromTable 메시지는 "다른 사본" 을 말함.
	const foreignArr = { __type = table.freeze({ name = "Arr" }), n = 2, 10, 20 }
	assert(
		stl.HashSet.Len(stl.HashSet.FromList(foreignArr :: any)) == 2,
		"리스트 진입점은 다른 사본 Arr 을 받음"
	)
	const foreignArrMsg = errOf(function()
		stl.HashMap.FromTable(foreignArr :: any)
	end)
	assert(
		string.find(foreignArrMsg, "another copy", 1, true) ~= nil,
		`FromTable 의 다른 사본 Arr: {foreignArrMsg}`
	)
	-- (4라운드) FromTable 의 메시지 갈래 둘 더: 같은 사본의 다른 종류 / 예약 필드. FromList 쪽 이름.
	const sameKindMsg = errOf(function()
		stl.HashMap.FromTable(stl.HashSet.Of(1) :: any)
	end)
	assert(
		string.find(sameKindMsg, "a HashSet container", 1, true)
			and not string.find(sameKindMsg, "another copy", 1, true),
		`FromTable 같은 사본 다른 종류: {sameKindMsg}`
	)
	const reservedMsg = errOf(function()
		stl.HashMap.FromTable({ 1, __type = "x" } :: any)
	end)
	assert(string.find(reservedMsg, "reserved __type field (x)", 1, true) ~= nil, `예약 필드: {reservedMsg}`)
	const listReservedMsg = errOf(function()
		stl.HashSet.FromList({ 1, __type = "x" } :: any)
	end)
	assert(string.find(listReservedMsg, "got x", 1, true) ~= nil, `FromList 예약 필드: {listReservedMsg}`)
	-- (4라운드) 같은 사본의 사용자 컨테이너가 `n` 을 가져도 리스트가 아님 — 링 버퍼처럼 `n` 이 개수면
	-- 1..n 으로 조용히 잘못 읽었음. 이름이 Arr 가 아니면 `n` 과 상관없이 거절.
	const Ring = T.NewToken("Ring")
	const ring = T.Stamp({ n = 3, head = 3, [1] = "c", [3] = "a", [4] = "b" }, Ring)
	const ringRuns: { () -> () } = {
		function()
			stl.HashSet.FromList(ring :: any)
		end,
		function()
			stl.Arr.FromTable(ring :: any)
		end,
	}
	for _, run in ringRuns do
		const msg = errOf(run)
		assert(
			string.find(msg, "Ring", 1, true) and string.find(msg, "spec.contracts", 1, true),
			`n 있는 사용자 컨테이너: {msg}`
		)
	end
	-- (4라운드) Arr.Adopt 은 이 사본의 Arr 말고도 `__type` 이 있으면 거절(입력의 토큰을 덮어써
	-- 다른 사본에서 사라지게 하지 않음)
	const containerish: { any } = { foreignArr, ring, stl.HashSet.Of(1) }
	for _, v in containerish do
		const msg = errOf(function()
			stl.Arr.Adopt(v)
		end)
		assert(string.find(msg, "already a container", 1, true) and string.find(msg, "spec.contracts", 1, true), msg)
	end
	-- Stamp 경계(2라운드 — 테이블 아님·얼린 테이블은 라이브러리 줄, 토큰 검사엔 테스트 없음)와
	-- Trait.New 의 이름 검사
	for _, run in
		{
			function()
				T.Stamp(5 :: any, MyKind)
			end,
			function()
				T.Stamp(table.freeze({}), MyKind)
			end,
			function()
				T.Stamp({}, table.freeze({ name = "x" }) :: any)
			end,
			function()
				T.New(nil :: any)
			end,
		}
	do
		const err = errOf(run)
		assert(
			string.find(err, "Trait:", 1, true) and string.find(err, "spec.contracts", 1, true),
			`Trait 경계: {err}`
		)
	end
	-- 내장 트레이트에 등록한 사용자 토큰도 버리면 수거됨(2라운드 — impls 가 강한 키라 남았음).
	-- 그리고 **쥐고 있으면 남음**(3라운드 — `__mode = "kv"` 로 잘못 쓰면 인라인 구현이 증발했음).
	-- 개수는 루프 전 기준선과 비교 — 다른 스펙·M5 의 CircularDeque 가 List 를 구현해도 거짓 실패 없게.
	-- 기준선 전에 수거 — 앞에서 버린 등록이 남아 있으면 기준선이 부풀어 거짓 실패했음(4라운드).
	-- `collectgarbage("collect")` 는 Roblox 타입 정의에 없어 분석기가 모름 — 실행기(luau)에는 있음.
	const fullGc = (_G :: any).collectgarbage
	fullGc("collect")
	fullGc("collect")
	local before = 0
	for _ in stl.List.impls do
		before += 1
	end
	-- 구현 테이블은 **인라인으로**(따로 쥐는 지역 변수 없이) — 쥐고 있으면 `"kv"` 로 잘못 써도
	-- 남아 돌연변이가 살아남았음.
	const keptToken = T.NewToken("Kept")
	T.Impl(
		stl.List,
		keptToken,
		{
			Get = stl.Arr.Get,
			FirstIndex = stl.Arr.FirstIndex,
			LastIndex = stl.Arr.LastIndex,
			NextIndex = stl.Arr.NextIndex,
			PrevIndex = stl.Arr.PrevIndex,
		} :: any
	)
	const ShowKept = T.New<<{ read Show: (any) -> string }>>("ShowKept")
	T.Impl(ShowKept, stl.Arr.Token, {
		Show = function(_: any): string
			return "kept"
		end,
	})
	local registered = 0
	for _ = 1, 50 do
		const tok = T.NewToken("Temp")
		T.Impl(stl.List, tok, arrListCore)
		registered += 1
	end
	fullGc("collect")
	fullGc("collect")
	local remaining = 0
	for _ in stl.List.impls do
		remaining += 1
	end
	assert(
		remaining == before + 1,
		if remaining > before + 1
			then `버린 사용자 토큰이 남음: List 구현 {remaining}개(기준 {before} + 쥔 것 1)`
			else `쥔 등록까지 사라짐: List 구현 {remaining}개(기준 {before} + 쥔 것 1)`
	)
	const kept = stl.List.impls[keptToken] :: any
	assert(kept ~= nil and kept.Get == stl.Arr.Get, "쥔 토큰의 인라인 구현은 남음")
	const shown = T.ImplOf(ShowKept, stl.Arr.Of(1))
	assert(shown ~= nil and shown.Show(stl.Arr.Of(1)) == "kept", "내장 토큰에 붙인 인라인 구현은 남음")
	-- 토큰이 아닌 것(얼지 않은 테이블)으로 Impl 하면 사용자 줄 에러
	assert(not pcall(function()
		stl.Trait.Impl(stl.List, {} :: any, stl.Arr)
	end), "토큰이 아닌 것으로 Impl")
end
print("PASS")

print(
	"=== 7. 계약 보강 — 원소 타입 ≠ 위치 타입, Keys/Values 내용, 담아 둔 SetCore (M0 리뷰) ==="
)
do
	-- ListCore 의 반환 타입(I? 대 E?)은 원소와 위치가 둘 다 number 면 우연히 맞아떨어집니다
	const s = stl.Arr.Of("x", "y", "z")
	const pos: number? = stl.List.IndexOf(s, "y")
	assert(pos == 2, "문자열 배열의 IndexOf")
	const ops: ListCore<stl.Arr<string>, string, number> = stl.Arr
	assert(ops.Get(s, 3) == "z" and ops.FirstIndex(s) == 1 and ops.NextIndex(s, 1) == 2, "문자열 배열의 ListCore")

	-- Keys/Values 는 개수가 아니라 **내용**을 봅니다(키와 값을 바꿔 돌려줘도 통과했음)
	const m = stl.FlatMap.FromRecords({ { key = "b", value = 20 }, { key = "a", value = 10 } }, Common.compareString)
	type T = stl.FlatMap<string, number>
	const keys = stl.Map.Keys(m)
	const values = stl.Map.Values(m)
	assert(table.concat(keys, ",") == "a,b", "Map.Keys 내용")
	assert(values[1] == 10 and values[2] == 20, "Map.Values 내용")

	-- ⭐ 사용자 컨테이너가 맵 트레이트에 들어오기(2026-10-06): 자기 타입 토큰을 만들고
	-- `Trait.Impl` 한 줄. 타입에는 토큰과 트레이트 마커(타입에만 있는 필드)를 적고, 값은
	-- 생성 함수에서 캐스트로 만듭니다(마커는 런타임에 없음).
	-- 2026-10-12: 계약이 여섯으로(`Has`·`Remove`·`Iter` 추가). `Keys`/`Values` 는 `Iter` 로 돕니다 —
	-- 넣은 순서를 지키는 연결 목록 맵으로, 순회자가 **함수 하나**(상태를 클로저에)인 모양을 봅니다.
	type MyMap = {
		read __type: stl.TraitToken<string>,
		read __mapKey: string,
		read __mapValue: number,
		read __mapMut: (string, number) -> (string, number),
		keys: { string },
		values: { number },
	}
	const MyMapType = stl.Trait.NewToken("MyMap")
	const function find(m: MyMap, k: string): number?
		return table.find(m.keys, k)
	end
	const myOps: MapCore<MyMap, string, number> = {
		Get = function(m: MyMap, k: string): number?
			const at = find(m, k)
			return if at then m.values[at] else nil
		end,
		Set = function(m: MyMap, k: string, v: number)
			const at = find(m, k)
			if at then
				m.values[at] = v
			else
				table.insert(m.keys, k)
				table.insert(m.values, v)
			end
		end,
		Has = function(m: MyMap, k: string): boolean
			return find(m, k) ~= nil
		end,
		Remove = function(m: MyMap, k: string): number?
			const at = find(m, k)
			if at == nil then
				return nil
			end
			table.remove(m.keys, at)
			return table.remove(m.values, at)
		end,
		Iter = function(m: MyMap)
			local at = 0
			return function(): (string, number)
				at += 1
				return m.keys[at], m.values[at]
			end
		end,
	}
	stl.Trait.Impl(stl.Map, MyMapType, myOps)
	const mine: MyMap = { __type = MyMapType, keys = {}, values = {} } :: any
	myOps.Set(mine, "x", 1)
	myOps.Set(mine, "y", 2)
	myOps.Set(mine, "w", 3)
	const myKeys = stl.Map.Keys(mine)
	const myValues = stl.Map.Values(mine)
	assert(table.concat(myKeys, ",") == "x,y,w", "Keys(사용자 맵) 은 순회 순서")
	-- ⭐ Records 는 계약이 아니라 알고리즘(2026-10-13 — `Iter` 위에 한 번만 구현). 사용자 맵은 다섯
	-- 함수만으로 레코드 목록을 얻습니다.
	const myRecords = stl.Map.Records(mine)
	assert(#myRecords == 3, `Records(사용자 맵): {#myRecords}`)
	assert(myRecords[1].key == "x" and myRecords[1].value == 1 and myRecords[3].key == "w", "Records 는 순회 순서")
	myRecords[1].value = 99 -- 받은 레코드를 고쳐도 맵은 그대로(새로 만든 레코드)
	assert(myOps.Get(mine, "x") == 1, "Records 의 레코드는 사본")
	assert(table.concat(myValues, ",") == "1,2,3", "Values(사용자 맵) — Keys 와 같은 순서")
	-- 결과는 메타 키 없는 새 평범한 배열 — 구현의 내부 목록이 아님
	assert((myKeys :: any) ~= mine.keys and (myValues :: any) ~= mine.values, "새 테이블")
	for key in myKeys :: { [any]: any } do
		assert(type(key) == "number", "Keys 결과에 숫자 아닌 키")
	end
	for key in myValues :: { [any]: any } do
		assert(type(key) == "number", "Values 결과에 숫자 아닌 키")
	end
	assert(#myKeys == 3 and #myValues == 3 and (myValues :: any).n == nil, "개수")
	-- 이 맵은 `stl.Collection` 을 구현하지 않음 — 크기를 몰라도 됨(미리 잡지 못할 뿐)
	assert(stl.Trait.ImplOf(stl.Collection, mine) == nil, "MyMap 은 Collection 아님")
	myOps.Remove(mine, "y")
	assert(table.concat(stl.Map.Keys(mine), ",") == "x,w", "지운 뒤 Keys")
	const emptyMine: MyMap = { __type = MyMapType, keys = {}, values = {} } :: any
	assert(#stl.Map.Keys(emptyMine) == 0 and #stl.Map.Values(emptyMine) == 0, "빈 사용자 맵")
	const emptyHash = stl.HashMap.New<<string, number>>()
	assert(#stl.Map.Keys(emptyHash) == 0 and #stl.Map.Values(emptyHash) == 0, "빈 맵")
	-- 내장 두 맵: Keys 와 Values 가 같은 순서로 짝이 맞고, 자기 모듈의 Keys/Values 와 같은 내용
	const big = stl.HashMap.New<<string, number>>()
	const bigTree = stl.FlatMap.New<<string, number>>(Common.compareString)
	for i = 1, 40 do
		stl.HashMap.Set(big, `k{i * 7}`, i * 100)
		stl.FlatMap.Set(bigTree, `k{i * 7}`, i * 100)
	end
	const bigKeys, bigValues = stl.Map.Keys(big), stl.Map.Values(big)
	assert(#bigKeys == 40 and #bigValues == 40, "HashMap 40개")
	for at, key in bigKeys do
		assert(stl.HashMap.Get(big, key) == bigValues[at], `Keys[{at}] 와 Values[{at}] 가 짝`)
	end
	-- 내장 두 맵의 stl.Map.Records: 자기 모듈의 Records 와 같은 내용, 받은 것을 고쳐도 맵은 그대로
	const hashRecords = stl.Map.Records(big)
	assert(#hashRecords == 40, "Map.Records(HashMap) 개수")
	for _, rec in hashRecords do
		assert(stl.HashMap.Get(big, rec.key) == rec.value, "Map.Records(HashMap) 의 키-값")
	end
	const treeRecords = stl.Map.Records(bigTree)
	const ownRecords = stl.FlatMap.Records(bigTree)
	assert(#treeRecords == #ownRecords and #treeRecords == 40, "Map.Records(FlatMap) 개수")
	for at, rec in treeRecords do
		assert(
			rec.key == ownRecords[at].key and rec.value == ownRecords[at].value,
			`FlatMap 레코드 {at} 은 정렬 순서`
		)
	end
	treeRecords[1].key = "zzz"
	treeRecords[1].value = -1
	assert(
		stl.FlatMap.Records(bigTree)[1].key == ownRecords[1].key,
		"받은 레코드를 고쳐도 FlatMap 은 그대로"
	)
	assert(#stl.Map.Records(emptyHash) == 0, "빈 맵의 Records")
	assert(not pcall(function()
		stl.Map.Records(stl.Arr.Of(1) :: any)
	end), "맵이 아닌 것의 Records 는 에러")
	const treeKeys, treeValues = stl.Map.Keys(bigTree), stl.Map.Values(bigTree)
	assert(
		table.concat(treeKeys, ",") == table.concat(stl.FlatMap.Keys(bigTree), ","),
		"FlatMap Keys 는 정렬 순서"
	)
	assert(table.concat(treeValues, ",") == table.concat(stl.FlatMap.Values(bigTree), ","), "FlatMap Values")

	-- 함수를 빠뜨린 구현은 **등록할 때** 사용자 줄 에러(2026-10-12 — 예전엔 알고리즘 안에서
	-- `attempt to call a nil value`: 타입을 안 쓰는 코드, 그리고 계약이 넓어지기 전의 구현)
	const partial = {
		Get = myOps.Get,
		Set = myOps.Set,
		Iter = myOps.Iter,
	}
	const PartialType = stl.Trait.NewToken("PartialMap")
	local partialLine = 0
	const okPartial, errPartial = pcall(function()
		partialLine = debug.info(1, "l") + 1
		stl.Trait.Impl(stl.Map, PartialType, partial :: any)
	end)
	assert(
		not okPartial
			and string.find(tostring(errPartial), "PartialMap is missing Has for Map", 1, true)
			and string.find(tostring(errPartial), `spec.contracts.luau:{partialLine}:`, 1, true),
		`빠진 함수: {errPartial}`
	)
	assert(stl.Map.impls[PartialType] == nil, "거절된 등록은 남지 않음")
	-- 함수가 아닌 값·테이블이 아닌 구현도
	local badLine = 0
	for _, bad in
		{
			{ impl = { Len = 1, Clear = function() end }, needle = "BadCollection is missing Len for Collection" },
			{ impl = { Len = function() end }, needle = "BadCollection is missing Clear for Collection" },
			{ impl = 5, needle = "needs a table of functions for Collection, got number" },
			{ impl = "impl", needle = "needs a table of functions for Collection, got string" },
		} :: { { impl: any, needle: string } }
	do
		const BadType = stl.Trait.NewToken("BadCollection")
		const okBad, errBad = pcall(function()
			badLine = debug.info(1, "l") + 1
			stl.Trait.Impl(stl.Collection, BadType, bad.impl)
		end)
		assert(not okBad and string.find(tostring(errBad), bad.needle, 1, true), `잘못된 구현: {errBad}`)
		assert(string.find(tostring(errBad), `spec.contracts.luau:{badLine}:`, 1, true), `사용자 줄: {errBad}`)
		assert(stl.Collection.impls[BadType] == nil, "거절된 등록은 남지 않음")
	end
	-- 필수 목록이 없는 사용자 트레이트는 예전처럼 아무 구현이나 받고, 목록의 모양은 `New` 가 봄
	const Loose = stl.Trait.New<<{ read Show: (any) -> string }>>("Loose")
	stl.Trait.Impl(Loose, stl.Trait.NewToken("LooseKind"), {} :: any)
	const names = { "Show" }
	const Strict = stl.Trait.New<<{ read Show: (any) -> string }>>("Strict", { required = names })
	names[1] = "Other" -- 넘긴 목록을 나중에 바꿔도 트레이트는 그대로(사본)
	const StrictKind = stl.Trait.NewToken("StrictKind")
	assert(not pcall(function()
		stl.Trait.Impl(Strict, StrictKind, { Other = function() end } :: any)
	end), "필수 목록은 넘긴 때의 것")
	stl.Trait.Impl(Strict, StrictKind, {
		Show = function(_: any): string
			return "s"
		end,
	})
	local newLine = 0
	for _, badRequired in
		{
			{ list = 5, needle = "required function names, got number" },
			{ list = { 1, 2 }, needle = "required function names, got a number in it" },
			{ list = { "ok", false }, needle = "required function names, got a boolean in it" },
		} :: { { list: any, needle: string } }
	do
		const okNew, errNew = pcall(function()
			newLine = debug.info(1, "l") + 1
			stl.Trait.New("BadRequired", { required = badRequired.list } :: any)
		end)
		assert(not okNew and string.find(tostring(errNew), badRequired.needle, 1, true), `New 의 목록: {errNew}`)
		assert(string.find(tostring(errNew), `spec.contracts.luau:{newLine}:`, 1, true), `사용자 줄: {errNew}`)
	end

	-- SetCore 자리에 모듈을 담아 두고 쓰기
	const hs = stl.HashSet.Of(1, 2)
	const setOps: SetCore<stl.HashSet<number>, number> = stl.HashSet
	assert(setOps.Has(hs, 2) and not setOps.Has(hs, 3), "담아 둔 SetCore")
end
print("PASS")

print("=== 8. ⭐ 리스트를 받는 진입점이 Arr·table.pack 결과를 받을 때 (M0 3라운드) ===")
do
	-- `{ T }` 를 받는 생성자들이 `#`/`pairs` 로 읽어 `Arr` 의 `n` 과 태그 키까지
	-- 원소로 담거나(HashSet 크기 4), 구멍 뒤를 잃었습니다(FromTable). 규약:
	-- **`n` 이 숫자로 있으면 그 길이로 숫자 루프**(구멍은 건너뜀), 없으면 `#`.
	const Arr, HashMap, HashSet, FlatMap, FlatSet, Heap =
		stl.Arr, stl.HashMap, stl.HashSet, stl.FlatMap, stl.FlatSet, stl.Heap
	local function lt(a: number, b: number): boolean
		return a < b
	end
	const nums = Arr.Of(30, 10)
	const set = HashSet.FromList(nums)
	assert(
		HashSet.Len(set) == 2 and HashSet.Has(set, 30) and not HashSet.Has(set, true :: any),
		"HashSet.FromList(Arr)"
	)
	const holed = HashSet.FromList(Arr.Of<<number?>>(10, nil, 30) :: any)
	assert(HashSet.Len(holed) == 2, "HashSet.FromList 는 구멍을 건너뜀")
	assert(HashSet.Len(HashSet.FromList(table.pack(1, nil, 3) :: any)) == 2, "table.pack 결과도 n 을 따름")
	assert(
		table.concat(FlatSet.Items(FlatSet.FromList(nums, Common.compareNumber)), ",") == "10,30",
		"FlatSet.FromList(Arr)"
	)
	const heap = Heap.FromList(nums, lt)
	assert(Heap.Len(heap) == 2 and Heap.Peek(heap) == 10, "Heap.FromList(Arr)")

	type Rec = stl.Record<string, number>
	const records = Arr.Map(Arr.Of("a", "b"), function(s: string, i: number): Rec
		return { key = s, value = i * 10 }
	end)
	const hm = HashMap.FromRecords(records)
	assert(HashMap.Len(hm) == 2 and HashMap.Get(hm, "b") == 20, "HashMap.FromRecords(Arr)")
	const tm = FlatMap.FromRecords(records, Common.compareString)
	assert(FlatMap.Len(tm) == 2 and table.concat(FlatMap.Keys(tm), ",") == "a,b", "FlatMap.FromRecords(Arr)")
	-- 사전을 받는 FromTable 은 Arr 를 "위치 → 값" 으로 읽습니다(n·태그 키는 원소가 아님)
	const byIndex = HashMap.FromTable(nums :: any)
	assert(HashMap.Len(byIndex) == 2 and HashMap.Get(byIndex, 1) == 30, "HashMap.FromTable(Arr) 는 위치 → 값")
	assert(
		HashMap.Get(byIndex, "n" :: any) == nil and HashMap.Get(byIndex, "__type" :: any) == nil,
		"n·태그는 키가 아님"
	)
	-- 복사 판은 구멍까지 그대로(n 을 따름)
	const cloned = Arr.FromTable(Arr.Of<<number?>>(1, nil, 3) :: any)
	assert(cloned.n == 3 and cloned[3] == 3 and cloned[2] == nil, "FromTable 은 n 을 따름")

	-- (M0 4라운드) 구멍 든 입력·table.pack 을 **모든 진입점에** — 구멍 없는 입력만
	-- 넣으면 `#` 와 `n` 이 같아 진입점을 `#` 로 되돌린 돌연변이가 살아남았음.
	const packed = table.pack(30, nil, 10) :: any
	assert(HashSet.Len(HashSet.FromList(packed)) == 2, "HashSet.FromList(pack)")
	assert(
		table.concat(FlatSet.Items(FlatSet.FromList(packed, Common.compareNumber)), ",") == "10,30",
		"FlatSet.FromList(pack)"
	)
	const packedHeap = Heap.FromList(packed, lt)
	assert(Heap.Len(packedHeap) == 2 and Heap.Peek(packedHeap) == 10, "Heap.FromList(pack)")
	const packedRecords = table.pack({ key = "a", value = 1 }, nil, { key = "c", value = 3 }) :: any
	assert(HashMap.Len(HashMap.FromRecords(packedRecords)) == 2, "HashMap.FromRecords(pack)")
	assert(FlatMap.Len(FlatMap.FromRecords(packedRecords, Common.compareString)) == 2, "FlatMap.FromRecords(pack)")
	const holedArr = Arr.Of<<number?>>(10, nil, 30)
	const byIndexHoled = HashMap.FromTable(holedArr :: any)
	assert(HashMap.Len(byIndexHoled) == 2 and HashMap.Get(byIndexHoled, 3) == 30, "HashMap.FromTable(구멍 Arr)")
	-- Arr.Adopt 은 pack 이 준 n 을 그대로(꼬리 구멍 포함)
	assert(Arr.Adopt(table.pack(1, nil, 3, nil, nil) :: any).n == 5, "Arr.Adopt(pack) 은 n 을 따름")
	-- FromTable 은 메타테이블이 있으면 원소 단위로 읽습니다(길이는 __len, 원소는 __index)
	const proxy = setmetatable({}, {
		__index = { 10, 20, 30 },
		__len = function()
			return 3
		end,
	}) :: any
	const fromProxy = Arr.FromTable(proxy)
	assert(
		fromProxy.n == 3 and fromProxy[1] == 10 and fromProxy[3] == 30,
		"FromTable 은 메타테이블 원소를 읽음"
	)

	-- listLength 단위: n 이 0 이상의 유한 정수일 때만 n, 아니면 #
	assert(Common.listLength({ 1, 2, n = 5 }) == 5, "listLength n")
	assert(Common.listLength({ 1, 2, n = -1 }) == 2, "listLength n 음수 → #")
	assert(Common.listLength({ 1, 2, n = 1.5 }) == 2, "listLength n 소수 → #")
	assert(Common.listLength({ 1, 2, n = math.huge }) == 2, "listLength n 무한 → #")
	assert(Common.listLength({ 1, 2, n = 0 / 0 }) == 2, "listLength n NaN → #")
	assert(Common.listLength({ 1, 2, n = "3" }) == 2, "listLength n 문자열 → #")

	-- Fut.All 도 같은 규약 — 소수 n 이면 영원히 Pending 이었고, 음수·NaN 이면 던졌음
	const one = stl.Fut.Resolved(1)
	for _, weird in { 2.5, -1, 0 / 0 } do
		const okAll, allFut = pcall(stl.Fut.All, { one, one, n = weird } :: any)
		assert(okAll and stl.Fut.Status(allFut) == "Resolved", `Fut.All n={weird}`)
	end
	-- 구멍 든 Arr·pack 은 n 까지 봐서 구멍을 "Fut 이 아님" 으로 실패시킵니다 — 리터럴
	-- `{ f, nil, f }` 만 쓰면 `#` 가 3 이라 `#` 로 되돌린 돌연변이가 살아남았음(M0 5라운드).
	assert(stl.Fut.Status(stl.Fut.All(Arr.Of<<any>>(one, nil, one))) == "Rejected", "Fut.All(구멍 Arr)")
	assert(stl.Fut.Status(stl.Fut.All(table.pack(one, nil) :: any)) == "Rejected", "Fut.All(pack 꼬리 구멍)")
	-- Adopt 는 n 뒤의 raw 칸을 비웁니다 — 남으면 정렬·삽입 뒤 그 값이 배열 안으로
	-- 다시 들어왔습니다(M0 5라운드, listLength 로 바꾸며 생긴 상태)
	const shortened = table.pack(50, 40, 30, 20, 10) :: any
	shortened.n = 2
	const adopted = Arr.Adopt(shortened)
	assert(adopted.n == 2 and adopted[3] == nil and adopted[5] == nil, "Adopt 는 n 뒤를 비움")
	Arr.SortInplaceUnchecked(adopted)
	assert(adopted[1] == 40 and adopted[2] == 50, "n 뒤 값이 정렬에 섞이지 않음")
	-- n = -0 은 +0 으로(Sized 와 같은 정규화)
	assert(tostring(Arr.Adopt({ n = -0 } :: any).n) == "0", "Adopt n = -0 → 0")
end
print("PASS")

print("=== 9. 쓰는 제네릭은 불변 마커로 — 맵·셋 종류와 무관하게 (2026-10-12, 질문 AM) ===")
do
	-- 타입 쪽(값 타입이 넓어지지 않음)은 spikes/61 이 지킵니다. 여기는 불변 마커를 받는 제네릭이
	-- 런타임에 HashMap·FlatMap, HashSet·FlatSet 양쪽에서 같은 답을 내는지.
	local function put<K, V>(m: stl.MapMarkerMut<K, V>, k: K, v: V)
		const ops = stl.Trait.ImplOf(stl.Map, m)
		assert(ops ~= nil, "Map 구현")
		ops.Set(m, k, v)
	end
	local function add<T>(s: stl.SetMarkerMut<T>, item: T): boolean
		const ops = stl.Trait.ImplOf(stl.Set, s)
		assert(ops ~= nil, "Set 구현")
		return ops.Add(s, item)
	end
	const hm = stl.HashMap.New<<string, number>>()
	const tm = stl.FlatMap.New<<string, number>>(Common.compareString)
	for _, key in { "b", "a", "b" } do
		put(hm, key, #key * 10)
		put(tm, key, #key * 10)
	end
	assert(stl.HashMap.Len(hm) == 2 and stl.FlatMap.Len(tm) == 2, "두 맵 모두 키 둘")
	assert(stl.HashMap.Get(hm, "a") == 10 and stl.FlatMap.Get(tm, "a") == 10, "같은 값")
	-- 불변 마커로 받은 값은 읽는 알고리즘에도 그대로 들어감
	local function keysOf<K, V>(m: stl.MapMarkerMut<K, V>): { K }
		return stl.Map.Keys(m)
	end
	assert(table.concat(keysOf(tm), ",") == "a,b" and #keysOf(hm) == 2, "Mut 마커 → Keys")
	const hs = stl.HashSet.New<<number>>()
	const ts = stl.FlatSet.New<<number>>(Common.compareNumber)
	assert(add(hs, 10) and add(ts, 10) and not add(hs, 10) and not add(ts, 10), "두 셋 모두 Add")
	-- 팬텀은 타입에만 — 런타임 필드는 없음
	for _, value in { hm, tm, hs, ts, stl.Arr.Of(1), stl.CircularDeque.Of(1) } :: { any } do
		for _, phantom in { "__mapMut", "__setMut", "__listMut", "__mapKey", "__setItem", "__list" } do
			assert(rawget(value, phantom) == nil, `팬텀 {phantom} 이 런타임에 있음`)
		end
	end
end
print("PASS")

print(
	"=== 10. 컬렉션 트레이트 — 종류를 모르고 크기·비우기, 넓힌 MapCore (2026-10-12, 질문 AO) ==="
)
do
	-- 일곱 컨테이너 전부: Len 은 자기 모듈의 Len 과 같고, Clear 는 **같은 객체**를 비워 돌려줌
	const cases: { { name: string, make: () -> any, len: (any) -> number } } = {
		{
			name = "Arr",
			make = function()
				return stl.Arr.Of(10, 20, 30)
			end,
			len = stl.Arr.Len,
		},
		{
			name = "CircularDeque",
			make = function()
				return stl.CircularDeque.PushFront(stl.CircularDeque.Of(10, 20), 5)
			end,
			len = stl.CircularDeque.Len,
		},
		{
			name = "LinkedDeque",
			make = function()
				return stl.LinkedDeque.PushFront(stl.LinkedDeque.Of(10, 20), 5)
			end,
			len = stl.LinkedDeque.Len,
		},
		{
			name = "HashMap",
			make = function()
				return stl.HashMap.FromTable({ a = 10, b = 20, c = 30 })
			end,
			len = stl.HashMap.Len,
		},
		{
			name = "FlatMap",
			make = function()
				return stl.FlatMap.FromRecords(
					{ { key = "a", value = 10 }, { key = "b", value = 20 }, { key = "c", value = 30 } },
					Common.compareString
				)
			end,
			len = stl.FlatMap.Len,
		},
		{
			name = "HashSet",
			make = function()
				return stl.HashSet.Of(10, 20, 30)
			end,
			len = stl.HashSet.Len,
		},
		{
			name = "FlatSet",
			make = function()
				return stl.FlatSet.FromList({ 30, 10, 20 }, Common.compareNumber)
			end,
			len = stl.FlatSet.Len,
		},
		{
			name = "TreeMap",
			make = function()
				return stl.TreeMap.FromRecords(
					{ { key = "a", value = 10 }, { key = "b", value = 20 }, { key = "c", value = 30 } },
					Common.compareString
				)
			end,
			len = stl.TreeMap.Len,
		},
		{
			name = "TreeSet",
			make = function()
				return stl.TreeSet.FromList({ 30, 10, 20 }, Common.compareNumber)
			end,
			len = stl.TreeSet.Len,
		},
		{
			name = "Heap",
			make = function()
				return stl.Heap.FromList({ 30, 10, 20 }, function(a: number, b: number): boolean
					return a < b
				end)
			end,
			len = stl.Heap.Len,
		},
	}
	for _, case in cases do
		const value = case.make()
		assert(stl.Trait.Implements(stl.Collection, value), `{case.name} 은 Collection`)
		assert(stl.Collection.Len(value) == 3 and case.len(value) == 3, `{case.name} Len: {stl.Collection.Len(value)}`)
		const cleared = stl.Collection.Clear(value)
		assert(rawequal(cleared, value), `{case.name} Clear 는 같은 객체`)
		assert(stl.Collection.Len(value) == 0 and case.len(value) == 0, `{case.name} Clear 뒤 Len`)
		assert(
			stl.Collection.Clear(value) == value and stl.Collection.Len(value) == 0,
			`{case.name} 빈 것을 또 Clear`
		)
	end
	-- Clear 뒤에도 쓸 수 있음(비우고 다시 채우기) — 맵 종류를 모르는 제네릭으로
	local function refill<K, V>(m: stl.MapMarkerMut<K, V> & stl.CollectionMarkerMut, records: { stl.Record<K, V> })
		const ops = stl.Trait.ImplOf(stl.Map, m)
		assert(ops ~= nil, "Map 구현")
		stl.Collection.Clear(m)
		for _, rec in records do
			ops.Set(m, rec.key, rec.value)
		end
	end
	const hm = stl.HashMap.FromTable<<string, number>>({ old = 1 })
	const tm = stl.FlatMap.FromRecords({ { key = "old", value = 1 } }, Common.compareString)
	const fresh = { { key = "q", value = 70 }, { key = "p", value = 80 } }
	refill(hm, fresh)
	refill(tm, fresh)
	assert(stl.Collection.Len(hm) == 2 and stl.Collection.Len(tm) == 2, "다시 채운 크기")
	assert(stl.HashMap.Get(hm, "old") == nil and stl.FlatMap.Get(tm, "old") == nil, "옛 키는 없음")
	assert(table.concat(stl.Map.Keys(tm), ",") == "p,q" and stl.HashMap.Get(hm, "q") == 70, "다시 채운 내용")

	-- 읽기 전용으로 빌린 참조도 Len 은 됨(타입 쪽 — Clear 는 못 함 — 은 spikes/63)
	local function lenOfBorrowed(list: stl.ArrRead<number>, dq: stl.CircularDequeRead<number>): number
		return stl.Collection.Len(list) + stl.Collection.Len(dq)
	end
	assert(lenOfBorrowed(stl.Arr.Of(1, 2), stl.CircularDeque.Of(1, 2, 3)) == 5, "빌린 참조의 Len")

	-- 컬렉션이 아닌 것: 사용자 줄 에러(토큰은 있지만 구현 없음 / 토큰 없음 / 테이블 아님)
	local where = 0
	for _, bad in
		{
			{ value = stl.Fut.Resolved(1), needle = "Fut does not implement Collection" },
			{ value = {}, needle = "needs a Collection" },
			{ value = 5, needle = "needs a Collection" },
		} :: { { value: any, needle: string } }
	do
		for _, call in { stl.Collection.Len, stl.Collection.Clear } :: { (any) -> any } do
			const ok, err = pcall(function()
				where = debug.info(1, "l") + 1
				call(bad.value)
			end)
			assert(not ok and string.find(tostring(err), bad.needle, 1, true), `컬렉션 아님: {err}`)
			assert(string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {err}`)
		end
	end

	-- ⭐ 넓힌 MapCore — 종류를 모르는 코드가 Has·Remove·Iter 까지. 두 맵이 같은 답
	local function exercise<K, V>(m: stl.MapMarkerMut<K, V>, present: K, absent: K): (boolean, boolean, V?, V?, number)
		const ops = stl.Trait.ImplOf(stl.Map, m)
		assert(ops ~= nil, "Map 구현")
		const hadPresent, hadAbsent = ops.Has(m, present), ops.Has(m, absent)
		local seen = 0
		for key, value in ops.Iter(m) do
			assert(ops.Get(m, key) == value, "Iter 의 값은 Get 과 같음")
			seen += 1
		end
		const removed = ops.Remove(m, present)
		const removedAgain = ops.Remove(m, present)
		assert(not ops.Has(m, present), "지운 뒤 Has")
		return hadPresent, hadAbsent, removed, removedAgain, seen
	end
	const hm2 = stl.HashMap.FromTable<<string, number>>({ a = 10, b = 20, c = 30 })
	const tm2 = stl.FlatMap.FromRecords(
		{ { key = "a", value = 10 }, { key = "b", value = 20 }, { key = "c", value = 30 } },
		Common.compareString
	)
	for name, m in { HashMap = hm2, FlatMap = tm2 } :: { [string]: any } do
		const hadPresent, hadAbsent, removed, removedAgain, seen = exercise(m, "b", "zz")
		assert(hadPresent and not hadAbsent, `{name} Has`)
		assert(removed == 20 and removedAgain == nil, `{name} Remove 는 지운 값: {removed}`)
		assert(
			seen == 3 and stl.Collection.Len(m) == 2,
			`{name} Iter 개수 {seen}, 지운 뒤 크기 {stl.Collection.Len(m)}`
		)
	end
	-- 모듈 테이블이 넓힌 계약과 컬렉션 계약을 정적으로 만족
	const _hmOps: MapCore<stl.HashMap<string, number>, string, number> = stl.HashMap
	const _tmOps: MapCore<stl.FlatMap<string, number>, string, number> = stl.FlatMap
	const _c1: stl.CollectionCore<stl.Arr<number>> = stl.Arr
	const _c2: stl.CollectionCore<stl.CircularDeque<number>> = stl.CircularDeque
	const _c3: stl.CollectionCore<stl.HashMap<string, number>> = stl.HashMap
	const _c4: stl.CollectionCore<stl.FlatMap<string, number>> = stl.FlatMap
	const _c5: stl.CollectionCore<stl.HashSet<number>> = stl.HashSet
	const _c6: stl.CollectionCore<stl.FlatSet<number>> = stl.FlatSet
	const _c7: stl.CollectionCore<stl.Heap<number>> = stl.Heap
end
print("PASS")

print(
	"=== 11. 트레이트 넓히기 리뷰 1라운드 — 필수 함수 목록 전수, 사용자 컬렉션 (2026-10-12) ==="
)
do
	const T = stl.Trait
	-- ⭐ 내장 트레이트의 필수 목록을 **전수로**: 함수를 하나씩 뺀 구현은 등록할 때 그 이름으로 거절.
	-- (리뷰: 목록에서 항목을 빼도 대부분 통과했음 — `Iter` 를 뺀 사본에서는 `Iter` 없는 맵이 등록되고
	-- `Map.Keys` 가 라이브러리 줄에서 `attempt to call a nil value`)
	const builtins: { { trait: any, name: string, full: { [string]: any } } } = {
		{
			trait = stl.List,
			name = "List",
			full = {
				Get = stl.Arr.Get,
				FirstIndex = stl.Arr.FirstIndex,
				LastIndex = stl.Arr.LastIndex,
				NextIndex = stl.Arr.NextIndex,
				PrevIndex = stl.Arr.PrevIndex,
			},
		},
		{
			trait = stl.Map,
			name = "Map",
			full = {
				Get = stl.HashMap.Get,
				Set = stl.HashMap.Set,
				Has = stl.HashMap.Has,
				Remove = stl.HashMap.Remove,
				Iter = stl.HashMap.Iter,
			},
		},
		{
			trait = stl.Set,
			name = "Set",
			full = {
				Add = stl.HashSet.Add,
				Has = stl.HashSet.Has,
				Remove = stl.HashSet.Remove,
				Items = stl.HashSet.Items,
			},
		},
		{ trait = stl.Collection, name = "Collection", full = { Len = stl.Arr.Len, Clear = stl.Arr.Clear } },
		{
			trait = stl.Deque,
			name = "Deque",
			full = {
				PushFront = stl.LinkedDeque.PushFront,
				PushBack = stl.LinkedDeque.PushBack,
				PopFront = stl.LinkedDeque.PopFront,
				PopBack = stl.LinkedDeque.PopBack,
				Front = stl.LinkedDeque.Front,
				Back = stl.LinkedDeque.Back,
			},
		},
	}
	local where = 0
	for _, builtin in builtins do
		local fnCount = 0
		for missing in builtin.full do
			fnCount += 1
			const partial = table.clone(builtin.full)
			partial[missing] = nil
			const Kind = T.NewToken("Partial")
			const ok, err = pcall(function()
				where = debug.info(1, "l") + 1
				T.Impl(builtin.trait, Kind, partial)
			end)
			const want = `Partial is missing {missing} for {builtin.name}`
			assert(
				not ok and string.find(tostring(err), want, 1, true),
				`{builtin.name} 에서 {missing} 누락: {err}`
			)
			assert(string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {err}`)
			assert(builtin.trait.impls[Kind] == nil, "거절된 등록은 남지 않음")
		end
		-- 목록이 계약의 함수 수와 같음(더 많이 요구하지도 않음) — 다 갖춘 구현은 등록됨
		assert(#builtin.trait.required == fnCount, `{builtin.name} 의 필수 목록 길이`)
		assert(table.isfrozen(builtin.trait.required), `{builtin.name} 의 필수 목록은 얼어 있음`)
		T.Impl(builtin.trait, T.NewToken("Full"), table.clone(builtin.full))
	end

	-- ⭐ 사용자 컬렉션(가방) — Len·Clear·(맵이면) 미리 잡기 경로를 사용자 구현으로
	type Bag = { read __type: stl.TraitToken<string>, read __collectionMut: true, items: { number } }
	const BagType = T.NewToken("Bag")
	T.Impl(
		stl.Collection,
		BagType,
		{
			Len = function(bag: Bag): number
				return #bag.items
			end,
			-- **아무것도 돌려주지 않는** Clear — `Collection.Clear` 는 그래도 넣은 것을 돌려줘야 함
			-- (리뷰: 구현의 반환을 그대로 돌려주게 바꿔도 통과했음)
			Clear = function(bag: Bag)
				table.clear(bag.items)
			end,
		} :: any
	)
	const bag: Bag = { __type = BagType, items = { 10, 20, 30 } } :: any
	assert(stl.Collection.Len(bag) == 3, "사용자 컬렉션의 Len")
	const clearedBag = stl.Collection.Clear(bag)
	assert(
		rawequal(clearedBag, bag) and stl.Collection.Len(bag) == 0,
		"구현이 안 돌려줘도 Clear 는 넣은 것을 돌려줌"
	)

	-- 맵이면서 컬렉션인 사용자 구현: `Len` 이 엉터리여도(음수·NaN·너무 큼·숫자 아님) Keys/Values 는 됨
	-- (리뷰: `table.create` 가 라이브러리 줄에서 죽었음). 실제보다 크거나 작아도 결과는 같음.
	type Sized = { read __type: stl.TraitToken<string>, read __mapKey: string, read __mapValue: number, len: any }
	const SizedType = T.NewToken("SizedMap")
	const pairsOf = { a = 10, b = 20, c = 30 }
	T.Impl(
		stl.Map,
		SizedType,
		{
			Get = function(_m: Sized, k: string): number?
				return pairsOf[k]
			end,
			Set = function() end,
			Has = function(_m: Sized, k: string): boolean
				return pairsOf[k] ~= nil
			end,
			Remove = function(): number?
				return nil
			end,
			Iter = function()
				return pairsOf
			end,
		} :: any
	)
	T.Impl(
		stl.Collection,
		SizedType,
		{
			Len = function(m: Sized): any
				return m.len
			end,
			Clear = function(m: Sized)
				return m
			end,
		} :: any
	)
	for _, len in { 3, 0, 1, 1000, -1, 0 / 0, math.huge, 2 ^ 26 + 1, 2 ^ 40, "three", false } :: { any } do
		const sized: Sized = { __type = SizedType, len = len } :: any
		const keys = stl.Map.Keys(sized)
		const values = stl.Map.Values(sized)
		table.sort(keys)
		table.sort(values)
		assert(table.concat(keys, ",") == "a,b,c", `Len 이 {tostring(len)} 일 때 Keys: {table.concat(keys, ",")}`)
		assert(table.concat(values, ",") == "10,20,30", `Len 이 {tostring(len)} 일 때 Values`)
	end
	-- 보호된 메타테이블을 단 필수 목록도 사본으로 읽음
	const guarded = setmetatable({ "Show" }, { __metatable = "locked" })
	const Guarded = T.New<<{ read Show: (any) -> string }>>("Guarded", { required = guarded :: any })
	assert(Guarded.required ~= nil and Guarded.required[1] == "Show", "보호된 목록")
end
print("PASS")

print("=== 12. ⭐ 기본 구현·의존·저절로 따라오는 구현 (2026-10-13, papers/07 1단계) ===")
do
	const T = stl.Trait
	-- 작은 계층: Counter(필수 Get·Inc) → 기본 구현 IncBy·Double / Show(필수 없음, Counter 를 요구)
	type Counter = { read __type: stl.TraitToken<string>, n: number }
	type CounterOps = {
		read Get: (c: Counter) -> number,
		read Inc: (c: Counter) -> (),
		read IncBy: (c: Counter, by: number) -> (),
		read Double: (c: Counter) -> (),
	}
	const CounterTrait = T.New<<CounterOps>>("Counter", {
		required = { "Get", "Inc" },
		defaults = function(ops: any)
			return {
				-- 필수 함수는 부를 때 `ops` 에서 꺼냄
				IncBy = function(c: Counter, by: number)
					const inc = ops.Inc
					for _ = 1, by do
						inc(c)
					end
				end,
				-- 다른 기본 구현을 부르는 기본 구현 — 재정의된 판을 써야 함
				Double = function(c: Counter)
					ops.IncBy(c, ops.Get(c))
				end,
			}
		end,
	}) :: stl.Trait<CounterOps, any>
	const Plain = T.NewToken("PlainCounter")
	const Fast = T.NewToken("FastCounter")
	local plainIncCalls = 0
	T.Impl(CounterTrait, Plain, {
		Get = function(c: Counter): number
			return c.n
		end,
		Inc = function(c: Counter)
			plainIncCalls += 1
			c.n += 1
		end,
	})
	local fastIncByCalls = 0
	T.Impl(CounterTrait, Fast, {
		Get = function(c: Counter): number
			return c.n
		end,
		Inc = function(c: Counter)
			c.n += 1
		end,
		-- 재정의: 한 번에 더함
		IncBy = function(c: Counter, by: number)
			fastIncByCalls += 1
			c.n += by
		end,
	})
	const plain: Counter = { __type = Plain, n = 3 } :: any
	const fast: Counter = { __type = Fast, n = 3 } :: any
	const plainOps = T.ImplOf(CounterTrait, plain)
	const fastOps = T.ImplOf(CounterTrait, fast)
	assert(plainOps ~= nil and fastOps ~= nil, "둘 다 구현")
	-- 기본 구현이 채워짐
	plainOps.IncBy(plain, 4)
	assert(plain.n == 7 and plainIncCalls == 4, `기본 IncBy 는 Inc 를 네 번: {plain.n}, {plainIncCalls}`)
	plainOps.Double(plain)
	assert(plain.n == 14, `기본 Double: {plain.n}`)
	-- 재정의가 이기고, **기본 구현이 부르는 다른 기본 구현도 재정의된 판**
	fastOps.IncBy(fast, 4)
	assert(fast.n == 7 and fastIncByCalls == 1, "재정의된 IncBy")
	fastOps.Double(fast)
	assert(fast.n == 14 and fastIncByCalls == 2, `Double 이 재정의된 IncBy 를 부름: {fastIncByCalls}`)
	-- 완성 표는 넘긴 표와 다른 표(합친 것)이고 넘긴 함수는 그대로 들어 있음
	assert(type(plainOps.IncBy) == "function" and plainOps ~= (fastOps :: any), "종류마다 자기 완성 표")
	-- 필수 함수가 빠지면 등록이 거절됨(기본 구현이 있어도)
	local where = 0
	const okMissing, errMissing = pcall(function()
		where = debug.info(1, "l") + 1
		T.Impl(CounterTrait, T.NewToken("NoInc"), {
			Get = function(c: Counter): number
				return c.n
			end,
		})
	end)
	assert(
		not okMissing and string.find(tostring(errMissing), "NoInc is missing Inc for Counter", 1, true),
		`{errMissing}`
	)
	assert(string.find(tostring(errMissing), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {errMissing}`)

	-- ⭐ 저절로 따라오는 구현: Show 는 필수 함수가 없고 Counter 를 요구 — **아무도 등록하지 않음**
	type ShowOps = { read Show: (c: Counter) -> string, read Shout: (c: Counter) -> string }
	const ShowTrait = T.New<<ShowOps>>("ShowCounter", {
		dependencies = { CounterTrait },
		defaults = function(ops: any, deps: { [any]: any })
			const counter = deps[CounterTrait]
			return {
				Show = function(c: Counter): string
					return `<{counter.Get(c)}>`
				end,
				Shout = function(c: Counter): string
					return string.upper(ops.Show(c)) .. "!"
				end,
			}
		end,
	})
	assert(T.Implements(ShowTrait, plain) and T.Implements(ShowTrait, fast), "의존을 갖춘 종류는 저절로")
	const shown = T.ImplOf(ShowTrait, plain)
	assert(shown ~= nil and shown.Show(plain) == "<14>" and shown.Shout(plain) == "<14>!", "저절로 따라온 Show")
	assert(rawequal(T.ImplOf(ShowTrait, plain), shown), "만들어 둔 표를 다시 돌려줌")
	-- 의존을 안 갖춘 종류에는 안 따라옴(토큰만 있는 값, 내장 컨테이너, 테이블 아님)
	const Other = T.NewToken("Other")
	for _, value in { { __type = Other }, stl.Arr.Of(1), 5, "x", {} } :: { any } do
		assert(T.ImplOf(ShowTrait, value) == nil and not T.Implements(ShowTrait, value), "의존이 없으면 없음")
	end
	-- 의존을 **나중에** 갖추면 그때부터 따라옴(없다는 답은 붙잡아 두지 않음)
	const late: Counter = { __type = Other, n = 1 } :: any
	T.Impl(CounterTrait, Other, { Get = plainOps.Get, Inc = plainOps.Inc })
	assert(T.ImplOf(ShowTrait, late) ~= nil, "의존을 나중에 갖춤")

	-- ⭐ 저절로 따라온 것 위에 재정의를 등록(사용자 결정) — 이미 쓴 뒤여도, **같은 표가 제자리에서** 바뀜
	const before = T.ImplOf(ShowTrait, fast)
	assert(before ~= nil and before.Show(fast) == "<14>", "재정의 전")
	T.Impl(
		ShowTrait,
		Fast,
		{
			Show = function(c: Counter): string
				return `fast:{c.n}`
			end,
		} :: any
	)
	assert(rawequal(T.ImplOf(ShowTrait, fast), before), "같은 표")
	assert(before.Show(fast) == "fast:14", "들고 있던 표도 새 함수를 봄")
	assert(before.Shout(fast) == "FAST:14!", "기본 구현(Shout)도 재정의된 Show 를 부름")
	assert((T.ImplOf(ShowTrait, plain) :: any).Show(plain) == "<14>", "다른 종류는 그대로")
	-- 재정의는 한 번 — 명시적으로 등록한 것을 또 등록하면 에러(내장 구현이 조용히 바뀌지 않게)
	const okTwice, errTwice = pcall(function()
		where = debug.info(1, "l") + 1
		T.Impl(ShowTrait, Fast, {} :: any)
	end)
	assert(
		not okTwice and string.find(tostring(errTwice), "FastCounter already implements ShowCounter", 1, true),
		`{errTwice}`
	)
	assert(string.find(tostring(errTwice), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {errTwice}`)
	-- 의존을 안 갖춘 종류를 명시적으로 등록하면 사용자 줄 에러
	const Lonely = T.NewToken("Lonely")
	const okDep, errDep = pcall(function()
		where = debug.info(1, "l") + 1
		T.Impl(ShowTrait, Lonely, {} :: any)
	end)
	assert(
		not okDep and string.find(tostring(errDep), "Lonely must implement Counter to implement ShowCounter", 1, true),
		`{errDep}`
	)
	assert(string.find(tostring(errDep), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {errDep}`)
	assert(ShowTrait.impls[Lonely] == nil, "거절된 등록은 남지 않음")

	-- 의존의 의존: Loud 는 Show 를 요구하고 Show 는 Counter 를 요구 — 한 번에 풀림
	const LoudTrait = T.New<<{ read Loud: (c: Counter) -> string }>>("Loud", {
		dependencies = { ShowTrait },
		defaults = function(_ops: any, deps: { [any]: any })
			const show = deps[ShowTrait]
			return {
				Loud = function(c: Counter): string
					return show.Shout(c) .. "!!"
				end,
			}
		end,
	})
	const fresh: Counter = { __type = T.NewToken("FreshCounter"), n = 2 } :: any
	T.Impl(CounterTrait, rawget(fresh :: any, "__type"), { Get = plainOps.Get, Inc = plainOps.Inc })
	assert((T.ImplOf(LoudTrait, fresh) :: any).Loud(fresh) == "<2>!!!", "의존의 의존")
	-- Show 가 나중에 재정의되면 Loud 도 따라감(Show 의 표가 다시 지어지면 Loud 도 다시 지어짐 — 질문 AW)
	T.Impl(
		ShowTrait,
		rawget(fresh :: any, "__type"),
		{
			Shout = function(_c: Counter): string
				return "quiet"
			end,
		} :: any
	)
	assert((T.ImplOf(LoudTrait, fresh) :: any).Loud(fresh) == "quiet!!", "의존의 재정의가 위로 전해짐")

	-- 기본 구현도 의존도 없는 트레이트는 예전 그대로: 넘긴 표가 곧 구현, 저절로 따라오지 않음
	-- 내장 종류의 구현 표는 그 트레이트의 함수만 든 표(모듈 테이블이 아님 — 질문 AS)
	do
		const arrCollection: any = T.ImplOf(stl.Collection, stl.Arr.Of(1))
		local keys = 0
		for _ in arrCollection do
			keys += 1
		end
		assert(
			keys == 2 and arrCollection.Len == stl.Arr.Len and arrCollection.Clear == stl.Arr.Clear,
			"내장 Collection 은 Len·Clear 만"
		)
		const hashMap: any = T.ImplOf(stl.Map, stl.HashMap.New())
		assert(hashMap.Set == stl.HashMap.Set and hashMap.Keys == nil and hashMap ~= stl.HashMap, "내장 Map 도")
	end
	const Bare = T.New<<{ read X: () -> number }>>("Bare")
	assert(
		T.ImplOf(Bare, plain) == nil and not T.Implements(Bare, plain),
		"아무것도 없는 트레이트는 등록해야"
	)
	-- 필수 함수가 있는 트레이트는 기본 구현이 있어도 저절로 따라오지 않음
	assert(
		T.ImplOf(CounterTrait, { __type = T.NewToken("Unregistered") }) == nil,
		"필수 함수가 있으면 등록해야"
	)

	-- spec 의 모양 검사(사용자 줄)
	for _, bad in
		{
			{ spec = 5, needle = "needs a spec table" },
			{ spec = { dependencies = 5 }, needle = "list of traits in dependencies, got number" },
			{ spec = { dependencies = { {} } }, needle = "list of traits in dependencies, got a table at 1" },
			{ spec = { defaults = {} }, needle = "needs a function for defaults, got table" },
		} :: { { spec: any, needle: string } }
	do
		const okSpec, errSpec = pcall(function()
			where = debug.info(1, "l") + 1
			T.New("BadSpec", bad.spec)
		end)
		assert(not okSpec and string.find(tostring(errSpec), bad.needle, 1, true), `spec: {errSpec}`)
		assert(string.find(tostring(errSpec), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {errSpec}`)
	end
	-- 넘긴 dependencies 목록을 나중에 바꿔도 트레이트는 그대로(사본)
	const deps = { CounterTrait }
	const Snap = T.New<<{ read Id: (c: Counter) -> number }>>("Snap", {
		dependencies = deps,
		defaults = function(_ops: any, got: { [any]: any })
			return {
				Id = function(c: Counter): number
					return got[CounterTrait].Get(c)
				end,
			}
		end,
	})
	deps[1] = nil :: any
	assert((T.ImplOf(Snap, plain) :: any).Id(plain) == 14, "dependencies 는 넘긴 때의 것")
end
print("PASS")

print(
	"=== 12b. 트레이트 1단계 리뷰 1라운드 (2026-10-13) — defaults 의 반환, 물려받은 구현, spec 의 오타, 빠진 시나리오 ==="
)
do
	const T = stl.Trait
	local where = 0
	const BaseTrait = T.New<<{ read Get: (v: any) -> number }>>("ReviewBase", { required = { "Get" } })
	const Kind = T.NewToken("ReviewKind")
	T.Impl(BaseTrait, Kind, {
		Get = function(_v: any): number
			return 7
		end,
	})
	const value = { __type = Kind }

	-- (1) `return` 을 빠뜨린 defaults — 라이브러리 줄의 `attempt to iterate over a nil value` 였음.
	-- 저절로 따라오는 트레이트에서는 **표를 만드는 자리**에서 드러납니다(2026-10-14 — 조회할 때 만들지 않음):
	-- 이미 의존을 갖춘 종류가 있으면 `New` 에서, 없으면 그 의존이 갖춰지는 `Impl` 에서.
	for _, returned in { "nil", 5, "text", true } :: { any } do
		const defaults = (
			function(_ops: any, _deps: any): any
				if returned == "nil" then
					return nil
				end
				return returned
			end
		) :: any
		local Forgot: any = nil
		const okNew, errNew = pcall(function()
			where = debug.info(1, "l") + 1
			Forgot = T.New("Forgot", { dependencies = { BaseTrait }, defaults = defaults } :: any)
		end)
		assert(
			not okNew and string.find(tostring(errNew), "defaults of Forgot must return a table", 1, true),
			`New(defaults 가 {tostring(returned)}): {errNew}`
		)
		assert(string.find(tostring(errNew), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {errNew}`)
		-- 의존을 갖춘 종류가 아직 없으면 `New` 는 통과하고, 의존이 갖춰지는 등록에서
		const LateBase = T.New<<{ read Get: (v: any) -> number }>>("LateBase", { required = { "Get" } })
		Forgot = T.New("Forgot", { dependencies = { LateBase }, defaults = defaults } :: any)
		const LateKind = T.NewToken("LateKind")
		const okImpl, errImpl = pcall(function()
			where = debug.info(1, "l") + 1
			T.Impl(LateBase, LateKind, {
				Get = function(_v: any): number
					return 1
				end,
			})
		end)
		assert(
			not okImpl and string.find(tostring(errImpl), "defaults of Forgot must return a table", 1, true),
			`Impl(defaults 가 {tostring(returned)}): {errImpl}`
		)
		assert(string.find(tostring(errImpl), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {errImpl}`)
		assert(Forgot.impls[LateKind] == nil and Forgot.derived[LateKind] == nil, "실패한 표는 남지 않음")
		assert(T.ImplOf(Forgot, { __type = LateKind }) == nil, "조회는 만들지 않음")
	end
	-- 필수 함수가 있는 트레이트의 명시 등록에서도
	const ForgotReq = T.New<<{ read Get: (v: any) -> number }>>("ForgotReq", {
		required = { "Get" },
		defaults = (function() end) :: any,
	})
	const okReq, errReq = pcall(function()
		where = debug.info(1, "l") + 1
		T.Impl(ForgotReq, Kind, {
			Get = function(): number
				return 1
			end,
		})
	end)
	assert(
		not okReq and string.find(tostring(errReq), "defaults of ForgotReq must return a table", 1, true),
		`{errReq}`
	)
	assert(string.find(tostring(errReq), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {errReq}`)
	assert(ForgotReq.impls[Kind] == nil, "실패한 등록은 남지 않음")

	-- (2) 구현 표가 `__index` 로 함수를 물려받을 때 — 필수 검사는 통과했는데 완성 표에는 그 함수가 없었고,
	-- 물려받은 재정의는 조용히 기본 구현에 졌습니다. (리스트가 기본 구현을 가진 지금, 기반 구현을 물려받은
	-- 사용자 리스트가 이 길을 탑니다.)
	type Shape = { read Get: (v: any) -> string, read Extra: (v: any) -> string, read Show: (v: any) -> string }
	const Shaped = T.New<<Shape>>("Shaped", {
		required = { "Get" },
		defaults = function(ops: any)
			return {
				Extra = function(_v: any): string
					return "default-extra"
				end,
				Show = function(v: any): string
					return `<{ops.Get(v)}/{ops.Extra(v)}>`
				end,
			}
		end,
	}) :: stl.Trait<Shape, any>
	const parent = {
		Get = function(_v: any): string
			return "inherited-get"
		end,
		Extra = function(_v: any): string
			return "inherited-extra"
		end,
	}
	const child = setmetatable({}, { __index = parent })
	const InheritKind = T.NewToken("InheritKind")
	T.Impl(Shaped, InheritKind, child)
	const shaped = T.ImplOf(Shaped, { __type = InheritKind })
	assert(shaped ~= nil and shaped.Get == parent.Get, "물려받은 필수 함수가 완성 표에")
	assert(shaped.Extra == parent.Extra, "물려받은 재정의가 기본 구현을 이김")
	assert(
		shaped.Show({}) == "<inherited-get/inherited-extra>",
		`기본 구현이 그것들을 부름: {shaped.Show({})}`
	)
	-- 트레이트가 모르는 **자기 키**는 에러(2026-10-13, 질문 AS — 예전엔 "자기 키도 그대로" 완성 표에 들어갔음).
	-- 물려받은 쪽(`__index` 사슬)의 다른 이름은 보지 않습니다(아는 이름만 찾아 씀).
	do
		const strayChild = setmetatable({
			Own = function(): string
				return "own"
			end,
		}, { __index = parent })
		const okStray, errStray = pcall(function()
			T.Impl(Shaped, T.NewToken("StrayKind"), strayChild)
		end)
		assert(
			not okStray
				and string.find(
					tostring(errStray),
					"Trait: StrayKind gave Own to Shaped, which Shaped does not have",
					1,
					true
				),
			`모르는 자기 키: {errStray}`
		)
	end
	-- 저절로 만들어진 표 위에 물려받은 재정의를 얹는 것도
	type AutoOps = { read Hello: (v: any) -> string, read Twice: (v: any) -> string }
	const Auto = T.New<<AutoOps>>("AutoShape", {
		dependencies = { BaseTrait },
		defaults = function(ops: any)
			return {
				Hello = function(_v: any): string
					return "hello"
				end,
				Twice = function(v: any): string
					return ops.Hello(v) .. ops.Hello(v)
				end,
			}
		end,
	}) :: stl.Trait<AutoOps, any>
	const auto = T.ImplOf(Auto, value)
	assert(auto ~= nil and auto.Twice(value) == "hellohello", "저절로")
	const inheritedHello = {
		Hello = function(): string
			return "hi"
		end,
	}
	T.Impl(Auto, Kind, setmetatable({}, { __index = inheritedHello }))
	assert(auto.Twice(value) == "hihi", `물려받은 재정의가 제자리에 얹힘: {auto.Twice(value)}`)

	-- (3) spec 의 모르는 필드 — 옛 호출 모양(이름 목록을 그대로)과 한 글자 오타가 조용히 통과해
	-- 필수 검사·의존이 사라졌습니다(`require = { … }` 면 의존이 없는 것으로 읽혀 아무 값에나 따라옴).
	const badSpecs: { { spec: any, needle: string } } = {
		{ spec = { "Get", "Inc" }, needle = "unknown spec field 1" },
		{ spec = { require = { BaseTrait } }, needle = "unknown spec field require" },
		{ spec = { default = function() end }, needle = "unknown spec field default" },
		{ spec = { required = { "Get" }, Requires = {} }, needle = "unknown spec field Requires" },
	}
	for _, bad in badSpecs do
		const ok, err = pcall(function()
			where = debug.info(1, "l") + 1
			T.New("BadField", bad.spec)
		end)
		assert(not ok and string.find(tostring(err), bad.needle, 1, true), `spec: {err}`)
		assert(string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {err}`)
	end

	-- 의존 목록의 **빈 칸·빈 목록은 에러**(2라운드 리뷰): 오타 난 트레이트 이름은 nil 이라 빈 목록과 구별이 안 되고,
	-- 그러면 "의존 없음" 으로 읽혀 아무 종류에나 따라왔음(부를 때 라이브러리 줄에서 죽음)
	for _, bad in
		{
			{ spec = { dependencies = {} }, needle = "got an empty dependencies list" },
			{ spec = { dependencies = { (T :: any).Lisst } }, needle = "got an empty dependencies list" },
			{ spec = { dependencies = { nil, BaseTrait } :: any }, needle = "in dependencies, got a nil at 1" },
			{ spec = { dependencies = { BaseTrait, 5 } :: any }, needle = "in dependencies, got a number at 2" },
		} :: { { spec: any, needle: string } }
	do
		const ok, err = pcall(function()
			where = debug.info(1, "l") + 1
			T.New("BadDeps", bad.spec)
		end)
		assert(not ok and string.find(tostring(err), bad.needle, 1, true), `의존 목록: {err}`)
		assert(string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {err}`)
	end

	--[[ 2라운드: 물려받기는 `__index` 가 **테이블**인 사슬만 — 함수형 `__index` 는 자기 키만 봄 ]]
	const Greeter = T.New<<{ [string]: any }>>("Greeter2", {
		required = { "Name" },
		defaults = function(ops: any)
			return {
				Hello = function(v: any): string
					return `hello {ops.Name(v)}`
				end,
				Bye = function(v: any): string
					return `bye {ops.Name(v)}`
				end,
			}
		end,
	})
	const nameOf = function(_v: any): string
		return "n"
	end
	-- (a) 없는 멤버를 읽으면 에러를 내는 엄격한 모듈: 프리미티브만 구현해도 등록됨(기본 구현 이름을 묻다 죽었음)
	const StrictKind = T.NewToken("StrictGreeter")
	const strict = setmetatable({ Name = nameOf }, {
		__index = function(_self: any, key: any)
			error(`Strict has no member {tostring(key)}`, 2)
		end,
	})
	T.Impl(Greeter, StrictKind, strict :: any)
	const strictOps = T.ImplOf(Greeter, { __type = StrictKind }) :: any
	assert(
		strictOps.Name == nameOf and strictOps.Hello({ __type = StrictKind }) == "hello n",
		"엄격한 모듈도 기본 구현을 받음"
	)
	-- 필수 함수가 빠진 엄격한 모듈은 그 모듈의 에러가 아니라 트레이트의 메시지(사용자 줄)
	const okStrict, errStrict = pcall(function()
		where = debug.info(1, "l") + 1
		T.Impl(Greeter, T.NewToken("StrictEmpty"), setmetatable({}, getmetatable(strict :: any)) :: any)
	end)
	assert(
		not okStrict
			and string.find(tostring(errStrict), "StrictEmpty is missing Name for Greeter2", 1, true)
			and string.find(tostring(errStrict), `spec.contracts.luau:{where}:`, 1, true),
		`엄격한 모듈의 필수 누락: {errStrict}`
	)
	-- (b) 값을 지어내는 프록시: 기본 구현을 갈아치우지 않음
	const ProxyKind = T.NewToken("ProxyGreeter")
	const proxy = setmetatable({ Name = nameOf }, {
		__index = function(_self: any, key: any)
			return function(): string
				return `fabricated-{tostring(key)}`
			end
		end,
	})
	T.Impl(Greeter, ProxyKind, proxy :: any)
	assert(
		(T.ImplOf(Greeter, { __type = ProxyKind }) :: any).Hello({ __type = ProxyKind }) == "hello n",
		"프록시가 지어낸 값은 재정의가 아님"
	)
	-- (c) 테이블 사슬은 여러 단이어도 따라감: 필수도 재정의도
	const ChainKind = T.NewToken("ChainGreeter")
	const grand = { Name = nameOf }
	const parentOps = setmetatable({
		Bye = function(_v: any): string
			return "inherited-bye"
		end,
	}, { __index = grand })
	T.Impl(Greeter, ChainKind, setmetatable({}, { __index = parentOps }) :: any)
	const chainOps2 = T.ImplOf(Greeter, { __type = ChainKind }) :: any
	assert(
		chainOps2.Name == nameOf and chainOps2.Bye({}) == "inherited-bye" and chainOps2.Hello({}) == "hello n",
		"두 단 위에서 물려받은 필수·재정의"
	)
	-- (d) 저절로 따라온 표 위의 재정의(제자리 경로): 엄격한 모듈이어도 됨, 모르는 이름은 에러, 반쯤 적용되지 않음
	const Auto2 = T.New<<{ [string]: any }>>("Auto2", {
		defaults = function()
			return {
				Hello = function(): string
					return "auto-hello"
				end,
				Bye = function(): string
					return "auto-bye"
				end,
			}
		end,
	})
	const AutoKind = T.NewToken("AutoKind2")
	const autoValue = { __type = AutoKind }
	const before = T.ImplOf(Auto2, autoValue) :: any
	assert(before.Hello() == "auto-hello" and T.Implements(Auto2, autoValue), "저절로 따라옴")
	-- 트레이트가 모르는 이름이 섞이면 에러이고 **아무것도 적용되지 않습니다**(2026-10-13, 질문 AS — 예전엔 새 이름도
	-- 얹혔음). 아는 이름(`Hello`)까지 같이 들어 있어도 표는 그대로, 저절로 따라온 상태도 그대로.
	const okExtra, errExtra = pcall(function()
		T.Impl(
			Auto2,
			AutoKind,
			setmetatable({
				Hello = function(): string
					return "own-hello"
				end,
				Extra = function(): string
					return "own-extra"
				end,
			}, getmetatable(strict :: any)) :: any
		)
	end)
	assert(
		not okExtra
			and string.find(
				tostring(errExtra),
				"Trait: AutoKind2 gave Extra to Auto2, which Auto2 does not have",
				1,
				true
			),
		`모르는 이름: {errExtra}`
	)
	assert(
		before.Hello() == "auto-hello" and rawget(before, "Extra") == nil,
		"실패한 등록은 반쯤 적용되지 않음"
	)
	T.Impl(
		Auto2,
		AutoKind,
		setmetatable({
			Hello = function(): string
				return "own-hello"
			end,
		}, getmetatable(strict :: any)) :: any
	)
	const after = T.ImplOf(Auto2, autoValue) :: any
	assert(after == before, "같은 표를 제자리에서 고침")
	assert(after.Hello() == "own-hello" and after.Bye() == "auto-bye", "재정의한 것만 바뀜")
	const okReimpl = pcall(function()
		T.Impl(Auto2, AutoKind, { Hello = print } :: any)
	end)
	assert(not okReimpl, "제자리 재정의 뒤에는 명시 등록 — 다시 등록은 에러")
	-- 저절로 따라올 수 없는 트레이트의 빗나감은 그냥 nil(만들기 경로를 타지 않음 — perf 32절)
	assert(
		T.ImplOf(BaseTrait, { __type = T.NewToken("Stranger") }) == nil,
		"필수 함수가 있는 트레이트의 빗나감"
	)

	-- ── 타입·검증 리뷰가 짚은 빠진 시나리오(돌연변이 16개가 살아남았음) ──
	-- 의존이 **둘**: 하나만 갖춘 종류는 따라오지 않고, 거절 메시지는 빠진 그 의존을 말함
	const SecondTrait = T.New<<{ read Put: (v: any) -> () }>>("ReviewSecond", { required = { "Put" } })
	const Both = T.New<<{ read Use: (v: any) -> string }>>("Both", {
		dependencies = { BaseTrait, SecondTrait },
		defaults = function(_ops: any, deps: { [any]: any })
			return {
				Use = function(v: any): string
					deps[SecondTrait].Put(v)
					return `use{deps[BaseTrait].Get(v)}`
				end,
			}
		end,
	}) :: stl.Trait<{ read Use: (v: any) -> string }, any>
	assert(T.ImplOf(Both, value) == nil and not T.Implements(Both, value), "의존 둘 중 하나만 — 안 따라옴")
	const okBoth, errBoth = pcall(function()
		where = debug.info(1, "l") + 1
		T.Impl(Both, Kind, {})
	end)
	assert(
		not okBoth
			and string.find(tostring(errBoth), "ReviewKind must implement ReviewSecond to implement Both", 1, true),
		`빠진 의존을 말함: {errBoth}`
	)
	local puts = 0
	T.Impl(SecondTrait, Kind, {
		Put = function(_v: any)
			puts += 1
		end,
	})
	const both = T.ImplOf(Both, value)
	assert(both ~= nil and both.Use(value) == "use7" and puts == 1, "둘 다 갖추면 따라오고 둘 다 받음")
	-- 의존 있는 트레이트를 **저절로 만들어지기 전에** 명시 등록(모듈을 불러올 때 등록하는 보통 순서)
	const EarlyKind = T.NewToken("EarlyKind")
	T.Impl(BaseTrait, EarlyKind, {
		Get = function(_v: any): number
			return 3
		end,
	})
	T.Impl(SecondTrait, EarlyKind, { Put = function(_v: any) end })
	-- (트레이트가 모르는 이름은 넘길 수 없음 — 질문 AS. 재정의할 것이 없으면 빈 표)
	const givenEarly = {}
	T.Impl(Both, EarlyKind, givenEarly)
	const early: any = T.ImplOf(Both, { __type = EarlyKind })
	assert(early.Use({ __type = EarlyKind }) == "use3", "먼저 등록해도 기본 구현이 의존을 받음")
	assert(not Both.derived[EarlyKind], "저절로 만든 것이 아님(명시 등록)")
	-- **넘긴 표는 고치지 않음** — 완성 표는 다른 표(모듈 테이블을 그대로 넘겨도 모듈에 기본 구현이 써지지 않음)
	assert(not rawequal(early, givenEarly) and rawget(givenEarly :: any, "Use") == nil, "넘긴 표는 그대로")
	-- 얼린 표를 넘겨도 됨
	const FrozenKind = T.NewToken("FrozenKind")
	T.Impl(
		BaseTrait,
		FrozenKind,
		table.freeze({
			Get = function(_v: any): number
				return 9
			end,
		})
	)
	T.Impl(SecondTrait, FrozenKind, { Put = function(_v: any) end })
	T.Impl(Both, FrozenKind, table.freeze({}))
	assert((T.ImplOf(Both, { __type = FrozenKind }) :: any).Use({}) == "use9", "얼린 표를 넘겨도 합쳐짐")
	-- 다 갖춘 등록을 또 하면 에러(합치는 트레이트에서도)
	const okAgain, errAgain = pcall(function()
		T.Impl(Both, EarlyKind, {})
	end)
	assert(not okAgain and string.find(tostring(errAgain), "EarlyKind already implements Both", 1, true), `{errAgain}`)
	-- 합치는 트레이트에 표가 아닌 구현 — 사용자 줄
	const okNum, errNum = pcall(function()
		where = debug.info(1, "l") + 1
		T.Impl(Both, T.NewToken("NumKind"), 5 :: any)
	end)
	assert(not okNum and string.find(tostring(errNum), "needs a table of functions for Both", 1, true), `{errNum}`)
	assert(string.find(tostring(errNum), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {errNum}`)

	-- **기본 구현만** 있는 트레이트(필수·의존 없음): 토큰 있는 모든 종류에 따라오고, 토큰 없는 값에는 안 따라옴
	const Anyone = T.New<<{ read Name: (v: any) -> string }>>("Anyone", {
		defaults = function()
			return {
				Name = function(v: any): string
					return (T.TokenOf(v) :: any).name
				end,
			}
		end,
	})
	assert((T.ImplOf(Anyone, value) :: any).Name(value) == "ReviewKind", "기본 구현만 — 토큰 있는 종류")
	assert((T.ImplOf(Anyone, stl.Arr.Of(1)) :: any).Name(stl.Arr.Of(1)) == "Arr", "내장 종류에도")
	for _, notKind in { 5, "x", {}, { __type = "Arr" } } :: { any } do
		assert(
			T.ImplOf(Anyone, notKind) == nil and not T.Implements(Anyone, notKind),
			"토큰 없는 값에는 안 따라옴"
		)
	end
	assert(T.ImplOf(Anyone, nil) == nil, "nil 에도")
	-- **의존만** 있는 트레이트(표식): 의존을 갖춘 종류에 빈 표가 따라오고, 못 갖춘 종류의 명시 등록은 거절
	const Marked = T.New<<{}>>("Marked", { dependencies = { BaseTrait } })
	assert(T.Implements(Marked, value) and not T.Implements(Marked, stl.Arr.Of(1)), "표식 트레이트")
	assert(not pcall(function()
		T.Impl(Marked, T.NewToken("Unmarked"), {})
	end), "의존을 못 갖춘 종류의 표식 등록은 거절")
	-- `required = {}`(빈 필수 목록) + 의존 — 필수가 없는 것으로 읽혀 따라옴
	const EmptyRequired = T.New<<{ read Id: (v: any) -> number }>>("EmptyRequired", {
		required = {},
		dependencies = { BaseTrait },
		defaults = function(_ops: any, deps: { [any]: any })
			return {
				Id = function(v: any): number
					return deps[BaseTrait].Get(v)
				end,
			}
		end,
	})
	assert((T.ImplOf(EmptyRequired, value) :: any).Id(value) == 7, "빈 필수 목록은 저절로 따라옴")
	-- 넘긴 의존 목록은 사본이고 얼어 있음
	assert(
		table.isfrozen(Both.dependencies :: any) and table.isfrozen(BaseTrait.required :: any),
		"사본은 얼어 있음"
	)
	-- `Map.Records` 의 에러 메시지(예전엔 에러가 나는지만 봤음 — 함수 이름이 틀려도 통과)
	const okRecords, errRecords = pcall(function()
		where = debug.info(1, "l") + 1
		stl.Map.Records(stl.Arr.Of(1) :: any)
	end)
	assert(not okRecords and string.find(tostring(errRecords), "Map: Records needs a Map", 1, true), `{errRecords}`)
	assert(string.find(tostring(errRecords), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {errRecords}`)
end
print("PASS")

print(
	"=== 13. ⭐ 리스트 알고리즘은 프리미티브 다섯에서 따라온다 (2026-10-13, papers/07 2단계) ==="
)
do
	const T = stl.Trait
	-- 사용자 리스트: 양방향으로 이은 노드. **위치가 노드**이고, 구현은 프리미티브 다섯뿐입니다.
	type ChainNode = { value: number?, prev: ChainNode?, next: ChainNode? }
	type Chain = {
		head: ChainNode?,
		tail: ChainNode?,
		read __type: stl.TraitToken<string>,
		read __list: number?,
		read __listIndex: ChainNode,
	}
	const ChainType = T.NewToken("Chain")
	T.Impl(stl.List, ChainType, {
		Get = function(_c: Chain, node: ChainNode): number?
			return node.value
		end,
		FirstIndex = function(c: Chain): ChainNode?
			return c.head
		end,
		LastIndex = function(c: Chain): ChainNode?
			return c.tail
		end,
		NextIndex = function(_c: Chain, node: ChainNode): ChainNode?
			return node.next
		end,
		PrevIndex = function(_c: Chain, node: ChainNode): ChainNode?
			return node.prev
		end,
	})
	local function chainOf(values: { number? }, count: number): Chain
		const chain: Chain = { head = nil, tail = nil, __type = ChainType } :: any
		for at = 1, count do
			const node: ChainNode = { value = values[at], prev = chain.tail, next = nil }
			if chain.tail then
				chain.tail.next = node
			else
				chain.head = node
			end
			chain.tail = node
		end
		return chain
	end
	-- 노드가 앞에서 몇 번째인지(견주기용)
	local function ordinal(chain: Chain, node: ChainNode?): number?
		local at, cursor = 1, chain.head
		while cursor ~= nil do
			if cursor == node then
				return at
			end
			at += 1
			cursor = cursor.next
		end
		return nil
	end

	-- 기본 구현을 받았는지 / 재정의가 이겼는지
	const chainOps = T.ImplOf(stl.List, chainOf({ 10 }, 1))
	assert(
		chainOps ~= nil and type(chainOps.Fold) == "function" and type(chainOps.Every) == "function",
		"Chain 이 받음"
	)
	const arrOps = T.ImplOf(stl.List, stl.Arr.Of(1))
	assert(
		arrOps ~= nil and arrOps.Fold == stl.Arr.Fold and arrOps.IndexOf == stl.Arr.IndexOf,
		"Arr 은 자기 구현으로"
	)
	assert(
		arrOps.Find == stl.Arr.Find and arrOps.Some == stl.Arr.Some and arrOps.Count == stl.Arr.Count,
		"Arr 재정의"
	)
	const dequeOps = T.ImplOf(stl.List, stl.CircularDeque.Of(1))
	assert(
		(stl.CircularDeque :: any).Fold == nil and dequeOps ~= nil and type(dequeOps.Fold) == "function",
		"CircularDeque 는 기본 구현"
	)
	assert(dequeOps.Fold ~= chainOps.Fold, "기본 구현은 종류마다 따로(자기 프리미티브를 부름)")

	-- ⭐ 무작위 대조: 같은 값 열을 Arr·CircularDeque(감기게)·Chain 에 — 일곱 알고리즘이 같은 답.
	-- 기준은 `Arr` 의 직접 구현입니다(값은 위치와 겹치지 않게 100 단위, 중복·구멍 포함).
	local seed = 20261013
	local function rand(limit: number): number
		seed = (seed * 16807) % 2147483647
		return seed % limit + 1
	end
	for round = 1, 300 do
		const count = rand(13) - 1
		const values = table.create(count) :: { number? }
		for at = 1, count do
			const roll = rand(10)
			values[at] = if roll == 1 then nil else rand(6) * 100
		end
		const arr = stl.Arr.Sized<<number?>>(count, nil)
		for at = 1, count do
			arr[at] = values[at]
		end
		-- 덱은 뒤 절반을 먼저 넣고 앞 절반을 PushFront 로 — 감긴 상태가 되게
		const dq = stl.CircularDeque.New<<number?>>()
		const half = count // 2
		for at = half + 1, count do
			stl.CircularDeque.PushBack(dq, values[at])
		end
		for at = half, 1, -1 do
			stl.CircularDeque.PushFront(dq, values[at])
		end
		const chain = chainOf(values, count)
		const target = rand(7) * 100
		const label = `라운드 {round}(길이 {count}, 찾는 값 {target})`

		const wantSum = stl.List.Fold(arr, 0, function(acc: number, v: number?): number
			return acc * 3 + (v or 7)
		end)
		assert(stl.List.Fold(dq, 0, function(acc: number, v: number?): number
			return acc * 3 + (v or 7)
		end) == wantSum, `{label} CircularDeque Fold`)
		assert(stl.List.Fold(chain, 0, function(acc: number, v: number?): number
			return acc * 3 + (v or 7)
		end) == wantSum, `{label} Chain Fold`)

		const wantIndex = stl.List.IndexOf(arr, target)
		assert(stl.List.IndexOf(dq, target) == wantIndex, `{label} CircularDeque IndexOf`)
		assert(ordinal(chain, stl.List.IndexOf(chain, target)) == wantIndex, `{label} Chain IndexOf`)
		assert(
			stl.List.IndexOf(dq, nil) == stl.List.IndexOf(arr, nil),
			`{label} CircularDeque IndexOf(nil) — 첫 구멍`
		)
		assert(ordinal(chain, stl.List.IndexOf(chain, nil)) == stl.List.IndexOf(arr, nil), `{label} Chain IndexOf(nil)`)

		const wantHas = stl.List.Contains(arr, target)
		assert(wantHas == (wantIndex ~= nil), `{label} Arr Contains 는 IndexOf 와 맞음`)
		assert(
			stl.List.Contains(dq, target) == wantHas and stl.List.Contains(chain, target) == wantHas,
			`{label} Contains`
		)

		const big = function(v: number?): boolean
			return v ~= nil and v >= 400
		end
		const wantCount = stl.List.Count(arr, big)
		assert(
			stl.List.Count(dq, big) == wantCount and stl.List.Count(chain, big) == wantCount,
			`{label} Count(술어)`
		)
		assert(
			stl.List.Count(arr) == count and stl.List.Count(dq) == count and stl.List.Count(chain) == count,
			`{label} Count() 는 구멍도 자리`
		)

		const wantItem, wantAt = stl.List.Find(arr, big)
		const dqItem, dqAt = stl.List.Find(dq, big)
		const chainItem, chainAt = stl.List.Find(chain, big)
		assert(dqItem == wantItem and dqAt == wantAt, `{label} CircularDeque Find`)
		assert(chainItem == wantItem and ordinal(chain, chainAt) == wantAt, `{label} Chain Find`)

		assert(
			stl.List.Some(dq, big) == stl.List.Some(arr, big) and stl.List.Some(chain, big) == stl.List.Some(arr, big),
			`{label} Some`
		)
		assert(
			stl.List.Every(dq, big) == stl.List.Every(arr, big)
				and stl.List.Every(chain, big) == stl.List.Every(arr, big),
			`{label} Every`
		)
		assert(
			stl.List.Some(arr, big) == (wantCount > 0) and stl.List.Every(arr, big) == (wantCount == count),
			`{label} Some/Every 의 뜻`
		)
	end

	-- 콜백은 원소와 **위치**를 받음 — Chain 에서는 노드
	const three = chainOf({ 10, 20, 30 }, 3)
	const seen: { string } = {}
	stl.List.Fold(three, 0, function(acc: number, v: number?, node: ChainNode): number
		table.insert(seen, `{v}@{ordinal(three, node)}:{node.value}`)
		return acc
	end)
	assert(table.concat(seen, " ") == "10@1:10 20@2:20 30@3:30", `위치는 노드: {table.concat(seen, " ")}`)
	const _, foundNode = stl.List.Find(three, function(_v: number?, node: ChainNode): boolean
		return node.prev ~= nil and node.prev.value == 10
	end)
	assert(foundNode ~= nil and foundNode.value == 20, "술어가 노드를 받음")
	-- CircularDeque·Arr 에서는 숫자 위치(앞에서부터 1)
	const positions: { number } = {}
	stl.List.Some(
		stl.CircularDeque.PushFront(stl.CircularDeque.Of(20, 30), 10),
		function(_v: number, at: number): boolean
			table.insert(positions, at)
			return false
		end
	)
	assert(table.concat(positions, ",") == "1,2,3", "CircularDeque 의 위치")

	-- 빈 리스트
	for name, empty in
		{ Arr = stl.Arr.Of<<number>>(), CircularDeque = stl.CircularDeque.New<<number>>(), Chain = chainOf({}, 0) } :: { [string]: any }
	do
		const never = function(_v: any): boolean
			return true
		end
		assert(stl.List.Fold(empty, "init", function(acc: string, _v: any): string
			return acc .. "!"
		end) == "init", `빈 {name} Fold`)
		const item, at = stl.List.Find(empty, never)
		assert(item == nil and at == nil, `빈 {name} Find`)
		assert(
			stl.List.IndexOf(empty, 10) == nil and not stl.List.Contains(empty, 10) and stl.List.Count(empty) == 0,
			`빈 {name} 찾기·세기`
		)
		assert(not stl.List.Some(empty, never) and stl.List.Every(empty, never), `빈 {name} Some 거짓·Every 참`)
	end

	-- 기본 구현이 부르는 다른 기본 구현은 재정의된 판(Contains → IndexOf)
	const OddType = T.NewToken("OddChain")
	local indexOfCalls = 0
	T.Impl(
		stl.List,
		OddType,
		{
			Get = chainOps.Get,
			FirstIndex = chainOps.FirstIndex,
			LastIndex = chainOps.LastIndex,
			NextIndex = chainOps.NextIndex,
			PrevIndex = chainOps.PrevIndex,
			IndexOf = function(c: Chain, item: number?): ChainNode?
				indexOfCalls += 1
				return if item == 777 then c.head else nil
			end,
		} :: any
	)
	const odd: Chain = chainOf({ 10, 20 }, 2)
	rawset(odd :: any, "__type", OddType)
	assert(
		stl.List.Contains(odd, 777) and not stl.List.Contains(odd, 10) and indexOfCalls == 2,
		"Contains 가 재정의된 IndexOf 를 부름"
	)
	assert(stl.List.Count(odd) == 2, "나머지는 기본 구현")

	-- 리스트가 아닌 것: 사용자 줄 에러
	-- (콜백은 밖에서 선언 — 테이블 리터럴 안에 콜백 리터럴을 겹쳐 쓰면 새 솔버가 다른 필드의 반환 타입을
	-- 끌어와 엉뚱한 에러를 냈습니다. `List.Fold` 의 서명 문제가 아님은 최소 재현으로 확인.)
	local where = 0
	const keepAcc = function(acc: number): number
		return acc
	end
	const alwaysTrue = function(): boolean
		return true
	end
	const calls: { { name: string, call: (any) -> any } } = {
		{
			name = "Fold",
			call = function(v: any): any
				return stl.List.Fold(v, 0, keepAcc)
			end,
		},
		{
			name = "Find",
			call = function(v: any): any
				return (stl.List.Find(v, alwaysTrue))
			end,
		},
		{
			name = "Contains",
			call = function(v: any): any
				return stl.List.Contains(v, 1)
			end,
		},
		{
			name = "Every",
			call = function(v: any): any
				return stl.List.Every(v, alwaysTrue)
			end,
		},
	}
	const notLists: { any } = {
		stl.HashMap.New<<string, number>>(),
		stl.Heap.New(function(a: number, b: number): boolean
			return a < b
		end),
		5,
		{},
	}
	for _, bad in notLists do
		for _, entry in calls do
			const ok, err = pcall(function()
				where = debug.info(1, "l") + 1
				entry.call(bad)
			end)
			assert(
				not ok and string.find(tostring(err), `List: {entry.name} needs a List`, 1, true),
				`{entry.name}: {err}`
			)
		end
	end
	const okLine, errLine = pcall(function()
		where = debug.info(1, "l") + 1
		stl.List.Some(stl.HashSet.Of(1) :: any, function(): boolean
			return true
		end)
	end)
	assert(
		not okLine and string.find(tostring(errLine), `spec.contracts.luau:{where}:`, 1, true),
		`사용자 줄: {errLine}`
	)

	--[[ 2단계 리뷰 1라운드가 짚은 공백(돌연변이 생존) ]]
	const add = function(acc: number, v: number?): number
		return acc + (v or 0)
	end
	const tens: { number? } = { 10, 20, 30, 40 }
	const kinds: { { name: string, list: any } } = {
		{ name = "Arr", list = stl.Arr.Of(10, 20, 30, 40) },
		{ name = "CircularDeque", list = stl.CircularDeque.Of(10, 20, 30, 40) },
		{ name = "Chain", list = chainOf(tens, 4) },
	}
	for _, kind in kinds do
		-- Fold 는 **손으로 센 값**과 견줌(기준값이 진입점 자신이면 "항상 init 을 돌려줌" 이 통과했음)
		assert(stl.List.Fold(kind.list, 0, add) == 100, `{kind.name} Fold 합`)
		assert(stl.List.Fold(kind.list, 5, add) == 105, `{kind.name} Fold 초기값`)
		-- 술어는 **위치**도 받음(Count·Every·Some·Find 전부) — 위치가 nil 이면 여기서 걸림
		local withPosition = 0
		assert(stl.List.Count(kind.list, function(_v: any, at: any): boolean
			withPosition += if at ~= nil then 1 else 0
			return at ~= nil
		end) == 4 and withPosition == 4, `{kind.name} Count 의 술어가 위치를 받음`)
		assert(
			stl.List.Every(kind.list, function(_v: any, at: any): boolean
				return at ~= nil
			end),
			`{kind.name} Every 의 술어가 위치를 받음`
		)
		assert(
			stl.List.Some(kind.list, function(_v: any, at: any): boolean
				return at ~= nil
			end),
			`{kind.name} Some 의 술어가 위치를 받음`
		)
		-- 못 찾은 Find 는 값 **둘**(nil, nil)
		assert(select(
			"#",
			stl.List.Find(kind.list, function(): boolean
				return false
			end)
		) == 2, `{kind.name} Find 못 찾음은 값 둘`)
		-- Some 은 술어의 참 값이 아니라 불리언
		assert(stl.List.Some(kind.list, function(): any
			return "truthy"
		end) == true, `{kind.name} Some 은 불리언`)
	end
	assert(stl.Arr.Fold(stl.Arr.Of(10, 20, 30, 40), 0, add) == 100, "Arr.Fold 직접 호출과 같은 값")

	-- 구멍: 술어는 구멍에도 불림(nil 을 받음) — 기본 구현(CircularDeque·Chain)과 Arr 이 같은 답
	const isHole = function(v: any): boolean
		return v == nil
	end
	const holedKinds: { { name: string, list: any } } = {
		{ name = "Arr", list = stl.Arr.Of<<number?>>(10, nil, 30, nil) },
		{ name = "CircularDeque", list = stl.CircularDeque.Of<<number?>>(10, nil, 30, nil) },
		{ name = "Chain", list = chainOf({ 10, nil, 30, nil }, 4) },
	}
	for _, kind in holedKinds do
		assert(stl.List.Count(kind.list, isHole) == 2, `{kind.name} Count(구멍)`)
		assert(stl.List.Some(kind.list, isHole), `{kind.name} Some(구멍)`)
		assert(not stl.List.Every(kind.list, isHole), `{kind.name} Every(구멍)`)
		const item, at = stl.List.Find(kind.list, isHole)
		assert(item == nil and at ~= nil, `{kind.name} Find(구멍) 은 nil 과 그 위치`)
		assert(stl.List.Contains(kind.list, nil) == true, `{kind.name} Contains(nil)`)
		assert(stl.List.IndexOf(kind.list, nil) ~= nil, `{kind.name} IndexOf(nil)`)
		assert(stl.List.Contains(kind.list, 30) and not stl.List.Contains(kind.list, 99), `{kind.name} Contains`)
	end

	-- ⭐ 내장 종류가 **무엇을 재정의하는지 전수로 고정**. 등록은 "넘길 것만 든 표" 라(2026-10-13, 질문 AS) 모듈에
	-- 같은 이름의 함수가 생겨도 저절로 재정의가 되지는 않습니다 — 여기는 "등록 표에 적은 것이 이 목록과 같은가" 를
	-- 봅니다. 재정의를 더하면(등록 표에 이름을 더하면) "그 함수가 기본 구현과 같은 뜻인가" 를 확인하고 목록을 고치세요.
	const defaultNames = { "Fold", "Find", "IndexOf", "Contains", "Count", "Some", "Every" }
	const overrides: { { name: string, module: any, value: any, own: { [string]: boolean } } } = {
		{
			name = "Arr",
			module = stl.Arr,
			value = stl.Arr.Of(1),
			own = { Fold = true, Find = true, IndexOf = true, Contains = true, Count = true, Some = true, Every = true },
		},
		{ name = "CircularDeque", module = stl.CircularDeque, value = stl.CircularDeque.Of(1), own = {} },
		{ name = "LinkedDeque", module = stl.LinkedDeque, value = stl.LinkedDeque.Of(1), own = {} },
	}
	for _, case in overrides do
		const ops = T.ImplOf(stl.List, case.value) :: any
		for _, fnName in defaultNames do
			assert(type(ops[fnName]) == "function", `{case.name} 완성 표에 {fnName}`)
			if case.own[fnName] then
				assert(ops[fnName] == case.module[fnName], `{case.name}.{fnName} 은 자기 구현(재정의)`)
			else
				assert(
					case.module[fnName] == nil or ops[fnName] ~= case.module[fnName],
					`{case.name}.{fnName} 이 재정의로 등록됨 — 목록에 없는 재정의`
				)
			end
		end
	end

	-- 에러 메시지의 진입점 이름: 일곱 전부
	const namedCalls: { { name: string, call: (any) -> any } } = {
		{
			name = "IndexOf",
			call = function(v: any): any
				return stl.List.IndexOf(v, 1)
			end,
		},
		{
			name = "Count",
			call = function(v: any): any
				return stl.List.Count(v)
			end,
		},
		{
			name = "Some",
			call = function(v: any): any
				return stl.List.Some(v, alwaysTrue)
			end,
		},
	}
	for _, entry in namedCalls do
		const ok, err = pcall(entry.call, stl.HashMap.New())
		assert(
			not ok and string.find(tostring(err), `List: {entry.name} needs a List — HashMap does not`, 1, true),
			`{entry.name} 이름: {err}`
		)
	end
end
print("PASS")

print(
	"=== 14. 트레이트 모듈 — 트레이트 객체에 진입점을 얹음, ExpectImpl (2026-10-13, 구조 재배치) ==="
)
do
	const T = stl.Trait
	-- 사용자 트레이트도 라이브러리의 트레이트 파일과 같은 모양으로 짭니다: 계약 + 기본 구현 + 진입점.
	type Gauge = { read __type: stl.TraitToken<any>, level: number }
	type GaugeFull = { read Read: (g: Gauge) -> number, read Label: (g: Gauge) -> string }
	type GaugeImpl = { read Read: (g: Gauge) -> number, read Label: ((g: Gauge) -> string)? }
	const GaugeBase = T.New<<GaugeFull>>("Gauge", {
		required = { "Read" },
		defaults = function(ops: any)
			return {
				Label = function(g: Gauge): string
					return `level {ops.Read(g)}`
				end,
			}
		end,
	}) :: stl.Trait<GaugeFull, GaugeImpl>
	const function Label(g: Gauge): string
		return T.ExpectImpl(GaugeBase, g, "Label").Label(g)
	end
	const Gauge = T.Expose(GaugeBase, { Label = Label })
	assert(Gauge == GaugeBase :: any, "Module 은 같은 트레이트 객체를 돌려줌(정체성 유지)")
	assert(Gauge.name == "Gauge" and Gauge.Label == Label, "트레이트의 필드와 진입점이 한 표에")

	const PlainKind, LoudKind, OtherKind = T.NewToken("PlainGauge"), T.NewToken("LoudGauge"), T.NewToken("NotGauge")
	T.Impl(Gauge, PlainKind, {
		Read = function(g: Gauge): number
			return g.level
		end,
	})
	T.Impl(Gauge, LoudKind, {
		Read = function(g: Gauge): number
			return g.level * 2
		end,
		Label = function(g: Gauge): string
			return `LEVEL {g.level}`
		end,
	})
	const plain: Gauge = { __type = PlainKind, level = 7 }
	const loud: Gauge = { __type = LoudKind, level = 7 }
	assert(Gauge.Label(plain) == "level 7", "기본 구현")
	assert(Gauge.Label(loud) == "LEVEL 7", "재정의")
	assert(T.ImplOf(Gauge, plain) ~= nil and T.Implements(Gauge, loud), "Module 을 거친 트레이트도 조회됨")

	-- ExpectImpl 의 빗나감: 메시지 머리는 **트레이트 이름**. 세 갈래(구현 없음 / 모르는 토큰 / 토큰 없음).
	-- 줄은 "라이브러리 파일이 아닌 첫 프레임" — 사용자 트레이트의 진입점은 사용자 파일이라 그 진입점 안의
	-- ExpectImpl 줄을 가리키고, 내장 트레이트의 진입점은 부른 줄을 가리킵니다(아래에서 정확한 줄로).
	local where = 0
	const misses: { { value: any, gauge: string, map: string } } = {
		{
			value = { __type = OtherKind, level = 1 },
			gauge = "Gauge: Label needs a Gauge — NotGauge does not implement Gauge",
			map = "Map: Keys needs a Map — NotGauge does not implement Map",
		},
		{
			value = { __type = table.freeze({ name = "Ghost" }), level = 1 },
			gauge = "Gauge: Label needs a Gauge — got a Ghost this library does not know",
			map = "Map: Keys needs a Map — got a Ghost this library does not know",
		},
		{
			value = { level = 1 },
			gauge = "Gauge: Label needs a Gauge (got table without a type token)",
			map = "Map: Keys needs a Map (got table without a type token)",
		},
		{
			value = 5,
			gauge = "Gauge: Label needs a Gauge (got number without a type token)",
			map = "Map: Keys needs a Map (got number without a type token)",
		},
	}
	for _, miss in misses do
		const okGauge, errGauge = pcall(function()
			Gauge.Label(miss.value)
		end)
		assert(not okGauge and string.find(tostring(errGauge), miss.gauge, 1, true), `ExpectImpl 메시지: {errGauge}`)
		assert(string.find(tostring(errGauge), "spec.contracts.luau:", 1, true), `사용자 파일의 줄: {errGauge}`)
		const okMap, errMap = pcall(function()
			where = debug.info(1, "l") + 1
			stl.Map.Keys(miss.value)
		end)
		assert(not okMap and string.find(tostring(errMap), miss.map, 1, true), `내장 진입점 메시지: {errMap}`)
		assert(
			string.find(tostring(errMap), `spec.contracts.luau:{where}:`, 1, true),
			`내장 진입점 사용자 줄: {errMap}`
		)
	end
	-- 내장 트레이트의 진입점도 같은 머리
	const okList, errList = pcall(function()
		where = debug.info(1, "l") + 1
		stl.List.Fold(stl.HashMap.New() :: any, 0, function(acc: number)
			return acc
		end)
	end)
	assert(
		not okList
			and string.find(tostring(errList), "List: Fold needs a List — HashMap does not implement List", 1, true)
			and string.find(tostring(errList), `spec.contracts.luau:{where}:`, 1, true),
		`List 진입점: {errList}`
	)
	const okLen, errLen = pcall(function()
		where = debug.info(1, "l") + 1
		stl.Collection.Len(stl.Fut.Resolved(1) :: any)
	end)
	assert(
		not okLen
			and string.find(
				tostring(errLen),
				"Collection: Len needs a Collection — Fut does not implement Collection",
				1,
				true
			)
			and string.find(tostring(errLen), `spec.contracts.luau:{where}:`, 1, true),
		`Collection 진입점: {errLen}`
	)

	-- Module 의 에러 셋 — 사용자 줄
	const SpareTrait = T.New<<{ read Ping: (v: any) -> number }>>("Spare", { required = { "Ping" } })
	const moduleErrors: { { call: () -> (), want: string } } = {
		{
			call = function()
				where = debug.info(1, "l") + 1
				T.Expose({} :: any, {})
			end,
			want = "Trait: Expose needs a trait (from Trait.New), got table",
		},
		{
			call = function()
				where = debug.info(1, "l") + 1
				T.Expose(SpareTrait, 5 :: any)
			end,
			want = "Trait: Expose needs a table of entry functions, got number",
		},
		{
			call = function()
				where = debug.info(1, "l") + 1
				T.Expose(SpareTrait, { Fine = print, impls = print })
			end,
			want = "Trait: Expose got an entry named impls, which the trait already has",
		},
		{
			-- 같은 이름을 두 번 얹는 것도(이미 얹은 진입점과 겹침)
			call = function()
				where = debug.info(1, "l") + 1
				T.Expose(Gauge, { Label = print })
			end,
			want = "Trait: Expose got an entry named Label, which the trait already has",
		},
	}
	for _, case in moduleErrors do
		const ok, err = pcall(case.call)
		assert(not ok and string.find(tostring(err), case.want, 1, true), `Module 메시지: {err}`)
		assert(string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true), `Module 사용자 줄: {err}`)
	end
	assert(Gauge.Label == Label, "거절된 Module 은 진입점을 덮어쓰지 않음")
	-- 내장 트레이트 넷이 배럴에 있고, 진입점과 트레이트가 같은 표
	assert(T.Implements(stl.List, stl.Arr.Of(1)) and type(stl.List.IndexOf) == "function", "stl.List")
	assert(T.Implements(stl.Map, stl.HashMap.New()) and type(stl.Map.Keys) == "function", "stl.Map")
	assert(T.Implements(stl.Set, stl.HashSet.New()), "stl.Set")
	assert(T.Implements(
		stl.Collection,
		stl.Heap.New(function(a: number, b: number): boolean
			return a < b
		end)
	) and type(stl.Collection.Len) == "function", "stl.Collection")
end
print("PASS")

print(
	"=== 15. 구조 재배치 리뷰 1라운드 — Module 의 예약 이름, 저절로 따라오는 트레이트의 진입점, Arr 토큰의 정체성 ==="
)
do
	const T = stl.Trait
	local where = 0
	-- (1) Module: 트레이트의 자기 필드 이름은 **값이 nil 이어도** 진입점 이름으로 못 씀(예전엔 `defaults`·`required`·
	--     `dependencies` 가 통과해 진입점이 기본 구현·필수 목록·의존 목록으로 읽혔음), 그리고 거절되면 아무것도 안 얹힘
	const Bare = T.New<<{ read X: (v: any) -> number }>>("BareForModule", { required = { "X" } })
	for _, reserved in { "defaults", "required", "dependencies", "derivable", "derived", "impls", "name", "__impl" } do
		const ok, err = pcall(function()
			where = debug.info(1, "l") + 1
			T.Expose(Bare, { Fine = print, [reserved] = print } :: any)
		end)
		assert(
			not ok
				and string.find(
					tostring(err),
					`Trait: Expose got an entry named {reserved}, which the trait already has`,
					1,
					true
				),
			`{reserved}: {err}`
		)
		assert(string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true), `{reserved} 사용자 줄: {err}`)
		assert(rawget(Bare :: any, "Fine") == nil, `{reserved}: 거절된 Module 은 다른 이름도 얹지 않음`)
	end
	assert(
		rawget(Bare :: any, "defaults") == nil and rawget(Bare :: any, "dependencies") == nil,
		"트레이트는 그대로"
	)
	const BareKind = T.NewToken("BareKind")
	const bareImpl = {
		X = function(_v: any): number
			return 7
		end,
	}
	T.Impl(Bare, BareKind, bareImpl)
	assert(
		T.ImplOf(Bare, { __type = BareKind }) == bareImpl,
		"거절 뒤에도 평범한 트레이트(넘긴 표 그대로)"
	)

	-- (2) 저절로 따라오는 트레이트의 **진입점**을 그 종류에 처음 부름(표는 의존이 갖춰질 때 이미 만들어져 있어야 함 — 2026-10-14)
	type SizedFull = { read IsEmpty: (c: any) -> boolean }
	const SizedBase = T.New<<SizedFull>>("Sized", {
		dependencies = { stl.Collection },
		defaults = function(_ops: any, deps: { [any]: any })
			return {
				IsEmpty = function(c: any): boolean
					return deps[stl.Collection].Len(c) == 0
				end,
			}
		end,
	})
	const Sized = T.Expose(SizedBase, {
		IsEmpty = function(c: any): boolean
			return T.ExpectImpl(SizedBase, c, "IsEmpty").IsEmpty(c)
		end,
	})
	assert(Sized.IsEmpty(stl.Arr.Of<<number>>()) == true, "처음 부르는 진입점 — Arr")
	assert(Sized.IsEmpty(stl.TreeMap.New<<number, number>>(stl.Common.compareNumber)) == true, "TreeMap")
	assert(Sized.IsEmpty(stl.LinkedDeque.Of(1)) == false, "LinkedDeque")
	const okSized, errSized = pcall(function()
		Sized.IsEmpty(stl.Fut.Resolved(1))
	end)
	assert(
		not okSized
			and string.find(
				tostring(errSized),
				"Sized: IsEmpty needs a Sized — Fut does not implement Sized",
				1,
				true
			),
		`의존을 못 갖춘 종류: {errSized}`
	)

	-- (3) `HashMap.FromTable` 은 Arr 을 **토큰의 정체성**으로 알아봄 — 사용자가 "Arr" 라는 이름으로 만든 종류는
	--     Arr 이 아님(이름으로 알아봤을 땐 조용히 빈 맵이 되거나 필드를 잃었음)
	const UserArr = T.NewToken("Arr")
	for _, value in
		{
			T.Stamp({ n = 3, items = { 10, 20, 30 } }, UserArr),
			T.Stamp({ n = 0, a = 1, b = 2 }, UserArr),
			T.Stamp({ n = 2, 10, 20, extra = "e" } :: any, UserArr),
			T.Stamp({ a = 1 }, UserArr),
		} :: { any }
	do
		const ok, err = pcall(function()
			where = debug.info(1, "l") + 1
			stl.HashMap.FromTable(value)
		end)
		assert(
			not ok
				and string.find(
					tostring(err),
					"HashMap: FromTable takes a plain table or an Arr, got a Arr container",
					1,
					true
				),
			`사용자의 "Arr" 종류: {err}`
		)
		assert(string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {err}`)
	end
	const fromArr = stl.HashMap.FromTable(stl.Arr.Of<<number?>>(10, nil, 30) :: any)
	assert(stl.HashMap.Len(fromArr) == 2 and stl.HashMap.Get(fromArr, 3) == 30, "진짜 Arr 은 위치 → 값으로")

	-- (4) 진입점의 에러 이름 — 빠져 있던 둘
	for _, entry in
		{
			{ name = "Map: Values needs a Map", call = stl.Map.Values :: any },
			{ name = "Collection: Clear needs a Collection", call = stl.Collection.Clear :: any },
		}
	do
		const ok, err = pcall(entry.call, 5)
		assert(not ok and string.find(tostring(err), entry.name, 1, true), `{entry.name}: {err}`)
	end
end
print("PASS")

print(
	"=== 16. 2라운드 리뷰(2026-10-13) — 리스트 자리의 비테이블, Adopt 의 비교자, 균형 계약의 배선 ==="
)
do
	const cmp = Common.compareNumber
	local where = 0
	-- (1) `{ T }` 를 받는 진입점에 테이블이 아닌 값: 예전엔 `Common.listLength` 의 `rawget` 이 라이브러리 줄에서
	--     죽었습니다(`invalid argument #1 to 'rawget'`). 타입 없는 코드에서 가장 흔한 것이 `nil` 입니다.
	const listSites: { { name: string, call: (any) -> () } } = {
		{
			name = "Arr.FromTable",
			call = function(bad)
				where = debug.info(1, "l") + 1
				stl.Arr.FromTable(bad)
			end,
		},
		{
			name = "HashSet.FromList",
			call = function(bad)
				where = debug.info(1, "l") + 1
				stl.HashSet.FromList(bad)
			end,
		},
		{
			name = "TreeMap.FromRecords",
			call = function(bad)
				where = debug.info(1, "l") + 1
				stl.TreeMap.FromRecords(bad, cmp)
			end,
		},
		{
			name = "FlatMap.FromRecords",
			call = function(bad)
				where = debug.info(1, "l") + 1
				stl.FlatMap.FromRecords(bad, cmp)
			end,
		},
		{
			name = "TreeSet.FromList",
			call = function(bad)
				where = debug.info(1, "l") + 1
				stl.TreeSet.FromList(bad, cmp)
			end,
		},
		{
			name = "LinkedDeque.FromList",
			call = function(bad)
				where = debug.info(1, "l") + 1
				stl.LinkedDeque.FromList(bad)
			end,
		},
		{
			name = "Heap.FromList",
			call = function(bad)
				where = debug.info(1, "l") + 1
				stl.Heap.FromList(bad, function(a: number, b: number)
					return a < b
				end)
			end,
		},
	}
	const bads: { { value: any, kind: string } } = {
		{ value = nil, kind = "nil" },
		{ value = 5, kind = "number" },
		{ value = "list", kind = "string" },
		{ value = false, kind = "boolean" },
	}
	for _, site in listSites do
		for _, bad in bads do
			const ok, err = pcall(site.call, bad.value)
			assert(
				not ok
					and string.find(
						tostring(err),
						`stl: expected a list (plain table, table.pack result or Arr), got {bad.kind}`,
						1,
						true
					),
				`{site.name}({bad.kind}): {err}`
			)
			assert(
				string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true),
				`{site.name}({bad.kind}) 사용자 줄: {err}`
			)
		end
	end

	-- (2) `FlatMap.Adopt` 도 비교자를 확인(닮은 문인 `TreeMap.FromSorted` 는 확인했음 — 빈 맵에서는 비교가 일어나지
	--     않아 엉뚱한 값이 통과하고 둘째 넣기에서 라이브러리 줄의 `attempt to call a nil value` 였습니다)
	for _, bad in { "compare" :: any, 5 :: any, {} :: any } do
		const ok, err = pcall(function()
			where = debug.info(1, "l") + 1
			stl.FlatMap.Adopt({}, 0, bad)
		end)
		assert(
			not ok and string.find(tostring(err), "FlatMap: Adopt needs a comparator function, got", 1, true),
			`Adopt: {err}`
		)
		assert(string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true), `Adopt 사용자 줄: {err}`)
	end
	const okNoCompare, errNoCompare = pcall(function()
		where = debug.info(1, "l") + 1
		stl.FlatMap.Adopt({}, 0, nil :: any)
	end)
	assert(
		not okNoCompare
			and string.find(tostring(errNoCompare), "FlatMap: Adopt needs a comparator function, got nil", 1, true),
		`Adopt nil: {errNoCompare}`
	)
	assert(
		string.find(tostring(errNoCompare), `spec.contracts.luau:{where}:`, 1, true),
		`Adopt nil 사용자 줄: {errNoCompare}`
	)
	-- 맞는 비교자면 그대로 입양
	const adopted = stl.FlatMap.Adopt({ { key = 10, value = "a" }, { key = 20, value = "b" } }, 2, cmp)
	assert(stl.FlatMap.Get(adopted, 20) == "b" and stl.FlatMap.Len(adopted) == 2, "Adopt 정상")

	-- (3) 균형 계약의 배선 — 배럴의 `stl.Balance`(이 줄을 지워도 아무 테스트도 안 깨졌음), `Expect` 가 함수 넷을
	--     **각각** 보는지(테스트의 나쁜 값이 `Insert` 만 없는 것뿐이었음), `FromSorted` 의 확인.
	assert(stl.Balance ~= nil and type(stl.Balance.Expect) == "function", "stl.Balance")
	assert(stl.Balance.Expect(nil, stl.RedBlack, "X: Y") == stl.RedBlack, "Expect(nil) 은 fallback")
	assert(stl.Balance.Expect(stl.Avl, stl.RedBlack, "X: Y") == stl.Avl, "Expect 는 받은 것을 그대로")
	for _, missing in { "Insert", "Remove", "Join", "AsRoot", "FromSorted", "Clone" } do
		const partial: any = table.clone(stl.Avl)
		partial[missing] = nil
		const ok, err = pcall(function()
			where = debug.info(1, "l") + 1
			stl.Balance.Expect(partial, stl.RedBlack, "Probe: New")
		end)
		assert(
			not ok
				and string.find(
					tostring(err),
					"Probe: New needs a balance scheme with Insert, Remove, Join, AsRoot, FromSorted and Clone",
					1,
					true
				),
			`Expect({missing} 없음): {err}`
		)
		assert(
			string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true),
			`Expect({missing} 없음) 사용자 줄: {err}`
		)
	end
	const okSorted, errSorted = pcall(function()
		where = debug.info(1, "l") + 1
		stl.TreeMap.FromSorted({ 10 }, { "a" }, 1, cmp, "avl" :: any)
	end)
	assert(
		not okSorted and string.find(tostring(errSorted), "TreeMap: FromSorted needs a balance scheme", 1, true),
		`FromSorted 균형: {errSorted}`
	)
	assert(
		string.find(tostring(errSorted), `spec.contracts.luau:{where}:`, 1, true),
		`FromSorted 균형 사용자 줄: {errSorted}`
	)
end
print("PASS")

print(
	"=== 17. 3라운드 리뷰(2026-10-13) — 테이블이 아닌 값을 받는 나머지 진입점, Heap 의 비교자 ==="
)
do
	local where = 0
	const bads: { { value: any, kind: string } } = {
		{ value = nil, kind = "nil" },
		{ value = 5, kind = "number" },
		{ value = "abc", kind = "string" },
		{ value = false, kind = "boolean" },
		{ value = print, kind = "function" },
	}
	-- (1) `Arr.Adopt` — 2라운드 수정(`listLength` 의 검사)이 닿지 않던 자리: 그 앞의 `rawget` 이 먼저 죽었습니다.
	--     문자열은 "메타테이블이 있다" 는 엉뚱한 메시지였습니다(`getmetatable("abc")` 가 문자열 메타테이블).
	for _, bad in bads do
		const ok, err = pcall(function()
			where = debug.info(1, "l") + 1
			stl.Arr.Adopt(bad.value)
		end)
		assert(
			not ok
				and string.find(
					tostring(err),
					`stl: expected a list (plain table, table.pack result or Arr), got {bad.kind}`,
					1,
					true
				),
			`Arr.Adopt({bad.kind}): {err}`
		)
		assert(
			string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true),
			`Arr.Adopt({bad.kind}) 사용자 줄: {err}`
		)
	end
	-- (2) 사전 진입점 `HashMap.FromTable` 도 같은 모양(리스트 규약의 `{ T }` 는 아니지만 같은 `rawget`)
	for _, bad in bads do
		const ok, err = pcall(function()
			where = debug.info(1, "l") + 1
			stl.HashMap.FromTable(bad.value)
		end)
		assert(
			not ok
				and string.find(
					tostring(err),
					`HashMap: FromTable takes a plain table or an Arr, got {bad.kind}`,
					1,
					true
				),
			`HashMap.FromTable({bad.kind}): {err}`
		)
		assert(
			string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true),
			`HashMap.FromTable({bad.kind}) 사용자 줄: {err}`
		)
	end
	-- (3) `Heap` 의 생성자도 비교자를 확인 — 빈 힙에서는 비교가 일어나지 않아 엉뚱한 값이 통과하고 둘째 `Push` 에서
	--     라이브러리 줄(`Trees/CompleteArray`)의 `attempt to call a nil value` 였습니다(트리 계열의 생성자와 같은 모양).
	for _, bad in { "less" :: any, 5 :: any, {} :: any } do
		const okNew, errNew = pcall(function()
			where = debug.info(1, "l") + 1
			stl.Heap.New(bad)
		end)
		assert(
			not okNew and string.find(tostring(errNew), "Heap: New needs a comparator function, got", 1, true),
			`Heap.New: {errNew}`
		)
		assert(
			string.find(tostring(errNew), `spec.contracts.luau:{where}:`, 1, true),
			`Heap.New 사용자 줄: {errNew}`
		)
		const okList, errList = pcall(function()
			where = debug.info(1, "l") + 1
			stl.Heap.FromList({ 30, 10, 20 }, bad)
		end)
		assert(
			not okList and string.find(tostring(errList), "Heap: FromList needs a comparator function, got", 1, true),
			`Heap.FromList: {errList}`
		)
		assert(
			string.find(tostring(errList), `spec.contracts.luau:{where}:`, 1, true),
			`Heap.FromList 사용자 줄: {errList}`
		)
	end
	const okNil, errNil = pcall(function()
		where = debug.info(1, "l") + 1
		stl.Heap.New(nil :: any)
	end)
	assert(
		not okNil and string.find(tostring(errNil), "Heap: New needs a comparator function, got nil", 1, true),
		`Heap.New(nil): {errNil}`
	)
	assert(
		string.find(tostring(errNil), `spec.contracts.luau:{where}:`, 1, true),
		`Heap.New(nil) 사용자 줄: {errNil}`
	)
	const okEmpty, errEmpty = pcall(function()
		where = debug.info(1, "l") + 1
		stl.Heap.FromList({}, nil :: any)
	end)
	assert(
		not okEmpty and string.find(tostring(errEmpty), "Heap: FromList needs a comparator function, got nil", 1, true),
		`빈 목록의 FromList: {errEmpty}`
	)
	assert(
		string.find(tostring(errEmpty), `spec.contracts.luau:{where}:`, 1, true),
		`빈 목록의 FromList 사용자 줄: {errEmpty}`
	)
end
print("PASS")

print(
	"=== 18. 트레이트에는 넘길 것만 든 표 — 모르는 이름은 에러 (2026-10-13 사용자 결정, 질문 AS) ==="
)
do
	const T = stl.Trait
	local where = 0
	-- (1) 모듈 테이블을 통째로 넘기면 에러(사용자 줄) — 예전엔 같은 이름이 전부 그 트레이트의 구현이 됐습니다
	const wholeSites: { { name: string, trait: any, module: any } } = {
		{ name = "List", trait = stl.List, module = stl.Arr },
		{ name = "Map", trait = stl.Map, module = stl.HashMap },
		{ name = "Set", trait = stl.Set, module = stl.TreeSet },
		{ name = "Collection", trait = stl.Collection, module = stl.Heap },
		{ name = "Deque", trait = stl.Deque, module = stl.LinkedDeque },
	}
	for _, site in wholeSites do
		const token = T.NewToken("Whole" .. site.name)
		const ok, err = pcall(function()
			where = debug.info(1, "l") + 1
			T.Impl(site.trait, token, site.module)
		end)
		assert(
			not ok
				and string.find(tostring(err), `Trait: Whole{site.name} gave `, 1, true)
				and string.find(tostring(err), ` to {site.name}, which {site.name} does not have`, 1, true),
			`통째 등록 {site.name}: {err}`
		)
		assert(
			string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true),
			`통째 등록 {site.name} 사용자 줄: {err}`
		)
		assert(
			T.ImplOf(site.trait, { __type = token }) == nil,
			`통째 등록 {site.name}: 실패했는데 등록이 남음`
		)
	end
	-- 이름 하나가 더 든 표, 문자열이 아닌 키
	for _, bad in
		{
			{ Len = stl.Arr.Len, Clear = stl.Arr.Clear, Size = stl.Arr.Len } :: any,
			{ Len = stl.Arr.Len, Clear = stl.Arr.Clear, [1] = print } :: any,
		}
	do
		const ok, err = pcall(function()
			where = debug.info(1, "l") + 1
			T.Impl(stl.Collection, T.NewToken("OneMore"), bad)
		end)
		assert(
			not ok and string.find(tostring(err), "to Collection, which Collection does not have", 1, true),
			`하나 더: {err}`
		)
		assert(string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true), `하나 더 사용자 줄: {err}`)
	end

	-- (2) ⭐ 두 트레이트에 같은 이름(`Test`)이 있고 한 종류가 둘 다 구현: 표를 따로 넘기니 **각자의 `Test`** 를 받음
	--     (통째로 넘기던 때는 모듈의 `Test` 하나가 두 트레이트에 다 먹었음 — 사용자가 물은 그 경우)
	type Tester = { read Test: (v: any) -> string }
	const TraitA = T.New<<Tester>>("TraitA", { required = { "Test" } })
	const TraitB = T.New<<Tester>>("TraitB", { required = { "Test" } })
	const StrA = T.NewToken("StrA")
	T.Impl(TraitA, StrA, {
		Test = function(_v: any): string
			return "A 의 Test"
		end,
	})
	T.Impl(TraitB, StrA, {
		Test = function(_v: any): string
			return "B 의 Test"
		end,
	})
	const strA = { __type = StrA }
	assert((T.ImplOf(TraitA, strA) :: Tester).Test(strA) == "A 의 Test", "TraitA 는 자기 Test")
	assert((T.ImplOf(TraitB, strA) :: Tester).Test(strA) == "B 의 Test", "TraitB 는 자기 Test")

	-- (3) 모듈에 **뜻이 다른 같은 이름**이 있어도 등록 표에 안 넣으면 기본 구현이 그대로: 값으로 찾는 `Find`,
	--     술어 없이 전부 세는 `Count`(진입점에 위임 — 통째 등록이면 무한 재귀였음)
	const BagToken = T.NewToken("Bag")
	const BagModule: any = {
		Get = function(bag: any, idx: number): any
			return bag.items[idx]
		end,
		FirstIndex = function(bag: any): number?
			return if #bag.items > 0 then 1 else nil
		end,
		LastIndex = function(bag: any): number?
			return if #bag.items > 0 then #bag.items else nil
		end,
		NextIndex = function(bag: any, idx: number): number?
			return if idx < #bag.items then idx + 1 else nil
		end,
		PrevIndex = function(_bag: any, idx: number): number?
			return if idx > 1 then idx - 1 else nil
		end,
		-- 뜻이 다름: **값**을 받아 그 위치를 돌려줌(트레이트의 `Find` 는 술어를 받아 원소와 위치)
		Find = function(bag: any, value: any): number?
			return table.find(bag.items, value)
		end,
		-- 진입점에 위임: 전부 셈
		Count = function(bag: any): number
			return stl.List.Count(bag, function(): boolean
				return true
			end)
		end,
	}
	T.Impl(stl.List, BagToken, {
		Get = BagModule.Get,
		FirstIndex = BagModule.FirstIndex,
		LastIndex = BagModule.LastIndex,
		NextIndex = BagModule.NextIndex,
		PrevIndex = BagModule.PrevIndex,
	})
	const bag = { __type = BagToken, items = { 10, 20, 30, 20 } }
	const found, at = stl.List.Find(bag :: any, function(item: number): boolean
		return item > 15
	end)
	assert(found == 20 and at == 2, `트레이트의 Find 는 기본 구현(술어): {found}, {at}`)
	assert(BagModule.Find(bag, 30) == 3, "모듈의 Find 는 모듈의 뜻(값) 그대로")
	assert(
		BagModule.Count(bag) == 4,
		"진입점에 위임하는 같은 이름 함수가 자기 자신으로 돌아오지 않음"
	)
	assert(stl.List.Count(bag :: any, function(item: number): boolean
		return item == 20
	end) == 2, "트레이트의 Count 는 기본 구현")
end
print("PASS")

print(
	"=== 19. 4라운드 리뷰(2026-10-14) — 등록 표의 배선 전수, 함수가 아닌 재정의, Stack·Queue 의 진입점 ==="
)
do
	const T = stl.Trait
	local where = 0
	-- (1) ⭐ 등록 표의 배선을 전수로: 표를 손으로 적으니 `Remove = …Has` 같은 복붙 실수가 가능하고 서명이 같아 타입도
	--     못 잡습니다(리뷰가 16가지를 통과시킴). 이름마다 **그 모듈의 그 이름의 함수**인지, 남는 키가 없는지.
	const listCore = { "Get", "FirstIndex", "LastIndex", "NextIndex", "PrevIndex" }
	const listDefaults = { "Fold", "Find", "IndexOf", "Contains", "Count", "Some", "Every" }
	const mapNames = { "Get", "Set", "Has", "Remove", "Iter" }
	const setNames = { "Add", "Has", "Remove", "Items" }
	const collectionNames = { "Len", "Clear" }
	const dequeNames = { "PushFront", "PushBack", "PopFront", "PopBack", "Front", "Back" }
	type Wiring = { kind: string, trait: any, own: { string }, filled: { string }? }
	const wirings: { Wiring } = {
		{
			kind = "Arr",
			trait = stl.List,
			own = table.move(listDefaults, 1, #listDefaults, #listCore + 1, table.clone(listCore)),
		},
		{ kind = "Arr", trait = stl.Collection, own = collectionNames },
		{ kind = "CircularDeque", trait = stl.List, own = listCore, filled = listDefaults },
		{ kind = "CircularDeque", trait = stl.Deque, own = dequeNames },
		{ kind = "CircularDeque", trait = stl.Collection, own = collectionNames },
		{ kind = "LinkedDeque", trait = stl.List, own = listCore, filled = listDefaults },
		{ kind = "LinkedDeque", trait = stl.Deque, own = dequeNames },
		{ kind = "LinkedDeque", trait = stl.Collection, own = collectionNames },
		{ kind = "HashMap", trait = stl.Map, own = mapNames },
		{ kind = "HashMap", trait = stl.Collection, own = collectionNames },
		{ kind = "TreeMap", trait = stl.Map, own = mapNames },
		{ kind = "TreeMap", trait = stl.Collection, own = collectionNames },
		{ kind = "FlatMap", trait = stl.Map, own = mapNames },
		{ kind = "FlatMap", trait = stl.Collection, own = collectionNames },
		{ kind = "HashSet", trait = stl.Set, own = setNames },
		{ kind = "HashSet", trait = stl.Collection, own = collectionNames },
		{ kind = "TreeSet", trait = stl.Set, own = setNames },
		{ kind = "TreeSet", trait = stl.Collection, own = collectionNames },
		{ kind = "FlatSet", trait = stl.Set, own = setNames },
		{ kind = "FlatSet", trait = stl.Collection, own = collectionNames },
		{ kind = "Heap", trait = stl.Collection, own = collectionNames },
	}
	for _, wiring in wirings do
		const module = (stl :: any)[wiring.kind]
		const impl = wiring.trait.impls[module.Token]
		const label = `{wiring.kind} 의 {wiring.trait.name}`
		assert(impl ~= nil, `{label}: 등록이 없음`)
		local expected = 0
		for _, fnName in wiring.own do
			expected += 1
			assert(type(module[fnName]) == "function", `{label}: 모듈에 {fnName} 이 없음`)
			assert(rawequal(impl[fnName], module[fnName]), `{label}: {fnName} 이 {wiring.kind}.{fnName} 이 아님`)
		end
		for _, fnName in wiring.filled or {} do
			expected += 1
			assert(type(impl[fnName]) == "function", `{label}: 기본 구현 {fnName} 이 없음`)
			assert(not rawequal(impl[fnName], module[fnName]), `{label}: {fnName} 이 목록에 없는 재정의`)
		end
		local keys = 0
		for _ in impl do
			keys += 1
		end
		assert(keys == expected, `{label}: 키 {keys}개, 기대 {expected}`)
	end
	-- 셋 트레이트는 진입점이 없어 표를 직접 부르는 코드가 유일한 사용처 — 표로 불러 동작까지 확인
	const setMakers: { () -> any } = {
		function(): any
			return stl.HashSet.New()
		end,
		function(): any
			return stl.TreeSet.New(Common.compareNumber)
		end,
		function(): any
			return stl.FlatSet.New(Common.compareNumber)
		end,
	}
	for _, make in setMakers do
		const set = make()
		const ops: any = T.ImplOf(stl.Set, set)
		assert(ops.Add(set, 10) == true and ops.Add(set, 10) == false and ops.Add(set, 20) == true, "Set.Add")
		assert(ops.Has(set, 10) == true and ops.Has(set, 30) == false, "Set.Has")
		assert(ops.Remove(set, 10) == true and ops.Remove(set, 10) == false and ops.Has(set, 10) == false, "Set.Remove")
		assert(#ops.Items(set) == 1 and ops.Items(set)[1] == 20, "Set.Items")
	end
	-- 맵의 `Remove`·`Has` 도 표로(진입점은 `Iter` 만 씀)
	const mapMakers: { () -> any } = {
		function(): any
			return stl.HashMap.New()
		end,
		function(): any
			return stl.TreeMap.New(Common.compareNumber)
		end,
		function(): any
			return stl.FlatMap.New(Common.compareNumber)
		end,
	}
	for _, make in mapMakers do
		const map = make()
		const ops: any = T.ImplOf(stl.Map, map)
		ops.Set(map, 10, "a")
		ops.Set(map, 20, "b")
		assert(ops.Has(map, 10) == true and ops.Has(map, 30) == false and ops.Get(map, 20) == "b", "Map.Has·Get")
		assert(ops.Remove(map, 10) == "a" and ops.Has(map, 10) == false and ops.Remove(map, 10) == nil, "Map.Remove")
	end
	-- 리스트의 뒤로 가는 프리미티브(진입점의 알고리즘은 앞으로만 감)
	for _, list in
		{
			stl.Arr.Of(10, 20, 30) :: any,
			stl.CircularDeque.Of(10, 20, 30) :: any,
			stl.LinkedDeque.Of(10, 20, 30) :: any,
		}
	do
		const ops: any = T.ImplOf(stl.List, list)
		const first, last = ops.FirstIndex(list), ops.LastIndex(list)
		assert(ops.Get(list, first) == 10 and ops.Get(list, last) == 30, "FirstIndex·LastIndex")
		assert(
			ops.Get(list, ops.NextIndex(list, first)) == 20 and ops.Get(list, ops.PrevIndex(list, last)) == 20,
			"NextIndex·PrevIndex"
		)
		assert(ops.PrevIndex(list, first) == nil and ops.NextIndex(list, last) == nil, "끝에서의 Prev·Next")
	end

	-- (2) 재정의 자리에 함수가 아닌 값 — 등록 때 사용자 줄 에러(예전엔 등록은 통과하고 부를 때 라이브러리 줄에서 죽음)
	const Widget = T.NewToken("Widget")
	T.Impl(
		stl.Deque,
		Widget,
		{
			PushFront = print,
			PushBack = print,
			PopFront = print,
			PopBack = print,
			Front = print,
			Back = print,
		} :: any
	)
	assert(T.Implements(stl.Stack, { __type = Widget }), "Widget 은 덱이라 스택이 따라옴")
	const okDerived, errDerived = pcall(function()
		where = debug.info(1, "l") + 1
		T.Impl(stl.Stack, Widget, { Push = 5 } :: any)
	end)
	assert(
		not okDerived
			and string.find(
				tostring(errDerived),
				"Trait: Widget gave a number as Push for Stack — it must be a function",
				1,
				true
			),
		`저절로 따라온 표 위의 함수 아닌 재정의: {errDerived}`
	)
	assert(string.find(tostring(errDerived), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {errDerived}`)
	assert((stl.Stack :: any).derived[Widget], "실패한 재정의는 저절로 따라온 상태를 바꾸지 않음")
	const Gadget = T.NewToken("Gadget")
	const okMerge, errMerge = pcall(function()
		where = debug.info(1, "l") + 1
		T.Impl(
			stl.List,
			Gadget,
			{
				Get = print,
				FirstIndex = print,
				LastIndex = print,
				NextIndex = print,
				PrevIndex = print,
				Fold = "fold",
			} :: any
		)
	end)
	assert(
		not okMerge
			and string.find(
				tostring(errMerge),
				"Trait: Gadget gave a string as Fold for List — it must be a function",
				1,
				true
			),
		`기본 구현 있는 트레이트의 함수 아닌 재정의: {errMerge}`
	)
	assert(string.find(tostring(errMerge), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {errMerge}`)
	assert(T.ImplOf(stl.List, { __type = Gadget }) == nil, "실패한 등록은 남지 않음")
	-- 물려받은(`__index` 사슬) 재정의도 함수여야 함(5라운드 리뷰 — 자기 키만 봐서, 물려받은 `Fold = 5` 는 등록을
	-- 통과하고 부를 때 라이브러리 줄에서 죽었음). 필수 이름은 원래 물려받은 것까지 봤습니다.
	const Heir = T.NewToken("Heir")
	const okHeir, errHeir = pcall(function()
		where = debug.info(1, "l") + 1
		T.Impl(
			stl.List,
			Heir,
			setmetatable({
				Get = print,
				FirstIndex = print,
				LastIndex = print,
				NextIndex = print,
				PrevIndex = print,
			}, { __index = { Fold = 5 } }) :: any
		)
	end)
	assert(
		not okHeir
			and string.find(
				tostring(errHeir),
				"Trait: Heir gave a number as Fold for List — it must be a function",
				1,
				true
			),
		`물려받은 함수 아닌 재정의: {errHeir}`
	)
	assert(string.find(tostring(errHeir), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {errHeir}`)
	assert(T.ImplOf(stl.List, { __type = Heir }) == nil, "실패한 등록은 남지 않음(물려받은 것)")
	const okHeirStack, errHeirStack = pcall(function()
		where = debug.info(1, "l") + 1
		T.Impl(stl.Stack, Widget, setmetatable({}, { __index = { Pop = "pop" } }) :: any)
	end)
	assert(
		not okHeirStack
			and string.find(
				tostring(errHeirStack),
				"Trait: Widget gave a string as Pop for Stack — it must be a function",
				1,
				true
			),
		`저절로 따라온 표 위의 물려받은 함수 아닌 재정의: {errHeirStack}`
	)
	assert(
		string.find(tostring(errHeirStack), `spec.contracts.luau:{where}:`, 1, true),
		`사용자 줄: {errHeirStack}`
	)
	assert(
		(stl.Stack :: any).derived[Widget],
		"실패한 재정의는 저절로 따라온 상태를 바꾸지 않음(물려받은 것)"
	)
	-- 멀쩡한 물려받은 재정의와 함수 아닌 것이 **섞인** 표: 실패하면 멀쩡한 것도 적용되지 않음(6라운드 리뷰 —
	-- "확인하고 바로 적용" 으로 두 루프를 합치는 실수가 통과했음). 틀린 이름을 셋으로 돌려 순회 순서에 기대지 않게.
	const stackBefore: any = T.ImplOf(stl.Stack, { __type = Widget })
	const pushBefore, popBefore, peekBefore = stackBefore.Push, stackBefore.Pop, stackBefore.Peek
	for _, wrong in { "Push", "Pop", "Peek" } do
		const inherited: any = { Push = print, Pop = print, Peek = print }
		inherited[wrong] = "not a function"
		const okMixed, errMixed = pcall(function()
			T.Impl(stl.Stack, Widget, setmetatable({}, { __index = inherited }) :: any)
		end)
		assert(
			not okMixed and string.find(tostring(errMixed), `gave a string as {wrong} for Stack`, 1, true),
			`섞인 표({wrong}): {errMixed}`
		)
		const stackAfter: any = T.ImplOf(stl.Stack, { __type = Widget })
		assert(
			stackAfter == stackBefore
				and stackAfter.Push == pushBefore
				and stackAfter.Pop == popBefore
				and stackAfter.Peek == peekBefore,
			`섞인 표({wrong}): 실패한 등록이 일부를 적용함`
		)
	end

	-- (3) Stack·Queue 의 진입점 여섯: 에러 메시지의 진입점 이름, `Push` 는 재정의가 무엇을 돌려주든 넣은 것을 돌려줌
	const entries: { { trait: string, name: string, call: (v: any) -> any } } = {
		{
			trait = "Stack",
			name = "Push",
			call = function(v)
				where = debug.info(1, "l") + 1
				return stl.Stack.Push(v, 1)
			end,
		},
		{
			trait = "Stack",
			name = "Pop",
			call = function(v)
				where = debug.info(1, "l") + 1
				return stl.Stack.Pop(v)
			end,
		},
		{
			trait = "Stack",
			name = "Peek",
			call = function(v)
				where = debug.info(1, "l") + 1
				return stl.Stack.Peek(v)
			end,
		},
		{
			trait = "Queue",
			name = "Push",
			call = function(v)
				where = debug.info(1, "l") + 1
				return stl.Queue.Push(v, 1)
			end,
		},
		{
			trait = "Queue",
			name = "Pop",
			call = function(v)
				where = debug.info(1, "l") + 1
				return stl.Queue.Pop(v)
			end,
		},
		{
			trait = "Queue",
			name = "Peek",
			call = function(v)
				where = debug.info(1, "l") + 1
				return stl.Queue.Peek(v)
			end,
		},
	}
	for _, entry in entries do
		const ok, err = pcall(entry.call, stl.Arr.Of(1))
		assert(
			not ok
				and string.find(
					tostring(err),
					`{entry.trait}: {entry.name} needs a {entry.trait} — Arr does not implement {entry.trait}`,
					1,
					true
				),
			`{entry.trait}.{entry.name}: {err}`
		)
		assert(
			string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true),
			`{entry.trait}.{entry.name} 사용자 줄: {err}`
		)
	end
	for _, trait in { stl.Stack :: any, stl.Queue :: any } do
		const Silent = T.NewToken("Silent" .. trait.name)
		T.Impl(
			stl.Deque,
			Silent,
			{
				PushFront = print,
				PushBack = print,
				PopFront = print,
				PopBack = print,
				Front = print,
				Back = print,
			} :: any
		)
		local pushed = 0
		T.Impl(
			trait,
			Silent,
			{
				Push = function(_self: any, _item: any)
					pushed += 1 -- `return self` 를 빠뜨린 재정의
				end,
			} :: any
		)
		const value = { __type = Silent }
		assert(trait.Push(value, 1) == value and pushed == 1, `{trait.name}.Push 는 넣은 것을 돌려줌`)
	end

	-- (4) `CompleteNode.IsHeap` 은 받은 부분 트리 **안에서만** — 가운데 노드를 넘기면 그 위의 부모와는 견주지 않음
	const Binary, Complete = stl.Node.Binary, stl.CompleteNode
	local function lessNumber(a: number, b: number): boolean
		return a < b
	end
	const top, low, leaf = Binary.New(50), Binary.New(10), Binary.New(20)
	local root = Complete.Append(nil, 0, top)
	root = Complete.Append(root, 1, low)
	root = Complete.Append(root, 2, Binary.New(60))
	root = Complete.Append(root, 3, leaf)
	assert(not Complete.IsHeap(root, lessNumber), "전체는 힙 순서가 아님(10 이 50 밑)")
	assert(
		Complete.IsHeap(low, lessNumber),
		"가운데 노드의 부분 트리(10 → 20)는 힙 순서 — 위의 50 과는 견주지 않음"
	)
	assert(Complete.IsHeap(leaf, lessNumber), "잎 하나")
end
print("PASS")

print()
print("=== ALL PASS (계약) ===")

return true

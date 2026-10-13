--!strict
--[[
	계약 테스트 — **구현을 모르는 코드가 정말 돌아가는가.**

	`Types` 의 계약 셋(`ListOps` / `MapOps` / `SetOps`)은 **함수 묶음**입니다
	(2026-10-01, 질문 AB). 컨테이너는 메타테이블 없는 평범한 테이블이라 메소드가
	없고, 디스패치는 **구현 함수 묶음을 컨테이너와 같이 넘기는** 모양입니다 —
	모듈 테이블이 그대로 구현체입니다(`exerciseMap(stl.HashMap, m, …)`).

	⭐ 여기서 가장 중요한 것은 **런타임이 아니라 타입**입니다. 이 파일이
	`--!strict` 로 진단 0건이라는 사실 자체가 "계약이 정말 섰다" 는 증거입니다.
	같은 함수에 `HashMap` 과 `TreeMap` 을 넣었을 때 타입 에러가 나면 계약이
	선 게 아닙니다.
]]
local stl = require("../src")
local Types = require("../src/Types")
local Common = stl.Common

type ListOps<C, E, I> = Types.ListOps<C, E, I>
type MapOps<C, K, V> = Types.MapOps<C, K, V>
type SetOps<C, T> = Types.SetOps<C, T>

--[[ 계약만 아는 함수들. 어떤 구현이 오는지 전혀 모릅니다. ]]

-- 순차 컨테이너: 위치 타입 `I` 가 무엇인지도 모른 채 순회합니다.
local function sumThroughContract<C, I>(ops: ListOps<C, number, I>, list: C): number
	local total = 0
	local idx = ops.FirstIndex(list)
	while idx ~= nil do
		total += ops.Get(list, idx) :: number
		idx = ops.NextIndex(list, idx)
	end
	return total
end

-- 맵: 넣고 빼고 세어봅니다.
local function fillAndCount<C, V>(ops: MapOps<C, string, V>, map: C, value: V): number
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
local function exerciseSet<C, T>(ops: SetOps<C, T>, set: C, a: T, b: T): string
	local added = ops.Add(set, a)
	local again = ops.Add(set, a)
	ops.Add(set, b)
	local hasA = ops.Has(set, a)
	local removed = ops.Remove(set, a)
	local hasAfter = ops.Has(set, a)
	return `{added},{again},{hasA},{removed},{hasAfter},{#ops.Items(set)}`
end

print("=== 1. ListOps — Arr 가 만족하는가 ===")
do
	const a = stl.Arr.Of(10, 20, 30)
	assert(sumThroughContract(stl.Arr, a) == 60, "계약을 통한 합")
	assert(sumThroughContract(stl.Arr, stl.Arr.Of<<number>>()) == 0, "빈 것")
	-- 공용 알고리즘도 계약만 압니다
	assert(stl.Algorithm.IndexOf(a, 20) == 2, "Algorithm.IndexOf")
	assert(stl.Algorithm.Count(a) == 3, "Algorithm.Count")
end
print("PASS")

print("=== 2. ⭐ MapOps — HashMap 과 TreeMap 을 바꿔 끼울 수 있는가 ===")
do
	-- **같은 함수**에 두 구현을 넣습니다. 타입이 갈리면 여기서 진단이 납니다.
	type H = stl.HashMap<string, number>
	type T = stl.TreeMap<string, number>
	const hash = stl.HashMap.New<<string, number>>()
	const tree = stl.TreeMap.New<<string, number>>(Common.compareString)

	-- ⚠️ 계약을 받는 함수는 **타입 인자를 알려줍니다** — 원소 타입을 함수 묶음
	-- (제네릭 함수들)에서도 끌어오며 `unknown` 이 섞입니다(typing-limits).
	assert(fillAndCount<<H, number>>(stl.HashMap, hash, 1) == 2, "HashMap 을 계약으로")
	assert(fillAndCount<<T, number>>(stl.TreeMap, tree, 1) == 2, "TreeMap 을 계약으로")
	assert(stl.HashMap.Len(hash) == stl.TreeMap.Len(tree), "둘의 크기가 같아야 합니다")

	-- 공용 알고리즘도 양쪽에서 같아야 합니다
	assert(#stl.Algorithm.Keys(hash) == #stl.Algorithm.Keys(tree), "Algorithm.Keys")
	assert(#stl.Algorithm.Values(hash) == #stl.Algorithm.Values(tree), "Algorithm.Values")

	-- 계약 자리에 모듈을 담아 두고 나중에 쓰는 것도 돼야 합니다
	const hashOps: MapOps<H, string, number> = stl.HashMap
	const treeOps: MapOps<T, string, number> = stl.TreeMap
	assert(
		hashOps.Get(hash, "하나") == 1 and treeOps.Get(tree, "하나") == 1,
		"계약 자리에 담긴 뒤에도 동작"
	)
end
print("PASS")

print("=== 3. ⭐ SetOps — HashSet 과 TreeSet 을 바꿔 끼울 수 있는가 ===")
do
	const hash = stl.HashSet.New<<number>>()
	const tree = stl.TreeSet.New<<number>>(Common.compareNumber)

	const hashResult = exerciseSet<<stl.HashSet<number>, number>>(stl.HashSet, hash, 10, 20)
	const treeResult = exerciseSet<<stl.TreeSet<number>, number>>(stl.TreeSet, tree, 10, 20)
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
		{ name = "Deque", instance = stl.Deque.Of(1), is = stl.isDeque },
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
	const Arr, HashMap, HashSet, TreeMap, TreeSet, Heap, Fut =
		stl.Arr, stl.HashMap, stl.HashSet, stl.TreeMap, stl.TreeSet, stl.Heap, stl.Fut
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
		FromTable = Arr.FromTable({ 1, 2 }),
		CloneFromTable = Arr.CloneFromTable({ 1, 2 }),
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
		GroupByInner = stl.HashMap.Get(Arr.GroupBy(a(), id), 30),
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
		GroupBy = Arr.GroupBy(a(), id),
		CountBy = Arr.CountBy(a(), id),
		KeyBy = Arr.KeyBy(a(), id),
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

	const tm = TreeMap.New<<number, number>>(Common.compareNumber)
	const treeMapResults: { [string]: any } = {
		New = tm,
		FromRecords = TreeMap.FromRecords({ { key = 1, value = 1 } }, Common.compareNumber),
		Adopt = TreeMap.Adopt({ { key = 1, value = 1 } }, 1, Common.compareNumber),
		Clone = TreeMap.Clone(tm),
		Clear = TreeMap.Clear(TreeMap.Clone(tm)),
	}
	for name, result in treeMapResults do
		assert(stl.isTreeMap(result), `TreeMap.{name} 결과에 태그가 없습니다`)
	end

	const ts = TreeSet.FromList({ 1, 2 }, Common.compareNumber)
	const treeSetResults: { [string]: any } = {
		New = TreeSet.New<<number>>(Common.compareNumber),
		FromList = ts,
		Clone = TreeSet.Clone(ts),
		Clear = TreeSet.Clear(TreeSet.Clone(ts)),
		Union = TreeSet.Union(ts, ts),
		Intersect = TreeSet.Intersect(ts, ts),
		Difference = TreeSet.Difference(ts, ts),
		SymmetricDifference = TreeSet.SymmetricDifference(ts, ts),
	}
	for name, result in treeSetResults do
		assert(stl.isTreeSet(result), `TreeSet.{name} 결과에 태그가 없습니다`)
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

	-- Deque(M5, 2026-10-07)
	const dq = stl.Deque.Of(1, 2)
	const dequeResults: { [string]: any } = {
		New = stl.Deque.New<<number>>(),
		NewCapacity = stl.Deque.New<<number>>(10),
		FromList = stl.Deque.FromList({ 1, 2 }),
		Of = dq,
		Clone = stl.Deque.Clone(dq),
		Clear = stl.Deque.Clear(stl.Deque.Of(1)),
		PushBack = stl.Deque.PushBack(stl.Deque.Of(1), 2),
		PushFront = stl.Deque.PushFront(stl.Deque.Of(1), 2),
	}
	for name, result in dequeResults do
		assert(stl.isDeque(result), `Deque.{name} 결과에 태그가 없습니다`)
		assert(getmetatable(result) == nil, `Deque.{name} 결과에 메타테이블이 있습니다`)
	end
	assert(stl.isArr(stl.Deque.ToArr(dq)), "Deque.ToArr 는 Arr")

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
		{ name = "Arr", is = stl.isArr, token = stl.Trait.Types.Arr },
		{ name = "HashMap", is = stl.isHashMap, token = stl.Trait.Types.HashMap },
		{ name = "HashSet", is = stl.isHashSet, token = stl.Trait.Types.HashSet },
		{ name = "TreeMap", is = stl.isTreeMap, token = stl.Trait.Types.TreeMap },
		{ name = "TreeSet", is = stl.isTreeSet, token = stl.Trait.Types.TreeSet },
		{ name = "Heap", is = stl.isHeap, token = stl.Trait.Types.Heap },
		{ name = "Fut", is = stl.isFut, token = stl.Trait.Types.Fut },
		{ name = "Deque", is = stl.isDeque, token = stl.Trait.Types.Deque },
	}
	const oldTags =
		{ "__arr__", "__hashmap__", "__hashset__", "__treemap__", "__treeset__", "__heap__", "__fut__", "__deque__" }
	for idx, case in predicates do
		-- 테이블이 아닌 것·토큰 없는 것·옛 문자열 태그·이름만 같은 다른 토큰은 아님
		for _, v in { nil, 1, "x", true, {}, { n = 0 }, { [oldTags[idx]] = true } } :: { any } do
			assert(not case.is(v), `{case.name}: {typeof(v)} 를 받아들임`)
		end
		assert(not case.is({ __type = stl.Trait.NewType(case.name) }), `{case.name}: 이름만 같은 토큰`)
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
	stl.Trait.Impl(ShowTrait, stl.Trait.Types.Arr, {
		Show = function(a: any): string
			return `Arr({a.n})`
		end,
	})
	const showArr = stl.Trait.ImplOf(ShowTrait, stl.Arr.Of(1, 2))
	assert(showArr ~= nil and showArr.Show(stl.Arr.Of(1, 2)) == "Arr(2)", "사용자 트레이트를 Arr 에")
	assert(stl.Trait.ImplOf(stl.Trait.List, stl.Arr.Of(1)) == stl.Arr, "Arr 은 List 도 그대로")
	assert(stl.Trait.ImplOf(ShowTrait, stl.HashMap.New()) == nil, "등록 안 한 종류는 nil")
	for _, v in { nil, 1, "x", {} } :: { any } do
		assert(stl.Trait.ImplOf(ShowTrait, v) == nil, `{typeof(v)} 는 안전하게 nil`)
		assert(stl.Trait.Implements(ShowTrait, v) == false, `{typeof(v)} 는 안전하게 false(Implements)`)
	end
	-- Count: 술어 없으면 전체, 있으면 참인 것만(AE) — Arr 와 Algorithm 이 같은 뜻
	const counted = stl.Arr.Of(1, 2, 3, 4)
	const isEven = function(v: number): boolean
		return v % 2 == 0
	end
	assert(stl.Arr.Count(counted) == 4 and stl.Algorithm.Count(counted) == 4, "Count 전체")
	assert(stl.Arr.Count(counted, isEven) == 2 and stl.Algorithm.Count(counted, isEven) == 2, "Count 술어")
	-- (8라운드) 값과 위치가 다르고 참·거짓이 반반이 아닌 데이터 — 조건을 뒤집거나 위치를 넘기는
	-- 실수가 위 데이터로는 같은 답이었음
	const tens = stl.Arr.Of(10, 20, 30)
	const over15 = function(v: number): boolean
		return v > 15
	end
	assert(stl.Algorithm.Count(tens, over15) == 2 and stl.Arr.Count(tens, over15) == 2, "Count 술어(값 ≠ 위치)")
	-- IndexOf 는 **처음** 위치 — 중복과 구멍(8라운드: 마지막 위치를 돌려줘도 통과했음)
	assert(stl.Algorithm.IndexOf(stl.Arr.Of(10, 20, 20), 20) == 2, "IndexOf 중복은 처음")
	assert(stl.Algorithm.IndexOf(stl.Arr.Of<<number?>>(10, nil, 30, nil), nil) == 2, "IndexOf 첫 구멍")
	-- Fut.All 에 Fut 이 아닌 원소 → 던지지 않고 Rejected(8라운드 참고: 라이브러리 줄에서 던질 수 있었음)
	assert(stl.Fut.Status(stl.Fut.All({ stl.Fut.Resolved(1), 2 :: any })) == "Rejected", "All 의 Fut 아닌 원소")
	-- 술어 없는 Count 는 **구멍도 자리로** 셉니다(7라운드 — "nil 아닌 것만" 으로 잘못 세도 통과했음)
	for _, holed in { stl.Arr.Of<<number?>>(1, nil, 3), stl.Arr.Sized<<number?>>(3, nil) } :: { any } do
		assert(
			stl.Arr.Count(holed) == holed.n and stl.Algorithm.Count(holed) == holed.n,
			`구멍 든 Count: n={holed.n}`
		)
	end
	-- ⭐ 내장 종류 × 내장 트레이트 전수(리뷰 1라운드 — Set 등록을 빼도 아무것도 안 잡혔음)
	const T = stl.Trait
	const samples: { { name: string, value: any, list: any, map: any, set: any } } = {
		{ name = "Arr", value = stl.Arr.Of(1), list = stl.Arr, map = nil, set = nil },
		{ name = "HashMap", value = stl.HashMap.New(), list = nil, map = stl.HashMap, set = nil },
		{ name = "TreeMap", value = stl.TreeMap.New(Common.compareNumber), list = nil, map = stl.TreeMap, set = nil },
		{ name = "HashSet", value = stl.HashSet.New(), list = nil, map = nil, set = stl.HashSet },
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
		{ name = "Deque", value = stl.Deque.Of(1), list = stl.Deque, map = nil, set = nil },
	}
	for _, case in samples do
		assert(T.ImplOf(T.List, case.value) == case.list, `{case.name} 의 List 구현`)
		assert(T.ImplOf(T.Map, case.value) == case.map, `{case.name} 의 Map 구현`)
		assert(T.ImplOf(T.Set, case.value) == case.set, `{case.name} 의 Set 구현`)
		assert(T.Implements(T.List, case.value) == (case.list ~= nil), `{case.name} Implements List`)
		assert(T.TokenOf(case.value) == (T.Types :: any)[case.name], `{case.name} 의 TokenOf`)
	end
	-- TokenOf 는 토큰이 아닌 `__type`(숫자·문자열·아무 테이블)을 토큰으로 돌려주지 않음
	for _, bogus in { 5, true, "Player", 0 / 0, {}, table.freeze({ name = "Arr" }) } :: { any } do
		assert(T.TokenOf({ __type = bogus }) == nil, `토큰 아닌 __type: {tostring(bogus)}`)
	end
	-- Stamp 로 사용자 값에 토큰
	const MyKind = T.NewType("MyKind")
	const stamped = T.Stamp({}, MyKind)
	assert(T.TokenOf(stamped) == MyKind and not stl.isArr(stamped), "Stamp")
	-- 공용 알고리즘의 에러는 토큰 아닌 `__type` 에서도 규약대로(리뷰 1라운드 — 라이브러리 줄에서
	-- `attempt to index number with 'name'` 이었음)
	for _, bogus in { 5, true, "Player", 0 / 0 } :: { any } do
		const ok, err = pcall(function()
			stl.Algorithm.IndexOf({ __type = bogus } :: any, 1)
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
				T.Impl(T.List, table.freeze({}) :: any, stl.Arr)
			end,
		},
		{
			name = "토큰 모음 테이블",
			run = function()
				T.Impl(T.List, T.Types :: any, stl.Arr)
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
				T.NewType(nil :: any)
			end,
		},
		{
			name = "같은 토큰을 두 번(내장 덮어쓰기)",
			run = function()
				T.Impl(T.List, T.Types.Arr, {} :: any)
			end,
		},
		{
			-- 다 갖춘 구현으로도(2라운드 리뷰: 위는 `{}` 라, 중복 검사를 지워도 필수 함수 검사가 대신
			-- 걸려 통과했음 — 지운 사본에서는 가짜 구현이 Arr 의 List 구현을 덮어 IndexOf 가 틀렸음)
			name = "같은 토큰을 두 번(다 갖춘 구현)",
			needle = "Arr already implements List",
			run = function()
				T.Impl(T.List, T.Types.Arr, table.clone(stl.Arr) :: any)
			end,
		},
		{
			name = "구현이 nil",
			run = function()
				T.Impl(T.List, MyKind, nil :: any)
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
	assert(T.ImplOf(T.List, stl.Arr.Of(1)) == stl.Arr, "덮어쓰기 시도 뒤에도 내장 그대로")
	-- 리스트·사전을 받는 진입점에 **다른 종류의 컨테이너**를 넘기면 조용히 비거나(`n` 이 없어
	-- `#` 가 0) 내부 필드가 키로 쏟아졌음(Gemini 트레이트 검토 — Deque 가 들어오면 바로 남) →
	-- 사용자 줄 에러. `Arr` 은 그대로 리스트로 받습니다.
	const wrongInputs: { { name: string, run: () -> () } } = {
		{
			name = "HashSet.FromList(HashMap)",
			run = function()
				stl.HashSet.FromList(stl.HashMap.New() :: any)
			end,
		},
		{
			name = "Arr.CloneFromTable(TreeSet)",
			run = function()
				stl.Arr.CloneFromTable(stl.TreeSet.New(Common.compareNumber) :: any)
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
			stl.Algorithm.IndexOf(nil :: any, 1)
		end,
		function()
			stl.Algorithm.Keys(5 :: any)
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
		stl.Algorithm.IndexOf(stl.HashMap.New() :: any, 1)
	end)
	assert(string.find(sameCopy, "HashMap does not implement List", 1, true) ~= nil, sameCopy)
	assert(string.find(sameCopy, "another copy", 1, true) == nil, `같은 사본인데 사본 안내: {sameCopy}`)
	const otherCopy = errOf(function()
		stl.Algorithm.IndexOf({ __type = table.freeze({ name = "Arr" }) } :: any, 1)
	end)
	assert(string.find(otherCopy, "another copy", 1, true) ~= nil, `다른 사본 안내가 없음: {otherCopy}`)
	const noToken = errOf(function()
		stl.Algorithm.IndexOf({} :: any, 1)
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
		assert(stl.TreeSet.Len(stl.TreeSet.FromList(empty, Common.compareNumber)) == 0, "빈 Arr → TreeSet")
		assert(stl.Arr.CloneFromTable(empty).n == 0, "빈 Arr → CloneFromTable")
		assert(stl.Fut.Status(stl.Fut.All(empty)) == "Resolved", "빈 Arr → Fut.All")
	end
	-- (AC 리뷰) 길이 정책 [0, 2^26] — 정수지만 너무 큰 n 은 어떤 진입점도 받지 않음(예전엔 FromTable 이
	-- n = 2^27 인 Arr 를 입양하고 다른 진입점은 위치 없는 table overflow 였음)
	const huge = { n = 2 ^ 27, 1 }
	for _, run in
		{
			function()
				stl.Arr.FromTable(huge :: any)
			end,
			function()
				stl.Arr.CloneFromTable(huge :: any)
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
	assert(stl.Arr.FromTable({ n = 2 ^ 26 } :: any).n == 2 ^ 26, "길이 2^26 은 받음")
	const overCap = errOf(function()
		stl.Arr.FromTable({ n = 2 ^ 26 + 1 } :: any)
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
	const Ring = T.NewType("Ring")
	const ring = T.Stamp({ n = 3, head = 3, [1] = "c", [3] = "a", [4] = "b" }, Ring)
	const ringRuns: { () -> () } = {
		function()
			stl.HashSet.FromList(ring :: any)
		end,
		function()
			stl.Arr.CloneFromTable(ring :: any)
		end,
	}
	for _, run in ringRuns do
		const msg = errOf(run)
		assert(
			string.find(msg, "Ring", 1, true) and string.find(msg, "spec.contracts", 1, true),
			`n 있는 사용자 컨테이너: {msg}`
		)
	end
	-- (4라운드) Arr.FromTable 은 이 사본의 Arr 말고도 `__type` 이 있으면 거절(입력의 토큰을 덮어써
	-- 다른 사본에서 사라지게 하지 않음)
	const containerish: { any } = { foreignArr, ring, stl.HashSet.Of(1) }
	for _, v in containerish do
		const msg = errOf(function()
			stl.Arr.FromTable(v)
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
	-- 개수는 루프 전 기준선과 비교 — 다른 스펙·M5 의 Deque 가 List 를 구현해도 거짓 실패 없게.
	-- 기준선 전에 수거 — 앞에서 버린 등록이 남아 있으면 기준선이 부풀어 거짓 실패했음(4라운드).
	-- `collectgarbage("collect")` 는 Roblox 타입 정의에 없어 분석기가 모름 — 실행기(luau)에는 있음.
	const fullGc = (_G :: any).collectgarbage
	fullGc("collect")
	fullGc("collect")
	local before = 0
	for _ in T.List.impls do
		before += 1
	end
	-- 구현 테이블은 **인라인으로**(따로 쥐는 지역 변수 없이) — 쥐고 있으면 `"kv"` 로 잘못 써도
	-- 남아 돌연변이가 살아남았음.
	const keptToken = T.NewType("Kept")
	T.Impl(
		T.List,
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
	T.Impl(ShowKept, T.Types.Arr, {
		Show = function(_: any): string
			return "kept"
		end,
	})
	local registered = 0
	for _ = 1, 50 do
		const tok = T.NewType("Temp")
		T.Impl(T.List, tok, stl.Arr)
		registered += 1
	end
	fullGc("collect")
	fullGc("collect")
	local remaining = 0
	for _ in T.List.impls do
		remaining += 1
	end
	assert(
		remaining == before + 1,
		if remaining > before + 1
			then `버린 사용자 토큰이 남음: List 구현 {remaining}개(기준 {before} + 쥔 것 1)`
			else `쥔 등록까지 사라짐: List 구현 {remaining}개(기준 {before} + 쥔 것 1)`
	)
	const kept = T.List.impls[keptToken] :: any
	assert(kept ~= nil and kept.Get == stl.Arr.Get, "쥔 토큰의 인라인 구현은 남음")
	const shown = T.ImplOf(ShowKept, stl.Arr.Of(1))
	assert(shown ~= nil and shown.Show(stl.Arr.Of(1)) == "kept", "내장 토큰에 붙인 인라인 구현은 남음")
	-- 토큰이 아닌 것(얼지 않은 테이블)으로 Impl 하면 사용자 줄 에러
	assert(not pcall(function()
		stl.Trait.Impl(stl.Trait.List, {} :: any, stl.Arr)
	end), "토큰이 아닌 것으로 Impl")
end
print("PASS")

print("=== 7. 계약 보강 — 원소 타입 ≠ 위치 타입, Keys/Values 내용, 담아 둔 SetOps (M0 리뷰) ===")
do
	-- ListOps 의 반환 타입(I? 대 E?)은 원소와 위치가 둘 다 number 면 우연히 맞아떨어집니다
	const s = stl.Arr.Of("x", "y", "z")
	const pos: number? = stl.Algorithm.IndexOf(s, "y")
	assert(pos == 2, "문자열 배열의 IndexOf")
	const ops: ListOps<stl.Arr<string>, string, number> = stl.Arr
	assert(ops.Get(s, 3) == "z" and ops.FirstIndex(s) == 1 and ops.NextIndex(s, 1) == 2, "문자열 배열의 ListOps")

	-- Keys/Values 는 개수가 아니라 **내용**을 봅니다(키와 값을 바꿔 돌려줘도 통과했음)
	const m = stl.TreeMap.FromRecords({ { key = "b", value = 20 }, { key = "a", value = 10 } }, Common.compareString)
	type T = stl.TreeMap<string, number>
	const keys = stl.Algorithm.Keys(m)
	const values = stl.Algorithm.Values(m)
	assert(table.concat(keys, ",") == "a,b", "Algorithm.Keys 내용")
	assert(values[1] == 10 and values[2] == 20, "Algorithm.Values 내용")

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
	const MyMapType = stl.Trait.NewType("MyMap")
	const function find(m: MyMap, k: string): number?
		return table.find(m.keys, k)
	end
	const myOps: MapOps<MyMap, string, number> = {
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
	stl.Trait.Impl(stl.Trait.Map, MyMapType, myOps)
	const mine: MyMap = { __type = MyMapType, keys = {}, values = {} } :: any
	myOps.Set(mine, "x", 1)
	myOps.Set(mine, "y", 2)
	myOps.Set(mine, "w", 3)
	const myKeys = stl.Algorithm.Keys(mine)
	const myValues = stl.Algorithm.Values(mine)
	assert(table.concat(myKeys, ",") == "x,y,w", "Keys(사용자 맵) 은 순회 순서")
	-- ⭐ Records 는 계약이 아니라 알고리즘(2026-10-13 — `Iter` 위에 한 번만 구현). 사용자 맵은 다섯
	-- 함수만으로 레코드 목록을 얻습니다.
	const myRecords = stl.Algorithm.Records(mine)
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
	-- 이 맵은 `Trait.Collection` 을 구현하지 않음 — 크기를 몰라도 됨(미리 잡지 못할 뿐)
	assert(stl.Trait.ImplOf(stl.Trait.Collection, mine) == nil, "MyMap 은 Collection 아님")
	myOps.Remove(mine, "y")
	assert(table.concat(stl.Algorithm.Keys(mine), ",") == "x,w", "지운 뒤 Keys")
	const emptyMine: MyMap = { __type = MyMapType, keys = {}, values = {} } :: any
	assert(#stl.Algorithm.Keys(emptyMine) == 0 and #stl.Algorithm.Values(emptyMine) == 0, "빈 사용자 맵")
	const emptyHash = stl.HashMap.New<<string, number>>()
	assert(#stl.Algorithm.Keys(emptyHash) == 0 and #stl.Algorithm.Values(emptyHash) == 0, "빈 맵")
	-- 내장 두 맵: Keys 와 Values 가 같은 순서로 짝이 맞고, 자기 모듈의 Keys/Values 와 같은 내용
	const big = stl.HashMap.New<<string, number>>()
	const bigTree = stl.TreeMap.New<<string, number>>(Common.compareString)
	for i = 1, 40 do
		stl.HashMap.Set(big, `k{i * 7}`, i * 100)
		stl.TreeMap.Set(bigTree, `k{i * 7}`, i * 100)
	end
	const bigKeys, bigValues = stl.Algorithm.Keys(big), stl.Algorithm.Values(big)
	assert(#bigKeys == 40 and #bigValues == 40, "HashMap 40개")
	for at, key in bigKeys do
		assert(stl.HashMap.Get(big, key) == bigValues[at], `Keys[{at}] 와 Values[{at}] 가 짝`)
	end
	-- 내장 두 맵의 Algorithm.Records: 자기 모듈의 Records 와 같은 내용, 받은 것을 고쳐도 맵은 그대로
	const hashRecords = stl.Algorithm.Records(big)
	assert(#hashRecords == 40, "Algorithm.Records(HashMap) 개수")
	for _, rec in hashRecords do
		assert(stl.HashMap.Get(big, rec.key) == rec.value, "Algorithm.Records(HashMap) 의 키-값")
	end
	const treeRecords = stl.Algorithm.Records(bigTree)
	const ownRecords = stl.TreeMap.Records(bigTree)
	assert(#treeRecords == #ownRecords and #treeRecords == 40, "Algorithm.Records(TreeMap) 개수")
	for at, rec in treeRecords do
		assert(
			rec.key == ownRecords[at].key and rec.value == ownRecords[at].value,
			`TreeMap 레코드 {at} 은 정렬 순서`
		)
	end
	treeRecords[1].key = "zzz"
	treeRecords[1].value = -1
	assert(
		stl.TreeMap.Records(bigTree)[1].key == ownRecords[1].key,
		"받은 레코드를 고쳐도 TreeMap 은 그대로"
	)
	assert(#stl.Algorithm.Records(emptyHash) == 0, "빈 맵의 Records")
	assert(not pcall(function()
		stl.Algorithm.Records(stl.Arr.Of(1) :: any)
	end), "맵이 아닌 것의 Records 는 에러")
	const treeKeys, treeValues = stl.Algorithm.Keys(bigTree), stl.Algorithm.Values(bigTree)
	assert(
		table.concat(treeKeys, ",") == table.concat(stl.TreeMap.Keys(bigTree), ","),
		"TreeMap Keys 는 정렬 순서"
	)
	assert(table.concat(treeValues, ",") == table.concat(stl.TreeMap.Values(bigTree), ","), "TreeMap Values")

	-- 함수를 빠뜨린 구현은 **등록할 때** 사용자 줄 에러(2026-10-12 — 예전엔 알고리즘 안에서
	-- `attempt to call a nil value`: 타입을 안 쓰는 코드, 그리고 계약이 넓어지기 전의 구현)
	const partial = {
		Get = myOps.Get,
		Set = myOps.Set,
		Iter = myOps.Iter,
	}
	const PartialType = stl.Trait.NewType("PartialMap")
	local partialLine = 0
	const okPartial, errPartial = pcall(function()
		partialLine = debug.info(1, "l") + 1
		stl.Trait.Impl(stl.Trait.Map, PartialType, partial :: any)
	end)
	assert(
		not okPartial
			and string.find(tostring(errPartial), "PartialMap is missing Has for Map", 1, true)
			and string.find(tostring(errPartial), `spec.contracts.luau:{partialLine}:`, 1, true),
		`빠진 함수: {errPartial}`
	)
	assert(stl.Trait.Map.impls[PartialType] == nil, "거절된 등록은 남지 않음")
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
		const BadType = stl.Trait.NewType("BadCollection")
		const okBad, errBad = pcall(function()
			badLine = debug.info(1, "l") + 1
			stl.Trait.Impl(stl.Trait.Collection, BadType, bad.impl)
		end)
		assert(not okBad and string.find(tostring(errBad), bad.needle, 1, true), `잘못된 구현: {errBad}`)
		assert(string.find(tostring(errBad), `spec.contracts.luau:{badLine}:`, 1, true), `사용자 줄: {errBad}`)
		assert(stl.Trait.Collection.impls[BadType] == nil, "거절된 등록은 남지 않음")
	end
	-- 필수 목록이 없는 사용자 트레이트는 예전처럼 아무 구현이나 받고, 목록의 모양은 `New` 가 봄
	const Loose = stl.Trait.New<<{ read Show: (any) -> string }>>("Loose")
	stl.Trait.Impl(Loose, stl.Trait.NewType("LooseKind"), {} :: any)
	const names = { "Show" }
	const Strict = stl.Trait.New<<{ read Show: (any) -> string }>>("Strict", names)
	names[1] = "Other" -- 넘긴 목록을 나중에 바꿔도 트레이트는 그대로(사본)
	const StrictKind = stl.Trait.NewType("StrictKind")
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
			stl.Trait.New("BadRequired", badRequired.list)
		end)
		assert(not okNew and string.find(tostring(errNew), badRequired.needle, 1, true), `New 의 목록: {errNew}`)
		assert(string.find(tostring(errNew), `spec.contracts.luau:{newLine}:`, 1, true), `사용자 줄: {errNew}`)
	end

	-- SetOps 자리에 모듈을 담아 두고 쓰기
	const hs = stl.HashSet.Of(1, 2)
	const setOps: SetOps<stl.HashSet<number>, number> = stl.HashSet
	assert(setOps.Has(hs, 2) and not setOps.Has(hs, 3), "담아 둔 SetOps")
end
print("PASS")

print("=== 8. ⭐ 리스트를 받는 진입점이 Arr·table.pack 결과를 받을 때 (M0 3라운드) ===")
do
	-- `{ T }` 를 받는 생성자들이 `#`/`pairs` 로 읽어 `Arr` 의 `n` 과 태그 키까지
	-- 원소로 담거나(HashSet 크기 4), 구멍 뒤를 잃었습니다(CloneFromTable). 규약:
	-- **`n` 이 숫자로 있으면 그 길이로 숫자 루프**(구멍은 건너뜀), 없으면 `#`.
	const Arr, HashMap, HashSet, TreeMap, TreeSet, Heap =
		stl.Arr, stl.HashMap, stl.HashSet, stl.TreeMap, stl.TreeSet, stl.Heap
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
		table.concat(TreeSet.Items(TreeSet.FromList(nums, Common.compareNumber)), ",") == "10,30",
		"TreeSet.FromList(Arr)"
	)
	const heap = Heap.FromList(nums, lt)
	assert(Heap.Len(heap) == 2 and Heap.Peek(heap) == 10, "Heap.FromList(Arr)")

	type Rec = stl.Record<string, number>
	const records = Arr.Map(Arr.Of("a", "b"), function(s: string, i: number): Rec
		return { key = s, value = i * 10 }
	end)
	const hm = HashMap.FromRecords(records)
	assert(HashMap.Len(hm) == 2 and HashMap.Get(hm, "b") == 20, "HashMap.FromRecords(Arr)")
	const tm = TreeMap.FromRecords(records, Common.compareString)
	assert(TreeMap.Len(tm) == 2 and table.concat(TreeMap.Keys(tm), ",") == "a,b", "TreeMap.FromRecords(Arr)")
	-- 사전을 받는 FromTable 은 Arr 를 "위치 → 값" 으로 읽습니다(n·태그 키는 원소가 아님)
	const byIndex = HashMap.FromTable(nums :: any)
	assert(HashMap.Len(byIndex) == 2 and HashMap.Get(byIndex, 1) == 30, "HashMap.FromTable(Arr) 는 위치 → 값")
	assert(
		HashMap.Get(byIndex, "n" :: any) == nil and HashMap.Get(byIndex, "__type" :: any) == nil,
		"n·태그는 키가 아님"
	)
	-- 복사 판은 구멍까지 그대로(n 을 따름)
	const cloned = Arr.CloneFromTable(Arr.Of<<number?>>(1, nil, 3) :: any)
	assert(cloned.n == 3 and cloned[3] == 3 and cloned[2] == nil, "CloneFromTable 은 n 을 따름")

	-- (M0 4라운드) 구멍 든 입력·table.pack 을 **모든 진입점에** — 구멍 없는 입력만
	-- 넣으면 `#` 와 `n` 이 같아 진입점을 `#` 로 되돌린 돌연변이가 살아남았음.
	const packed = table.pack(30, nil, 10) :: any
	assert(HashSet.Len(HashSet.FromList(packed)) == 2, "HashSet.FromList(pack)")
	assert(
		table.concat(TreeSet.Items(TreeSet.FromList(packed, Common.compareNumber)), ",") == "10,30",
		"TreeSet.FromList(pack)"
	)
	const packedHeap = Heap.FromList(packed, lt)
	assert(Heap.Len(packedHeap) == 2 and Heap.Peek(packedHeap) == 10, "Heap.FromList(pack)")
	const packedRecords = table.pack({ key = "a", value = 1 }, nil, { key = "c", value = 3 }) :: any
	assert(HashMap.Len(HashMap.FromRecords(packedRecords)) == 2, "HashMap.FromRecords(pack)")
	assert(TreeMap.Len(TreeMap.FromRecords(packedRecords, Common.compareString)) == 2, "TreeMap.FromRecords(pack)")
	const holedArr = Arr.Of<<number?>>(10, nil, 30)
	const byIndexHoled = HashMap.FromTable(holedArr :: any)
	assert(HashMap.Len(byIndexHoled) == 2 and HashMap.Get(byIndexHoled, 3) == 30, "HashMap.FromTable(구멍 Arr)")
	-- Arr.FromTable 은 pack 이 준 n 을 그대로(꼬리 구멍 포함)
	assert(Arr.FromTable(table.pack(1, nil, 3, nil, nil) :: any).n == 5, "Arr.FromTable(pack) 은 n 을 따름")
	-- CloneFromTable 은 메타테이블이 있으면 원소 단위로 읽습니다(길이는 __len, 원소는 __index)
	const proxy = setmetatable({}, {
		__index = { 10, 20, 30 },
		__len = function()
			return 3
		end,
	}) :: any
	const fromProxy = Arr.CloneFromTable(proxy)
	assert(
		fromProxy.n == 3 and fromProxy[1] == 10 and fromProxy[3] == 30,
		"CloneFromTable 은 메타테이블 원소를 읽음"
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
	-- FromTable 은 n 뒤의 raw 칸을 비웁니다 — 남으면 정렬·삽입 뒤 그 값이 배열 안으로
	-- 다시 들어왔습니다(M0 5라운드, listLength 로 바꾸며 생긴 상태)
	const shortened = table.pack(50, 40, 30, 20, 10) :: any
	shortened.n = 2
	const adopted = Arr.FromTable(shortened)
	assert(adopted.n == 2 and adopted[3] == nil and adopted[5] == nil, "FromTable 은 n 뒤를 비움")
	Arr.SortInplaceUnchecked(adopted)
	assert(adopted[1] == 40 and adopted[2] == 50, "n 뒤 값이 정렬에 섞이지 않음")
	-- n = -0 은 +0 으로(Sized 와 같은 정규화)
	assert(tostring(Arr.FromTable({ n = -0 } :: any).n) == "0", "FromTable n = -0 → 0")
end
print("PASS")

print("=== 9. 쓰는 제네릭은 불변 마커로 — 맵·셋 종류와 무관하게 (2026-10-12, 질문 AM) ===")
do
	-- 타입 쪽(값 타입이 넓어지지 않음)은 spikes/61 이 지킵니다. 여기는 불변 마커를 받는 제네릭이
	-- 런타임에 HashMap·TreeMap, HashSet·TreeSet 양쪽에서 같은 답을 내는지.
	local function put<K, V>(m: stl.MapMarkerMut<K, V>, k: K, v: V)
		const ops = stl.Trait.ImplOf(stl.Trait.Map, m)
		assert(ops ~= nil, "Map 구현")
		ops.Set(m, k, v)
	end
	local function add<T>(s: stl.SetMarkerMut<T>, item: T): boolean
		const ops = stl.Trait.ImplOf(stl.Trait.Set, s)
		assert(ops ~= nil, "Set 구현")
		return ops.Add(s, item)
	end
	const hm = stl.HashMap.New<<string, number>>()
	const tm = stl.TreeMap.New<<string, number>>(Common.compareString)
	for _, key in { "b", "a", "b" } do
		put(hm, key, #key * 10)
		put(tm, key, #key * 10)
	end
	assert(stl.HashMap.Len(hm) == 2 and stl.TreeMap.Len(tm) == 2, "두 맵 모두 키 둘")
	assert(stl.HashMap.Get(hm, "a") == 10 and stl.TreeMap.Get(tm, "a") == 10, "같은 값")
	-- 불변 마커로 받은 값은 읽는 알고리즘에도 그대로 들어감
	local function keysOf<K, V>(m: stl.MapMarkerMut<K, V>): { K }
		return stl.Algorithm.Keys(m)
	end
	assert(table.concat(keysOf(tm), ",") == "a,b" and #keysOf(hm) == 2, "Mut 마커 → Keys")
	const hs = stl.HashSet.New<<number>>()
	const ts = stl.TreeSet.New<<number>>(Common.compareNumber)
	assert(add(hs, 10) and add(ts, 10) and not add(hs, 10) and not add(ts, 10), "두 셋 모두 Add")
	-- 팬텀은 타입에만 — 런타임 필드는 없음
	for _, value in { hm, tm, hs, ts, stl.Arr.Of(1), stl.Deque.Of(1) } :: { any } do
		for _, phantom in { "__mapMut", "__setMut", "__listMut", "__mapKey", "__setItem", "__list" } do
			assert(rawget(value, phantom) == nil, `팬텀 {phantom} 이 런타임에 있음`)
		end
	end
end
print("PASS")

print(
	"=== 10. 컬렉션 트레이트 — 종류를 모르고 크기·비우기, 넓힌 MapOps (2026-10-12, 질문 AO) ==="
)
do
	const A = stl.Algorithm
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
			name = "Deque",
			make = function()
				return stl.Deque.PushFront(stl.Deque.Of(10, 20), 5)
			end,
			len = stl.Deque.Len,
		},
		{
			name = "HashMap",
			make = function()
				return stl.HashMap.FromTable({ a = 10, b = 20, c = 30 })
			end,
			len = stl.HashMap.Len,
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
			name = "HashSet",
			make = function()
				return stl.HashSet.Of(10, 20, 30)
			end,
			len = stl.HashSet.Len,
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
		assert(stl.Trait.Implements(stl.Trait.Collection, value), `{case.name} 은 Collection`)
		assert(A.Len(value) == 3 and case.len(value) == 3, `{case.name} Len: {A.Len(value)}`)
		const cleared = A.Clear(value)
		assert(rawequal(cleared, value), `{case.name} Clear 는 같은 객체`)
		assert(A.Len(value) == 0 and case.len(value) == 0, `{case.name} Clear 뒤 Len`)
		assert(A.Clear(value) == value and A.Len(value) == 0, `{case.name} 빈 것을 또 Clear`)
	end
	-- Clear 뒤에도 쓸 수 있음(비우고 다시 채우기) — 맵 종류를 모르는 제네릭으로
	local function refill<K, V>(m: stl.MapMarkerMut<K, V> & stl.CollectionMarkerMut, records: { stl.Record<K, V> })
		const ops = stl.Trait.ImplOf(stl.Trait.Map, m)
		assert(ops ~= nil, "Map 구현")
		A.Clear(m)
		for _, rec in records do
			ops.Set(m, rec.key, rec.value)
		end
	end
	const hm = stl.HashMap.FromTable<<string, number>>({ old = 1 })
	const tm = stl.TreeMap.FromRecords({ { key = "old", value = 1 } }, Common.compareString)
	const fresh = { { key = "q", value = 70 }, { key = "p", value = 80 } }
	refill(hm, fresh)
	refill(tm, fresh)
	assert(A.Len(hm) == 2 and A.Len(tm) == 2, "다시 채운 크기")
	assert(stl.HashMap.Get(hm, "old") == nil and stl.TreeMap.Get(tm, "old") == nil, "옛 키는 없음")
	assert(table.concat(A.Keys(tm), ",") == "p,q" and stl.HashMap.Get(hm, "q") == 70, "다시 채운 내용")

	-- 읽기 전용으로 빌린 참조도 Len 은 됨(타입 쪽 — Clear 는 못 함 — 은 spikes/63)
	local function lenOfBorrowed(list: stl.ArrRead<number>, dq: stl.DequeRead<number>): number
		return A.Len(list) + A.Len(dq)
	end
	assert(lenOfBorrowed(stl.Arr.Of(1, 2), stl.Deque.Of(1, 2, 3)) == 5, "빌린 참조의 Len")

	-- 컬렉션이 아닌 것: 사용자 줄 에러(토큰은 있지만 구현 없음 / 토큰 없음 / 테이블 아님)
	local where = 0
	for _, bad in
		{
			{ value = stl.Fut.Resolved(1), needle = "Fut does not implement Collection" },
			{ value = {}, needle = "needs a Collection" },
			{ value = 5, needle = "needs a Collection" },
		} :: { { value: any, needle: string } }
	do
		for _, call in { A.Len, A.Clear } :: { (any) -> any } do
			const ok, err = pcall(function()
				where = debug.info(1, "l") + 1
				call(bad.value)
			end)
			assert(not ok and string.find(tostring(err), bad.needle, 1, true), `컬렉션 아님: {err}`)
			assert(string.find(tostring(err), `spec.contracts.luau:{where}:`, 1, true), `사용자 줄: {err}`)
		end
	end

	-- ⭐ 넓힌 MapOps — 종류를 모르는 코드가 Has·Remove·Iter 까지. 두 맵이 같은 답
	local function exercise<K, V>(m: stl.MapMarkerMut<K, V>, present: K, absent: K): (boolean, boolean, V?, V?, number)
		const ops = stl.Trait.ImplOf(stl.Trait.Map, m)
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
	const tm2 = stl.TreeMap.FromRecords(
		{ { key = "a", value = 10 }, { key = "b", value = 20 }, { key = "c", value = 30 } },
		Common.compareString
	)
	for name, m in { HashMap = hm2, TreeMap = tm2 } :: { [string]: any } do
		const hadPresent, hadAbsent, removed, removedAgain, seen = exercise(m, "b", "zz")
		assert(hadPresent and not hadAbsent, `{name} Has`)
		assert(removed == 20 and removedAgain == nil, `{name} Remove 는 지운 값: {removed}`)
		assert(seen == 3 and A.Len(m) == 2, `{name} Iter 개수 {seen}, 지운 뒤 크기 {A.Len(m)}`)
	end
	-- 모듈 테이블이 넓힌 계약과 컬렉션 계약을 정적으로 만족
	const _hmOps: MapOps<stl.HashMap<string, number>, string, number> = stl.HashMap
	const _tmOps: MapOps<stl.TreeMap<string, number>, string, number> = stl.TreeMap
	const _c1: stl.CollectionOps<stl.Arr<number>> = stl.Arr
	const _c2: stl.CollectionOps<stl.Deque<number>> = stl.Deque
	const _c3: stl.CollectionOps<stl.HashMap<string, number>> = stl.HashMap
	const _c4: stl.CollectionOps<stl.TreeMap<string, number>> = stl.TreeMap
	const _c5: stl.CollectionOps<stl.HashSet<number>> = stl.HashSet
	const _c6: stl.CollectionOps<stl.TreeSet<number>> = stl.TreeSet
	const _c7: stl.CollectionOps<stl.Heap<number>> = stl.Heap
end
print("PASS")

print(
	"=== 11. 트레이트 넓히기 리뷰 1라운드 — 필수 함수 목록 전수, 사용자 컬렉션 (2026-10-12) ==="
)
do
	const T = stl.Trait
	const A = stl.Algorithm
	-- ⭐ 내장 트레이트의 필수 목록을 **전수로**: 함수를 하나씩 뺀 구현은 등록할 때 그 이름으로 거절.
	-- (리뷰: 목록에서 항목을 빼도 대부분 통과했음 — `Iter` 를 뺀 사본에서는 `Iter` 없는 맵이 등록되고
	-- `Algorithm.Keys` 가 라이브러리 줄에서 `attempt to call a nil value`)
	const builtins: { { trait: any, name: string, full: { [string]: any } } } = {
		{
			trait = T.List,
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
			trait = T.Map,
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
			trait = T.Set,
			name = "Set",
			full = {
				Add = stl.HashSet.Add,
				Has = stl.HashSet.Has,
				Remove = stl.HashSet.Remove,
				Items = stl.HashSet.Items,
			},
		},
		{ trait = T.Collection, name = "Collection", full = { Len = stl.Arr.Len, Clear = stl.Arr.Clear } },
	}
	local where = 0
	for _, builtin in builtins do
		local fnCount = 0
		for missing in builtin.full do
			fnCount += 1
			const partial = table.clone(builtin.full)
			partial[missing] = nil
			const Kind = T.NewType("Partial")
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
		T.Impl(builtin.trait, T.NewType("Full"), table.clone(builtin.full))
	end

	-- ⭐ 사용자 컬렉션(가방) — Len·Clear·(맵이면) 미리 잡기 경로를 사용자 구현으로
	type Bag = { read __type: stl.TraitToken<string>, read __collectionMut: true, items: { number } }
	const BagType = T.NewType("Bag")
	T.Impl(
		T.Collection,
		BagType,
		{
			Len = function(bag: Bag): number
				return #bag.items
			end,
			-- **아무것도 돌려주지 않는** Clear — `Algorithm.Clear` 는 그래도 넣은 것을 돌려줘야 함
			-- (리뷰: 구현의 반환을 그대로 돌려주게 바꿔도 통과했음)
			Clear = function(bag: Bag)
				table.clear(bag.items)
			end,
		} :: any
	)
	const bag: Bag = { __type = BagType, items = { 10, 20, 30 } } :: any
	assert(A.Len(bag) == 3, "사용자 컬렉션의 Len")
	const clearedBag = A.Clear(bag)
	assert(
		rawequal(clearedBag, bag) and A.Len(bag) == 0,
		"구현이 안 돌려줘도 Clear 는 넣은 것을 돌려줌"
	)

	-- 맵이면서 컬렉션인 사용자 구현: `Len` 이 엉터리여도(음수·NaN·너무 큼·숫자 아님) Keys/Values 는 됨
	-- (리뷰: `table.create` 가 라이브러리 줄에서 죽었음). 실제보다 크거나 작아도 결과는 같음.
	type Sized = { read __type: stl.TraitToken<string>, read __mapKey: string, read __mapValue: number, len: any }
	const SizedType = T.NewType("SizedMap")
	const pairsOf = { a = 10, b = 20, c = 30 }
	T.Impl(
		T.Map,
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
		T.Collection,
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
		const keys = A.Keys(sized)
		const values = A.Values(sized)
		table.sort(keys)
		table.sort(values)
		assert(table.concat(keys, ",") == "a,b,c", `Len 이 {tostring(len)} 일 때 Keys: {table.concat(keys, ",")}`)
		assert(table.concat(values, ",") == "10,20,30", `Len 이 {tostring(len)} 일 때 Values`)
	end
	-- 보호된 메타테이블을 단 필수 목록도 사본으로 읽음
	const guarded = setmetatable({ "Show" }, { __metatable = "locked" })
	const Guarded = T.New<<{ read Show: (any) -> string }>>("Guarded", guarded :: any)
	assert(Guarded.required ~= nil and Guarded.required[1] == "Show", "보호된 목록")
end
print("PASS")

print()
print("=== ALL PASS (계약) ===")

return true

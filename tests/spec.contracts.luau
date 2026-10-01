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
	return #ops.Records(map)
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
	assert(stl.Algorithm.IndexOf(stl.Arr, a, 20) == 2, "Algorithm.IndexOf")
	assert(stl.Algorithm.Count(stl.Arr, a) == 3, "Algorithm.Count")
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
	assert(
		#stl.Algorithm.Keys<<H, string, number>>(stl.HashMap, hash)
			== #stl.Algorithm.Keys<<T, string, number>>(stl.TreeMap, tree),
		"Algorithm.Keys"
	)
	assert(
		#stl.Algorithm.Values<<H, string, number>>(stl.HashMap, hash)
			== #stl.Algorithm.Values<<T, string, number>>(stl.TreeMap, tree),
		"Algorithm.Values"
	)

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
	stl.HashMap.Set(m, "__hashmap__", 1)
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
		FromRecords = HashMap.FromRecords({ { key = "x", value = 1 } }),
		Adopt = HashMap.Adopt({ x = 1 }, 1),
		Clone = HashMap.Clone(hm),
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
	}
	for name, result in treeMapResults do
		assert(stl.isTreeMap(result), `TreeMap.{name} 결과에 태그가 없습니다`)
	end

	const ts = TreeSet.FromList({ 1, 2 }, Common.compareNumber)
	const treeSetResults: { [string]: any } = {
		New = TreeSet.New<<number>>(Common.compareNumber),
		FromList = ts,
		Clone = TreeSet.Clone(ts),
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
	}
	for name, result in heapResults do
		assert(stl.isHeap(result), `Heap.{name} 결과에 태그가 없습니다`)
	end

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

print("=== 6. ⭐ 술어는 모양만 같은 테이블과 위조 태그를 거부하는가 (M0 리뷰) ===")
do
	const lookalikes: { { name: string, value: any, is: (any) -> boolean } } = {
		-- 모양만 같고 태그가 없는 것
		{ name = "Arr 모양", value = { n = 0 }, is = stl.isArr },
		{ name = "HashMap 모양", value = { data = {}, size = 0 }, is = stl.isHashMap },
		{ name = "HashSet 모양", value = { map = { data = {}, size = 0 } }, is = stl.isHashSet },
		{ name = "TreeMap 모양", value = { records = {}, size = 0 }, is = stl.isTreeMap },
		{ name = "TreeSet 모양", value = { map = { records = {}, size = 0 } }, is = stl.isTreeSet },
		{ name = "Heap 모양", value = { items = {}, size = 0 }, is = stl.isHeap },
		{ name = "Fut 모양", value = { status = "Pending", listeners = {} }, is = stl.isFut },
		-- 태그만 있고 모양이 없는 것(위조)
		{ name = "HashMap 위조", value = { __hashmap__ = true }, is = stl.isHashMap },
		{ name = "HashSet 위조", value = { __hashset__ = true }, is = stl.isHashSet },
		{ name = "TreeMap 위조", value = { __treemap__ = true }, is = stl.isTreeMap },
		{ name = "TreeSet 위조", value = { __treeset__ = true }, is = stl.isTreeSet },
		{ name = "Heap 위조", value = { __heap__ = true }, is = stl.isHeap },
		{ name = "Fut 위조", value = { __fut__ = true }, is = stl.isFut },
		-- 모양 조건을 **하나씩만** 뺀 위조 — 조건 하나를 지운 돌연변이가 나머지
		-- 조건 덕에 살아남지 않게(M0 2라운드)
		{ name = "Arr 위조(n 없음)", value = { __arr__ = true }, is = stl.isArr },
		{ name = "Arr 위조(n 이 문자열)", value = { __arr__ = true, n = "3" }, is = stl.isArr },
		{ name = "HashMap 위조(data 없음)", value = { __hashmap__ = true, size = 0 }, is = stl.isHashMap },
		{ name = "HashMap 위조(size 없음)", value = { __hashmap__ = true, data = {} }, is = stl.isHashMap },
		{ name = "HashSet 위조(map 없음)", value = { __hashset__ = true, size = 0 }, is = stl.isHashSet },
		{ name = "TreeMap 위조(records 없음)", value = { __treemap__ = true, size = 0 }, is = stl.isTreeMap },
		{ name = "TreeMap 위조(size 없음)", value = { __treemap__ = true, records = {} }, is = stl.isTreeMap },
		{ name = "TreeSet 위조(map 없음)", value = { __treeset__ = true, size = 0 }, is = stl.isTreeSet },
		{ name = "Heap 위조(items 없음)", value = { __heap__ = true, size = 0 }, is = stl.isHeap },
		{ name = "Heap 위조(size 없음)", value = { __heap__ = true, items = {} }, is = stl.isHeap },
		{ name = "Fut 위조(status 없음)", value = { __fut__ = true, listeners = {} }, is = stl.isFut },
		{
			name = "Fut 위조(status 이상)",
			value = { __fut__ = true, status = "Done", listeners = {} },
			is = stl.isFut,
		},
		{ name = "Fut 위조(listeners 없음)", value = { __fut__ = true, status = "Pending" }, is = stl.isFut },
		{
			name = "Fut 위조(Resolved 인데 values 없음)",
			value = { __fut__ = true, status = "Resolved", listeners = {} },
			is = stl.isFut,
		},
	}
	for _, case in lookalikes do
		assert(not case.is(case.value), `{case.name} 을 진짜로 받아들임`)
	end
	-- 위조 Fut 을 Chain 콜백이 돌려주면 입양하지 말고 실패시켜야 합니다(AwaitSafe 는 던지면 안 됨)
	const forged = stl.Fut.Chain(stl.Fut.Resolved(1), function(): any
		return { __fut__ = true }
	end)
	assert(stl.Fut.Status(forged) == "Rejected", "위조 Fut 은 Rejected")
	assert(stl.Fut.AwaitSafe(forged) == false, "AwaitSafe 는 던지지 않음")
	-- 조금 더 그럴듯한 위조(Resolved 인데 values 없음)도 — 그리고 All 은 던지지
	-- 않고 Rejected 를 돌려줘야 합니다(문서대로 "곧바로 실패")
	const forged2 = { __fut__ = true, status = "Resolved", listeners = {} }
	const chained2 = stl.Fut.Chain(stl.Fut.Resolved(1), function(): any
		return forged2
	end)
	assert(
		stl.Fut.Status(chained2) == "Rejected" and stl.Fut.AwaitSafe(chained2) == false,
		"그럴듯한 위조도 Rejected"
	)
	const okAll, allFut = pcall(stl.Fut.All, { forged2 } :: any)
	assert(okAll and stl.Fut.Status(allFut) == "Rejected", "All 은 위조를 받으면 던지지 않고 Rejected")
	-- Optional 도 교차표에 — 다른 술어가 Optional 을, Optional 술어가 컨테이너를 받으면 안 됨
	const present = stl.Optional.Present(1)
	const containerPredicates: { (any) -> boolean } =
		{ stl.isArr, stl.isHashMap, stl.isHashSet, stl.isTreeMap, stl.isTreeSet, stl.isHeap, stl.isFut }
	for _, is in containerPredicates do
		assert(not is(present), "컨테이너 술어가 Optional 을 받아들임")
	end
	assert(stl.isOptional(present) and not stl.isOptional(stl.Arr.Of(1)), "Optional 술어")
end
print("PASS")

print("=== 7. 계약 보강 — 원소 타입 ≠ 위치 타입, Keys/Values 내용, 담아 둔 SetOps (M0 리뷰) ===")
do
	-- ListOps 의 반환 타입(I? 대 E?)은 원소와 위치가 둘 다 number 면 우연히 맞아떨어집니다
	const s = stl.Arr.Of("x", "y", "z")
	const pos: number? = stl.Algorithm.IndexOf(stl.Arr, s, "y")
	assert(pos == 2, "문자열 배열의 IndexOf")
	const ops: ListOps<stl.Arr<string>, string, number> = stl.Arr
	assert(ops.Get(s, 3) == "z" and ops.FirstIndex(s) == 1 and ops.NextIndex(s, 1) == 2, "문자열 배열의 ListOps")

	-- Keys/Values 는 개수가 아니라 **내용**을 봅니다(키와 값을 바꿔 돌려줘도 통과했음)
	const m = stl.TreeMap.FromRecords({ { key = "b", value = 20 }, { key = "a", value = 10 } }, Common.compareString)
	type T = stl.TreeMap<string, number>
	const keys = stl.Algorithm.Keys<<T, string, number>>(stl.TreeMap, m)
	const values = stl.Algorithm.Values<<T, string, number>>(stl.TreeMap, m)
	assert(table.concat(keys, ",") == "a,b", "Algorithm.Keys 내용")
	assert(values[1] == 10 and values[2] == 20, "Algorithm.Values 내용")

	-- SetOps 자리에 모듈을 담아 두고 쓰기
	const hs = stl.HashSet.Of(1, 2)
	const setOps: SetOps<stl.HashSet<number>, number> = stl.HashSet
	assert(setOps.Has(hs, 2) and not setOps.Has(hs, 3), "담아 둔 SetOps")
end
print("PASS")

print()
print("=== ALL PASS (계약) ===")

return true

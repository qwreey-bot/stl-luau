--!strict
--[[
	M4 — 맵·셋 표면의 타입 (2026-10-07).

	지키는 성질: 꺼내기·엄격 이웃 조회·누적은 **`?` 를 돌려줌**, `GetOrInsert(With)` 는 값이 있음을
	약속(`V`), 합치기는 **같은 맵 타입**만, `GroupBy`/`CountBy`/`KeyBy` 는 키·원소 타입을 정확히 옮김,
	`Retain`·`make`·`combine` 콜백은 키·값 타입으로 검사됨.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 20 줄 · 22건 + CANARY 1 — `negCounts` 는 세 건)
]]
local stl = require("../../../../src")
local Arr, HashMap, HashSet, TreeMap, TreeSet, Common =
	stl.Arr, stl.HashMap, stl.HashSet, stl.TreeMap, stl.TreeSet, stl.Common
type Arr<T> = stl.Arr<T>
type HashMap<K, V> = stl.HashMap<K, V>

local m = HashMap.New<<string, number>>()
local other = HashMap.New<<string, string>>()
local tm = TreeMap.New<<number, string>>(Common.compareNumber)
local ts = TreeSet.New<<number>>(Common.compareNumber)
local hs = HashSet.Of(1, 2)
local words = Arr.Of("apple", "bob")
local first = function(w: string): string
	return string.sub(w, 1, 1)
end

--[[ POS ]]
local got: number = HashMap.GetOrInsert(m, "a", 1)
local made: number = HashMap.GetOrInsertWith(m, "b", function(key: string): number
	return #key
end)
local acc: number? = HashMap.Accumulate(m, "a", 1, function(old: number, value: number): number
	return old + value
end)
local merged: HashMap<string, number> = HashMap.Merge(m, m)
HashMap.MergeInplace(m, m)
HashMap.Retain(m, function(key: string, value: number): boolean
	return #key < value
end)
HashSet.Retain(hs, function(item: number): boolean
	return item > 1
end)
local lower: number? = TreeMap.LowerKey(tm, 3)
local popped = TreeMap.PopFirst(tm)
local poppedValue: string? = if popped then popped.value else nil
local item: number? = TreeSet.PopLast(ts)
local higher: number? = TreeSet.HigherItem(ts, 3)
local cleared: HashMap<string, number> = HashMap.Clear(HashMap.Clone(m)) -- 자기 자신(질문 AM)
local clearedSet: stl.HashSet<number> = HashSet.Clear(HashSet.Clone(hs))
local groups: HashMap<string, Arr<string>> = Arr.GroupBy(words, first, HashMap.New<<string, Arr<string>>>())
local counts: HashMap<string, number> = Arr.CountBy(words, first, HashMap.New<<string, number>>())
local keyed: HashMap<string, string> = Arr.KeyBy(words, first, HashMap.New<<string, string>>())

--[[ NEG — `?` 를 지킴 ]]
local negAcc: number = HashMap.Accumulate(m, "a", 1, function(old: number, value: number): number
	return old + value
end)
local negLower: number = TreeMap.LowerKey(tm, 3)
local negPopSet: number = TreeSet.PopFirst(ts)
local negPopMap = TreeMap.PopLast(tm).key

--[[ NEG — Clear 는 같은 타입의 자기 자신 ]]
local negClear: HashMap<string, string> = HashMap.Clear(m)
local negClearTree: stl.TreeMap<string, number> = TreeMap.Clear(tm)

--[[ NEG — 합치기는 같은 맵 타입만 ]]
local negMerge = HashMap.Merge(m, other)
HashMap.MergeInplace(m, other)

--[[ NEG — 묶기의 결과 타입 ]]
local negGroups = Arr.GroupBy(words, first, HashMap.New<<string, Arr<number>>>()) -- 묶음의 원소 타입
local negCounts = Arr.CountBy(words, first, HashMap.New<<string, string>>()) -- 세는 값은 number
local negKeyed = Arr.KeyBy(words, first, HashMap.New<<number, string>>()) -- 키 타입
-- 묶기의 목적지(2026-10-13, 질문 AR): 넣은 타입 그대로 돌려줌 / 생략 불가 / 맵이어야 함 / 빌린 읽기 참조는 안 됨
local sortedGroups: stl.TreeMap<string, Arr<string>> =
	Arr.GroupBy(words, first, stl.TreeMap.New<<string, Arr<string>>>(stl.Common.compareString))
local negDestKind: stl.TreeMap<string, Arr<string>> = Arr.GroupBy(words, first, HashMap.New<<string, Arr<string>>>())
local negNoDest = Arr.GroupBy(words, first)
local negNotMap = Arr.CountBy(words, first, Arr.Of(1))
local negSetDest = Arr.KeyBy(words, first, stl.HashSet.New<<string>>())

--[[ NEG — 콜백은 키·값 타입으로 검사 ]]
HashMap.Retain(m, function(key: number, value: number): boolean
	return key < value
end)
HashSet.Retain(hs, function(item: string): boolean
	return item == ""
end)
local negMake = HashMap.GetOrInsertWith(m, "c", function(key: string): string
	return key
end)
local negCombine = HashMap.Accumulate(m, "a", 1, function(old: string, value: number): number
	return value
end)
TreeMap.Retain(tm, function(key: string, value: string): boolean
	return key == value
end)

local canary: string = 42

return {
	got,
	made,
	acc,
	merged,
	lower,
	poppedValue,
	item,
	higher,
	groups,
	counts,
	keyed,
	cleared,
	clearedSet,
	negClear,
	negClearTree,
	negAcc,
	negLower,
	negPopSet,
	negPopMap,
	negMerge,
	negGroups,
	negCounts,
	negKeyed,
	sortedGroups,
	negDestKind,
	negNoDest,
	negNotMap,
	negSetDest,
	negMake,
	negCombine,
	canary,
}

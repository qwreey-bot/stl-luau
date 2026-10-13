--!strict
--[[
	67 — 노드 기반 `TreeMap`·`TreeSet`(레드블랙 조립)의 음성 대조군 (2026-10-13).

	지키는 성질: 조회는 옵셔널 / 키·값 타입 / 토큰 없는 리터럴은 맵이 아님 / `FlatMap` 과 서로 다른 타입 /
	경계 조회(`FloorKey` …)는 옵셔널 키 / `PopFirst` 는 옵셔널 레코드 / `Retain` 콜백의 타입 / 뿌리 노드는
	읽기 전용 / 균형 방식 자리에 계약과 다른 것은 안 들어감 / 순회 변수의 타입.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 34 + CANARY 1)
]]
local stl = require("../../../../src")
local TreeMap = stl.TreeMap
type TreeMap<K, V> = stl.TreeMap<K, V>

local cmp = stl.Common.compareNumber
local scores = TreeMap.New<<number, string>>(cmp)

--[[ POS ]]
TreeMap.Set(scores, 10, "ten")
local got: string? = TreeMap.Get(scores, 10)
local floor: number? = TreeMap.FloorKey(scores, 15)
local firstRec: stl.Record<number, string>? = TreeMap.First(scores)
local keys: { number } = TreeMap.Keys(scores)
local same: TreeMap<number, string> = TreeMap.Clear(scores)
local withAvl: TreeMap<number, string> = TreeMap.New<<number, string>>(cmp, stl.Avl)
local viaTrait: { number } = stl.Map.Keys(scores)
for key, value in TreeMap.Iter(scores) do
	local k: number, v: string = key, value
	print(k, v)
end

--[[ NEG ]]
-- 조회는 옵셔널
local negGet: string = TreeMap.Get(scores, 10)
local negFloor: number = TreeMap.FloorKey(scores, 15)
local negPop: stl.Record<number, string> = TreeMap.PopFirst(scores)
-- 키·값 타입
TreeMap.Set(scores, "ten", "x")
TreeMap.Set(scores, 10, 12345)
local negKeys: { string } = TreeMap.Keys(scores)
local negRemoved: number? = TreeMap.Remove(scores, 10)
-- 토큰 없는 리터럴은 맵이 아님 / FlatMap 과 서로 다른 타입
local negLiteral: TreeMap<number, string> = { root = nil, size = 0, compare = cmp, balance = stl.RedBlack }
local negFlat: TreeMap<number, string> = stl.FlatMap.New<<number, string>>(cmp)
-- Retain 콜백의 타입
TreeMap.Retain(scores, function(key: string, _value: string): boolean
	return key == "x"
end)
-- 뿌리 노드는 읽기 전용
if scores.root then
	scores.root.value = "changed"
	scores.root[1] = nil
end
-- 균형 방식 자리에 계약과 다른 것
local negBalance = TreeMap.New<<number, string>>(cmp, { Insert = stl.RedBlack.Insert })
-- 순회 변수의 타입
for key in TreeMap.Iter(scores) do
	local negKey: string = key
	print(negKey)
end

--[[ TreeSet — 같은 성질 ]]
local ranks = stl.TreeSet.FromList({ 30, 10, 20 }, cmp)
local okAdd: boolean = stl.TreeSet.Add(ranks, 40)
local okItems: { number } = stl.TreeSet.Items(ranks)
local okUnion: stl.TreeSet<number> = stl.TreeSet.Union(ranks, stl.TreeSet.New<<number>>(cmp, stl.Avl))
local negFirst: number = stl.TreeSet.First(ranks)
stl.TreeSet.Add(ranks, "forty")
local negItems: { string } = stl.TreeSet.Items(ranks)
local negFlatSet: stl.TreeSet<number> = stl.FlatSet.New<<number>>(cmp)
local negUnion = stl.TreeSet.Union(ranks, stl.TreeSet.New<<string>>(stl.Common.compareString))
local negSetLiteral: stl.TreeSet<number> = { map = scores }

--[[ 리뷰 1라운드(2026-10-13) — 지키는 NEG 가 없던 성질 ]]
local negCeiling: number = TreeMap.CeilingKey(scores, 15)
local negLower: number = TreeMap.LowerKey(scores, 15)
local negGetKey = TreeMap.Get(scores, "ten")
local negRange = TreeMap.RangeRecords(scores, "a", "z")
local negSetHas = stl.TreeSet.Has(ranks, "x")
local negSetPop: number = stl.TreeSet.PopFirst(ranks)
local negSetFloor: number = stl.TreeSet.FloorItem(ranks, 5)
stl.TreeSet.Retain(ranks, function(item: string): boolean
	return item == "x"
end)
local negSetBalance = stl.TreeSet.New<<number>>(cmp, { Insert = stl.RedBlack.Insert })
for _, again in stl.TreeSet.Iter(ranks) do
	local negAgain: string = again
	print(negAgain)
end

--[[ 균형 계약 — 서명이 다른 방식은 안 들어감(2라운드 리뷰: 계약의 인자가 `any` 이던 때는 아래 넷이 전부 0건) ]]
local okScheme: stl.TreeBalance = stl.Avl
local shortInsert = {
	Insert = function(_root: any, _key: any, _value: any, _order: any): (number, number)
		return 1, 2
	end,
	Remove = stl.Avl.Remove,
	FromSorted = stl.Avl.FromSorted,
	Clone = stl.Avl.Clone,
}
local noRoot = {
	Insert = stl.Avl.Insert,
	Remove = function(_root: any, _node: any) end,
	FromSorted = stl.Avl.FromSorted,
	Clone = stl.Avl.Clone,
}
local partial = { Insert = stl.Avl.Insert, FromSorted = stl.Avl.FromSorted, Clone = stl.Avl.Clone }
-- NEG: `Insert` 가 셋째 반환을 안 줌 / `Remove` 가 새 뿌리를 안 돌려줌 / 함수 하나가 빠진 표(리터럴이 아님) / 찾기 모듈
local negShortInsert: stl.TreeBalance = shortInsert
local negNoRoot: stl.TreeBalance = noRoot
local negPartial: stl.TreeBalance = partial
local negSearch: stl.TreeBalance = stl.Search

local canary: string = 42

return {
	got,
	floor,
	firstRec,
	keys,
	same,
	withAvl,
	viaTrait,
	negGet,
	negFloor,
	negPop,
	negKeys,
	negRemoved,
	negLiteral,
	negFlat,
	negBalance,
	okAdd,
	okItems,
	okUnion,
	negFirst,
	negItems,
	negFlatSet,
	negUnion,
	negSetLiteral,
	negCeiling,
	negLower,
	negGetKey,
	negRange,
	negSetHas,
	negSetPop,
	negSetFloor,
	negSetBalance,
	okScheme,
	negShortInsert,
	negNoRoot,
	negPartial,
	negSearch,
	canary,
}

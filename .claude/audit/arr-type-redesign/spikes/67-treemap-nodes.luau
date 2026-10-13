--!strict
--[[
	67 — 노드 기반 `TreeMap`·`TreeSet`(레드블랙 조립)의 음성 대조군 (2026-10-13).

	지키는 성질: 조회는 옵셔널 / 키·값 타입 / 토큰 없는 리터럴은 맵이 아님 / `FlatMap` 과 서로 다른 타입 /
	경계 조회(`FloorKey` …)는 옵셔널 키 / `PopFirst` 는 옵셔널 레코드 / `Retain` 콜백의 타입 / 뿌리 노드는
	읽기 전용 / 균형 방식 자리에 계약과 다른 것은 안 들어감 / 순회 변수의 타입.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 20 + CANARY 1)
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
	canary,
}

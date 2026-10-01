--!strict
--[[
	실제 `src/TreeMap.luau` / `src/TreeSet.luau` 에 대한 음성 대조군.

	정렬 컨테이너는 비교자를 주입받으므로 **비교자와 컨테이너의 타입이 갈릴
	여지**가 있습니다. 그 자리를 특히 봅니다.

	기대 진단: 12건 (NEG 11 + CANARY 1)
]]
local stl = require("../../../../src")
local TreeMap = stl.TreeMap
local TreeSet = stl.TreeSet

type TreeMap<K, V> = stl.TreeMap<K, V>
type TreeSet<T> = stl.TreeSet<T>

local scores = stl.TreeMap.New(stl.Common.compareNumber) :: TreeMap<number, string>
local ranks = stl.TreeSet.FromList({ 3, 1, 2 }, stl.Common.compareNumber)

--[[ POS ]]
TreeMap.Set(scores, 1, "금")
local okGet: string? = TreeMap.Get(scores, 1)
local okOr: string = TreeMap.GetOr(scores, 9, "없음")
local okLen: number = TreeMap.Len(scores)
local okKeys: { number } = TreeMap.Keys(scores)
local okValues: { string } = TreeMap.Values(scores)
local okFirst = TreeMap.First(scores)
local okFloor: number? = TreeMap.FloorKey(scores, 5)
local okCeiling: number? = TreeMap.CeilingKey(scores, 0)
local okRange = TreeMap.RangeRecords(scores, 1, 9)
local okRangeKey: number = okRange[1].key
local okClone: TreeMap<number, string> = TreeMap.Clone(scores)
local okRemoved: string? = TreeMap.Remove(scores, 1)
local okJoined = ""
for _key, value in TreeMap.Iter(scores) do
	okJoined ..= value
end

local okAdd: boolean = TreeSet.Add(ranks, 4)
local okHas: boolean = TreeSet.Has(ranks, 1)
local okItems: { number } = TreeSet.Items(ranks)
local okUnion: TreeSet<number> = TreeSet.Union(ranks, ranks)
local okSubset: boolean = TreeSet.IsSubsetOf(ranks, ranks)
local okSetFirst: number? = TreeSet.First(ranks)
local okSetRange: { number } = TreeSet.RangeItems(ranks, 1, 2)
local okCount = 0
for _, _item in TreeSet.Iter(ranks) do
	okCount += 1
end
-- 계약만 아는 공용 알고리즘
local okAlgoKeys: { number } = stl.Algorithm.Keys<<TreeMap<number, string>, number, string>>(stl.TreeMap, scores)

--[[ NEG ]]
local neg1 = TreeMap.Get(scores, "문자열") -- 키 타입이 다름
local neg2: number = TreeMap.GetOr(scores, 1, "없음") -- 값은 string
TreeMap.Set(scores, 1, 42) -- neg3: 값 타입이 다름 (Set 은 반환이 없어 바인딩하지 않습니다)
local neg4 = TreeMap.NoSuchMethod(scores)
local neg5 = stl.TreeMap.Nope -- 네임스페이스 오타
local neg6: { string } = TreeMap.Keys(scores) -- 키는 number
local neg7 = TreeMap.FloorKey(scores, "문자열") -- 키 타입이 다름
local neg8 = TreeSet.Add(ranks, "문자열") -- 원소 타입이 다름
local neg9: number = TreeSet.Has(ranks, 1) -- 술어는 boolean
local neg10 = TreeSet.Union(ranks, scores) -- 셋 자리에 맵
local neg11 = TreeSet.Set(ranks, 1, true) -- 셋에는 맵의 어휘가 없어야 함
local canary: string = 42

return {
	okGet, okOr, okLen, okKeys, okValues, okFirst, okFloor, okCeiling,
	okRange, okRangeKey, okClone, okRemoved, okJoined, okAdd, okHas,
	okItems, okUnion, okSubset, okSetFirst, okSetRange, okCount, okAlgoKeys,
	neg1, neg2, neg4, neg5, neg6, neg7, neg8, neg9, neg10, neg11, canary,
}

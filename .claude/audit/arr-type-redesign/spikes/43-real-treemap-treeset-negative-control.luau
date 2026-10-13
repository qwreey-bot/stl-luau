--!strict
--[[
	실제 `src/FlatMap.luau` / `src/FlatSet.luau` 에 대한 음성 대조군.

	정렬 컨테이너는 비교자를 주입받으므로 **비교자와 컨테이너의 타입이 갈릴
	여지**가 있습니다. 그 자리를 특히 봅니다.

	기대 진단: 12건 (NEG 11 + CANARY 1)
]]
local stl = require("../../../../src")
local FlatMap = stl.FlatMap
local FlatSet = stl.FlatSet

type FlatMap<K, V> = stl.FlatMap<K, V>
type FlatSet<T> = stl.FlatSet<T>

local scores = stl.FlatMap.New(stl.Common.compareNumber) :: FlatMap<number, string>
local ranks = stl.FlatSet.FromList({ 3, 1, 2 }, stl.Common.compareNumber)

--[[ POS ]]
FlatMap.Set(scores, 1, "금")
local okGet: string? = FlatMap.Get(scores, 1)
local okOr: string = FlatMap.GetOr(scores, 9, "없음")
local okLen: number = FlatMap.Len(scores)
local okKeys: { number } = FlatMap.Keys(scores)
local okValues: { string } = FlatMap.Values(scores)
local okFirst = FlatMap.First(scores)
local okFloor: number? = FlatMap.FloorKey(scores, 5)
local okCeiling: number? = FlatMap.CeilingKey(scores, 0)
local okRange = FlatMap.RangeRecords(scores, 1, 9)
local okRangeKey: number = okRange[1].key
local okClone: FlatMap<number, string> = FlatMap.Clone(scores)
local okRemoved: string? = FlatMap.Remove(scores, 1)
local okJoined = ""
for _key, value in FlatMap.Iter(scores) do
	okJoined ..= value
end

local okAdd: boolean = FlatSet.Add(ranks, 4)
local okHas: boolean = FlatSet.Has(ranks, 1)
local okItems: { number } = FlatSet.Items(ranks)
local okUnion: FlatSet<number> = FlatSet.Union(ranks, ranks)
local okSubset: boolean = FlatSet.IsSubsetOf(ranks, ranks)
local okSetFirst: number? = FlatSet.First(ranks)
local okSetRange: { number } = FlatSet.RangeItems(ranks, 1, 2)
local okCount = 0
for _, _item in FlatSet.Iter(ranks) do
	okCount += 1
end
-- 계약만 아는 공용 알고리즘
local okAlgoKeys: { number } = stl.Map.Keys(scores)

--[[ NEG ]]
local neg1 = FlatMap.Get(scores, "문자열") -- 키 타입이 다름
local neg2: number = FlatMap.GetOr(scores, 1, "없음") -- 값은 string
FlatMap.Set(scores, 1, 42) -- neg3: 값 타입이 다름 (Set 은 반환이 없어 바인딩하지 않습니다)
local neg4 = FlatMap.NoSuchMethod(scores)
local neg5 = stl.FlatMap.Nope -- 네임스페이스 오타
local neg6: { string } = FlatMap.Keys(scores) -- 키는 number
local neg7 = FlatMap.FloorKey(scores, "문자열") -- 키 타입이 다름
local neg8 = FlatSet.Add(ranks, "문자열") -- 원소 타입이 다름
local neg9: number = FlatSet.Has(ranks, 1) -- 술어는 boolean
local neg10 = FlatSet.Union(ranks, scores) -- 셋 자리에 맵
local neg11 = FlatSet.Set(ranks, 1, true) -- 셋에는 맵의 어휘가 없어야 함
local canary: string = 42

return {
	okGet, okOr, okLen, okKeys, okValues, okFirst, okFloor, okCeiling,
	okRange, okRangeKey, okClone, okRemoved, okJoined, okAdd, okHas,
	okItems, okUnion, okSubset, okSetFirst, okSetRange, okCount, okAlgoKeys,
	neg1, neg2, neg4, neg5, neg6, neg7, neg8, neg9, neg10, neg11, canary,
}

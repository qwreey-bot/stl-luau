--!strict
--[[
	실제 `src/TreeMap.luau` / `src/TreeSet.luau` 에 대한 음성 대조군.

	정렬 컨테이너는 비교자를 주입받으므로 **비교자와 컨테이너의 타입이 갈릴
	여지**가 있습니다. 그 자리를 특히 봅니다.

	기대 진단: 12건 (NEG 11 + CANARY 1)
]]
local stl = require("../../../../src")

type TreeMap<K, V> = stl.TreeMap<K, V>
type TreeSet<T> = stl.TreeSet<T>

local scores = stl.TreeMap.New(stl.Common.compareNumber) :: TreeMap<number, string>
local ranks = stl.TreeSet.FromList({ 3, 1, 2 }, stl.Common.compareNumber)

--[[ POS ]]
scores:Set(1, "금")
local okGet: string? = scores:Get(1)
local okOr: string = scores:GetOr(9, "없음")
local okLen: number = scores:Len()
local okKeys: { number } = scores:Keys()
local okValues: { string } = scores:Values()
local okFirst = scores:First()
local okFloor: number? = scores:FloorKey(5)
local okCeiling: number? = scores:CeilingKey(0)
local okRange = scores:RangeRecords(1, 9)
local okRangeKey: number = okRange[1].key
local okClone: TreeMap<number, string> = scores:Clone()
local okRemoved: string? = scores:Remove(1)
local okJoined = ""
for _key, value in scores:Iter() do
	okJoined ..= value
end

local okAdd: boolean = ranks:Add(4)
local okHas: boolean = ranks:Has(1)
local okItems: { number } = ranks:Items()
local okUnion: TreeSet<number> = ranks:Union(ranks)
local okSubset: boolean = ranks:IsSubsetOf(ranks)
local okSetFirst: number? = ranks:First()
local okSetRange: { number } = ranks:RangeItems(1, 2)
local okCount = 0
for _, _item in ranks:Iter() do
	okCount += 1
end
-- 계약만 아는 공용 알고리즘
local okAlgoKeys: { number } = stl.Algorithm.Keys(scores)

--[[ NEG ]]
local neg1 = scores:Get("문자열") -- 키 타입이 다름
local neg2: number = scores:GetOr(1, "없음") -- 값은 string
scores:Set(1, 42) -- neg3: 값 타입이 다름 (Set 은 반환이 없어 바인딩하지 않습니다)
local neg4 = scores:NoSuchMethod()
local neg5 = stl.TreeMap.Nope -- 네임스페이스 오타
local neg6: { string } = scores:Keys() -- 키는 number
local neg7 = scores:FloorKey("문자열") -- 키 타입이 다름
local neg8 = ranks:Add("문자열") -- 원소 타입이 다름
local neg9: number = ranks:Has(1) -- 술어는 boolean
local neg10 = ranks:Union(scores) -- 셋 자리에 맵
local neg11 = ranks:Set(1, true) -- 셋에는 맵의 어휘가 없어야 함
local canary: string = 42

return {
	okGet, okOr, okLen, okKeys, okValues, okFirst, okFloor, okCeiling,
	okRange, okRangeKey, okClone, okRemoved, okJoined, okAdd, okHas,
	okItems, okUnion, okSubset, okSetFirst, okSetRange, okCount, okAlgoKeys,
	neg1, neg2, neg4, neg5, neg6, neg7, neg8, neg9, neg10, neg11, canary,
}

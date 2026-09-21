--!strict
--[[
	⭐ **실제 `src/HashMap.luau` / `src/HashSet.luau` 에 대한 음성 대조군.**

	두 모듈 다 진단 0건인데, 이 저장소에서 0건은 축하가 아니라 경보입니다.
	"틀린 코드가 정말 틀리다고 나오는지" 를 따로 고정합니다.

	⚠️ 아래 "캐비엇" 절은 **일부러 에러가 안 나는 것들**입니다. 잡히기 시작하면
	Luau 가 좋아진 것이니 기대 건수를 올리고 캐비엇을 지우세요.

	기대 진단: 12건 (NEG 11 + CANARY 1)
]]
local stl = require("../../../../src")

type HashMap<K, V> = stl.HashMap<K, V>
type HashSet<T> = stl.HashSet<T>

local ages = stl.HashMap.New() :: HashMap<string, number>
local names = stl.HashSet.Of("철수", "영희")

--[[ POS: 전부 통과해야 합니다 ]]
ages:Set("철수", 20)
local okGet: number? = ages:Get("철수")
local okOr: number = ages:GetOr("없음", 0)
local okHas: boolean = ages:Has("철수")
local okLen: number = ages:Len()
local okKeys: { string } = ages:Keys()
local okValues: { number } = ages:Values()
local okRemoved: number? = ages:Remove("철수")
local okRecords = ages:Records()
local okFirstKey: string = okRecords[1].key
local okFirstValue: number = okRecords[1].value
local okClone: HashMap<string, number> = ages:Clone()
local okSum = 0
for _key, value in ages:Iter() do
	okSum += value
end

local okAdd: boolean = names:Add("민수")
local okSetHas: boolean = names:Has("철수")
local okItems: { string } = names:Items()
local okUnion: HashSet<string> = names:Union(stl.HashSet.Of("지연"))
local okSubset: boolean = names:IsSubsetOf(names)
local okSetClone: HashSet<string> = names:Clone()
for _item in names:Iter() do
	okSum += 1
end
-- 계약만 아는 공용 알고리즘이 맵 위에서 동작해야 합니다
local okAlgoKeys: { string } = stl.Algorithm.Keys(ages)

--[[ NEG: 전부 에러여야 합니다 ]]
local neg1 = ages:Get(42) -- 키 타입이 다름
local neg2: string = ages:GetOr("a", 0) -- 값은 number
local neg3 = ages:NoSuchMethod()
local neg4 = stl.HashMap.Nope -- 네임스페이스 오타
ages:Set("철수", "스무살") -- neg5: 값 타입이 다름 (Set 은 반환이 없어 바인딩하지 않습니다)
local neg6: { number } = ages:Keys() -- 키는 string
local neg7 = names:Add(42) -- 원소 타입이 다름
local neg8: number = names:Has("철수") -- 술어는 boolean
local neg9 = names:NoSuchMethod()
local neg10 = names:Union(ages) -- 셋 자리에 맵
local neg11 = names:Set("철수", 1) -- 셋에는 맵의 어휘가 없어야 함

--[[ 캐비엇: 지금은 **일부러** 안 잡히는 것들 ]]
-- 테이블 리터럴은 `{ [string]: number }` 가 아니라 이름 붙은 속성을 가진
-- 레코드 `{ a: number }` 라서 K/V 를 못 뽑습니다. 결과가 조용히
-- HashMap<unknown, unknown> 이 되고, 그 뒤로는 무엇을 해도 안 잡힙니다.
local literalMap = stl.HashMap.FromTable({ a = 1 })
local caveat1 = literalMap:Get(42) -- 키 타입이 틀렸는데 안 잡힘 (K 가 unknown)
literalMap:Set(true, "아무거나") -- 키가 boolean 인데 안 잡힘

local canary: string = 42

return {
	okGet, okOr, okHas, okLen, okKeys, okValues, okRemoved, okRecords,
	okFirstKey, okFirstValue, okClone, okSum, okAdd, okSetHas, okItems,
	okUnion, okSubset, okSetClone, okAlgoKeys,
	neg1, neg2, neg3, neg4, neg6, neg7, neg8, neg9, neg10, neg11,
	caveat1, canary,
}

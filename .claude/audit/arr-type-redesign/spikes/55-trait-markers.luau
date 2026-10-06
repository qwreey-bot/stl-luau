--!strict
--[[
	트레이트와 팬텀 마커의 타입 (2026-10-06, 시제품).

	`Algorithm` 이 구현을 손으로 받지 않고(값의 타입 토큰으로 트레이트에서 찾음) 원소·키·
	값 타입을 **트레이트 마커**(타입에만 있는 필드 `__list`/`__mapKey`/`__mapValue`)에서
	추론하는지. 예전엔 `Algorithm.Keys<<HashMap<string, number>, string, number>>(HashMap, m)`.
	사용자 컨테이너·사용자 트레이트도 같은 모양으로 들어오는지.

	기대 진단: 8건 (NEG 여섯이 7건 — neg6 은 두 자리 + CANARY 1)
]]
local stl = require("../../../../src")
local Arr, HashMap, TreeMap, Algorithm, Trait = stl.Arr, stl.HashMap, stl.TreeMap, stl.Algorithm, stl.Trait
type Arr<T> = stl.Arr<T>

local nums = Arr.Of(10, 20, 30)
local words = Arr.Of("a", "b")
local ages = HashMap.New<<string, number>>()
local ranks = TreeMap.New<<number, string>>(stl.Common.compareNumber)

--[[ POS — 타입 인자 없이 ]]
local pos: number? = Algorithm.IndexOf(nums, 20)
local cnt: number = Algorithm.Count(words, function(w)
	return w == "a"
end)
local keys: { string } = Algorithm.Keys(ages)
local values: { number } = Algorithm.Values(ages)
local rankKeys: { number } = Algorithm.Keys(ranks)
-- 사용자 리스트: 토큰 + 마커를 타입에 적고 구현을 등록
type Pair<T> = { read __t: stl.TraitToken<string>, read __list: T, read __listIndex: number, a: T, b: T }
local PairType = Trait.NewType("Pair")
local pairOps: stl.ListOps<Pair<any>, any, number> = {
	Get = function(p: Pair<any>, i: number): any
		return if i == 1 then p.a elseif i == 2 then p.b else nil
	end,
	FirstIndex = function(_: Pair<any>): number?
		return 1
	end,
	LastIndex = function(_: Pair<any>): number?
		return 2
	end,
	NextIndex = function(_: Pair<any>, i: number): number?
		return if i < 2 then i + 1 else nil
	end,
	PrevIndex = function(_: Pair<any>, i: number): number?
		return if i > 1 then i - 1 else nil
	end,
}
Trait.Impl(Trait.List, PairType, pairOps)
local pair: Pair<string> = { __t = PairType, a = "x", b = "y" } :: any
local inPair: number? = Algorithm.IndexOf(pair, "y")
-- 사용자 트레이트를 우리 Arr 에 붙이기 — 구현 타입이 ImplOf 로 돌아옴
type Show = { read Show: (any) -> string }
local ShowTrait = Trait.New<<Show>>("Show")
Trait.Impl(ShowTrait, Trait.Types.Arr, {
	Show = function(_: any): string
		return "arr"
	end,
})
local shown = Trait.ImplOf(ShowTrait, nums)
local text: string? = if shown then shown.Show(nums) else nil

--[[ NEG — 트레이트가 갈리는가 ]]
local neg1 = Algorithm.IndexOf(ages, 1) -- 맵은 리스트가 아님
local neg2 = Algorithm.Keys(nums) -- 리스트는 맵이 아님
local neg3: { number } = Algorithm.Keys(ages) -- 키 타입
local neg4: { string } = Algorithm.Values(ages) -- 값 타입
local neg5: Arr<number> = { n = 3 } -- 생성자를 거치지 않은 리터럴은 Arr 이 아님(토큰 없음)
local neg6: number = if shown then shown.Show(nums) else "" -- ImplOf 가 구현 타입을 돌려줌

local canary: string = 42

return { pos, cnt, keys, values, rankKeys, inPair, text, neg1, neg2, neg3, neg4, neg5, neg6, canary }

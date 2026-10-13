--!strict
--[[
	트레이트와 팬텀 마커의 타입 (2026-10-06, 시제품).

	트레이트의 진입점(`stl.List.IndexOf` 등)이 구현을 손으로 받지 않고(값의 타입 토큰으로 트레이트에서 찾음) 원소·키·
	값 타입을 **트레이트 마커**(타입에만 있는 필드 `__list`/`__mapKey`/`__mapValue`)에서
	추론하는지. 예전엔 `Map.Keys<<HashMap<string, number>, string, number>>(HashMap, m)`.
	사용자 컨테이너·사용자 트레이트도 같은 모양으로 들어오는지.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 스물다섯 줄 · 26건 — neg6 은 두 자리 + CANARY 1)
]]
local stl = require("../../../../src")
local Arr, HashMap, FlatMap, Trait = stl.Arr, stl.HashMap, stl.FlatMap, stl.Trait
type Arr<T> = stl.Arr<T>

local nums = Arr.Of(10, 20, 30)
local words = Arr.Of("a", "b")
local ages = HashMap.New<<string, number>>()
local ranks = FlatMap.New<<number, string>>(stl.Common.compareNumber)

--[[ POS — 타입 인자 없이 ]]
local pos: number? = stl.List.IndexOf(nums, 20)
local cnt: number = stl.List.Count(words, function(w)
	return w == "a"
end)
local keys: { string } = stl.Map.Keys(ages)
local values: { number } = stl.Map.Values(ages)
local rankKeys: { number } = stl.Map.Keys(ranks)
-- 사용자 리스트: 토큰 + 마커를 타입에 적고 구현을 등록
type Pair<T> = { read __type: stl.TraitToken<string>, read __list: T, read __listIndex: number, a: T, b: T }
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
Trait.Impl(stl.List, PairType, pairOps)
local pair: Pair<string> = { __type = PairType, a = "x", b = "y" } :: any
local inPair: number? = stl.List.IndexOf(pair, "y")
-- 사용자 트레이트를 우리 Arr 에 붙이기 — 구현 타입이 ImplOf 로 돌아옴
type Show = { read Show: (any) -> string }
local ShowTrait = Trait.New<<Show>>("Show")
Trait.Impl(ShowTrait, stl.Arr.Token, {
	Show = function(_: any): string
		return "arr"
	end,
})
local shown = Trait.ImplOf(ShowTrait, nums)
local text: string? = if shown then shown.Show(nums) else nil

--[[ NEG — 트레이트가 갈리는가 ]]
local neg1 = stl.List.IndexOf(ages, 1) -- 맵은 리스트가 아님
local neg2 = stl.Map.Keys(nums) -- 리스트는 맵이 아님
local neg3: { number } = stl.Map.Keys(ages) -- 키 타입
local neg4: { string } = stl.Map.Values(ages) -- 값 타입
local neg5: Arr<number> = { n = 3 } -- 생성자를 거치지 않은 리터럴은 Arr 이 아님(토큰 없음)
local neg6: number = if shown then shown.Show(nums) else "" -- ImplOf 가 구현 타입을 돌려줌
-- 토큰**만** 빠진 꼴 — 마커는 다 있어서 토큰 필드가 정말 막는지(리뷰 1라운드: 리터럴 NEG 는
-- 마커도 같이 빠져 토큰을 지워도 안 잡혔음). 2026-10-12 에 데이터 타입에 팬텀 둘(`__xxxMut`,
-- `__collectionMut`)이 더해지고 여기를 안 채워, 다시 "토큰을 지워도 이 줄이 남는" 상태였습니다
-- (2026-10-13 리뷰가 토큰 필드를 지워 확인) — 채웠습니다. 데이터 타입에 필드를 더하면 여기도.
type ArrLike = {
	n: number,
	read __list: number,
	read __listIndex: number,
	read __listMut: (number, number) -> (number, number),
	read __collectionMut: true,
	[number]: number,
}
type MapLike = {
	data: { [string]: number },
	size: number,
	read __mapKey: string,
	read __mapValue: number,
	read __mapMut: (string, number) -> (string, number),
	read __collectionMut: true,
}
type SetLike = {
	map: stl.HashMap<number, number>,
	read __setItem: number,
	read __setMut: (number) -> number,
	read __collectionMut: true,
}
local neg7: Arr<number> = (nil :: any) :: ArrLike
local neg8: stl.HashMap<string, number> = (nil :: any) :: MapLike
local neg9: stl.HashSet<number> = (nil :: any) :: SetLike
-- 마커만 흉내 내고 토큰이 없는 평범한 테이블은 공용 알고리즘에 못 들어감(Gemini 트레이트 검토
-- Case 1 — 마커가 토큰을 요구하기 전엔 타입은 통과하고 런타임에 터졌음)
type MarkerOnly = { read __list: number, read __listIndex: number }
local neg10 = stl.List.IndexOf((nil :: any) :: MarkerOnly, 1)
-- 맵·셋 마커도 토큰을 요구(2라운드 — ListMarker 만 대조돼 Map/SetMarker 의 `__type` 을 빼도 통과)
local function keyOf<K, V>(map: stl.MapMarker<K, V>): K?
	return nil
end
local function itemOf<T>(set: stl.SetMarker<T>): T?
	return nil
end
local neg11 = keyOf((nil :: any) :: { read __mapKey: string, read __mapValue: number })
local neg12 = itemOf((nil :: any) :: { read __setItem: number })

--[[ 기본 구현을 가진 트레이트(2026-10-13, papers/07 1단계) — 완성 표의 타입과 구현이 넘기는 표의 타입 ]]
type Shape = { read __type: stl.TraitToken<string>, side: number }
-- 구현이 넘기는 표: 필수(`Area`) + **재정의할 수 있는 것은 선택 필드**(`Describe?`). 필수만 적으면 재정의 자리는
-- 검사되지 않았습니다(`Describe = "문자열"` 이 0건 — 1단계 리뷰).
type ShapeCore = { read Area: (s: Shape) -> number, read Describe: ((s: Shape) -> string)? }
type ShapeFull = { read Area: (s: Shape) -> number, read Describe: (s: Shape) -> string }
local ShapeTrait = Trait.New<<ShapeFull>>("Shape", {
	required = { "Area" },
	defaults = function(ops: any)
		return {
			Describe = function(s: Shape): string
				return `area {ops.Area(s)}`
			end,
		}
	end,
}) :: stl.Trait<ShapeFull, ShapeCore>
local SquareType = Trait.NewType("Square")
-- 구현은 필수 함수만(ShapeCore) — 완성 표(ShapeFull)의 Describe 는 기본 구현이 채움
Trait.Impl(ShapeTrait, SquareType, {
	Area = function(s: Shape): number
		return s.side * s.side
	end,
})
local square: Shape = { __type = SquareType, side = 3 } :: any
local shapeOps = Trait.ImplOf(ShapeTrait, square)
local described: string? = if shapeOps then shapeOps.Describe(square) else nil
-- 맞는 재정의는 통과
Trait.Impl(ShapeTrait, Trait.NewType("Round"), {
	Area = function(s: Shape): number
		return s.side
	end,
	Describe = function(_s: Shape): string
		return "round"
	end,
})
-- NEG: 넘기는 표의 타입이 어긋남 / 재정의 자리 / 완성 표의 함수 타입 / 없는 함수
Trait.Impl(ShapeTrait, Trait.NewType("Bad"), { Area = "not a function" })
local function area(s: Shape): number
	return s.side
end
Trait.Impl(ShapeTrait, Trait.NewType("BadOverride"), { Area = area, Describe = "not a function" })
Trait.Impl(ShapeTrait, Trait.NewType("BadReturn"), {
	Area = area,
	Describe = function(_s: Shape): number
		return 12345
	end,
})
-- 캐스트하지 않은 평범한 트레이트도 `Impl` 이 표를 검사함(완성 표 전체를 요구)
local PlainTrait = Trait.New<<{ read Show: (v: Shape) -> string }>>("PlainShow", { required = { "Show" } })
Trait.Impl(PlainTrait, Trait.NewType("BadPlain"), { Show = 5 })
-- 인자 하나짜리 `Trait<I>` 자리에는 기본 구현 달린 트레이트(`Trait<Full, Core>`)가 안 들어감
local negOneParam: stl.Trait<ShapeFull> = ShapeTrait
local negDescribed: number? = if shapeOps then shapeOps.Describe(square) else nil
local negNoSuch = if shapeOps then shapeOps.Perimeter(square) else nil

--[[ 트레이트 모듈 — 트레이트 객체에 진입점을 얹은 것(`Trait.Module`), `Trait.Dispatch` ]]
local function describe(s: Shape): string
	return Trait.Dispatch(ShapeTrait, s, "Describe").Describe(s)
end
local ShapeModule = Trait.Module(ShapeTrait, { Describe = describe })
-- POS: 진입점 호출, 그리고 모듈이 그대로 트레이트로 쓰임(Impl·ImplOf)
local viaModule: string = ShapeModule.Describe(square)
Trait.Impl(ShapeModule, Trait.NewType("ViaModule"), { Area = area })
local moduleOps = Trait.ImplOf(ShapeModule, square)
local moduleArea: number? = if moduleOps then moduleOps.Area(square) else nil
-- NEG: 진입점의 반환 타입 / 인자 타입 / 없는 진입점 / 모듈을 거친 Impl 도 표를 검사 / Dispatch 의 완성 표 타입
local negEntryReturn: number = ShapeModule.Describe(square)
local negEntryArg = ShapeModule.Describe(12345)
local negEntryMissing = ShapeModule.Perimeter(square)
Trait.Impl(ShapeModule, Trait.NewType("BadViaModule"), { Area = "not a function" })
local negDispatch: number = Trait.Dispatch(ShapeTrait, square, "Describe").Describe(square)
-- 내장 트레이트 모듈: 없는 진입점
local negListEntry = stl.List.NoSuchEntry(Arr.Of(1))

local canary: string = 42

return {
	pos,
	cnt,
	keys,
	values,
	rankKeys,
	inPair,
	text,
	neg1,
	neg2,
	neg3,
	neg4,
	neg5,
	neg6,
	neg7,
	neg8,
	neg9,
	neg10,
	described,
	negDescribed,
	negNoSuch,
	negOneParam,
	viaModule,
	moduleArea,
	negEntryReturn,
	negEntryArg,
	negEntryMissing,
	negDispatch,
	negListEntry,
	canary,
}

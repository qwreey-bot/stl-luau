--!strict
--[[
	트레이트와 팬텀 마커의 타입 (2026-10-06, 시제품).

	트레이트의 진입점(`stl.List.IndexOf` 등)이 구현을 손으로 받지 않고(값의 타입 토큰으로 트레이트에서 찾음) 원소·키·
	값 타입을 **트레이트 마커**(타입에만 있는 필드 `__list`/`__mapKey`/`__mapValue`)에서
	추론하는지. 예전엔 `Map.Keys<<HashMap<string, number>, string, number>>(HashMap, m)`.
	사용자 컨테이너·사용자 트레이트도 같은 모양으로 들어오는지.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 21건 + CANARY 1). 2026-10-15 새 트레이트 시스템으로 옮김(질문 AY) —
	사용자 트레이트는 `Trait.Trait` 정의 + 주석 단 등록 표, 옛 `Trait<I>` 한 인자 자리·`ExpectImpl` 의 반환 타입 NEG 는 그 성질이 없어져 뺌.
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
type Pair<T> = { read __type: stl.TraitToken<string>, read __traits: { read List: stl.ListAssocRead<T, number> }, a: T, b: T }
local PairType = Trait.NewToken("Spike55.Pair")
local pairOps: stl.ListProvided<Pair<any>, any, number> = {
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
stl.List.ImplFor(PairType, pairOps)
local pair: Pair<string> = { __type = PairType, a = "x", b = "y" } :: any
local inPair: number? = stl.List.IndexOf(pair, "y")
-- 사용자 트레이트를 우리 Arr 에 붙이기 — 구현 타입이 ImplOf 로 돌아옴
local ShowTrait = Trait.Trait("Spike55.Show", function<Self>(of: Self | stl.TraitToken<string>)
	return table.freeze({ Show = Trait.Fn<<(v: Self) -> string>>() })
end)
local showArr: typeof(ShowTrait.ImplOf<<Arr<any>>>(nil :: any)) = {
	Show = function(_: Arr<any>): string
		return "arr"
	end,
}
ShowTrait.ImplFor(stl.Trait.TokenOf(stl.Arr), showArr)
local shown = ShowTrait.Of(nums)
local text: string? = shown.Show(nums)

--[[ NEG — 트레이트가 갈리는가 ]]
local neg1 = stl.List.IndexOf(ages, 1) -- 맵은 리스트가 아님
local neg2 = stl.Map.Keys(nums) -- 리스트는 맵이 아님
local neg3: { number } = stl.Map.Keys(ages) -- 키 타입
local neg4: { string } = stl.Map.Values(ages) -- 값 타입
local neg5: Arr<number> = { n = 3 } -- 생성자를 거치지 않은 리터럴은 Arr 이 아님(토큰 없음)
local neg6: number = shown.Show(nums) -- Of 가 완성 표 타입을 돌려줌
-- 토큰**만** 빠진 꼴 — 마커는 다 있어서 토큰 필드가 정말 막는지(리뷰 1라운드: 리터럴 NEG 는
-- 마커도 같이 빠져 토큰을 지워도 안 잡혔음). 2026-10-12 에 데이터 타입에 팬텀 둘(`__xxxMut`,
-- `__collectionMut`)이 더해지고 여기를 안 채워, 다시 "토큰을 지워도 이 줄이 남는" 상태였습니다
-- (2026-10-13 리뷰가 토큰 필드를 지워 확인) — 채웠습니다. 데이터 타입에 필드를 더하면 여기도.
type ArrLike = {
	n: number,
	read __traits: { read List: { read Item: () -> number, read Index: () -> number, read Mut: (number, number) -> (number, number) }, read Collection: { read Mut: true } },
	[number]: number,
}
type MapLike = {
	data: { [string]: number },
	size: number,
	read __traits: { read Map: { read Key: () -> string, read Value: () -> number, read Mut: (string, number) -> (string, number) }, read Collection: { read Mut: true } },
}
type SetLike = {
	map: stl.HashMap<number, number>,
	read __traits: { read Set: { read Item: () -> number, read Mut: (number) -> number }, read Collection: { read Mut: true } },
}
local neg7: Arr<number> = (nil :: any) :: ArrLike
local neg8: stl.HashMap<string, number> = (nil :: any) :: MapLike
local neg9: stl.HashSet<number> = (nil :: any) :: SetLike
-- 마커만 흉내 내고 토큰이 없는 평범한 테이블은 공용 알고리즘에 못 들어감(Gemini 트레이트 검토
-- Case 1 — 마커가 토큰을 요구하기 전엔 타입은 통과하고 런타임에 터졌음)
type MarkerOnly = { read __traits: { read List: { read Item: () -> number, read Index: () -> number } } }
local neg10 = stl.List.IndexOf((nil :: any) :: MarkerOnly, 1)
-- 맵·셋 마커도 토큰을 요구(2라운드 — ListRead 만 대조돼 Map/SetRead 의 `__type` 을 빼도 통과)
local function keyOf<K, V>(map: stl.MapRead<K, V>): K?
	return nil
end
local function itemOf<T>(set: stl.SetRead<T>): T?
	return nil
end
local neg11 = keyOf((nil :: any) :: { read __traits: { read Map: { read Key: () -> string, read Value: () -> number, read Mut: (string, number) -> (string, number) } } })
local neg12 = itemOf((nil :: any) :: { read __traits: { read Set: { read Item: () -> number, read Mut: (number) -> number } } })

--[[ 기본 구현을 가진 트레이트(2026-10-13, papers/07 1단계) — 완성 표의 타입과 구현이 넘기는 표의 타입 ]]
type Shape = { read __type: stl.TraitToken<string>, side: number }
-- 기본 구현이 있는 트레이트도 정의는 한 번(타입 함수 `Trait.View` 가 두 보기로 — 질문 AY). 등록 표 타입(`ShapeImpl`)은 필수(`Area`) +
-- 재정의할 수 있는 것은 **선택 칸**(`Describe?`) — 재정의 자리도 검사됩니다(필수만 적은 타입이던 때는 `Describe = "문자열"` 이 0건).
local ShapeTrait = Trait.Trait("Spike55.Shape", function<Self>(of: Self | stl.TraitToken<string>)
	return table.freeze({
		Area = Trait.Fn<<(s: Self) -> number>>(),
		Describe = Trait.Default(function(ops: any): (s: Self) -> string
			return function(s: Self): string
				return `area {ops.Area(s)}`
			end
		end),
	})
end)
type ShapeImpl = typeof(ShapeTrait.ImplOf<<Shape>>(nil :: any))
local SquareType = Trait.NewToken("Spike55.Square")
-- 구현은 필수 함수만 — 완성 표의 Describe 는 기본 구현이 채움
local squareImpl: ShapeImpl = {
	Area = function(s: Shape): number
		return s.side * s.side
	end,
}
ShapeTrait.ImplFor(SquareType, squareImpl)
local square: Shape = { __type = SquareType, side = 3 } :: any
local shapeOps = ShapeTrait.Of(square)
local described: string = shapeOps.Describe(square)
-- 맞는 재정의는 통과
local roundImpl: ShapeImpl = {
	Area = function(s: Shape): number
		return s.side
	end,
	Describe = function(_s: Shape): string
		return "round"
	end,
}
ShapeTrait.ImplFor(Trait.NewToken("Spike55.Round"), roundImpl)
-- NEG: 필수 칸 / 재정의 칸 / 재정의의 반환 타입 / 완성 표의 함수 타입 / 없는 함수
local negBad: ShapeImpl = { Area = "not a function" }
local function area(s: Shape): number
	return s.side
end
local negBadOverride: ShapeImpl = { Area = area, Describe = "not a function" }
local negBadReturn: ShapeImpl = {
	Area = area,
	Describe = function(_s: Shape): number
		return 12345
	end,
}
local negDescribed: number = shapeOps.Describe(square)
local negNoSuch = shapeOps.Perimeter(square)

--[[ 트레이트 객체에 알고리즘 진입점을 얹음(`Trait.Expose`), `Trait.ExpectImpl` ]]
local function describe(s: Shape): string
	return Trait.ExpectImpl(ShapeTrait, s, "Describe").Describe(s)
end
local ShapeModule = Trait.Expose(ShapeTrait, { DescribeOf = describe })
-- POS: 진입점 호출, 그리고 모듈이 그대로 트레이트로 쓰임(ImplFor·Of)
local viaModule: string = ShapeModule.DescribeOf(square)
ShapeModule.ImplFor(Trait.NewToken("Spike55.ViaModule"), squareImpl)
local moduleArea: number = ShapeModule.Of(square).Area(square)
-- NEG: 진입점의 반환 타입 / 인자 타입 / 없는 진입점
local negEntryReturn: number = ShapeModule.DescribeOf(square)
local negEntryArg = ShapeModule.DescribeOf(12345)
local negEntryMissing = ShapeModule.Perimeter(square)
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
	negBad,
	negBadOverride,
	negBadReturn,
	negNoSuch,
	viaModule,
	moduleArea,
	negEntryReturn,
	negEntryArg,
	negEntryMissing,
	negListEntry,
	canary,
}

--!strict
--[[
	구멍은 타입에 `T?` 로 드러난다 (2026-09-30, 질문 T (b)).

	사용자: *"러스트에 maybe uninit 과도 유사한듯. 우리가 default 가 없어서,
	채워주는걸 못 하고, 그럼 선택지가 드러내기가 가장 명시적이야."*

	예전에는 `Arr.Sized<<number>>(3)` 이 칸이 전부 `nil` 인 `Arr<number>` 를
	만들어 `Arr.Map(s, function(x: number) return x * 2 end)` 가 **진단 0건**
	으로 통과하고 런타임에 터졌다. 이 스파이크는 그 길이 막혔는지 본다:

	- `Sized` 의 `fill` 이 필수인가
	- 구멍이 생기는 생성자(`Of`/`FromTable`/`Sized(…, nil)`)가 `Arr<T?>` 를 주는가
	- `Arr<T?>` 에서 집계가 막히고, 콜백이 `T?` 를 받아야 하는가
	- 정리(`Compact`/`FillHoles`)가 `?` 를 떼는가, 제자리판은 안 떼는가

	⚠️ **알려진 구멍 하나(`hole7`)**: 네임스페이스 호출에서 콜백 원소 파라미터를
	**더 좁게**(`number` ⊂ `number?`) 적으면 통과합니다. 콜백 타입의 셋째 인자
	(`arr: ArrView<T>`)가 `T` 를 언급하고 람다가 그 인자를 생략할 때의 체커
	한계입니다 — `T?` 만의 문제가 아니라 `Arr<number | string>` 에서도 같고,
	콜론 호출·명시적 타입 인자·셋째 인자에 `T` 가 없는 모양은 잡힙니다
	(`base/typing-limits.md`). 막히면 건수가 1 늘어 배터리가 알려줍니다.

	기대 진단: 9건 (NEG 8 + CANARY 1, hole7 은 지금 0건)
]]
local stl = require("../../../../src")
local Arr = stl.Arr
type Arr<T> = stl.Arr<T>

--[[ POS ]]
local filled: Arr<number> = Arr.Sized(3, 0)
local holed: Arr<number?> = Arr.Sized<<number?>>(3, nil)
local fromOf: Arr<number?> = Arr.Of(1, nil, 3)
local fromTable: Arr<number?> = Arr.FromTable({ 1, nil, 3 })
local seen: Arr<number> = Arr.Map(holed, function(v: number?): number
	return v or 0
end)
local dense: Arr<number> = Arr.Compact(holed)
local fixed: Arr<number> = Arr.FillHoles(holed, 0)
local total: number = Arr.Sum(Arr.FillHoles(holed, 0))
local count: number = Arr.Count(holed, function(v: number?)
	return v == nil
end)

--[[ NEG ]]
local neg1 = Arr.Sized(3) -- fill 빠짐
local neg2 = Arr.Sized<<number>>(3) -- fill 빠짐(명시해도)
local neg3 = Arr.Sized<<number>>(3, nil) -- 구멍을 number 자리에
local neg4: Arr<number> = Arr.Sized<<number?>>(3, nil) -- ? 를 숨김
local neg5: Arr<number> = Arr.Of(1, nil, 3)
local neg6 = Arr.Sum(holed) -- 집계는 구멍 없는 타입만
local hole7 = Arr.Map(holed, function(v: number): number -- ⚠️ 잡혀야 하는데 안 잡힘
	return v * 2
end)
local neg8: Arr<number> = Arr.FillHolesInplace(holed, 0) -- 제자리판은 ? 를 못 뗌
local neg9: Arr<number> = Arr.FromTable({ 1, nil, 3 })
local canary: string = 42

return {
	filled, holed, fromOf, fromTable, seen, dense, fixed, total, count,
	neg1, neg2, neg3, neg4, neg5, neg6, hole7, neg8, neg9, canary,
}

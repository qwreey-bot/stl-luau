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

	⭐ `neg7` 은 **구멍이던 자리**입니다: 콜백 타입의 셋째 인자가 `ArrView<T>`
	이던 때는 네임스페이스 호출에서 원소 파라미터를 더 좁게(`number` ⊂
	`number?`) 적어도 0건이었습니다. `ArrView<T>` 를 빼서 닫았습니다(질문 V,
	`base/typing-limits.md`). `neg10` 은 같은 구멍의 유니온 판입니다.

	⭐ `neg11`/`neg12` 는 **그 다음 구멍**입니다: 처음엔 `ArrView<any>` 로 뺐는데
	`any` 가 콜백 반환을 타고 `Map`/`Flatmap` 의 결과 타입으로 새서, 셋째 인자로
	읽은 값을 아무 원소 타입에나 담을 수 있었습니다(질문 Z, 리뷰 재현).
	`ArrView<unknown>` 으로 닫았습니다.

	기대 진단: 13건 (NEG 12 + CANARY 1)
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
local neg7 = Arr.Map(holed, function(v: number): number -- ⭐ 구멍이던 자리
	return v * 2
end)
local neg8: Arr<number> = Arr.FillHolesInplace(holed, 0) -- 제자리판은 ? 를 못 뗌
local neg9: Arr<number> = Arr.FromTable({ 1, nil, 3 })
local mixed = Arr.Of<<number | string>>(1, "a")
local neg10 = Arr.Filter(mixed, function(v: number) -- 유니온에서도 같은 구멍이었음
	return v > 0
end)
local nums = Arr.Of(10, 20)
local neg11: Arr<string> = Arr.Map(nums, function(_v: number, i: number, arr) -- arr[i] 가 결과로 새면 통과
	return arr[i]
end)
local neg12: Arr<string> = Arr.Flatmap(nums, function(_v: number, i: number, arr)
	return arr[i], arr[1]
end)
local canary: string = 42

--[[ POS — 셋째 인자를 쓰려면 unknown 으로 받고 캐스트 ]]
local okView: Arr<number> = Arr.Map(nums, function(v: number, i: number, arr: stl.ArrView<unknown>): number
	return v + (arr[i] :: number)
end)

return {
	filled, holed, fromOf, fromTable, seen, dense, fixed, total, count,
	okView, neg1, neg2, neg3, neg4, neg5, neg6, neg7, neg8, neg9, neg10, neg11, neg12, canary,
}

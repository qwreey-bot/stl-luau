--!strict
--[[
	실제 `src/Optional.luau` 와 `Arr` 의 구멍 다루기 넷에 대한 음성 대조군.

	특히 본다:
	- 태그 좁히기가 실제 모듈에서 사는가
	- `Absent` 싱글턴이 어느 `Optional<T>` 자리에나 들어가는가
	- 공변 `self`(`Compact`/`ToOptionals`)가 결과에서 `?` 를 빼는가
	- ⭐ `FillHoles` 에 다른 타입을 넣으면 잡히는가 — 공변으로 받던 초안에서
	  `T` 가 넓어져 **통과**하던 건전성 구멍이다

	기대 진단: 11건 (NEG 10 + CANARY 1)
]]
local stl = require("../../../../src")
local Optional = stl.Optional
type Optional<T> = stl.Optional<T>
type Arr<T> = stl.Arr<T>

local p: Optional<number> = Optional.Present(3)
local a: Optional<number> = Optional.Absent
local s: Optional<string> = Optional.Absent -- Absent 는 어느 T 에나

--[[ POS ]]
if p.isPresent then
	local okNarrow: number = p.value
	print(okNarrow)
end
local okUnwrap: number = Optional.Unwrap(p)
local okOr: number = Optional.UnwrapOr(a, 0)
local okMap: Optional<string> = Optional.Map(p, function(v: number): string
	return tostring(v)
end)
local okNil: number? = Optional.ToNil(p)
local okIs: boolean = stl.isOptional(p)

local maybe = stl.Arr.Of<<number?>>(1, nil, 3)
local plain = stl.Arr.Of(1, 2, 3)
local okCompact: Arr<number> = maybe:Compact() -- ? 가 빠짐
local okCompactIn: Arr<number> = maybe:CompactInplace()
local okOpts: Arr<Optional<number>> = maybe:ToOptionals()
local okOptsPlain: Arr<Optional<number>> = plain:ToOptionals()
local okFillSum: number = plain:FillHoles(0):SumUnchecked()

--[[ NEG ]]
if p.isPresent then
	local neg1: string = p.value -- 좁힌 값은 number
	print(neg1)
end
local neg2: string = Optional.Unwrap(p)
local neg3 = Optional.UnwrapOr(p, "문자열") -- fallback 타입이 다름
local neg4: Optional<number> = Optional.Map(p, function(v: number): string
	return tostring(v)
end)
local neg5: Optional<number> = s -- Optional<string> 을 Optional<number> 에
local neg6: Arr<string> = maybe:Compact()
local neg7: Arr<Optional<string>> = maybe:ToOptionals()
local neg8 = maybe:FillHoles("문자열") -- ⭐ 건전성 구멍이던 자리
local neg9 = plain:FillHoles("문자열")
local neg10 = Optional.Nope
local canary: string = 42

return {
	okUnwrap, okOr, okMap, okNil, okIs, okCompact, okCompactIn, okOpts, okOptsPlain, okFillSum,
	neg2, neg3, neg4, neg5, neg6, neg7, neg8, neg9, neg10, canary,
}

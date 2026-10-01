--!strict
--[[
	명시적 타입 인자가 있으면 콜백 파라미터 주석이 필요 없다 (2026-10-02, quad 탐사 B).

	`typing-limits.md` 는 "`f<<T>>` 는 콜백 파라미터 주석 요구를 안 없앤다" 고 적었는데
	그건 **콜론 시절**(`nums:Map<<number>>(function(v) …)`)의 실측이었습니다.
	네임스페이스 호출(`Arr.Map<<number>>(a, function(v) …)`)에서는 **풀립니다** —
	람다의 `v` 가 `number` 로 들어가고(NEG 1), 결과 타입도 람다 반환에서 추론되고
	(NEG 2), 구멍 든 원소면 `number?` 로 들어가 산술이 막힙니다(NEG 3).
	`spikes/52` 의 솔버 구멍도 같은 처방으로 막힙니다.

	LIMIT 은 **남아 있는 한계**를 에러로 고정한 것입니다 — 사라지면(=솔버가 나아지면)
	기대치를 내리고 `typing-limits.md` 를 고치세요.

	기대 진단: 9건 (NEG 셋이 6건 — 한 식에 여럿 + LIMIT 2 + CANARY 1)
]]
local stl = require("../../../../src")
local Arr = stl.Arr
type Arr<T> = stl.Arr<T>

local nums = Arr.Of(5, 2, 8)
local holed = Arr.Of<<number?>>(5, nil, 8)

--[[ POS — 타입 인자만 주고 람다는 맨몸 ]]
local doubled: Arr<number> = Arr.Map<<number>>(nums, function(v)
	return v * 2
end)
local labels: Arr<string> = Arr.Map<<number, string>>(nums, function(v)
	return tostring(v)
end)
local big = Arr.Filter<<number>>(nums, function(v)
	return v > 3
end)
local found = Arr.Find<<number>>(nums, function(v)
	return v == 8
end)
local sorted = Arr.Sort<<number>>(nums, function(a, b)
	return a > b
end)
local total: number = Arr.Fold<<number, number>>(nums, 0, function(acc, v)
	return acc + v
end)
local maybe = Arr.Map<<number, number?>>(nums, function(v) -- 분기마다 다른 반환도
	if v > 4 then
		return nil
	end
	return v
end)

--[[ NEG — 람다 파라미터가 정말 타입을 받았는가 ]]
local neg1 = Arr.Map<<number>>(nums, function(v)
	return v.foo -- v 는 number
end)
local neg2: Arr<string> = Arr.Map<<number>>(nums, function(v)
	return v * 2 -- 결과는 Arr<number>
end)
local neg3 = Arr.Map<<number?>>(holed, function(v)
	return v * 2 -- 구멍: v 는 number?
end)

--[[ LIMIT — 타입 인자 없이는 아직 안 됨 ]]
local lim1 = Arr.Map(nums, function(v) -- "Consider placing the following annotations"
	return v * 2
end)
local lim2 = Arr.Map(nums, function(v: number) -- 첫 return 이 G 를 굳힘(nil), 둘째가 어긋남
	if v > 4 then
		return nil
	end
	return v
end)

local canary: string = 42

return {
	doubled, labels, big, found, sorted, total, maybe,
	neg1, neg2, neg3, lim1, lim2, canary,
}

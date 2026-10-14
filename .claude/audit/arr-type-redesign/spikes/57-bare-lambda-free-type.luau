--!strict
--[[
	맨 람다가 결과 타입을 비워 둔다 — 새 솔버 결함, 조용한 쪽 (2026-10-06, AC 2라운드 리뷰).

	타입 인자도 파라미터 주석도 없는 람다(`function(p) return p.name end`)를 제네릭 함수에 넘기면,
	몸통이 산술·비교로 파라미터를 제약하지 **않는** 한 진단 0건으로 통과하고 결과 원소가 **아무
	타입에나** 들어갑니다(실행하면 다른 타입). 몸통이 산술로 제약하면(`v * 2`) "Consider placing
	the following annotations" 로 에러 — `spikes/54` LIMIT 1, 업스트림 #2168. (비교 `v < 3` 은 에러
	없이 바르게 풀립니다 — 리뷰 확인.) 이 파일은 그 반대편(에러가
	안 나는 쪽)을 고정합니다. 라이브러리 없이도 재현되고(`Map2`), `--solver=old` 는 잡습니다.

	**처방**: 콜백을 넘길 땐 `f<<T>>` 나 파라미터 주석 중 하나를 **항상** 붙입니다(CTRL).

	⭐ **luau 0.742 에서 고쳐졌습니다**(2026-10-14 버전 올리기 — HOLE 셋이 잡히기 시작함). 기대 진단: 7건
	(HOLE 3 + CTRL 3 + CANARY 1). 처방(콜백엔 `f<<T>>` 나 주석)은 그대로 권합니다 — 맨 람다는 몸통이 산술이면 여전히 에러.
]]
local stl = require("../../../../src")
local Arr = stl.Arr
type P = { name: string, age: number }
local people: stl.Arr<P> = Arr.Of({ name = "a", age = 1 })
local nums = Arr.Of(1, 2)
local function Map2<T, G>(_xs: { T }, _f: (T) -> G): { G }
	return {}
end

--[[ HOLE — 0.734 까지 0건이었음, 0.742 부터 잡힘 ]]
local names = Arr.Map(people, function(p)
	return p.name
end)
local hole1: number = names[1] -- 실제로는 string
local same = Arr.Map(nums, function(v)
	return v
end)
local hole2: string = same[1] -- 실제로는 number
local hole3: { string } = Map2({ 1, 2 }, function(v)
	return v
end)

--[[ CTRL — 타입 인자나 주석을 주면 잡힘 ]]
local typed = Arr.Map<<P, string>>(people, function(p)
	return p.name
end)
local ctrl1: number = typed[1]
local annotated = Arr.Map(nums, function(v: number)
	return v
end)
local ctrl2: string = annotated[1]
local ctrl3: { string } = Map2({ 1, 2 }, function(v: number)
	return v
end)

local canary: string = 42

return { hole1, hole2, hole3, ctrl1, ctrl2, ctrl3, canary }

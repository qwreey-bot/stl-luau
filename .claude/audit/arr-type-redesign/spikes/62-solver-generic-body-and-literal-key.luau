--!strict
--[[
	새 솔버 결함 둘 — 조용한 쪽 (2026-10-12, 질문 AM 리뷰가 범위 밖에서 발견). 라이브러리 없이 재현됩니다.

	1. **제네릭 함수의 몸통이 타입 변수로 검사되지 않습니다.** `local function h<V>(v: V): number return v end`
	   가 진단 0건이고 `h("str")` 은 `"str"` 을 돌려줍니다(타입은 `number`). 그래서 불변 마커(`spikes/61`)는
	   **호출 자리만** 지킵니다 — 제네릭 안에서 `put(m, k, "bad")` 처럼 다시 부르는 것은 0건.
	2. **문자열 키 리터럴을 인덱서 파라미터에 넘기면** 값 타입을 안 봅니다. `plain({ x = "bad" })`
	   (`t: { [string]: number }`)가 0건 — `HashMap.FromTable<<string, number>>({ x = "bad" })` 도 그래서 0건.
	   (배열 리터럴 `plain({ "bad" })` 은 잡힙니다 — CTRL.)

	HOLE 은 지금 0건이 기대치입니다 — 잡히기 시작하면(솔버가 나아지면) 기대치를 올리고 `typing-limits.md`·
	질문 AA 를 고치세요. 기대 진단: 줄 번호는 scripts/spike-expectations.tsv (CTRL 2줄 3건 + CANARY 1)
]]
local stl = require("../../../../src")

--[[ HOLE 1 — 제네릭 몸통 ]]
local function h<V>(v: V): number
	return v -- 잡혀야 함: V 는 number 가 아님
end
local hole1: number = h("str") -- 실제로는 string

--[[ HOLE 2 — 문자열 키 리터럴 → 인덱서 ]]
local function plain(t: { [string]: number }): number
	return t.x
end
local hole2: number = plain({ x = "bad" }) -- 실제로는 string
local hole3 = stl.HashMap.FromTable<<string, number>>({ x = "bad" })

--[[ CTRL — 같은 실수의 다른 모양은 잡힘 ]]
local function mono(v: string): number
	return v -- 제네릭이 아니면 잡힘
end
local ctrlArray = plain({ "bad" }) -- 배열 리터럴은 잡힘

local canary: string = 42

return { hole1, hole2, hole3, mono, ctrlArray, canary }

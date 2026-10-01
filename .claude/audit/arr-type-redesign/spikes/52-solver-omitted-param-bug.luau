--!strict
--[[
	⚠️ **Luau 새 솔버의 결함을 지켜보는 감시 스파이크** (2026-10-01).
	우리 코드가 아니라 체커를 봅니다. 업스트림이 고치면 건수가 늘어 배터리가
	알려줍니다 — 그때 `Arr` 콜백의 셋째 인자를 `ArrView<unknown>` 에서
	`ArrView<T>` 로 되살릴 수 있는지 다시 재세요(`question.md` V·Z·AA).

	결함: 제네릭 `T` 를 추론해야 하는 호출에서, 람다가 **`T` 가 공변·불변으로
	나오는 뒤쪽 인자를 생략**하면 람다 인자 주석이 `T` 에 주는 상한이 버려집니다.
	좁은 타입뿐 아니라 **아예 다른 타입**도 통과합니다(`hole3`). 옛 솔버
	(`--solver=old`)는 전부 잡습니다. 명시적 타입 인자(`F<<number?>>(…)`)나
	제네릭이 아닌 함수, 람다가 그 인자를 선언하는 경우는 잡힙니다.

	기대 진단: 4건 (CTRL 3 + CANARY 1) — HOLE 셋은 지금 0건이 기대치입니다.
	HOLE 이 잡히기 시작하면 이 파일의 기대치를 올리고 위 재검토를 하세요.
]]

local function F<T>(x: T, fn: (T, T) -> ()) end
local function F1<T>(x: T, fn: (T) -> ()) end
local maybe: number? = nil
local text: string = "x"

--[[ HOLE — 잡혀야 하는데 지금 0건 ]]
F(maybe, function(_v: number) end) -- 좁은 주석
F(text, function(_v: number) end) -- 아예 다른 타입
F(maybe, function(_v: number, ...) end) -- 가변인자로 받아도

--[[ CTRL — 잡힘(대조) ]]
F1(maybe, function(_v: number) end) -- 생략할 뒤 인자가 없음
F(maybe, function(_v: number, _w) end) -- 람다가 그 인자를 선언함
F<<number?>>(maybe, function(_v: number) end) -- 명시적 타입 인자
local canary: string = 42

return canary

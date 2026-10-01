--!strict
--[[
	BSearch — 정렬된 배열 위의 이분 탐색. **컨테이너를 모릅니다.**

	평범한 Lua 배열(`{ E }`)과 **개수**를 받습니다. `#` 를 쓰지 않는 것은 이
	저장소의 다른 컨테이너와 같은 이유입니다(희소·꼬리 nil). `TreeMap`/
	`TreeSet` 이 이걸 백엔드로 씁니다.

	## ⭐ 여기가 3방향 비교자가 값을 하는 자리입니다

	정렬은 불리언 `LessThan` 이 빠릅니다(`table.sort` 가 그 모양이라 래퍼가
	없음). 그런데 **탐색은 "작다/같다/크다" 를 한 번에 알아야** 합니다 —
	불리언만 있으면 같은지 알려고 양방향으로 두 번 물어야 하니 호출이 2배입니다.
	그래서 이 모듈은 `Types.Comparator`(3방향)를 받습니다.
	(근거: `.claude/base/perf-measurements.md` 5절, `src/Common.luau` 상단)

	## 비교 함수의 모양

	```lua
	probe(element, target) -> number   -- 음수면 element 가 앞, 0 이면 같음
	```

	**원소 타입 `E` 와 찾는 값의 타입 `K` 가 달라도 됩니다.** 레코드 배열에서
	키로 찾는 경우가 그렇습니다 — `TreeMap` 이 정확히 그렇게 씁니다.
	`E == K` 면 `Types.Comparator<T>` 를 그대로 넘기면 됩니다.

	## 반환 규약

	`LowerBound`/`UpperBound` 는 **삽입 위치**를 돌려줍니다 — `1 .. count + 1`
	입니다. 원소 위치(`1 .. count`)보다 하나 넓다는 데 주의하세요. 그 자리에
	넣으면 정렬이 유지됩니다.
]]
local Common = require("./Common")
Common.registerSource(debug.info(1, "s"))

export type Probe<E, K> = (element: E, target: K) -> number

local exports = {}

-- `target` 보다 **앞서지 않는** 첫 위치. 같은 값이 여럿이면 그 중 첫 번째.
-- 전부 `target` 보다 앞서면 `count + 1`.
function exports.LowerBound<E, K>(list: { E }, count: number, target: K, probe: Probe<E, K>): number
	local low = 1
	local high = count + 1
	while low < high do
		-- (low + high) // 2 는 Luau 의 number 가 double 이라 오버플로가 없습니다.
		const mid = (low + high) // 2
		if probe(list[mid], target) < 0 then
			low = mid + 1
		else
			high = mid
		end
	end
	return low
end

-- `target` 보다 **뒤서는** 첫 위치. 같은 값이 여럿이면 그 다음 자리.
function exports.UpperBound<E, K>(list: { E }, count: number, target: K, probe: Probe<E, K>): number
	local low = 1
	local high = count + 1
	while low < high do
		const mid = (low + high) // 2
		if probe(list[mid], target) <= 0 then
			low = mid + 1
		else
			high = mid
		end
	end
	return low
end

-- 같은 값이 있으면 그 위치, 없으면 `nil`.
-- 같은 값이 여럿이면 **첫 번째**입니다(`LowerBound` 와 같은 자리).
function exports.Find<E, K>(list: { E }, count: number, target: K, probe: Probe<E, K>): number?
	const pos = exports.LowerBound(list, count, target, probe)
	if pos <= count and probe(list[pos], target) == 0 then
		return pos
	end
	return nil
end

-- 같은 값의 구간 `[first, last]`. 없으면 `nil`.
-- 한 번의 `LowerBound` 로 시작을 찾고, 없으면 `UpperBound` 를 아예 부르지
-- 않습니다 — 없는 값을 찾는 게 흔한 경우라 그쪽을 짧게 뺍니다.
function exports.EqualRange<E, K>(list: { E }, count: number, target: K, probe: Probe<E, K>): (number?, number?)
	const first = exports.LowerBound(list, count, target, probe)
	if first > count or probe(list[first], target) ~= 0 then
		return nil, nil
	end
	return first, exports.UpperBound(list, count, target, probe) - 1
end

-- 정렬돼 있는지 검사합니다. **테스트와 디버깅용입니다** — O(n) 이라 평소
-- 경로에서 부르지 마세요.
function exports.IsSorted<E>(list: { E }, count: number, probe: Probe<E, E>): boolean
	for idx = 2, count do
		if probe(list[idx - 1], list[idx]) > 0 then
			return false
		end
	end
	return true
end

return exports

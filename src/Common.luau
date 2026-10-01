--!strict
--[[
	Common — 런타임 헬퍼. 얇은 어댑터와 기본 전략만 둡니다.

	컨테이너 본체에서 타입별 분기를 없애는 게 목적입니다. 여기에 로직을
	쌓지 마세요 — 컨테이너가 자기 일을 하는 데 필요한 **작은 조각**만 둡니다.

	## ⭐ 비교의 통화가 둘인 이유 (실측으로 갈림)

	| 정렬 방식 | 20만 개 정렬 | 배수 |
	|---|---|---|
	| `table.sort(t)` — 비교자 없음 | 0.0151s | 0.22x |
	| `table.sort(t, lt)` — 불리언 비교자 | 0.0678s | **1.00x (기준)** |
	| 3방향 비교자를 래퍼로 감싸서 넘김 | 0.1233s | **1.82x** |

	(20만 개 × 5회 중 최소, luau 0.734)

	`table.sort` 가 받는 것은 **불리언** 이라, 3방향 비교자를 쓰려면 비교마다
	클로저가 한 겹 더 붙습니다. 그래서:

	- **정렬의 기본 통화는 `LessThan`**(불리언)입니다. `table.sort` 에 그대로
	  넘어갑니다. 호스트 언어가 그 모양이라는 점도 같은 방향입니다.
	- **정렬된 구조에서의 탐색은 `Comparator`**(3방향)입니다. 이분 탐색이나
	  트리는 "작다/같다/크다" 를 한 번에 알아야 하는데, 불리언으로 같은지
	  알려면 두 번 물어야 합니다.
	- 둘 사이는 아래 어댑터로 건넙니다. **어댑터를 쓰면 비용이 눈에 보이게**
	  하려고 일부러 자동 변환을 넣지 않았습니다.
]]
local Types = require("./Types")

type Comparator<T> = Types.Comparator<T>
type LessThan<T> = Types.LessThan<T>

local exports = {}

--[[ 리스트 길이 규약 (2026-10-01, M0 3라운드) ]]

-- `{ T }` 를 받는 진입점이 리스트의 길이를 재는 **하나의 규칙**: `n` 이 0 이상의
-- 정수로 있으면 그것(`Arr`, `table.pack` 결과), 없으면 `#`. `#`/`pairs` 로 읽으면
-- `Arr` 의 `n` 과 태그 키까지 원소로 담거나(`HashSet.FromList(Arr.Of(10, 20))` 의
-- 크기가 4) 구멍 뒤를 잃었습니다(`CloneFromTable`). `Fut.All` 이 먼저 쓰던 규칙입니다.
function exports.listLength(list: any): number
	const n = rawget(list, "n")
	if type(n) == "number" and n >= 0 and n == math.floor(n) and n < math.huge then
		return n + 0 -- `-0 + 0 = +0` — 결과 배열의 `n` 이 "-0" 으로 찍히지 않게
	end
	return #list
end

-- 위 규칙의 길이까지 돌며 **구멍을 건너뛴** 조밀한 사본(메타테이블 없는 평범한
-- 배열)과 그 개수.
function exports.denseList<T>(list: { T }): ({ T }, number)
	const len = exports.listLength(list)
	const out = table.create(len) :: { T }
	local count = 0
	for idx = 1, len do
		const item = list[idx]
		if item ~= nil then
			count += 1
			out[count] = item
		end
	end
	return out, count
end

--[[ 기본 3방향 비교자 ]]

-- ⚠️ `a - b` 로 쓰면 안 됩니다 — `math.huge - math.huge` 가 NaN 이라 무한대가
-- 자기 자신과 "같지 않다" 고 나와 TreeMap 이 무한대 키를 중복으로 넣고
-- 못 찾았습니다(2026-09-30 리뷰). 비교 연산자로 답합니다.
-- NaN 은 무엇과도 작지도 크지도 않아 0 이 나옵니다 — 정렬 구조가 NaN 키를
-- 받지 않는 이유입니다(TreeMap 이 거절).
function exports.compareNumber(a: number, b: number): number
	if a < b then
		return -1
	elseif a > b then
		return 1
	end
	return 0
end

function exports.compareString(a: string, b: string): number
	if a < b then
		return -1
	elseif a > b then
		return 1
	end
	return 0
end

--[[ 어댑터 ]]

-- 3방향 → 불리언. 정렬에 3방향 비교자를 쓰고 싶을 때.
-- **비용**: 비교마다 호출이 한 겹 더 붙어 정렬이 약 1.82배 느려집니다(실측).
-- 그래도 쓸 값어치가 있는 경우가 많지만, 공짜가 아니라는 것만 알고 쓰세요.
function exports.lessFrom<T>(compare: Comparator<T>): LessThan<T>
	return function(a: T, b: T): boolean
		return compare(a, b) < 0
	end
end

-- 불리언 → 3방향. 탐색 계열에 불리언 비교자밖에 없을 때.
-- **비용**: 같음을 판정하려면 양방향으로 물어야 해서 **호출이 2배**입니다.
-- 3방향을 직접 줄 수 있으면 그게 낫습니다.
function exports.compareFrom<T>(less: LessThan<T>): Comparator<T>
	return function(a: T, b: T): number
		if less(a, b) then
			return -1
		elseif less(b, a) then
			return 1
		end
		return 0
	end
end

return exports

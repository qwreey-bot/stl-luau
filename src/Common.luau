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
-- 크기가 4) 구멍 뒤를 잃었습니다(`FromTable`). `Fut.All` 이 먼저 쓰던 규칙입니다.
function exports.listLength(list: any): number
	-- 테이블이 아닌 값(타입 없는 코드에서 가장 흔한 것이 `nil`)은 아래 `rawget` 이 라이브러리 줄에서 죽었습니다
	-- (2라운드 리뷰). 호출마다 검사 하나 — 원소마다가 아닙니다.
	if type(list) ~= "table" then
		exports.raise(`stl: expected a list (plain table, table.pack result or Arr), got {typeof(list)}`)
	end
	const n = rawget(list, "n")
	-- 유효한 `n` 은 한 번만 판정합니다 — 두 갈래에 따로 적었더니 한쪽만 줄이는 실수를 테스트가
	-- 못 잡을 자리가 생겼습니다(리뷰 5라운드).
	const validN = type(n) == "number" and n >= 0 and n == math.floor(n) and n < math.huge
	-- **다른 종류의 컨테이너**(타입 토큰이 있고 이름이 Arr 가 아님)는 `n` 이 있든 없든 리스트가
	-- 아닙니다 — `n` 이 없으면 `#` 가 0 이라 조용히 빈 결과(2026-10-06 Gemini 트레이트 검토 —
	-- `HashSet.FromList(map)`), `n` 이 개수인 링 버퍼면 1..n 으로 조용히 잘못 읽었습니다(리뷰 4라운드).
	-- 이름 "Stl.Arr"(토큰 이름 — 2026-10-15 부터 `Stl.` 접두)는 다른 사본의 Arr 도 받으려고(Common 은 Trait 를 모름 — 순환). 메시지는 내부 모듈
	-- 이름(Common) 없이 라이브러리 이름으로(리뷰 2라운드).
	const token = rawget(list, "__type")
	if token ~= nil then
		const name = if type(token) == "table" then rawget(token, "name") else nil
		if name ~= "Stl.Arr" then
			-- 바꾸는 길을 안내합니다(2026-10-07 가로지른 리뷰 — CircularDeque 를 넣으면 무엇을 하라는지 몰랐음)
			exports.raise(
				`stl: expected a list (plain table, table.pack result or Arr), got {tostring(name or token)} — convert it first (e.g. CircularDeque.ToArr, HashSet.Items)`
			)
		end
		if not validN then
			exports.raise(`stl: an Arr with an invalid n ({tostring(n)}) — its n must be a non-negative integer`)
		end
	end
	if validN then
		-- 길이 정책(`[0, 2^26]`, `table.create` 한계) — 너무 큰 `n` 은 입양되거나 위치 없는
		-- `table overflow` 였습니다(AC 리뷰). 숫자 인자 정책과 같은 메시지.
		if n > 2 ^ 26 then
			exports.raise(`stl: list length must be in [0, {2 ^ 26}] (got {n})`)
		end
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
-- 자기 자신과 "같지 않다" 고 나와 FlatMap 이 무한대 키를 중복으로 넣고
-- 못 찾았습니다(2026-09-30 리뷰). 비교 연산자로 답합니다.
-- NaN 은 무엇과도 작지도 크지도 않아 0 이 나옵니다 — 정렬 구조가 NaN 키를
-- 받지 않는 이유입니다(FlatMap 이 거절).
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

--[[ 에러는 사용자 줄을 가리킵니다 (2026-10-02, quad 탐사 C) ]]

-- `error(msg, 2|3)` 처럼 프레임을 손으로 세면 **-O2 에서 틀립니다** — 로컬 헬퍼가
-- 인라인되면 프레임이 사라지는데, 어느 것이 인라인될지는 컴파일러 휴리스틱입니다
-- (`NthElement` 의 `k` NaN 은 라이브러리 줄을, 같은 level 3 인 `Slice` 는 사용자 줄을
-- 가리켰음). 라이브 Roblox 는 -O2 가 기본입니다. 그래서 세지 않고 **걷습니다**:
-- 스택을 위로 올라가며 **라이브러리 파일이 아닌 첫 프레임**에서 에러를 냅니다.
-- 인라인돼도 사라진 프레임은 어차피 라이브러리 것이라 답이 같습니다.
--
-- - 콜백 안에서 부른 라이브러리 함수의 에러는 그 콜백 줄을 가리킵니다(콜백이
--   사용자 파일이므로) — 손으로 센 level 과 같은 뜻입니다.
-- - C 함수가 바로 부르면(`pcall(Arr.At, a, 0/0)`) 첫 비라이브러리 프레임이 C 라
--   위치 접두가 빠집니다. 메시지는 그대로입니다.
-- - 걷는 비용은 에러 경로에만 듭니다. 핫패스는 그대로입니다.
-- - 한계(재현 못 함, 리뷰 추측): Roblox 의 청크 이름은 인스턴스 전체 이름이라 이름이
--   같은 형제 스크립트가 있으면 사용자 프레임을 라이브러리로 볼 수 있고, 라이브러리
--   사본이 둘이면 각 사본은 자기 파일만 압니다. 번들러(darklua 등)가 사용자 코드와
--   라이브러리를 **한 청크로** 합치면 사용자 프레임도 라이브러리로 보여 스택 끝까지 걸어
--   위치가 빠집니다(Gemini 지적, 추정). 셋 다 위치 접두만 어긋나고 메시지는 그대로입니다.
--
-- **라이브러리 내부용**입니다(`stl.Common` 으로 보이지만 공개 API 가 아님 — 밖에서 부르면
-- 걷기의 출발점이 달라 줄이 한 프레임 어긋날 수 있습니다, 7라운드 리뷰).
-- 모듈은 로드할 때 `registerSource(debug.info(1, "s"))` 로 자기 파일을 알립니다.
-- 경로 접두사로 맞추지 않는 것은 require 경로에 따라 청크 이름이 달라질 수 있어서입니다.
const librarySources: { [string]: true } = {}

function exports.registerSource(source: string)
	librarySources[source] = true
end
exports.registerSource(debug.info(1, "s"))

-- `transact` 안이면 0 보다 큼 — 그동안 라이브러리 코드가 바로 낸 `raise` 는 위치를 붙이지 않고 표식 값으로 던집니다(아래 `transact`
-- 가 받아 되돌린 뒤 **자기 자리에서** 다시 `raise` 해 사용자 줄을 찾음). `pcall` 안에서 걸으면 첫 비라이브러리 프레임이 `pcall` 의
-- C 프레임이라 위치가 빠지기 때문입니다.
local deferring = 0
const DEFERRED = table.freeze({})

function exports.raise(message: string): never
	local level = 2
	while true do
		const source = debug.info(level, "s")
		if source == nil then
			-- 스택 끝까지 라이브러리 — 가리킬 사용자 줄이 없습니다.
			error(message, 0)
		end
		if not librarySources[source] then
			-- 묶음(`transact`) 안에서 처음 만난 비라이브러리 프레임이 그 `pcall`(C)이면 위치를 미룸 — 사용자 코드(뭉텅이의 builder,
			-- 기본 구현 빌더) 안이면 그 줄이 맞으니 그대로 던짐.
			if deferring > 0 and source == "[C]" then
				return exports.rethrow({ [DEFERRED] = message })
			end
			break
		end
		level += 1
	end
	error(message, level)
end

-- 받은 에러 값을 **그대로** 다시 던집니다(위치를 덧붙이지 않음 — 문자열이면 홉마다
-- 쌓이고, 테이블이면 원래 값이 바뀌면 안 됨). 라이브러리 밖의 `error(` 는 이것과
-- `raise` 둘로만 갑니다 — 새 에러를 `error(msg, 0)` 으로 내면 위치가 안 붙는데 되던지기와
-- 겉모양이 같아 게이트가 못 가렸습니다(3라운드 리뷰). 그래서 둘을 이름으로 가릅니다.
function exports.rethrow(value: any): never
	error(value, 0)
end

-- 실패하면 되돌려야 하는 묶음(트레이트 등록 — 등록부의 기록과 지은 표)을 돌립니다. `fn` 이 던지면 `undo` 를 부르고 다시 던집니다:
-- 라이브러리의 `raise` 는 여기서 다시 `raise` 해 **사용자 줄**을 가리키고(묶음 안의 위치는 버림), 그 밖의 값(사용자 코드 — 뭉텅이의
-- builder 등이 던진 것)은 그대로. 실패한 등록이 반쯤 남아 그 뒤 무관한 `NewToken` 마다 던지던 것을 막으려고 둡니다(2026-10-15
-- 트레이트 리뷰 2~4라운드 — 같은 뿌리가 라운드마다 한 겹씩 깊어져 뿌리를 막음). 비용은 등록할 때만.
function exports.transact(fn: () -> (), undo: () -> ())
	deferring += 1
	const ok, err = pcall(fn)
	deferring -= 1
	if ok then
		return
	end
	undo()
	if type(err) == "table" and rawget(err :: any, DEFERRED) ~= nil then
		exports.raise(rawget(err :: any, DEFERRED))
	end
	exports.rethrow(err)
end

-- 비교자 인자가 함수인지. 정렬 구조의 생성자가 씁니다 — 빈 구조에서는 비교가 일어나지 않아 `nil` 비교자가
-- 조용히 통과하고 나중에(둘째 원소를 넣을 때) 라이브러리 줄에서 `attempt to call a nil value` 였습니다
-- (`nil` 키와 같은 모양, 2026-10-13 리뷰). `who` 는 메시지 머리(`"TreeMap: New"`).
function exports.expectComparator(compare: any, who: string)
	if type(compare) ~= "function" then
		exports.raise(`{who} needs a comparator function, got {typeof(compare)}`)
	end
end

return exports

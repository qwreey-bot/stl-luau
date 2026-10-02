--!strict
--[[
	Arr — 배열 컨테이너. 이 저장소에서 가장 성숙한 모듈입니다.

	## 표현

	`{ n: number, [number]: T }` 입니다. 길이는 **`n` 이 진실**이고 `#` 를
	믿지 않습니다 — 희소 배열과 꼬리 `nil` 문제를 피하기 위함입니다. 1..n
	사이에 `nil` 구멍이 있을 수 있고, 그걸 각 메소드가 어떻게 다루는지는
	메소드마다 주석에 적습니다.

	## ⭐ 구멍은 타입에 드러납니다 (`Arr<T?>`)

	Rust 의 `MaybeUninit` 과 같은 결입니다 — 기본값이 없는 언어라 칸을 대신
	채워줄 수 없으니, **비어 있을 수 있는 칸은 타입이 `T?` 라고 말하게** 합니다.
	구멍이 생기는 생성자는 전부 `Arr<T?>` 를 돌려주거나(`Of(1, nil, 3)`,
	`FromTable({ 1, nil, 3 })`), 명시를 요구합니다(`Sized(n, fill)` 의 `fill`
	은 필수 — 구멍을 원하면 `Arr.Sized<<number?>>(n, nil)`).

	그래서 두 갈래가 어긋나지 않습니다:

	- **콜백 계열**(`Map`/`Filter`/`Fold`/`Count`/`Find`/`Some`/`Every`/`Reduce`
	  …)은 구멍을 **`nil` 그대로 콜백에 넘깁니다.** 타입이 `Arr<number?>` 면
	  콜백도 `number?` 를 받으니 건전합니다 — `Map(a, function(v) return v or
	  0 end)` 처럼 구멍을 **보고 싶을 때** 볼 수 있습니다.
	- **집계·정렬**(`Sum`/`Prod`/`Max`/`Min`/`Sort`/`Join`)은 `ArrData<number>`
	  처럼 구멍 없는 타입을 받으므로 `Arr<number?>` 에서는 타입이 먼저
	  `Compact`/`FillHoles` 를 하라고 알려줍니다. 그래도 구멍을 **건너뛰는**
	  것은 캐스트나 직접 대입(`a[5] = nil`)으로 타입이 거짓말할 때를 위한
	  **런타임 그물**입니다 — 그 그물을 걷은 게 `*Unchecked` 입니다.

	## ⭐ 데이터는 엔티티, 함수는 서비스 (2026-10-01, 질문 AB)

	배열은 **메타테이블 없는 평범한 테이블**이고, 모든 연산은 이 모듈의
	**네임스페이스 함수**입니다(`Arr.Map(a, fn)`). 콜론 호출(`a:Map(fn)`)은
	없습니다 — Luau 표준 라이브러리(`table`/`buffer`/`coroutine`)와 같은 모양.

	- **속도**: 메타테이블이 붙은 테이블은 `t[i]` 가 1.59배 느렸습니다. 떼고 나니
	  사용자 루프 0.57~0.70x, `Sum` 0.69x(perf 16-2절). `local` 로 받아 부르면
	  호출도 더 빠릅니다(perf 14절).
	- **타입**: 함수가 타입 **바깥**에 있으니 `Arr<T>` 는 데이터부 그 자체입니다.
	  메소드 교집합·재귀 별칭 우회·"계약 멤버 재선언 금지" 같은 규칙이 필요 없습니다.
	- **확장**: `Arr<T>` 를 받는 함수는 누구나 같은 모양으로 더할 수 있습니다 —
	  라이브러리에 묶이지 않습니다.

	| 타입 | 무엇 |
	|---|---|
	| `Arr<T>` = `ArrData<T>` | `{ n: number, [number]: T }` — 사용자가 들고 다니는 것 |
	| `ArrView<T>` | 읽기 전용 `{ read n, read [number]: T }` — **콜백이 받는 셋째 인자** |

	⭐ **콜백 타입에서는 `T` 를 언급하지 않습니다(`ArrView<unknown>`).** 언급하면
	콜백 원소를 더 좁게 적은 것(`Arr<number?>` 에 `function(v: number)`)을 체커가
	놓칩니다 — Luau 새 솔버의 결함입니다(질문 V·Z·AA, `spikes/50`·`52`).

	## 성능 (.claude/base/perf-measurements.md)

	- 메타테이블이 없으니 `self[i]` 에 세금이 없습니다. 그래도 **`table.move`/
	  `table.create` 가 원소 루프보다 빠릅니다** — 벌크로 할 수 있는 일을 원소
	  루프로 쓰지 마세요.
	- 가변인자 다수 처리는 `table.pack` 이 아니라 `select` 루프입니다(1.6~2.3배).
	- 편의가 기본 경로를 느리게 만들지 않습니다. `PushBack(v)` 는 고정 인자고
	  가변인자 편의는 `PushBackMany(...)` 로 옆에 있습니다.

	## 구간 규약 (Lua 관례를 따릅니다)

	닫힌 구간 `[start, last]`, 음수 인덱스 지원(`-1` = 마지막), 범위를 넘으면
	clamp, 뒤집힌 구간은 조용히 빈 결과. `string.sub` 와 같은 규약입니다.

	⚠️ **삽입 위치는 원소 위치보다 범위가 하나 넓습니다**(`1 .. n+1`).
	조회용 clamp 로 삽입 위치까지 처리하면 "맨 뒤에 삽입" 이 표현 불가능해집니다
	— 실제로 그 버그를 낸 선례가 있습니다. 그래서 정규화 함수를 둘로 나눴습니다.
]]
local Types = require("./Types")
local Common = require("./Common")
Common.registerSource(debug.info(1, "s"))
local Optional = require("./Optional")

type LessThan<T> = Types.LessThan<T>
type Optional<T> = Optional.Optional<T>

-- `read __arr__: true` 는 **타입에만 드러난 태그**입니다 — 런타임엔 생성자가 붙이는
-- 실제 필드이고, 타입에 두면 생성자를 거치지 않은 리터럴(`{ n = 3 }`)이 `Arr`
-- 자리에 들어가는 것을 막습니다(M0 리뷰: 교집합을 걷어낸 뒤 열린 구멍).
export type ArrData<T> = { n: number, read __arr__: true, [number]: T }

-- 콜백이 셋째 인자로 받는 뷰 — **읽기 전용**입니다. 콜백 안에서 배열을 바꾸면
-- 순회가 망가지니 타입이 막습니다. 원소 타입은 `unknown` 으로 씁니다(아래).
export type ArrView<T> = { read n: number, read [number]: T }

-- 콜백 타입은 **가장 넓은 시그니처 하나**로 씁니다. Luau 는 인자를 덜 받는
-- 함수를 이미 서브타입으로 받아주므로 arity 별 오버로드가 필요 없습니다.
-- 교집합(`&`)으로 늘어놓으면 "모든 arity 를 동시에 만족" 을 요구해서
-- `function(x: number) return tostring(x) end` 같은 정상 콜백이 거부됩니다(실측).
--
-- ⭐ 셋째 인자는 **`ArrView<unknown>`** 입니다.
-- - `ArrView<T>` 로 두면 네임스페이스 호출(`Arr.Map(a, fn)`)에서 람다가 그
--   인자를 생략할 때 원소 파라미터를 더 좁게 적은 것(`number?` 자리에
--   `v: number`)이 **진단 0건으로 통과**했습니다(2026-09-30 실측, 질문 V).
-- - `ArrView<any>` 로 두면 그 구멍은 닫히지만 `any` 가 **결과 타입으로
--   샜습니다** — `Arr.Map(nums, function(v, i, arr) return arr[i] end)` 를
--   `Arr<string>` 에 담아도 0건(리뷰 재현, 질문 Z).
-- 대가: 콜백 안 `arr[i]` 는 `unknown` 이라 쓰려면 캐스트하고, 주석은
-- `arr: ArrView<unknown>` 으로만 답니다(`ArrView<number>` 는 에러).
-- 드물게 쓰는 셋째 인자의 편의를 내주고 모든 콜백의 건전성을 삽니다.
export type Mapper<T, G> = (element: T, index: number, arr: ArrView<unknown>) -> G
export type Predicate<T> = (element: T, index: number, arr: ArrView<unknown>) -> boolean
export type Folder<T, U> = (accumulator: U, element: T, index: number, arr: ArrView<unknown>) -> U
export type UntilFolder<T, U> = (accumulator: U, element: T, index: number, arr: ArrView<unknown>) -> (U, boolean?)
-- 값을 여러 개 돌려줄 수 있는 변환 콜백. `Flatmap` 계열이 씁니다.
export type Spreader<T, G> = (element: T, index: number, arr: ArrView<unknown>) -> ...G
-- `[min, max]` 의 **정수**를 돌려줘야 합니다(`math.random` 모양, Roblox 는
-- `Random:NextInteger`). 실수(`NextNumber`)나 범위 밖이면 **에러**입니다 —
-- 자르거나 가두면 분포가 조용히 치우칩니다. 균등성은 rng 책임입니다.
export type Rng = (min: number, max: number) -> number

const TAG = "__arr__"

--#region ----------- 내부 헬퍼 -----------

-- 조회용 구간 정규화. 닫힌 구간 `[start, last]`, 음수는 끝에서부터,
-- 범위를 벗어나면 clamp. 뒤집힌 구간은 그대로 돌려주고 **호출자가 검사**합니다
-- (`start > last` 이면 빈 구간).
-- 정수가 아닌 인덱스는 **0 쪽으로 자릅니다** — Luau 자신이 그렇습니다
-- (`string.sub("abcdef", 1.5)` 는 1, `-1.5` 는 -1). 자르지 않으면 `table.move`/
-- `table.create` 에 소수가 그대로 들어가 회전이 아니라 뒤섞임이 나왔습니다
-- (2026-09-30 리뷰).
const function toIndex(x: number): number
	return if x >= 0 then math.floor(x) else math.ceil(x)
end

const function resolveRange(len: number, start: number?, last: number?): (number, number)
	const st = if start == nil then nil else toIndex(start)
	const la = if last == nil then nil else toIndex(last)
	-- NaN 은 clamp 할 방향이 없습니다. 그냥 두면 `table.move` 의 엉뚱한 에러나
	-- (`Some`/`Every` 에서) 조용한 무동작이 됐습니다(2026-09-30 리뷰).
	if st ~= st or la ~= la then
		Common.raise("Arr: range bound is NaN")
	end
	local s = if st == nil then 1 elseif st < 0 then len + st + 1 else st
	local l = if la == nil then len elseif la < 0 then len + la + 1 else la
	if s < 1 then
		s = 1
	end
	if l > len then
		l = len
	end
	return s, l
end

-- 삽입 위치 정규화. **유효 범위가 `1 .. len + 1` 로 하나 넓습니다** —
-- `len + 1` 이 "맨 뒤에 붙이기" 입니다. 조회용과 같은 함수를 쓰면 이게
-- 표현 불가능해집니다.
const function resolveInsertPos(len: number, at: number): number
	-- NaN 은 가둘 방향이 없습니다. `InsertArray` 는 값이 음수 키로 조용히
	-- 사라졌습니다(2026-09-30 3라운드 리뷰). 구간 NaN 과 같은 정책.
	if at ~= at then
		Common.raise("Arr: insert position is NaN")
	end
	const whole = toIndex(at)
	local pos = if whole < 0 then len + whole + 1 else whole
	if pos < 1 then
		pos = 1
	elseif pos > len + 1 then
		pos = len + 1
	end
	return pos
end

-- 날 테이블에 길이와 태그를 붙여 배열로 만듭니다. 생성자들이 공유합니다.
-- **메타테이블은 없습니다**(질문 AB) — 태그는 `isArr` 의 판별용입니다.
const function wrap<T>(raw: { [number]: T }, len: number): Arr<T>
	const result = raw :: any
	result.n = len
	result[TAG] = true
	return result
end

-- `table.create` 가 받는 최대 크기(실측: 2^26 은 되고 그 위는 "table overflow").
-- 그보다 긴 길이는 라이브러리 줄의 엉뚱한 에러 대신 우리 메시지로 거절합니다.
const MAX_LENGTH = 2 ^ 26

-- 길이 인자. 소수는 구간 규약처럼 0 쪽으로 자르고, 음수·NaN 은 에러입니다
-- (`Sized(2.5, 0)` 이 `n = 2.5` 를 만들어 뒤에 넣은 값이 3.5 키로 사라졌음,
-- 2026-09-30 리뷰).
const function checkLength(len: number, who: string): number
	const count = toIndex(len)
	if not (count >= 0) or count > MAX_LENGTH then
		Common.raise(`Arr: {who} length must be in [0, {MAX_LENGTH}] (got {len})`)
	end
	-- `-0 + 0 = +0` — `Sized(-0.5)` 가 `n = -0` 을 만들었습니다(`tostring` 이 "-0").
	return count + 0
end

const function newSized<T>(len: number): Arr<T>
	return wrap(table.create(len) :: any, len)
end

const function isArrRaw(value: any): boolean
	if type(value) ~= "table" or rawget(value, TAG) ~= true then
		return false
	end
	-- `n` 은 0 이상의 유한 정수여야 — 위조 `n = 0/0`·`-1` 을 `Flat` 이 입양하면
	-- 라이브러리 줄 에러나 조용한 유실이었습니다(M0 3라운드).
	const n = rawget(value, "n")
	return type(n) == "number" and n >= 0 and n == math.floor(n) and n < math.huge
end

--#endregion

--#region ----------- 계약 구현 (Types.ListOps) -----------
-- 이 모듈 테이블이 그대로 `Types.ListOps` 구현체입니다 — `Algorithm.IndexOf(Arr, a, x)`.

const function Get<T>(self: ArrData<T>, idx: number): T?
	return self[idx]
end
const function FirstIndex<T>(self: ArrData<T>): number?
	return if self.n > 0 then 1 else nil
end
const function LastIndex<T>(self: ArrData<T>): number?
	return if self.n > 0 then self.n else nil
end
const function NextIndex<T>(self: ArrData<T>, idx: number): number?
	return if idx < self.n then idx + 1 else nil
end
const function PrevIndex<T>(self: ArrData<T>, idx: number): number?
	return if idx > 1 then idx - 1 else nil
end

--#endregion

--#region ----------- 조회 -----------

-- ⚠️ 위 계약 함수들(`Get`/`FirstIndex`/`LastIndex`/`NextIndex`/`PrevIndex`)은
-- **숫자 정책(NaN 에러, 소수 자르기) 밖**입니다 — `FirstIndex`/`NextIndex` 가
-- 준 위치를 그대로 돌려받는 자리라 검사를 붙이지 않습니다(매 조회의 분기).
-- 거기에 NaN·소수·무한을 넣으면 조용히 `nil` 이거나 순회가 끝나지 않습니다.

-- 음수를 받는 단일 조회. `At(-1)` 은 마지막 원소입니다(JS `Array.prototype.at`).
-- 소수는 구간 규약처럼 0 쪽으로 자릅니다. **범위 밖은 clamp 하지 않고 `nil`** —
-- 구간은 "가능한 만큼" 이 자연스럽지만 단일 조회에서 가장 가까운 칸을 주면
-- 거짓말이 됩니다.
--
-- `Get` 은 계약(`Types.ListOps`) 멤버라 **원시 조회**로 둡니다 — 알고리즘이
-- `FirstIndex`/`NextIndex` 로 얻은 위치를 그대로 넣는 자리이고, 거기에 음수
-- 변환을 끼우면 매 조회에 분기가 붙습니다.
const function At<T>(self: ArrData<T>, idx: number): T?
	-- NaN 은 "범위 밖" 이 아니라 인자 오류입니다(구간·k 의 NaN 과 같은 정책).
	if idx ~= idx then
		Common.raise("Arr: At index is NaN")
	end
	const len = self.n
	const i = toIndex(idx)
	const pos = if i < 0 then len + i + 1 else i
	if pos < 1 or pos > len then
		return nil
	end
	return self[pos]
end

const function Len<T>(self: ArrData<T>): number
	return self.n
end

const function Empty<T>(self: ArrData<T>): boolean
	return self.n == 0
end

-- `for i, v in Arr.Iter(arr) do … end`
-- ⭐ 반환 타입을 `(number, T)` 로 **일부러 비옵셔널로** 선언합니다. 끝에서는
-- `nil` 을 돌려주지만 타입에 드러내지 않습니다 — 드러내면 루프 변수가
-- 옵셔널이 되어 산술에 바로 못 씁니다. Luau 자신의 `ipairs` 도 같은 방식입니다.
-- 메타테이블이 없으니 `__iter` 자리도 없습니다(질문 AB) — 순회는 이 함수로.
-- (예전 교집합 타입 시절에도 `__iter` 는 타입을 잃었고 이 방식은 살았음, spikes/37.)
const function iterStep<T>(self: ArrData<T>, idx: number): (number, T)
	const nextIdx = idx + 1
	if nextIdx > self.n then
		return nil :: any, nil :: any
	end
	return nextIdx, self[nextIdx]
end

const function Iter<T>(self: ArrData<T>): (typeof(iterStep), ArrData<T>, number)
	return iterStep, self, 0
end

const function Unpack<T>(self: ArrData<T>): ...T
	return table.unpack(self :: any, 1, self.n)
end

-- 구분자로 이어붙입니다. `nil` 구멍은 건너뜁니다.
const function Join<T>(self: ArrData<T>, delimiter: string?): string
	const len = self.n
	const parts = table.create(len)
	local count = 0
	for idx = 1, len do
		const item = self[idx]
		if item ~= nil then
			count += 1
			parts[count] = tostring(item)
		end
	end
	return table.concat(parts, delimiter or "", 1, count)
end

-- 길이와 원소가 모두 같은가. 원소 비교는 `==` 입니다.
const function Equal<T>(self: ArrData<T>, other: ArrData<T>): boolean
	const len = self.n
	if len ~= other.n then
		return false
	end
	for idx = 1, len do
		if self[idx] ~= other[idx] then
			return false
		end
	end
	return true
end

-- 조건을 만족하는 원소의 개수.
const function Count<T>(self: ArrData<T>, fn: Predicate<T>): number
	local total = 0
	for idx = 1, self.n do
		if fn(self[idx], idx, self :: any) then
			total += 1
		end
	end
	return total
end

-- 처음으로 조건을 만족하는 원소와 그 위치. 없으면 `nil, nil`.
const function Find<T>(self: ArrData<T>, fn: Predicate<T>): (T?, number?)
	for idx = 1, self.n do
		const item = self[idx]
		if fn(item, idx, self :: any) then
			return item, idx
		end
	end
	return nil, nil
end

-- 하나라도 만족하는가. 구간 인자를 받습니다.
const function Some<T>(self: ArrData<T>, fn: Predicate<T>, start: number?, last: number?): boolean
	local s, l = resolveRange(self.n, start, last)
	for idx = s, l do
		if fn(self[idx], idx, self :: any) then
			return true
		end
	end
	return false
end

-- 전부 만족하는가. 빈 구간이면 참입니다(공허 참).
const function Every<T>(self: ArrData<T>, fn: Predicate<T>, start: number?, last: number?): boolean
	local s, l = resolveRange(self.n, start, last)
	for idx = s, l do
		if not fn(self[idx], idx, self :: any) then
			return false
		end
	end
	return true
end

-- 가장 큰 원소. 빈 배열이면 `nil`. `nil` 구멍은 건너뜁니다.
-- 비교자는 **불리언** `LessThan` 입니다 — 3방향 비교자를 쓰려면
-- `Common.lessFrom(cmp)` 로 감싸세요(정렬이 1.82배 느려지는 대신).
const function Max<T>(self: ArrData<T>, less: LessThan<T>?): T?
	local best: T? = nil
	for idx = 1, self.n do
		const item = self[idx]
		if item ~= nil then
			if best == nil then
				best = item
			elseif if less then less(best :: T, item) else (best :: any) < (item :: any) then
				best = item
			end
		end
	end
	return best
end

-- 가장 작은 원소. 빈 배열이면 `nil`. `nil` 구멍은 건너뜁니다.
const function Min<T>(self: ArrData<T>, less: LessThan<T>?): T?
	local best: T? = nil
	for idx = 1, self.n do
		const item = self[idx]
		if item ~= nil then
			if best == nil then
				best = item
			elseif if less then less(item, best :: T) else (item :: any) < (best :: any) then
				best = item
			end
		end
	end
	return best
end

-- 합. **숫자 배열에서만 부를 수 있습니다** — `Arr<string>` 에서 부르면
-- 타입 에러입니다. `nil` 구멍은 건너뜁니다(핫 루프에서 13% 비용).
const function Sum(self: ArrData<number>, base: number?): number
	local acc = base or 0
	for idx = 1, self.n do
		const item = self[idx]
		if item ~= nil then
			acc += item
		end
	end
	return acc
end

-- 곱. `Sum` 과 같은 규약이고 기본 씨앗은 1 입니다.
const function Prod(self: ArrData<number>, base: number?): number
	local acc = base or 1
	for idx = 1, self.n do
		const item = self[idx]
		if item ~= nil then
			acc *= item
		end
	end
	return acc
end

--#region ----------- ⚠️ unchecked 계열 — 안전을 포기하고 고르는 것 -----------
--[[
	위의 `Max`/`Min`/`Sum`/`Prod`/`Sort` 는 1..n 사이의 `nil` 구멍을 **건너뜁니다.**
	구멍이 있어도 터지지 않는 대신 원소마다 검사가 한 번 붙습니다.

	여기 있는 `*Unchecked` 판은 **그 검사를 빼는 대신 "구멍이 없다" 를 전제**
	합니다. 배열에 무엇이 들어 있는지는 **호출자만 아는 것**이지 이 라이브러리가
	아는 것이 아니므로, 판단을 호출자에게 넘기는 문입니다(Rust 의
	`get_unchecked` 계열과 같은 발상).

	⚠️ **거의 항상 검사 있는 쪽을 쓰세요.** 이건 측정해서 이 자리가 정말
	병목이라고 확인했을 때만 고르는 것입니다. **얻는 것이 얼마인지 알고
	고르라고** 수치를 같이 둡니다(원소 20만/200만, 2026-09-22 실측 — **M0 이전,
	메타테이블이 있던 때**의 콜론 호출이라 지금은 checked 쪽도 빨라져 배수가
	다를 수 있습니다. 다시 재면 perf 11절에 덧붙이세요):

	| 무엇 | 빨라지는 정도 |
	|---|---|
	| `MaxUnchecked` / `MinUnchecked` | **1.83배** |
	| `SortInplaceUnchecked` | 1.18배 |
	| `SumUnchecked` / `ProdUnchecked` | 1.08배 |

	`Max`/`Min` 이 유독 큰 것은 검사 있는 판이 원소마다 `nil` 검사에 더해
	**"아직 첫 값을 못 찾았는가"(`best == nil`) 분기까지** 보기 때문입니다.
	`Sum` 의 8% 는 작지만 두 크기에서 똑같이 나왔습니다.

	⚠️ **구멍이 있는 배열에 쓰면 어떻게 되는지**:

	| 무엇 | 구멍을 만나면 |
	|---|---|
	| `SumUnchecked` / `ProdUnchecked` | `attempt to perform arithmetic on nil` 로 **터집니다** |
	| `MaxUnchecked` / `MinUnchecked` | 비교에서 **터지거나**, 비교자를 준 경우 그 비교자에 `nil` 이 넘어갑니다 |
	| `SortUnchecked` / `SortInplaceUnchecked` | `#` 와 `n` 이 어긋나면(꼬리 구멍, `n` 밖 값) checked 판으로 넘어가 정답. 같으면 기본 비교에서 **터집니다** — 어느 쪽일지는 `#` 가 구멍 배치·쓰기 순서에 따라 아무 경계나 돌려줘 예측할 수 없습니다(실측상 checked 쪽이 56~79%). 어느 쪽이든 조용히 틀리지는 않습니다. nil 을 견디는 비교자를 주면 그 비교자에 `nil` 이 넘어갑니다 |

	예전 마지막 줄은 "구멍 뒤쪽이 조용히 잘린다" 였습니다 — M0 6라운드의 `#` 검사 뒤로는 조용한
	경로가 없습니다(2026-10-02 리뷰가 재현으로 확인).
]]

-- `Sum` 의 검사 없는 판. **구멍이 없어야 합니다.**
const function SumUnchecked(self: ArrData<number>, base: number?): number
	local acc = base or 0
	for idx = 1, self.n do
		acc += self[idx]
	end
	return acc
end

-- `Prod` 의 검사 없는 판. **구멍이 없어야 합니다.**
const function ProdUnchecked(self: ArrData<number>, base: number?): number
	local acc = base or 1
	for idx = 1, self.n do
		acc *= self[idx]
	end
	return acc
end

-- `Max` 의 검사 없는 판. **구멍이 없어야 합니다.** 빈 배열이면 `nil`.
const function MaxUnchecked<T>(self: ArrData<T>, less: LessThan<T>?): T?
	const len = self.n
	if len == 0 then
		return nil
	end
	local best = self[1]
	if less then
		for idx = 2, len do
			const item = self[idx]
			if less(best, item) then
				best = item
			end
		end
	else
		-- 비교자가 없을 때 분기를 루프 밖으로 뺍니다 — 원소마다 `if less` 를
		-- 다시 보지 않기 위함입니다.
		for idx = 2, len do
			const item = self[idx]
			if (best :: any) < (item :: any) then
				best = item
			end
		end
	end
	return best
end

-- `Min` 의 검사 없는 판. **구멍이 없어야 합니다.** 빈 배열이면 `nil`.
const function MinUnchecked<T>(self: ArrData<T>, less: LessThan<T>?): T?
	const len = self.n
	if len == 0 then
		return nil
	end
	local best = self[1]
	if less then
		for idx = 2, len do
			const item = self[idx]
			if less(item, best) then
				best = item
			end
		end
	else
		for idx = 2, len do
			const item = self[idx]
			if (item :: any) < (best :: any) then
				best = item
			end
		end
	end
	return best
end

--#endregion

--#region ----------- 구멍 다루기 -----------
--[[
	1..n 사이의 `nil` 구멍을 없애는 세 갈래. 이 셋 중 하나를 거치면
	**`*Unchecked` 계열의 전제("구멍이 없다")가 보증**되어 그 빠른 경로를
	안심하고 쓸 수 있습니다 — checked/unchecked 갈림의 세 번째 답입니다.

	| 무엇 | 길이 | 구멍 자리 |
	|---|---|---|
	| `FillHoles(v)` / `FillHolesInplace(v)` | 그대로 | `v` 로 채움 |
	| `Compact()` / `CompactInplace()` | 줄어듦 | 없앰 (순서 유지) |
	| `ToOptionals()` | 그대로 | `Optional.Absent` 로, 값은 `Present` 로 감쌈 |

	⚠️ **한 번만 쓸 거면 정리하지 마세요.** 정리 한 번이 checked 집계 한 번만큼
	듭니다. 원소 20만(구멍 10%), `Max` 를 k 번(실측):

	| k | checked | `FillHolesInplace` + unchecked |
	|---|---|---|
	| 1 | 1.00x | **0.87x (더 느림)** |
	| 2 | 1.00x | 1.15x |
	| 5 | 1.00x | 1.50x |
	| 10 | 1.00x | 1.69x |

	**한 번 정리하고 여러 번 쓸 때**(또는 데이터를 들여올 때 한 번 정리해 두는
	자리)에만 값을 합니다. `ToOptionals` 는 칸마다 테이블(128바이트)을 만들어
	checked 합의 약 5배라 성능 경로가 아니라 **표현** 경로입니다.

	`ToOptionals` 가 따로 있는 이유: 자연스러운 `Arr.Map(arr, Optional.Of)` 는
	**타입 에러**입니다 — 제네릭 함수 값을 콜백으로 그대로 넘기면 Luau 가
	`T` 를 인스턴스화하지 못합니다(실측, 명시적 타입 인자로도 안 됨).
]]

-- `FillHoles`/`Compact`/`CompactInplace`/`ToOptionals` 는 `self` 를 **읽기 전용 인덱서**로
-- 받습니다. 그래야 `Arr<number>`(런타임에만 구멍)와 `Arr<number?>`(타입에도
-- 드러남)를 **둘 다** 받으면서 `T = number` 로 잡고, 결과에서 `?` 를 뺄 수
-- 있습니다. 읽기·쓰기 인덱서는 불변이라 `Arr<number>` 가 `ArrData<number?>`
-- 자리에 안 들어갑니다(실측).
-- 팬텀 태그(`read __arr__`)까지 요구합니다 — 없으면 리터럴이나 `table.pack`
-- 결과, 콜백의 읽기 전용 뷰가 `CompactInplace` 를 거쳐 `Arr<T>` 로 둔갑했습니다
-- (M0 2라운드 — 1라운드가 막은 "리터럴이 Arr 자리에" 의 우회로).
type ArrRead<T> = { read n: number, read __arr__: true, read [number]: T }

-- 구멍을 `value` 로 채운 **새 배열**. 길이는 그대로이고 원본은 안 건드립니다.
-- `Arr<number?>` 를 받아 **`Arr<number>` 를 돌려줍니다** — 구멍을 타입에
-- 드러내는 규약(질문 T (b))에서 `?` 를 떼는 정식 경로입니다.
--
-- `value` 가 다른 타입이면(`FillHoles("x")`) `T` 가 `number | string` 으로
-- 넓어집니다. 새 배열이라 원래 변수는 그대로 `Arr<number?>` 이므로 건전합니다.
const function FillHoles<T>(self: ArrRead<T?>, value: T): Arr<T>
	const len = self.n
	-- 메타테이블 없는 날 테이블에 먼저 채우고 마지막에 씌웁니다(인덱싱 세금 회피).
	const raw = table.create(len)
	for idx = 1, len do
		const item = self[idx]
		raw[idx] = if item == nil then value else item
	end
	return wrap(raw, len)
end

-- `FillHoles` 의 제자리 판. 할당이 없습니다.
--
-- ⚠️ **이것만 `self` 가 불변(`ArrData<T>`)입니다.** 공변으로 받으면
-- `Arr.FillHolesInplace(arr, "문자열")` 이 `T` 를 `number | string` 으로 넓혀
-- **통과**하고, 제자리 변형이라 원래 변수(`Arr<number?>`)에 문자열이 들어갑니다
-- (실측 — 타입 건전성 구멍). 새 배열을 만드는 `FillHoles` 는 이 문제가 없습니다.
--
-- 대가: `Arr<number?>` 는 채운 뒤에도 `Arr<number?>` 로 남습니다. `?` 를
-- 빼야 하면 `FillHoles`(새 배열)나 `Compact` 를 쓰세요. `Arr<number>`(캐스트나
-- 직접 대입으로 런타임에만 구멍이 난 것)는 그대로
-- `Arr.SumUnchecked(Arr.FillHolesInplace(arr, 0))` 로 이어집니다.
const function FillHolesInplace<T>(self: ArrData<T>, value: T): Arr<T>
	for idx = 1, self.n do
		if self[idx] == nil then
			self[idx] = value
		end
	end
	return self :: any
end

-- 구멍을 빼고 조밀하게 모은 **새 배열**. 순서는 유지됩니다.
const function Compact<T>(self: ArrRead<T?>): Arr<T>
	const len = self.n
	const result = newSized(len)
	local count = 0
	for idx = 1, len do
		const item = self[idx]
		if item ~= nil then
			count += 1
			result[count] = item
		end
	end
	result.n = count
	return result :: any
end

-- `Compact` 의 제자리 판.
--
-- ⚠️ **입력을 소비합니다**(질문 Y): 돌려받은 값이 같은 테이블이고 `Arr<T?>` 가
-- `Arr<T>` 로 좁혀집니다. 결과만 쓰고 원래 변수는 다시 쓰지 마세요 — 원래 변수는 옛 타입
-- 그대로라 타입 검사가 못 잡습니다(Rust 의 move 와 같은 결, Luau 는 강제 못 함).
--     local dense = Arr.CompactInplace(holed)   -- 이후로는 dense 만
--     Arr.PushBack(holed, nil)                  -- ❌ dense(Arr<number>)에 구멍이 생김
const function CompactInplace<T>(self: ArrRead<T?>): Arr<T>
	const raw = self :: any
	const len = raw.n
	local count = 0
	for idx = 1, len do
		const item = raw[idx]
		if item ~= nil then
			count += 1
			raw[count] = item
		end
	end
	for idx = count + 1, len do
		raw[idx] = nil
	end
	raw.n = count
	return raw
end

-- 구멍은 `Optional.Absent` 로, 값은 `Optional.Present` 로 감싼 **새 배열**.
-- 원소마다 테이블이 하나씩 생깁니다(값이 있는 칸만) — 공짜가 아닙니다.
const function ToOptionals<T>(self: ArrRead<T?>): Arr<Optional<T>>
	const len = self.n
	const result = newSized(len)
	for idx = 1, len do
		result[idx] = Optional.Of(self[idx])
	end
	return result :: any
end

--#endregion

--#region ----------- 원소 추가 -----------

-- 맨 뒤에 하나 추가. **고정 인자입니다**(가변인자로 만들면 가장 흔한 이
-- 경로가 8~13% 느려집니다). 여러 개는 `PushBackMany`, 배열은 `PushBackArray`.
const function PushBack<T>(self: ArrData<T>, item: T): Arr<T>
	const n = self.n + 1
	self[n] = item
	self.n = n
	return self :: any
end

-- 맨 뒤에 여러 개 추가. `table.pack` 이 아니라 `select` 루프입니다(1.6~2.3배).
const function PushBackMany<T>(self: ArrData<T>, ...: T): Arr<T>
	const count = select("#", ...)
	if count == 0 then
		return self :: any
	end
	local n = self.n
	for idx = 1, count do
		n += 1
		self[n] = select(idx, ...)
	end
	self.n = n
	return self :: any
end

-- 다른 배열의 내용을 맨 뒤에 이어붙입니다. `table.move` 라 원소 수와 무관하게
-- 한 번에 끝납니다.
const function PushBackArray<T>(self: ArrData<T>, source: ArrData<T>): Arr<T>
	const sourceLen = source.n
	if sourceLen == 0 then
		return self :: any
	end
	table.move(source :: any, 1, sourceLen, self.n + 1, self :: any)
	self.n += sourceLen
	return self :: any
end

-- 맨 앞에 하나 추가. **뒤 원소를 전부 밀어야 하므로 `PushBack` 과 달리
-- O(n) 입니다** — 이름이 대칭이라고 비용까지 대칭이 아닙니다.
const function PushFront<T>(self: ArrData<T>, item: T): Arr<T>
	const len = self.n
	table.move(self :: any, 1, len, 2)
	self[1] = item
	self.n = len + 1
	return self :: any
end

-- 맨 앞에 여러 개 추가. 인자 순서가 보존됩니다(`PushFrontMany(1, 2)` 뒤엔
-- 앞에서부터 `1, 2, …` 입니다). O(n) 입니다.
const function PushFrontMany<T>(self: ArrData<T>, ...: T): Arr<T>
	const count = select("#", ...)
	if count == 0 then
		return self :: any
	end
	const len = self.n
	table.move(self :: any, 1, len, count + 1)
	for idx = 1, count do
		self[idx] = select(idx, ...)
	end
	self.n = len + count
	return self :: any
end

-- 다른 배열을 맨 앞에 이어붙입니다. O(n) 입니다.
const function PushFrontArray<T>(self: ArrData<T>, source: ArrData<T>): Arr<T>
	const sourceLen = source.n
	if sourceLen == 0 then
		return self :: any
	end
	const len = self.n
	table.move(self :: any, 1, len, sourceLen + 1)
	table.move(source :: any, 1, sourceLen, 1, self :: any)
	self.n = len + sourceLen
	return self :: any
end

-- `at` 위치에 하나 끼워넣습니다. 기존 원소는 뒤로 밀립니다.
-- **`at` 의 유효 범위는 `1 .. n + 1`** 이고 `n + 1` 이 "맨 뒤에 붙이기" 입니다.
-- 음수는 끝에서부터(`-1` = 마지막 원소 앞).
const function Insert<T>(self: ArrData<T>, at: number, item: T): Arr<T>
	const len = self.n
	const pos = resolveInsertPos(len, at)
	if pos <= len then
		table.move(self :: any, pos, len, pos + 1)
	end
	self[pos] = item
	self.n = len + 1
	return self :: any
end

const function InsertMany<T>(self: ArrData<T>, at: number, ...: T): Arr<T>
	const count = select("#", ...)
	if count == 0 then
		return self :: any
	end
	const len = self.n
	const pos = resolveInsertPos(len, at)
	if pos <= len then
		table.move(self :: any, pos, len, pos + count)
	end
	for idx = 1, count do
		self[pos + idx - 1] = select(idx, ...)
	end
	self.n = len + count
	return self :: any
end

const function InsertArray<T>(self: ArrData<T>, at: number, source: ArrData<T>): Arr<T>
	const sourceLen = source.n
	if sourceLen == 0 then
		return self :: any
	end
	const len = self.n
	const pos = resolveInsertPos(len, at)
	if pos <= len then
		table.move(self :: any, pos, len, pos + sourceLen)
	end
	table.move(source :: any, 1, sourceLen, pos, self :: any)
	self.n = len + sourceLen
	return self :: any
end

--#endregion

--#region ----------- 복제·비우기·채우기 -----------

-- 얕은 복사. 원소 자체는 공유합니다.
const function Clone<T>(self: ArrData<T>): Arr<T>
	const len = self.n
	const result = newSized(len)
	table.move(self :: any, 1, len, 1, result :: any)
	return result
end

-- 내용을 비웁니다. **`n` 도 0 이 되고 태그는 유지됩니다** — `table.clear` 를
-- 쓰면 태그까지 날아가 비운 배열이 `isArr` 를 통과 못 하는 버그가 있었습니다.
const function Clear<T>(self: ArrData<T>): Arr<T>
	for idx = 1, self.n do
		self[idx] = nil :: any
	end
	self.n = 0
	return self :: any
end

-- 구간을 같은 값으로 채웁니다. 길이는 바뀌지 않습니다.
const function Fill<T>(self: ArrData<T>, item: T, start: number?, last: number?): Arr<T>
	const s, l = resolveRange(self.n, start, last)
	for idx = s, l do
		self[idx] = item
	end
	return self :: any
end

--#endregion

--#region ----------- 구간 잘라내기·지우기·치환 -----------

-- 구간을 잘라낸 **새 배열**. `to` 를 주면 그 배열의 **뒤에 이어붙이고** 그것을
-- 돌려줍니다(누적용). 뒤집힌 구간은 빈 결과입니다.
const function Slice<T>(self: ArrData<T>, start: number?, last: number?, to: Arr<T>?): Arr<T>
	const s, l = resolveRange(self.n, start, last)
	const count = if l >= s then l - s + 1 else 0
	if to == nil then
		const result = newSized(count)
		if count > 0 then
			table.move(self :: any, s, l, 1, result :: any)
		end
		return result
	end
	if count > 0 then
		table.move(self :: any, s, l, to.n + 1, to :: any)
		to.n += count
	end
	return to
end

-- 구간만 남기고 나머지를 버립니다(제자리).
const function SliceInplace<T>(self: ArrData<T>, start: number?, last: number?): Arr<T>
	const len = self.n
	const s, l = resolveRange(len, start, last)
	if l < s then
		return Clear(self)
	end
	const count = l - s + 1
	if s > 1 then
		table.move(self :: any, s, l, 1)
	end
	for idx = count + 1, len do
		self[idx] = nil :: any
	end
	self.n = count
	return self :: any
end

-- 구간을 **지운** 새 배열. 원본은 그대로입니다.
const function Erase<T>(self: ArrData<T>, start: number?, last: number?): Arr<T>
	const len = self.n
	const s, l = resolveRange(len, start, last)
	if l < s then
		return Clone(self)
	end
	const removed = l - s + 1
	const result = newSized(len - removed)
	table.move(self :: any, 1, s - 1, 1, result :: any)
	table.move(self :: any, l + 1, len, s, result :: any)
	return result
end

-- 구간을 지웁니다(제자리).
-- ⚠️ 뒤집힌 구간에서 아무것도 안 하는 가드가 필수입니다 — 없으면 지운 개수가
-- 음수가 되어 배열이 **오히려 늘어납니다**(실제로 났던 버그).
const function EraseInplace<T>(self: ArrData<T>, start: number?, last: number?): Arr<T>
	const len = self.n
	const s, l = resolveRange(len, start, last)
	if l < s then
		return self :: any
	end
	if s == 1 and l == len then
		return Clear(self)
	end
	const removed = l - s + 1
	const afterLen = len - removed
	table.move(self :: any, l + 1, len, s)
	for idx = afterLen + 1, len do
		self[idx] = nil :: any
	end
	self.n = afterLen
	return self :: any
end

-- 구간을 `with` 의 내용으로 바꾼 **새 배열**. 길이가 달라질 수 있습니다.
-- `with` 가 비면 구간 삭제, 구간이 비면(`last < start`) 그 자리에 삽입입니다.
--
-- ⚠️ **JS 의 `splice` 와 기본값이 반대입니다.** JS 는 제자리에서 바꾸고 **지운
-- 원소들을** 돌려주지만, 여기 `Splice` 는 이 저장소 관례대로 **새 배열**을
-- 돌려주고 제자리 판은 `SpliceInplace` 입니다(자기 자신을 돌려줌). 인자도
-- 개수가 아니라 **닫힌 구간** `[start, last]` 입니다. (2026-09-30 에
-- `Replace` 에서 개명 — C++ `replace` 는 값→값 치환이라 오해를 불렀습니다.)
const function Splice<T>(self: ArrData<T>, start: number, last: number, with: ArrData<T>): Arr<T>
	const len = self.n
	const rs, l = resolveRange(len, start, last)
	-- 지울 구간이 비면 `with` 는 **삽입 위치**에 들어가므로 `1..n+1` 로 자릅니다.
	-- 안 자르면 `n` 바깥에 쓰고 가운데에 구멍이 생겼습니다(2026-09-30 리뷰).
	const s = math.min(rs, len + 1)
	const removed = if l >= s then l - s + 1 else 0
	const withLen = with.n
	const result = newSized(len - removed + withLen)
	table.move(self :: any, 1, s - 1, 1, result :: any)
	table.move(with :: any, 1, withLen, s, result :: any)
	table.move(self :: any, s + removed, len, s + withLen, result :: any)
	return result
end

-- `Splice` 의 제자리 판.
const function SpliceInplace<T>(self: ArrData<T>, start: number, last: number, with: ArrData<T>): Arr<T>
	const len = self.n
	const rs, l = resolveRange(len, start, last)
	-- 지울 구간이 비면 `with` 는 **삽입 위치**에 들어가므로 `1..n+1` 로 자릅니다.
	-- 안 자르면 `n` 바깥에 쓰고 가운데에 구멍이 생겼습니다(2026-09-30 리뷰).
	const s = math.min(rs, len + 1)
	const removed = if l >= s then l - s + 1 else 0
	const withLen = with.n
	const afterLen = len - removed + withLen
	-- 꼬리를 먼저 제자리로 옮깁니다. 줄어드는 경우와 늘어나는 경우 모두
	-- table.move 가 겹침을 알아서 처리합니다.
	table.move(self :: any, s + removed, len, s + withLen)
	table.move(with :: any, 1, withLen, s, self :: any)
	for idx = afterLen + 1, len do
		self[idx] = nil :: any
	end
	self.n = afterLen
	return self :: any
end

--#endregion

--#region ----------- 순서 바꾸기 -----------
-- `to` 인자는 이 계열에 **두지 않습니다.** "목적지에 누적" 은 스트림 계열
-- (`Slice`/`Map`/`Filter`/`Flat`)에서만 뜻이 분명하고, 여기서는 "밀어내기냐
-- 덮어쓰기냐" 가 갈려 실제로 데이터를 잃는 버그를 냈던 자리입니다.

-- 구간을 뒤집습니다(제자리).
-- 아래 세 쌍(Reverse/Rotate/Shuffle)은 **구간을 푼 뒤의 몸통**을 헬퍼로 두고
-- 두 판이 각자 구간을 풉니다. (처음엔 에러 줄 때문이었습니다 — 손으로 센 level 은
-- 새 배열판이 `XxxInplace(Clone(self))` 로 부르면 한 프레임 어긋났습니다. 지금은
-- `Common.raise` 가 스택을 걸어 깊이와 무관하지만, 구조는 그대로 둡니다.)
const function reverseRange<T>(self: ArrData<T>, s: number, l: number)
	while s < l do
		self[s], self[l] = self[l], self[s]
		s += 1
		l -= 1
	end
end

const function ReverseInplace<T>(self: ArrData<T>, start: number?, last: number?): Arr<T>
	const s, l = resolveRange(self.n, start, last)
	reverseRange(self, s, l)
	return self :: any
end

-- 구간을 뒤집은 **새 배열**(나머지는 그대로).
const function Reverse<T>(self: ArrData<T>, start: number?, last: number?): Arr<T>
	const s, l = resolveRange(self.n, start, last)
	const copy = Clone(self)
	reverseRange(copy, s, l)
	return copy
end

const function rotateRange<T>(self: ArrData<T>, shift: number, s: number, l: number)
	-- 빈 구간이어도 shift 를 먼저 봅니다 — 구간 NaN 이 빈 배열에서도 에러인 것과 같게.
	if shift ~= shift or shift == math.huge or shift == -math.huge then
		Common.raise("Arr: Rotate shift must be finite")
	end
	if l <= s then
		return
	end
	const span = l - s + 1
	-- `%` 가 아니라 `math.fmod`: Luau 의 `%` 는 `a - floor(a/b)*b` 라 |a| 가 2^53
	-- 근처를 넘으면 반올림으로 틀린 나머지(범위 밖 포함)가 나와 0 이하 키에 쓰고
	-- 뒤에 구멍을 냈습니다(2026-09-30 4라운드 리뷰, `Rotate(1e17)`). fmod 는 정확합니다.
	local k = math.fmod(toIndex(shift), span)
	if k < 0 then
		k += span
	end
	if k == 0 then
		return
	end
	const buffer = table.create(k)
	table.move(self :: any, s, s + k - 1, 1, buffer)
	table.move(self :: any, s + k, l, s)
	table.move(buffer, 1, k, l - k + 1, self :: any)
end

-- 구간을 회전합니다(제자리). **양수 shift 가 왼쪽 회전**입니다
-- (`std::rotate` 방향). 구간 길이로 나눈 나머지만 의미가 있습니다.
const function RotateInplace<T>(self: ArrData<T>, shift: number, start: number?, last: number?): Arr<T>
	const s, l = resolveRange(self.n, start, last)
	rotateRange(self, shift, s, l)
	return self :: any
end

const function Rotate<T>(self: ArrData<T>, shift: number, start: number?, last: number?): Arr<T>
	const s, l = resolveRange(self.n, start, last)
	const copy = Clone(self)
	rotateRange(copy, shift, s, l)
	return copy
end

const function shuffleRange<T>(self: ArrData<T>, s: number, l: number, rng: Rng?)
	const random = rng or math.random
	for idx = l, s + 1, -1 do
		const pick = random(s, idx)
		-- 계약 위반은 **에러**입니다. 실수(`Random:NextNumber` 모양)나 범위 밖을
		-- 그냥 쓰면 구멍과 데이터 유실이 났고(1차 리뷰), 0 쪽으로 잘라 가두면 `idx`
		-- 가 영영 안 뽑혀 사톨로 순열(24개 중 6개만)로 **조용히 치우쳤습니다**
		-- (2라운드 리뷰). NaN 도 여기서 걸립니다(`NaN ~= NaN`).
		if pick ~= math.floor(pick) or pick < s or pick > idx then
			Common.raise(`Arr: Shuffle rng must return an integer in [{s}, {idx}] (got {pick})`)
		end
		self[idx], self[pick] = self[pick], self[idx]
	end
end

-- 구간을 섞습니다(제자리). Fisher-Yates.
-- `rng` 를 주입할 수 있습니다(`(min, max) -> number`). 기본은 `math.random`
-- 이고, 테스트에서 결정적으로 만들려면 직접 넣으세요.
const function ShuffleInplace<T>(self: ArrData<T>, start: number?, last: number?, rng: Rng?): Arr<T>
	const s, l = resolveRange(self.n, start, last)
	shuffleRange(self, s, l, rng)
	return self :: any
end

const function Shuffle<T>(self: ArrData<T>, start: number?, last: number?, rng: Rng?): Arr<T>
	const s, l = resolveRange(self.n, start, last)
	const copy = Clone(self)
	shuffleRange(copy, s, l, rng)
	return copy
end

-- 1..n 중 **`nil` 이 아닌 것만** 조밀하게 모아 정렬합니다. `table.sort` 가
-- `#` 를 쓰는 문제와, 구멍이 있으면 비교가 터지는 문제를 둘 다 피합니다.
-- 사용자 비교자에도 `nil` 이 넘어가지 않습니다.
-- 구멍은 결과 뒤쪽으로 몰리고 `n` 은 보존됩니다(JS `Array.prototype.sort` 와 같음).
--
-- 비교자는 **불리언** `LessThan` 입니다 — `table.sort` 가 받는 모양 그대로라
-- 래퍼가 없습니다. 3방향 비교자가 있으면 `Common.lessFrom(cmp)` 로 감싸세요
-- (정렬이 1.82배 느려집니다).
const function sortInto<T>(self: ArrData<T>, buffer: { T }, less: LessThan<T>?): number
	local count = 0
	for idx = 1, self.n do
		const item = self[idx]
		if item ~= nil then
			count += 1
			buffer[count] = item
		end
	end
	if less then
		table.sort(buffer, less)
	else
		table.sort(buffer :: any)
	end
	return count
end

const function Sort<T>(self: ArrData<T>, less: LessThan<T>?): Arr<T>
	const len = self.n
	const buffer = table.create(len)
	const count = sortInto(self, buffer, less)
	const result = newSized(len)
	table.move(buffer, 1, count, 1, result :: any)
	return result
end

const function SortInplace<T>(self: ArrData<T>, less: LessThan<T>?): Arr<T>
	const len = self.n
	const buffer = table.create(len)
	const count = sortInto(self, buffer, less)
	table.move(buffer, 1, count, 1, self :: any)
	for idx = count + 1, len do
		self[idx] = nil :: any
	end
	return self :: any
end

-- `SortInplace` 의 검사 없는 판. **구멍이 없어야 합니다.**
-- 조밀 버퍼로 모으는 단계를 통째로 건너뛰고 `table.sort` 를 배열에 바로 겁니다.
--
-- (M0 6라운드) `#` 와 `n` 이 어긋나면 checked 판(`SortInplace`)으로 넘어갑니다 —
-- 예전엔 구멍이 있으면 뒤쪽이 정렬되지 않은 채 **조용히** 남았고, `n` 밖 raw 칸에
-- 값이 남아 있으면(대입으로 만든 테이블을 입양한 경우 — `FromTable` 의 비우기는
-- `#` 가 닿는 데까지이고 그 너머는 계약 밖) 그 값이 안으로 섞이거나 크래시했습니다. 구멍이 있어도
-- `#` 가 `n` 과 같으면 여전히 `table.sort` 가 구멍을 만나 터집니다. 어느 쪽일지는
-- 예측할 수 없습니다 — `#` 는 구멍 배치와 쓰기 순서에 따라 아무 경계나 돌려줍니다
-- (맨 `table.create` 는 끝 칸만 차면 `#` 가 n 이지만 — Gemini 실측 — `n`·태그가 해시에
-- 있는 `Arr` 은 다르고, 무작위 구멍 배열에서 checked 쪽이 56~79% — 2026-10-02 리뷰).
-- 전제("구멍 없음")는 그대로이고, 어겨도 **조용히 틀리지는 않습니다**(무작위 2만 건에서
-- 조용히 틀린 답 0).
const function SortInplaceUnchecked<T>(self: ArrData<T>, less: LessThan<T>?): Arr<T>
	-- `table.sort` 는 `n` 이 아니라 `#` 를 봅니다. `#` 와 `n` 이 어긋나면(구멍, 또는
	-- `n` 밖 raw 칸에 남은 값 — 대입으로 만든 테이블을 입양한 경우) 바깥 값이 섞이거나
	-- 크래시했습니다(M0 6라운드). 그때만 checked 판으로 — `#` 는 O(log n), 정렬 대비
	-- 0.3%(perf 17절). 구멍 검사 O(n) 을 건너뛰는 이 판의 존재 이유는 그대로입니다.
	if #(self :: any) ~= self.n then
		return SortInplace(self, less)
	end
	if less then
		table.sort(self :: any, less)
	else
		table.sort(self :: any)
	end
	return self :: any
end

-- `Sort` 의 검사 없는 판. 복사한 뒤 제자리 정렬합니다.
const function SortUnchecked<T>(self: ArrData<T>, less: LessThan<T>?): Arr<T>
	return SortInplaceUnchecked(Clone(self), less)
end

--#endregion

--#region ----------- 정렬 가족 -----------
--[[
	`table.sort` 하나로는 안 되는 정렬들. 전부 **순수 Luau** 이고 구멍은 값만
	모아 다룹니다. 배열을 그대로 돌려주는 것(`StableSort`/`SortBy` 와 모든
	`*Inplace`)은 `Sort` 와 같이 **구멍을 꼬리로 보내고 `n` 은 그대로**이고,
	`PartialSort`(길이 `min(k, 값 개수)`)·`MergeSorted`(값 개수)는 조밀한 새
	배열, `NthElement` 는 값 하나를 돌려줍니다 — 각 함수 주석이 기준입니다.

	| 무엇 | 언제 | 실측(비교자 준 `table.sort` = 1.00, 원소 10만) |
	|---|---|---|
	| `StableSort` | 같은 순위끼리 **입력 순서를 지켜야** 할 때 | 무작위 1.44x, **이미 정렬된 입력 0.11x** |
	| `SortBy(key)` | **키 계산이 비쌀 때** — 키를 원소당 한 번만 계산(안정) | 아래 ⚠️ |
	| `NthElement(k)` | k 번째 값만 필요할 때(중앙값 등) | 0.17x |
	| `PartialSort(k)` | 앞 k 개만 정렬해서 필요할 때(상위 k) | k=10: 0.07x, k=1000: 0.14x |
	| `MergeSorted` | **이미 정렬된** 두 배열을 합칠 때 | 5만+5만: 0.07x |

	⚠️ **`SortBy` 는 키가 쌀 때 오히려 느립니다.** 키·순서 표를 따로 만드는
	비용이 있어서, 필드 하나(`r.age`)면 `StableSort(a, function(x, y) return
	x.age < y.age end)` 가 낫습니다(1.35x 대 1.53x). 키가 비싸면(`string.lower`
	등) 비교자 안에서 뽑는 것보다 **2배** 빠릅니다(1.97x 대 4.01x).

	⚠️ 원소가 숫자·문자열이고 기본 순서면 **비교자 없는 `Sort()` 가 이들보다
	빠릅니다**(0.24x — VM 안에서 비교). 안정성이 필요 없으면 `Sort` 를 쓰세요.

	⚠️ **비교자는 엄격해야 합니다**(`less(x, x) == false`, 즉 `<` 이지 `<=` 가
	아님 — `table.sort` 와 같은 계약). 어기면:
	- 선택·부분 정렬(`NthElement`/`NthElementInplace`/`PartialSort`/
	  `PartialSortInplace`)은 `"invalid order function"` **에러**로 멈춥니다
	  (진입에서 `less(x, x)` 를 한 번 보고, 선택의 스캔도 경계에서 잡음).
	- 병합 계열(`StableSort`/`SortBy`/`MergeSorted`)은 에러 없이 **안정성만** 잃습니다.
	- `IsSorted` 는 에러 없이 **틀립니다**(`<=` 면 같은 값 이웃에서 거짓). **NaN** 이 섞인 숫자는 어떤 순서와도 비교가 거짓이라 결과 순서가
	의미 없고 `IsSorted` 도 참을 줄 수 있습니다(C++ 와 같음) — 먼저 걸러내세요.

	정렬·선택 작업은 전부 **메타테이블 없는 날 버퍼**에서 합니다 — 원소를
	여러 번 읽고 쓰므로 인덱싱 세금(1.59x)이 곱해지지 않게.
]]

-- 비교자를 주지 않았을 때. 순수 Luau 정렬은 VM 의 기본 비교 경로가 없어서
-- 함수 하나를 거칩니다.
const function defaultLess(a: any, b: any): boolean
	return a < b
end

-- 이 크기 이하 구간은 삽입 정렬로(병합 재귀의 바닥). 16~32 에서 평평했습니다.
const INSERTION_CUTOFF = 24

-- 값만 조밀하게 모읍니다. 구멍은 건너뜁니다.
const function gatherValues<T>(self: ArrData<T>, buffer: { T }): number
	local count = 0
	for idx = 1, self.n do
		const item = self[idx]
		if item ~= nil then
			count += 1
			buffer[count] = item
		end
	end
	return count
end

-- 조밀 버퍼를 제자리로 되쓰고 꼬리(구멍 자리)를 비웁니다.
const function writeBack<T>(self: ArrData<T>, buffer: { T }, count: number)
	table.move(buffer, 1, count, 1, self :: any)
	for idx = count + 1, self.n do
		self[idx] = nil :: any
	end
end

-- 안정 삽입 정렬. `less(v, a[j])` 가 **엄격**해서 같은 값은 앞질러 가지 않습니다.
const function insertionSortRange(a: { any }, lo: number, hi: number, less: (any, any) -> boolean)
	for i = lo + 1, hi do
		const v = a[i]
		local j = i - 1
		while j >= lo and less(v, a[j]) do
			a[j + 1] = a[j]
			j -= 1
		end
		a[j + 1] = v
	end
end

-- 안정 병합 정렬(하향식). `tmp` 는 왼쪽 절반을 **원래 위치 그대로**
-- 잠시 옮겨두는 버퍼 하나이고 재귀 전체가 같이 씁니다(그래서 결국 n 가까이
-- 자랍니다 — 미리 잡는 크기는 힌트일 뿐). 두 절반이 이미 순서면 병합을 건너뜁니다 — 거의
-- 정렬된 입력에서 `table.sort` 보다 10배 빠른 이유입니다.
local function mergeSortRange(a: { any }, tmp: { any }, lo: number, hi: number, less: (any, any) -> boolean)
	if hi - lo < INSERTION_CUTOFF then
		insertionSortRange(a, lo, hi, less)
		return
	end
	const mid = (lo + hi) // 2
	mergeSortRange(a, tmp, lo, mid, less)
	mergeSortRange(a, tmp, mid + 1, hi, less)
	if not less(a[mid + 1], a[mid]) then
		return
	end
	table.move(a, lo, mid, lo, tmp)
	local i, j, k = lo, mid + 1, lo
	while i <= mid and j <= hi do
		-- 같으면 왼쪽(tmp)을 먼저 — 안정성
		if less(a[j], tmp[i]) then
			a[k] = a[j]
			j += 1
		else
			a[k] = tmp[i]
			i += 1
		end
		k += 1
	end
	if i <= mid then
		table.move(tmp, i, mid, k, a)
	end
end

const function stableSortBuffer(buffer: { any }, count: number, less: (any, any) -> boolean)
	if count > 1 then
		mergeSortRange(buffer, table.create(count // 2 + 1), 1, count, less)
	end
end

const STRICT_ERROR = "Arr: invalid order function (less must be strict: less(x, x) == false)"

-- 선택·부분 정렬의 진입 검사. 선택의 스캔은 경계에서 엄격성 위반을 잡지만,
-- 힙과 `table.sort` 경로는 `<=` 를 받아도 **에러 없이 틀린 결과**를 냈습니다
-- (Luau `table.sort` 는 `<=` 에서 조용히 오정렬 — 2라운드 리뷰, 1만 회 중 6601회).
-- 원소 하나로 `less(x, x)` 를 한 번 봅니다. 모든 위반을 잡지는 못하지만
-- `<=` 처럼 흔한 실수는 잡습니다. `k` 의 NaN 도 구간 NaN 과 같은 정책(에러).
--
-- `willCompare` 가 거짓이면(값이 둘 미만이거나 k 가 범위 밖·0) 엄격성은 보지
-- 않습니다 — 비교할 수 없는 원소(테이블 등)라도 비교가 안 일어나는 호출은
-- `Sort` 처럼 통과해야 합니다(3라운드 리뷰가 진입 검사의 회귀로 재현).
const function checkSelectArgs(sample: any, k: number, less: (any, any) -> boolean, willCompare: boolean)
	if k ~= k then
		Common.raise("Arr: k is NaN")
	end
	if willCompare and less(sample, sample) then
		Common.raise(STRICT_ERROR)
	end
end

-- 선택이 예산을 다 쓴 구간을 통째로 정렬합니다. `table.sort` 는 부분 구간을
-- 못 받으므로 잠시 옮겨서.
const function sortRangeFallback(a: { any }, lo: number, hi: number, less: (any, any) -> boolean)
	const len = hi - lo + 1
	const part = table.move(a, lo, hi, 1, table.create(len))
	table.sort(part, less)
	table.move(part, 1, len, lo, a)
end

-- 선택(introselect — 호어 분할 + 중앙값 셋, 예산을 넘으면 정렬로). 끝나면
-- `a[k]` 는 정렬했을 때의 그 값이고, 왼쪽은 전부 `a[k]` 이하, 오른쪽은
-- 이상입니다. 평균 O(n), **최악 O(n log n)**.
--
-- 예산이 있는 이유: 중앙값 셋은 "정렬된 배열 끝에 최솟값 하나" 같은 **흔한
-- 모양**에서 한 번에 원소 하나씩만 줄여 O(n²) 였습니다(2026-09-30 리뷰,
-- n=16000 에서 1.4초). 분할이 약 2·log₂n 번을 넘으면 남은 구간을 정렬합니다.
--
-- 안쪽 스캔에 경계를 둡니다 — 비교자가 엄격하지 않으면(`<=`) 스캔이 구간
-- 밖으로 달려 사용자 비교자에 `nil` 이 가거나 **무한 루프**였습니다. 엄격한
-- 비교자에서는 피벗 값이 구간 안에 있어 경계에 닿지 않습니다.
const function selectRange(a: { any }, lo: number, hi: number, k: number, less: (any, any) -> boolean)
	local budget = 2 * math.floor(math.log(hi - lo + 1, 2)) + 4
	while hi > lo do
		if budget <= 0 then
			sortRangeFallback(a, lo, hi, less)
			return
		end
		budget -= 1
		-- 후보를 끝점이 아니라 1/4·1/2·3/4 지점에서 — "정렬 + 끝에 하나" 모양은
		-- 끝점이 극단값이라 중앙값 셋이 매번 나쁜 피벗을 골랐습니다.
		const quarter = (hi - lo) // 4
		const x, y, z = a[lo + quarter], a[(lo + hi) // 2], a[hi - quarter]
		const pivot = if less(x, y)
			then (if less(y, z) then y elseif less(x, z) then z else x)
			else (if less(x, z) then x elseif less(y, z) then z else y)
		local i, j = lo, hi
		while i <= j do
			while less(a[i], pivot) do
				i += 1
				if i > hi then
					Common.raise(STRICT_ERROR)
				end
			end
			while less(pivot, a[j]) do
				j -= 1
				if j < lo then
					Common.raise(STRICT_ERROR)
				end
			end
			if i <= j then
				a[i], a[j] = a[j], a[i]
				i += 1
				j -= 1
			end
		end
		if k <= j then
			hi = j
		elseif k >= i then
			lo = i
		else
			return -- j < k < i: 가운데는 전부 피벗과 같음
		end
	end
end

-- 같은 순위끼리 **입력 순서를 지키는** 정렬의 새 배열. 구멍은 꼬리로.
-- 비교자를 안 주면 `<` 입니다.
const function StableSort<T>(self: ArrData<T>, less: LessThan<T>?): Arr<T>
	const len = self.n
	const buffer = table.create(len)
	const count = gatherValues(self, buffer)
	stableSortBuffer(buffer, count, less or defaultLess)
	-- 버퍼가 곧 결과입니다(꼬리는 이미 nil). 복사 한 번을 아낍니다.
	return wrap(buffer, len)
end

-- `StableSort` 의 제자리 판.
const function StableSortInplace<T>(self: ArrData<T>, less: LessThan<T>?): Arr<T>
	const buffer = table.create(self.n)
	const count = gatherValues(self, buffer)
	stableSortBuffer(buffer, count, less or defaultLess)
	writeBack(self, buffer, count)
	return self :: any
end

-- 키로 정렬한 새 배열. **키를 원소당 한 번만 계산**합니다 — 비교자 안에서
-- 키를 뽑으면 n log n 번 부릅니다. **안정 정렬**입니다(같은 키는 입력 순서).
-- `less` 는 키끼리의 비교이고, 안 주면 `<` 입니다. 구멍에는 `key` 를 부르지
-- 않고 꼬리로 보냅니다.
const function sortByInto<T, K>(self: ArrData<T>, key: (element: T) -> K, less: LessThan<K>?): ({ T }, number)
	const len = self.n
	const values = table.create(len)
	const count = gatherValues(self, values)
	const keys = table.create(count) :: { K }
	const order = table.create(count) :: { number }
	for idx = 1, count do
		keys[idx] = key(values[idx])
		order[idx] = idx
	end
	const keyLess: (any, any) -> boolean = less or defaultLess
	stableSortBuffer(order, count, function(a: number, b: number): boolean
		return keyLess(keys[a], keys[b])
	end)
	const sorted = table.create(len)
	for idx = 1, count do
		sorted[idx] = values[order[idx]]
	end
	return sorted, count
end

const function SortBy<T, K>(self: ArrData<T>, key: (element: T) -> K, less: LessThan<K>?): Arr<T>
	const sorted = sortByInto(self, key, less)
	return wrap(sorted, self.n)
end

-- `SortBy` 의 제자리 판.
const function SortByInplace<T, K>(self: ArrData<T>, key: (element: T) -> K, less: LessThan<K>?): Arr<T>
	const sorted, count = sortByInto(self, key, less)
	writeBack(self, sorted, count)
	return self :: any
end

-- 정렬했을 때 `k` 번째에 올 **값**. 배열은 안 건드립니다. 평균 O(n), 최악 O(n log n).
-- `k` 는 **구멍을 뺀 값들 사이의 순위**이고 음수는 뒤에서(`-1` = 최댓값)입니다.
-- 범위 밖이면 `nil`. 중앙값은 `NthElement(a, (Len + 1) // 2)` 처럼.
const function NthElement<T>(self: ArrData<T>, k: number, less: LessThan<T>?): T?
	const buffer = table.create(self.n)
	const count = gatherValues(self, buffer)
	const i = toIndex(k)
	const pos = if i < 0 then count + i + 1 else i
	checkSelectArgs(buffer[1], k, less or defaultLess, count >= 2 and pos >= 1 and pos <= count)
	if pos < 1 or pos > count then
		return nil
	end
	selectRange(buffer, 1, count, pos, less or defaultLess)
	return buffer[pos]
end

-- C++ `nth_element` 의 모양 그대로(제자리): `k` 번째 자리에 정렬했을 때의 값이
-- 오고, 그 왼쪽은 전부 이하, 오른쪽은 이상입니다(양쪽 안의 순서는 정하지
-- 않음). 구멍은 꼬리로. `k` 가 범위 밖이면 구멍만 치웁니다.
const function NthElementInplace<T>(self: ArrData<T>, k: number, less: LessThan<T>?): Arr<T>
	const buffer = table.create(self.n)
	const count = gatherValues(self, buffer)
	const i = toIndex(k)
	const pos = if i < 0 then count + i + 1 else i
	checkSelectArgs(buffer[1], k, less or defaultLess, count >= 2 and pos >= 1 and pos <= count)
	if pos >= 1 and pos <= count then
		selectRange(buffer, 1, count, pos, less or defaultLess)
	end
	writeBack(self, buffer, count)
	return self :: any
end

-- 가장 앞에 올 `k` 개를 **정렬해서** 담은 새 배열(길이 `min(k, 값 개수)`).
-- 크기 k 힙으로 한 번 훑습니다 — O(n log k). **안정하지 않습니다**(C++
-- `partial_sort` 와 같음). 가장 큰 k 개는 `less` 를 뒤집어 넘기세요.
const function PartialSort<T>(self: ArrData<T>, k: number, less: LessThan<T>?): Arr<T>
	const lt: (any, any) -> boolean = less or defaultLess
	-- 값이 둘 이상일 때만 비교가 일어납니다 — 첫 값을 표본으로.
	local sample: any = nil
	local values = 0
	for idx = 1, self.n do
		if self[idx] ~= nil then
			values += 1
			if values == 1 then
				sample = self[idx]
			else
				break
			end
		end
	end
	checkSelectArgs(sample, k, lt, values >= 2 and k >= 1)
	-- 값 개수보다 큰 k 는 전체 — k 로 버퍼를 잡으면 `math.huge` 에서 크래시,
	-- 큰 k 에서 원소 수가 아니라 k 에 비례해 느렸습니다(2026-09-30 리뷰).
	const want = math.min(math.max(0, toIndex(k)), self.n)
	-- 최대 힙(꼭대기 = 지금까지 고른 k 개 중 가장 뒤에 올 것)
	const heap = table.create(want)
	local size = 0
	for idx = 1, self.n do
		const item = self[idx]
		if item == nil then
			continue
		end
		if size < want then
			size += 1
			heap[size] = item
			local child = size
			while child > 1 do
				const parent = child // 2
				if lt(heap[parent], heap[child]) then
					heap[parent], heap[child] = heap[child], heap[parent]
					child = parent
				else
					break
				end
			end
		elseif size > 0 and lt(item, heap[1]) then
			heap[1] = item
			local parent = 1
			while true do
				const left = parent * 2
				if left > size then
					break
				end
				local child = left
				if left + 1 <= size and lt(heap[left], heap[left + 1]) then
					child = left + 1
				end
				if lt(heap[parent], heap[child]) then
					heap[parent], heap[child] = heap[child], heap[parent]
					parent = child
				else
					break
				end
			end
		end
	end
	if less then
		table.sort(heap, less)
	else
		table.sort(heap)
	end
	return wrap(heap, size)
end

-- `PartialSort` 의 제자리 판(C++ `partial_sort` 모양): 앞 `k` 칸에 가장 앞에 올
-- 값들이 정렬되어 오고, 나머지 값들은 그 뒤에 **순서 없이** 옵니다. 구멍은 꼬리로.
const function PartialSortInplace<T>(self: ArrData<T>, k: number, less: LessThan<T>?): Arr<T>
	const lt: (any, any) -> boolean = less or defaultLess
	const buffer = table.create(self.n)
	const count = gatherValues(self, buffer)
	checkSelectArgs(buffer[1], k, lt, count >= 2 and k >= 1)
	const want = math.min(math.max(0, toIndex(k)), count)
	if want > 0 then
		if want < count then
			selectRange(buffer, 1, count, want, lt)
		end
		-- 앞 want 칸만 따로 정렬합니다(`table.sort` 는 부분 구간을 못 받음).
		const head = table.move(buffer, 1, want, 1, table.create(want))
		if less then
			table.sort(head, less)
		else
			table.sort(head)
		end
		table.move(head, 1, want, 1, buffer)
	end
	writeBack(self, buffer, count)
	return self :: any
end

-- **이미 정렬된** 두 배열을 정렬을 유지하며 합친 새 배열. O(n + m).
-- 같은 순위면 `self` 쪽이 먼저입니다(안정). 구멍은 건너뜁니다. 정렬되지 않은
-- 입력을 주면 결과도 정렬되지 않습니다(검사하지 않음 — `IsSorted` 로 확인).
-- 그냥 이어붙이기는 `Concat` 입니다.
const function MergeSorted<T>(self: ArrData<T>, other: ArrData<T>, less: LessThan<T>?): Arr<T>
	const lt: (any, any) -> boolean = less or defaultLess
	const leftLen, rightLen = self.n, other.n
	const raw = table.create(leftLen + rightLen)
	local i, j, count = 1, 1, 0
	-- 구멍을 건너뛴 다음 값의 위치
	while i <= leftLen and self[i] == nil do
		i += 1
	end
	while j <= rightLen and other[j] == nil do
		j += 1
	end
	while i <= leftLen and j <= rightLen do
		const a, b = self[i], other[j]
		count += 1
		if lt(b, a) then
			raw[count] = b
			j += 1
			while j <= rightLen and other[j] == nil do
				j += 1
			end
		else
			raw[count] = a
			i += 1
			while i <= leftLen and self[i] == nil do
				i += 1
			end
		end
	end
	for idx = i, leftLen do
		const item = self[idx]
		if item ~= nil then
			count += 1
			raw[count] = item
		end
	end
	for idx = j, rightLen do
		const item = other[idx]
		if item ~= nil then
			count += 1
			raw[count] = item
		end
	end
	return wrap(raw, count)
end

-- 구멍을 건너뛰고 이웃한 값끼리 순서가 맞는가. 같은 값은 순서가 맞는 것으로 봅니다.
const function IsSorted<T>(self: ArrData<T>, less: LessThan<T>?): boolean
	const lt: (any, any) -> boolean = less or defaultLess
	local prev: any = nil
	for idx = 1, self.n do
		const item = self[idx]
		if item ~= nil then
			if prev ~= nil and lt(item, prev) then
				return false
			end
			prev = item
		end
	end
	return true
end

--#endregion

--#region ----------- 스트림 -----------

-- 각 원소를 변환한 **새 배열**. `to` 를 주면 그 뒤에 이어붙입니다.
const function Map<T, G>(self: ArrData<T>, fn: Mapper<T, G>, to: Arr<G>?): Arr<G>
	const len = self.n
	if to == nil then
		const result = newSized(len)
		for idx = 1, len do
			result[idx] = fn(self[idx], idx, self :: any)
		end
		return result :: any
	end
	local outLen = to.n
	for idx = 1, len do
		outLen += 1
		to[outLen] = fn(self[idx], idx, self :: any)
	end
	to.n = outLen
	return to
end

-- 각 원소를 변환해 **제자리에** 덮어씁니다. 타입이 바뀔 수 있습니다.
--
-- ⚠️ **입력을 소비합니다**(질문 Y): 돌려받은 값이 같은 테이블이고 **타입이
-- 바뀝니다.** 결과만 쓰고 원래 변수는 다시 쓰지 마세요 — 원래 변수는 옛 타입
-- 그대로라 타입 검사가 못 잡습니다(Rust 의 move 와 같은 결, Luau 는 강제 못 함).
--
--     const labels = Arr.MapInplace(nums, function(v: number): string
--         return tostring(v)
--     end)                                             -- 이후로는 labels 만
--     Arr.Sum(nums)                                    -- ❌ 0건인데 런타임 에러
--
-- 같은 타입끼리(`T → T`)로 막는 안도 있었지만 "Map" 이라는 이름에 맞지 않아
-- 접었습니다(사용자 결정 2026-10-01).
const function MapInplace<T, G>(self: ArrData<T>, fn: Mapper<T, G>): Arr<G>
	for idx = 1, self.n do
		(self :: any)[idx] = fn(self[idx], idx, self :: any)
	end
	return self :: any
end

-- 조건을 만족하는 원소만 모은 **새 배열**. `to` 를 주면 그 뒤에 이어붙입니다.
const function Filter<T>(self: ArrData<T>, fn: Predicate<T>, to: Arr<T>?): Arr<T>
	const len = self.n
	const out: Arr<T> = to or newSized(0)
	local outLen = out.n
	for idx = 1, len do
		const item = self[idx]
		if fn(item, idx, self :: any) then
			outLen += 1
			out[outLen] = item
		end
	end
	out.n = outLen
	return out
end

-- 조건을 만족하는 원소만 **남깁니다**(제자리). 나머지는 버립니다.
const function Retain<T>(self: ArrData<T>, fn: Predicate<T>): Arr<T>
	const len = self.n
	local kept = 0
	for idx = 1, len do
		const item = self[idx]
		if fn(item, idx, self :: any) then
			kept += 1
			self[kept] = item
		end
	end
	for idx = kept + 1, len do
		self[idx] = nil :: any
	end
	self.n = kept
	return self :: any
end

-- 한 겹 평탄화한 **새 배열**. 구간 인자를 받습니다(예전의 `rangeflat` 이
-- 여기 흡수됐습니다). 연속된 비배열 구간은 `table.move` 로 한 번에 옮깁니다.
-- ⚠️ **입력 쪽 원소 타입을 `any` 로 엽니다.** 자연스러운 선언인
-- `self: Arr<T | Arr<T>>` 은 Luau 가 `T | Arr<T>` 를 `number | Arr<number>` 로
-- 분해하지 못해 *"No valid instantiation could be inferred"* 가 납니다(실측).
-- 평탄화는 어차피 원소마다 런타임에 배열인지 보는 동적 연산이라, 결과 타입만
-- 박고 입력은 여는 쪽이 정직합니다.
--
-- ⚠️ **호출자가 결과 타입을 직접 알려줘야 합니다** —
-- `Arr.Flat<<number>>(nested)` 가 권장이고 캐스트(`:: Arr<number>`)가 차선입니다.
-- 선언 주석(`local flat: Arr<number> = …`)은 **안 됩니다**: Luau 는 기대
-- 타입을 제네릭 호출 안으로 전파하지 않아 `T` 가 `unknown` 으로 남습니다.
--
-- ⚠️ 안쪽 배열의 **구멍은 그대로 옮겨집니다.** 결과 타입은 호출자가 알려주는
-- 것이라 `Flat<<number>>` 라고 하면 구멍이 든 `Arr<number>` 가 나올 수 있습니다
-- — 안쪽에 구멍이 있을 수 있으면 `Flat<<number?>>` 로 받으세요.
const function Flat<T>(self: ArrData<any>, start: number?, last: number?, to: Arr<T>?): Arr<T>
	const s, l = resolveRange(self.n, start, last)
	const out: Arr<T> = to or newSized(0)
	local outLen = out.n
	local runStart = s
	for idx = s, l do
		const inner = self[idx]
		if not isArrRaw(inner) then
			continue
		end
		-- 앞서 밀어둔 비배열 구간을 먼저 flush
		const runLen = idx - runStart
		if runLen == 1 then
			outLen += 1
			out[outLen] = self[runStart] :: any
		elseif runLen > 1 then
			table.move(self :: any, runStart, idx - 1, outLen + 1, out :: any)
			outLen += runLen
		end
		-- 중첩 배열을 펼쳐 이어붙임
		const innerArr = inner :: Arr<T>
		const innerLen = innerArr.n
		if innerLen == 1 then
			out[outLen + 1] = innerArr[1]
		elseif innerLen > 1 then
			table.move(innerArr :: any, 1, innerLen, outLen + 1, out :: any)
		end
		outLen += innerLen
		runStart = idx + 1
	end
	-- 마지막 비배열 구간 flush
	const tailLen = l - runStart + 1
	if tailLen == 1 then
		outLen += 1
		out[outLen] = self[runStart] :: any
	elseif tailLen > 1 then
		table.move(self :: any, runStart, l, outLen + 1, out :: any)
		outLen += tailLen
	end
	out.n = outLen
	return out
end

-- 한 겹 평탄화(제자리).
-- `Flat` 과 같은 이유로 입력 쪽을 엽니다.
--
-- ⚠️ **입력을 소비합니다**(질문 Y): 돌려받은 값이 같은 테이블이고 **타입이
-- 바뀝니다.** 결과만 쓰고 원래 변수는 다시 쓰지 마세요 — 원래 변수는 옛 타입
-- 그대로라 타입 검사가 못 잡습니다(Rust 의 move 와 같은 결, Luau 는 강제 못 함).
const function FlatInplace<T>(self: ArrData<any>): Arr<T>
	local idx = 1
	local len = self.n
	while idx <= len do
		const inner = self[idx]
		if not isArrRaw(inner) then
			idx += 1
			continue
		end
		const innerArr = inner :: Arr<T>
		const innerLen = innerArr.n
		if innerLen == 1 then
			(self :: any)[idx] = innerArr[1]
			idx += 1
			continue
		elseif innerLen == 0 then
			table.move(self :: any, idx + 1, len, idx)
			self[len] = nil :: any
			len -= 1
			continue
		end
		table.move(self :: any, idx + 1, len, idx + innerLen)
		table.move(innerArr :: any, 1, innerLen, idx, self :: any)
		len += innerLen - 1
		idx += innerLen
	end
	self.n = len
	return self :: any
end

-- 각 원소를 여러 값으로 펼쳐 이어붙인 **새 배열**. 콜백은 값 여러 개를
-- 돌려줄 수 있습니다.
const function Flatmap<T, G>(self: ArrData<T>, fn: Spreader<T, G>, to: Arr<G>?): Arr<G>
	const out: Arr<G> = to or newSized(0)
	local outLen = out.n
	for idx = 1, self.n do
		-- 콜백은 **한 번만** 부릅니다. 개수를 먼저 세려고 두 번 부르면
		-- 부수효과가 두 번 일어납니다.
		const produced = table.pack(fn(self[idx], idx, self :: any))
		const count = produced.n
		if count == 1 then
			outLen += 1
			out[outLen] = produced[1]
		elseif count > 1 then
			table.move(produced, 1, count, outLen + 1, out :: any)
			outLen += count
		end
	end
	out.n = outLen
	return out
end

-- `Flatmap` 의 제자리 판. 버퍼에 모은 뒤 한 번에 되돌려 씁니다 — 원소마다
-- 밀면 O(n^2) 가 됩니다.
--
-- ⚠️ **입력을 소비합니다**(질문 Y): 돌려받은 값이 같은 테이블이고 **타입이
-- 바뀝니다.** 결과만 쓰고 원래 변수는 다시 쓰지 마세요 — 원래 변수는 옛 타입
-- 그대로라 타입 검사가 못 잡습니다(Rust 의 move 와 같은 결, Luau 는 강제 못 함).
const function FlatmapInplace<T, G>(self: ArrData<T>, fn: Spreader<T, G>): Arr<G>
	const len = self.n
	const buffer = table.create(len)
	local outLen = 0
	for idx = 1, len do
		const produced = table.pack(fn(self[idx], idx, self :: any))
		const count = produced.n
		if count == 1 then
			outLen += 1
			buffer[outLen] = produced[1]
		elseif count > 1 then
			table.move(produced, 1, count, outLen + 1, buffer)
			outLen += count
		end
	end
	table.move(buffer, 1, outLen, 1, self :: any)
	for idx = outLen + 1, len do
		self[idx] = nil :: any
	end
	self.n = outLen
	return self :: any
end

-- 순회하며 **비웁니다**(Rust 의 drain). 콜백이 각 원소를 받고, 끝나면 배열은
-- 비어 있습니다.
const function Drain<T>(self: ArrData<T>, fn: Mapper<T, any>): Arr<T>
	const len = self.n
	for idx = 1, len do
		fn(self[idx], idx, self :: any)
		self[idx] = nil :: any
	end
	self.n = 0
	return self :: any
end

-- 다른 배열들을 뒤에 이어붙입니다(제자리). 새 배열판은 생성자 `Arr.Concat`.
-- (2026-09-30 에 `MergeInplace` 에서 개명 — `merge` 는 C++·정렬 전통에서 정렬
-- 유지 병합이라 오해를 불렀습니다. 그건 `MergeSorted` 자리입니다.)
const function ConcatInplace<T>(self: ArrData<T>, ...: ArrData<T>): Arr<T>
	const count = select("#", ...)
	local outLen = self.n
	for argIdx = 1, count do
		const source: ArrData<T> = select(argIdx, ...)
		const sourceLen = source.n
		if sourceLen > 0 then
			table.move(source :: any, 1, sourceLen, outLen + 1, self :: any)
			outLen += sourceLen
		end
	end
	self.n = outLen
	return self :: any
end

--#endregion

--#region ----------- 접기 (Fold 네 갈래) -----------
-- `Fold` 초기값 있음 / `FoldRight` 오른쪽부터 / `Reduce` 초기값 없음 /
-- `FoldUntil` 조기 중단. **초기값이 앞에 옵니다** — 후행 클로저가 여러 줄일 때
-- 초기값이 뒤에 붕 뜨지 않게 하려는 것이고 Rust·Haskell·Java 도 그렇습니다.

const function Fold<T, U>(self: ArrData<T>, init: U, fn: Folder<T, U>): U
	local acc = init
	for idx = 1, self.n do
		acc = fn(acc, self[idx], idx, self :: any)
	end
	return acc
end

const function FoldRight<T, U>(self: ArrData<T>, init: U, fn: Folder<T, U>): U
	local acc = init
	for idx = self.n, 1, -1 do
		acc = fn(acc, self[idx], idx, self :: any)
	end
	return acc
end

-- 초기값 없이 **첫 원소를 씨앗으로** 접습니다. 빈 배열이면 `nil`.
-- 예: `Arr.Reduce(arr, function(a, b) return math.max(a, b) end)`.
-- ⚠️ `Arr.Reduce(arr, math.max)` 는 **안 됩니다** — 콜백은 `(acc, v, index, arr)` 를
-- 받으므로 `math.max` 가 위치와 배열까지 받아 틀린 값이나 에러가 납니다(타입
-- 검사도 거부합니다). 예전 주석이 권하던 모양이라 적어둡니다(2026-09-30 리뷰).
const function Reduce<T>(self: ArrData<T>, fn: (a: T, b: T, index: number, arr: ArrView<unknown>) -> T): T?
	const len = self.n
	if len == 0 then
		return nil
	end
	local acc = self[1]
	for idx = 2, len do
		acc = fn(acc, self[idx], idx, self :: any)
	end
	return acc
end

-- 조기 중단이 있는 접기. 콜백이 `(acc, done)` 을 돌려주고 `done` 이 참이면
-- 거기서 멈춥니다. **후행 조건**이라 `While` 이 아니라 `Until` 입니다 —
-- 원소를 처리한 **뒤에** 조건을 보고, Lua 의 `repeat … until` 이 그 의미입니다.
--
-- 돌려주는 둘째 값은 **멈춘 위치**입니다. 끝까지 갔으면 `nil` 이라 완주
-- 여부를 알 수 있습니다.
const function FoldUntil<T, U>(self: ArrData<T>, init: U, fn: UntilFolder<T, U>): (U, number?)
	local acc = init
	for idx = 1, self.n do
		const nextAcc, done = fn(acc, self[idx], idx, self :: any)
		acc = nextAcc
		if done then
			return acc, idx
		end
	end
	return acc, nil
end

--#endregion

--#region ----------- 타입 -----------

-- 함수가 타입 바깥(네임스페이스)에 있으니 전체형은 데이터부 그 자체입니다.
-- 예전엔 `ArrData<T> & ArrIfce & ListCore<T, number>` 교집합이었고, 그 때문에
-- 메소드 `self` 를 데이터부로 받기·재귀 별칭 우회(`typeof` 나열)·계약 멤버
-- 재선언 금지 같은 규칙이 필요했습니다(질문 AB 로 전부 사라짐).
export type Arr<T> = ArrData<T>

--#endregion

--#region ----------- 생성자 -----------
-- **순수 테이블 네임스페이스**입니다. 콜러블(`Arr(...)`)로 만들면 제네릭
-- 생성자가 `__call` 경유에서 타입 인자를 잃고, 모듈 오타도 못 잡습니다(실측).

-- `Arr.Of(1, 2, 3)`. 인자 사이의 `nil` 도 보존됩니다(`n` 이 진실이므로).
const function Of<T>(...: T): Arr<T>
	const raw: any = table.pack(...)
	raw[TAG] = true
	return raw
end

-- 길이가 정해진 배열을 `fill` 로 채웁니다.
--
-- ⭐ **`fill` 은 필수입니다**(질문 T (b)). 빼먹으면 칸이 전부 `nil` 인데 타입은
-- `Arr<number>` 라서 `Arr.Map(s, function(x: number) return x * 2 end)` 가
-- 타입 검사를 통과하고 런타임에 터졌습니다. 구멍으로 시작하고 싶으면 **타입에
-- 드러내세요**: `Arr.Sized<<number?>>(5, nil)` → `Arr<number?>`.
--
-- ⚠️ `fill` 에 테이블을 주면 **모든 칸이 같은 테이블을 공유**합니다
-- (`table.create` 의 동작). 칸마다 다른 것이 필요하면 `FromFunc` 를 쓰세요.
const function Sized<T>(len: number, fill: T): Arr<T>
	const count = checkLength(len, "Sized")
	return wrap(table.create(count, fill) :: any, count)
end

-- 평범한 Lua 배열을 **그대로 입양합니다**(복사 안 함). 넘긴 테이블을 뒤에서
-- 또 건드리면 이 배열도 같이 바뀝니다. 복사가 필요하면 `CloneFromTable`.
--
-- ⚠️ **길이는 `Common.listLength` 규약**입니다 — `n` 이 0 이상의 정수로 있으면
-- 그것(`table.pack` 결과), 없으면 `#`. `n` 이 실제 원소보다 짧으면 그 뒤 raw 칸을
-- **`#` 가 닿는 데까지 비웁니다**(넘긴 테이블이 바뀜) — 구멍 뒤·큰 키처럼 `#` 가 안 닿는
-- `n` 밖 키는 **계약 밖**이니, 그런 희소 테이블은 `CloneFromTable`(1..n 만 복사)로.
-- `n` 이 없을 때 입력에 구멍이 있으면 `#` 는
-- 경계 중 **아무 곳**이나 돌려줄 수 있어(Lua 규격) 구멍 뒤의 값이 **조용히 잘릴
-- 수** 있습니다 — `{ 1, nil, 3 }` 리터럴은 3 이지만 `t[1] = 1; t[3] = 3` 으로
-- 채운 테이블은 1 입니다. 구멍이 있을 수 있는 데이터는 `Of(...)` 나
-- `table.pack` 결과처럼 **길이를 따로 아는 경로**로 만드세요.
--
-- ⚠️ 반대 방향도 있습니다: `#` 가 **구멍 뒤의 경계**를 고르면 구멍이 든 배열이
-- 들어옵니다. 타입은 입력 선언을 따르는데, Luau 의 `{ number }` 는 구멍을
-- 표현하지 못하므로(`table.create(4)` 에 1·4 만 채운 것도 `{ number }`)
-- **`Arr<number>` 인데 구멍이 있을 수 있습니다**. 구멍 가능성이 있는 입력은
-- `{ number? }` 로 선언해 넘기세요 — 그러면 `Arr<number?>` 가 됩니다.
const function FromTable<T>(tbl: { T }): Arr<T>
	-- 메타테이블이 남으면 범위 밖 조회가 `__index` 값을 주고 쓰기가 `__newindex`
	-- 를 타며 1.59배 인덱싱 세금도 다시 붙습니다 — "인스턴스는 평범한 테이블"
	-- 전제가 이 경로만 비켜 갔습니다(M0 리뷰). 입양 대신 복사를 안내합니다.
	if getmetatable(tbl :: any) ~= nil then
		Common.raise("Arr: FromTable adopts plain tables only (this one has a metatable) — use CloneFromTable")
	end
	-- 이미 Arr 면 `#` 로 `n` 을 덮어써 구멍 뒤가 사라졌습니다(M0 2라운드, 예전부터).
	if rawget(tbl :: any, TAG) ~= nil then
		Common.raise("Arr: FromTable got a table that is already an Arr — use it as is, or Clone")
	end
	-- 동결된 테이블엔 길이·태그를 못 씁니다 — 라이브러리 줄의 "readonly table" 대신.
	if table.isfrozen(tbl :: any) then
		Common.raise("Arr: FromTable cannot adopt a frozen table — use CloneFromTable")
	end
	-- 길이는 `Common.listLength` 규약 — `table.pack` 이 준 `n`(꼬리 구멍 포함)을
	-- `#` 로 덮어쓰던 것(M0 4라운드).
	const len = Common.listLength(tbl)
	-- `n` 이 실제 원소보다 짧으면 그 뒤 raw 칸을 `#` 가 닿는 데까지 비웁니다 — 남으면
	-- `n` 바깥이라 안 보이다가 정렬·삽입 뒤 배열 안으로 다시 들어왔습니다(M0 5라운드).
	-- 입양이라 넘긴 테이블이 바뀝니다.
	-- **경계**(2026-10-02, 제가 정함 — 되돌리기 쉬움): `#` 가 닿지 않는 `n` 밖 숫자 키
	-- (구멍 뒤 `{ n = 1, [1] = 10, [3] = 30 }` 의 `[3]`, 큰 키 `[100]`)는 **계약 밖**입니다 —
	-- 그런 희소 테이블은 `CloneFromTable`(1..n 만 복사)로 넘기세요. Gemini 사냥이 이 자리를
	-- 짚어 전부 순회해 지우게 했더니 입양이 5~8배 느려져 **복사보다 느려졌습니다**(perf 20절)
	-- — "복사 없이 입양" 이라는 존재 이유가 사라져 되돌렸습니다. `next(raw, len)` 부터만
	-- 도는 안은 `len` 이 해시 부분에 있으면 앞의 키를 건너뛰어 틀렸습니다(리뷰가 반례로 확인).
	const raw = tbl :: any
	for idx = len + 1, #raw do
		raw[idx] = nil
	end
	return wrap(raw, len)
end

-- `FromTable` 의 복사 판. 길이는 `Common.listLength` 규약(`n` 우선, 없으면 `#` —
-- 대입으로 만든 구멍은 `#` 의 함정이 같음). 메타테이블이 있어도 됩니다(원소 단위로 읽음).
const function CloneFromTable<T>(tbl: { T }): Arr<T>
	-- 길이는 `Common.listLength` 규약(`n` 우선) — `#` 면 `Arr`·`table.pack` 결과의
	-- 구멍 뒤가 조용히 사라졌습니다(M0 3라운드). 구멍은 **그대로** 복사합니다.
	const len = Common.listLength(tbl)
	const result = newSized(len)
	if getmetatable(tbl :: any) ~= nil then
		-- 메타테이블이 있으면 원소 단위로(`__index` 를 따름) — 길이는 `__len` 을 따르는데
		-- `table.move` 는 raw 로 읽어 칸이 전부 nil 이었습니다(M0 4라운드). `FromTable`
		-- 이 메타테이블 테이블을 이리로 안내하므로 이 경로가 정상이어야 합니다.
		for idx = 1, len do
			result[idx] = (tbl :: any)[idx]
		end
		return result
	end
	table.move(tbl :: any, 1, len, 1, result :: any)
	return result
end

-- `FromIter` 가 구멍 자리에 잠시 두는 값. 모듈 밖으로 나가지 않습니다.
const HOLE = table.freeze({})

-- 반환 개수와 앞의 둘. `select("#", ...)` 는 끝의 nil 까지 셉니다.
const function countReturns(...: any): (number, any, any)
	return select("#", ...), ...
end

-- 임의의 for-in 이터레이터에서 값을 모읍니다.
-- `Arr.FromIter(pairs(t))`, `Arr.FromIter(string.gmatch(s, "%a+"))` 처럼 씁니다.
--
-- ⚠️ **원소 타입을 직접 알려줘야 합니다.** 이터레이터는 `any` 로 받으므로
-- `T` 를 뽑을 재료가 없습니다.
--
--     local a = Arr.FromIter<<number>>(ipairs(list))   -- 권장
--     local a = Arr.FromIter(ipairs(list)) :: Arr<number>  -- 차선
--
-- (`.claude/base/typing-limits.md` 의 "조용히 타입을 잃는 자리 셋")
--
-- **값 규칙**: 순회자가 값을 **하나** 내면 그것이, **둘 이상** 내면 둘째가 원소입니다
-- (`pairs`/`ipairs` 는 값, `gmatch` 는 캡처가 하나면 그것 둘 이상이면 둘째). 개수는 **첫
-- 호출에서 한 번** 세고, 순회자의 반환 개수가 호출마다 같다고 봅니다.
-- ⚠️ **구멍이 생깁니다**: `(키, nil)` 을 내는 순회자(`Arr.Iter` 의 구멍)는 그 자리를
-- 구멍으로 둡니다 — 원소 타입을 `T?` 로 적으세요: `Arr.FromIter<<number?>>(Arr.Iter(a))`.
const function FromIter<T>(iter: any, state: any?, control: any?): Arr<T>
	const result: Arr<T> = newSized(0)
	local count = 0
	local key = control
	-- 값이 둘 이상이면 둘째가 값, 하나면 그것이 값입니다. **둘째의 nil 이 아니라 반환
	-- 개수로** 가릅니다 — `(index, nil)` 을 내는 순회자(`Arr.Iter` 의 구멍)에서
	-- 인덱스를 값으로 담았습니다(2026-10-02 Gemini 사냥). 개수는 **첫 호출에서 한 번**
	-- 셉니다 — 매번 세면 가변 인자 헬퍼가 원소마다 붙어 2.1배 느려졌습니다(perf 19절).
	-- 순회자의 반환 개수는 호출마다 같다고 봅니다(`pairs`/`ipairs`/`gmatch`/`Arr.Iter`
	-- 모두 그렇습니다).
	--
	-- 구멍(값이 nil)은 **자리표시자로 채우고 그 위치를 적어 두었다가 끝에 그 자리만 nil 로**
	-- 바꿉니다 — nil 을 바로 넣으면 그 자리에서 배열 부분이 못 자라 뒤 원소가 해시 부분에
	-- 쌓였고, 구멍이 많은 순회자에서 만드는 것이 5배, 만든 배열의 인덱싱도 4.5배 느렸습니다.
	-- 루프는 값의 개수로 둘로 나눕니다 — 원소마다 "하나냐 둘이냐" 와 "구멍이냐" 를 묻는
	-- 분기가 구멍 없는 순회자에서도 3~11% 를 냈습니다(perf 19절, 리뷰 둘).
	const returned, firstA, firstB = countReturns(iter(state, key))
	if firstA == nil then
		return result
	end
	key = firstA
	count = 1
	if returned >= 2 then
		const holes: { number } = {}
		local holeCount = 0
		if firstB == nil then
			result[1] = HOLE
			holeCount = 1
			holes[1] = 1
		else
			result[1] = firstB
		end
		while true do
			const a, b = iter(state, key)
			if a == nil then
				break
			end
			key = a
			count += 1
			if b == nil then
				result[count] = HOLE
				holeCount += 1
				holes[holeCount] = count
			else
				result[count] = b
			end
		end
		const raw = result :: any
		for idx = 1, holeCount do
			raw[holes[idx]] = nil
		end
	else
		-- 값이 하나면 그것이 곧 다음 키라 nil 일 수 없습니다(nil 이면 순회 끝).
		result[1] = firstA
		while true do
			const a = iter(state, key)
			if a == nil then
				break
			end
			key = a
			count += 1
			result[count] = a
		end
	end
	result.n = count
	return result
end

-- 위치를 받아 값을 만드는 함수로 채웁니다. 칸마다 새 테이블이 필요할 때.
const function FromFunc<T>(len: number, fn: (index: number) -> T): Arr<T>
	const count = checkLength(len, "FromFunc")
	const result = newSized(count)
	for idx = 1, count do
		result[idx] = fn(idx)
	end
	return result
end

-- 여러 배열을 이어붙인 새 배열. 제자리 판은 `ConcatInplace`.
const function Concat<T>(...: ArrData<T>): Arr<T>
	const count = select("#", ...)
	local total = 0
	for argIdx = 1, count do
		const source: ArrData<T> = select(argIdx, ...)
		total += source.n
	end
	const result = newSized(total)
	local outLen = 0
	for argIdx = 1, count do
		const source: ArrData<T> = select(argIdx, ...)
		const sourceLen = source.n
		if sourceLen > 0 then
			table.move(source :: any, 1, sourceLen, outLen + 1, result :: any)
			outLen += sourceLen
		end
	end
	return result
end

-- 숫자 구간. `Arr.Range(1, 5)` → `1, 2, 3, 4, 5`. **닫힌 구간**입니다.
-- `step` 이 0 이면 에러, 방향이 맞지 않으면 빈 배열입니다.
--
-- ⚠️ **소수 step 에서는 끝점이 빠질 수 있습니다** — `Range(0, 0.3, 0.1)` 은
-- `0, 0.1, 0.2` 입니다(`0.3 / 0.1` 이 2.9999… 라서). **Lua 의 `for i = 0, 0.3,
-- 0.1` 과 같은 동작**이라 호스트 관례를 따릅니다. 끝점이 꼭 필요하면 정수로
-- 만들고 나누세요: `Arr.Map(Arr.Range(0, 3), function(i) return i / 10 end)`.
const function Range(from: number, to: number, step: number?): Arr<number>
	const by = step or 1
	if by == 0 then
		Common.raise("Arr: Range step must not be zero")
	end
	-- 끝점·step 의 NaN·무한은 `table.create` 의 엉뚱한 에러(라이브러리 줄)였습니다
	-- (3라운드 리뷰). `x - x ~= 0` 은 NaN 과 ±inf 를 한 번에 가립니다.
	if by - by ~= 0 then
		Common.raise("Arr: Range step must be finite")
	end
	if from - from ~= 0 or to - to ~= 0 then
		Common.raise("Arr: Range bounds must be finite")
	end
	const span = math.floor((to - from) / by)
	if span < 0 then
		return newSized(0) :: Arr<number>
	end
	if span + 1 > MAX_LENGTH then
		Common.raise(`Arr: Range is too long ({span + 1} > {MAX_LENGTH})`)
	end
	const result = newSized(span + 1) :: Arr<number>
	for idx = 0, span do
		result[idx + 1] = from + idx * by
	end
	return result
end

-- 이 값이 `Arr` 인가. 술어라 최상위에서 `stl.isArr` 로 노출됩니다.
const function isArr(value: any): boolean
	return isArrRaw(value)
end

--#endregion

-- stylua: ignore
return {
	Of = Of,
	Sized = Sized,
	FromTable = FromTable,
	CloneFromTable = CloneFromTable,
	FromIter = FromIter,
	FromFunc = FromFunc,
	Concat = Concat,
	Range = Range,
	isArr = isArr,

	-- ⭐ 모든 연산은 여기 네임스페이스 함수입니다(`Arr.X(v, …)`) — 콜론 호출은
	-- 없습니다(질문 AB). `local Map = Arr.Map` 처럼 받아 부르면 더 빠릅니다
	-- (`.claude/base/perf-measurements.md` 14·16절).
	At = At, Len = Len, Empty = Empty, Iter = Iter, Unpack = Unpack, Join = Join, Equal = Equal, Count = Count,
	Find = Find, Some = Some, Every = Every, Max = Max, Min = Min, Sum = Sum, Prod = Prod,
	SumUnchecked = SumUnchecked, ProdUnchecked = ProdUnchecked, MaxUnchecked = MaxUnchecked,
	MinUnchecked = MinUnchecked, FillHoles = FillHoles, FillHolesInplace = FillHolesInplace, Compact = Compact,
	CompactInplace = CompactInplace, ToOptionals = ToOptionals, PushBack = PushBack,
	PushBackMany = PushBackMany, PushBackArray = PushBackArray, PushFront = PushFront,
	PushFrontMany = PushFrontMany, PushFrontArray = PushFrontArray, Insert = Insert,
	InsertMany = InsertMany, InsertArray = InsertArray, Clone = Clone, Clear = Clear, Fill = Fill,
	Slice = Slice, SliceInplace = SliceInplace, Erase = Erase, EraseInplace = EraseInplace,
	Splice = Splice, SpliceInplace = SpliceInplace, Reverse = Reverse,
	ReverseInplace = ReverseInplace, Rotate = Rotate, RotateInplace = RotateInplace, Shuffle = Shuffle,
	ShuffleInplace = ShuffleInplace, Sort = Sort, SortInplace = SortInplace,
	SortUnchecked = SortUnchecked, SortInplaceUnchecked = SortInplaceUnchecked,
	StableSort = StableSort, StableSortInplace = StableSortInplace, SortBy = SortBy, SortByInplace = SortByInplace,
	NthElement = NthElement, NthElementInplace = NthElementInplace, PartialSort = PartialSort,
	PartialSortInplace = PartialSortInplace, MergeSorted = MergeSorted, IsSorted = IsSorted, Map = Map,
	MapInplace = MapInplace, Filter = Filter, Retain = Retain, Flat = Flat, FlatInplace = FlatInplace,
	Flatmap = Flatmap, FlatmapInplace = FlatmapInplace, Drain = Drain, ConcatInplace = ConcatInplace,
	Fold = Fold, FoldRight = FoldRight, Reduce = Reduce, FoldUntil = FoldUntil, Get = Get,
	FirstIndex = FirstIndex, LastIndex = LastIndex, NextIndex = NextIndex, PrevIndex = PrevIndex,
}

# Luau 새 솔버 결함 — 업스트림 보고 초안 (질문 AA)

**상태(2026-10-12)**: 초안만 다듬어 둔 것입니다. **아무것도 올리지 않았습니다** — 사용자 결정(*"초안만 다듬어 두기"*).
올리는 것은 사용자가 직접 하거나 나중에 지시할 때.

- 대상: `luau-lang/luau` 이슈 트래커.
- 버전: `luau-analyze` 0.734(`mise.toml` 고정). 모두 **새 솔버(기본)에서 진단 0건, `--solver=old` 는 잡음** — 2026-10-12 에
  이 디렉터리의 재현 파일로 다시 확인했습니다(`luau-analyze <파일>` 대 `luau-analyze --solver=old <파일>`).
- 재현 파일은 라이브러리 없이 혼자 돕니다. 파일마다 `control` 줄(같은 실수의 다른 모양 — 잡힘)이 있어 "검사가 통째로
  꺼진 것이 아님" 을 보입니다.
- 저장소 쪽 감시: `spikes/52`(1번), `spikes/57`(2번), `spikes/62`(3·4번)가 기대치를 고정합니다 — 솔버가 고쳐지면
  배터리가 알려 줍니다.

## 올리기 전 체크리스트

1. **중복 검색**을 그 시점에 다시(이슈는 계속 바뀝니다). 검색어: `new solver generic function body return`,
   `table literal indexer string key`, `lambda annotation generic omitted parameter`, `free type leak lambda`.
   알려진 이웃: **`#2168`**("basic mapping function fails in new solver" — 타입 인자 없는 맨 람다가 **에러**가 나는 쪽,
   2025-12), 그것을 고치려던 PR `#2894` 등은 2026-09-08 에 머지 없이 닫힘. 아래 1·2번은 같은 영역
   (`FunctionCheckConstraint`)이지만 **증상이 반대**(에러가 안 남)라 별개로 봅니다 — 본문에 Related 로 적으세요.
2. **최신 릴리스에서 재현되는지** 다시(0.734 이후 고쳐졌을 수 있음). 고쳐진 것은 빼고, 저장소의 스파이크 기대치도 올립니다.
3. 다섯 건을 **이슈 다섯으로** 나눠 올리는 것을 권합니다(원인이 다를 수 있고, 하나씩 닫히기 쉬움). 실해 순서는 3 > 5 > 2 > 4 > 1.

---

## 1. 생략한 파라미터가 있으면 람다 주석의 상한이 사라짐

재현: `1-annotation-bound-lost.luau`

> **New solver: annotation on a function literal is not checked against an inferred generic when the literal omits a later parameter that mentions the generic**
>
> ```lua
> --!strict
> local function F<T>(x: T, fn: (T, T) -> ()) end
> local text: string = "x"
> F(text, function(v: number) end) -- no error in the new solver; error with --solver=old
> F(text, function(v: number, _w) end) -- control: reported once the parameter is declared
> ```
>
> **Expected**: an error on the first call (`T` is `string`, the callback annotates its parameter as `number`).
> **Actual**: no diagnostic with the new solver. `--solver=old` reports `Expected this to be 'number', but got 'string'`.
>
> The upper bound contributed by the annotation is lost when the lambda omits the second parameter (whose type
> mentions `T`). Declaring the parameter, passing explicit type arguments (`F<<string>>(…)`), or a non-generic
> signature all report the error. The shape of the omitted parameter does not matter (`T`, `{ T }`,
> `{ read [number]: T }`, `{ get: () -> T }` all reproduce); a contravariant occurrence (`(T) -> ()`) does not.
>
> Version: luau-analyze 0.734. Related (same area, opposite symptom): #2168.

우리 쪽 영향: 콜백의 셋째 인자를 `ArrView<T>` 로 두면 원소 타입을 더 좁게 적은 콜백이 안 잡혀 `ArrView<unknown>` 으로
바꿨습니다(질문 V → Z, `typing-limits.md` "뿌리" 절). 고쳐지면 `ArrView<T>` 로 되돌릴지 다시 봅니다.

## 2. 파라미터를 제약하지 않는 맨 람다의 결과가 자유 타입으로 샘

재현: `2-bare-lambda-free-type.luau`

> **New solver: result of an unannotated lambda that does not constrain its parameter is a free type — assignable to anything**
>
> ```lua
> --!strict
> local function Map2<T, G>(xs: { T }, f: (T) -> G): { G }
> 	local out: { G } = {}
> 	for i, x in xs do
> 		out[i] = f(x)
> 	end
> 	return out
> end
> local leaked: { string } = Map2({ 1, 2 }, function(v) return v end) -- no error; error with --solver=old
> print(leaked[1]) -- 1
> local control: { string } = Map2({ 1, 2 }, function(v: number) return v end) -- control: reported
> ```
>
> **Expected**: an error — the result is `{ number }`, not `{ string }`.
> **Actual**: no diagnostic with the new solver; at runtime `leaked[1]` is a number. `--solver=old` reports
> `Expected this to be exactly '{string}', but got '{number}'`.
>
> Annotating the lambda parameter or passing explicit type arguments (`Map2<<number, number>>(…)`) restores the
> error. The lambda body must not constrain its parameter (e.g. `return v` or `return v.name`).
>
> Version: luau-analyze 0.734. Related (same area): #2168.

우리 쪽 영향: 흔한 코드 모양(`Arr.Map(a, function(v) return v end)`)에서 타입이 거짓말을 합니다. 규약으로 "콜백을 넘길 땐
`<<T>>` 나 파라미터 주석을 항상"(conventions).

## 3. 제네릭 함수의 몸통이 타입 변수로 검사되지 않음

재현: `3-generic-body-unchecked.luau`, `3b-generic-body-arguments.luau`(인자 쪽)

> **New solver: a value of a generic type parameter is accepted where a concrete type is required inside the generic function's body**
>
> ```lua
> --!strict
> local function h<V>(v: V): number
> 	return v -- no error in the new solver; --solver=old: Expected this to be 'number', but got 'V'
> end
> local n: number = h("str")
> print(n) -- "str"
> local function mono(v: string): number
> 	return v -- control: reported for the non-generic function
> end
> ```
>
> **Expected**: an error on `return v` — `V` is not known to be `number`.
> **Actual**: no diagnostic with the new solver, so `h("str")` has static type `number` and runtime value `"str"`.
>
> The same happens for arguments in both directions (a type variable where a concrete type is required, and a
> concrete value where a type variable is required) — neither line is reported, `--solver=old` reports both:
>
> ```lua
> --!strict
> local function needsNumber(n: number): number
> 	return n
> end
> local function g<V>(v: V): number
> 	return needsNumber(v) -- old: Expected this to be 'number', but got 'V'
> end
> local function store<K, V>(t: { [K]: V }, k: K, v: V)
> 	t[k] = v
> end
> local function wrap<K, V>(t: { [K]: V }, k: K)
> 	store(t, k, "bad") -- old: Expected this to be 'V', but got 'string'
> end
> local nums: { [string]: number } = {}
> wrap(nums, "x")
> print(g("str"), nums.x) -- str	bad
> ```
>
> This makes generic helper functions unsound without any cast or `any`.
>
> Version: luau-analyze 0.734.

우리 쪽 영향: 불변 마커(`MapMarkerMut` 등, 질문 AM)가 **호출 자리만** 지킵니다 — 제네릭 안에서 다시 부르는 잘못된 쓰기는
0건. 넷 중 실해가 가장 큽니다(캐스트 없이 제네릭 하나로 타입 시스템이 뚫림).

## 4. 문자열 키 테이블 리터럴을 인덱서 파라미터에 넘기면 값 타입을 안 봄

재현: `4-string-key-literal-indexer.luau`

> **New solver: a table literal with string keys is not checked against an indexer parameter's value type**
>
> ```lua
> --!strict
> local function plain(t: { [string]: number }): number
> 	return t.x
> end
> local n: number = plain({ x = "bad" }) -- no error in the new solver; error with --solver=old
> print(n) -- "bad"
> local control = plain({ "bad" }) -- control: an array-style literal is reported
> local t: { [string]: number } = { x = "bad" } -- control: assigning to an annotated local is reported
> ```
>
> **Expected**: an error — `x = "bad"` does not fit `{ [string]: number }`.
> **Actual**: no diagnostic with the new solver when the literal is a **function argument**; the same literal assigned
> to an annotated local is reported, and so is an array-style literal passed as the argument.
>
> Version: luau-analyze 0.734.

우리 쪽 영향: `HashMap.FromTable<<string, number>>({ x = "bad" })` 가 0건입니다.

---

## 5. 재귀 타입 별칭이 유니온의 갈래이면 타입 인자를 안 봄 (2026-10-13 추가 — `LinkedDeque` 리뷰)

재현: `5-recursive-alias-in-union.luau`

> **New solver: a recursive generic alias is not checked against a different instantiation when the expected type is a union containing it (including `T?`)**

```lua
type Plain<T> = { value: T, next: Plain<T>? }
local ps: Plain<string> = { value = "s", next = nil }
local control: Plain<number> = ps          -- TypeError (정상)
local optional: Plain<number>? = ps        -- 0건
local union: Plain<number> | boolean = ps  -- 0건
```

- 옵셔널이 아닌 자리는 잡힙니다. 필드 이름이 다른 재귀 타입이나 테이블 리터럴도 잡힙니다. 유니온의 갈래일 때만.
- **이 저장소에서의 해**: 노드 위치가 전부 옵셔널로 나옵니다(`FirstIndex`·`List.IndexOf`·`Find` 의 둘째 반환 …) —
  `local at: NodeRead<number>? = List.IndexOf(문자열덱, "b")` 가 0건이고, 그 위치로 숫자 덱에 `InsertAfter` 하면
  문자열 덱에 숫자가 들어갑니다(리뷰어 재현, 메인 확인). 트리의 노드 타입(`RbNode` …)도 같은 모양입니다.
- 피하는 모양을 찾아봤습니다: 노드 타입을 교집합(`{ read value: T } & { read [number]: NodeRead<T>? }`)으로 적으면
  옵셔널 자리에서도 잡히지만, **기존 제네릭 추론 192곳이 깨져**(`No valid instantiation could be inferred`) 쓰지
  못합니다(2026-10-13 메인 실측). 팬텀 함수 필드, `| false`, 연결을 하위 테이블로 옮기기는 효과 없음(리뷰어 실측).
- 저장소 쪽 감시: `spikes/65` 의 "알려진 구멍" 줄(기대 0건 — 솔버가 고쳐지면 배터리가 알려 줌).
- 실해 순위: 3번 다음(조용히 다른 타입이 컨테이너에 들어감).

## 참고 — 올리지 않는 것

- **맨 람다가 제약될 때 에러가 남**(`Arr.Map(a, function(v) return v * 2 end)` — 타입 인자도 주석도 없을 때): 이미 있는
  이슈 `#2168` 과 같은 증상입니다. 새로 올리지 않고 2번 본문에서 Related 로만. 우리 쪽 우회는 `<<T>>`(`spikes/54`).

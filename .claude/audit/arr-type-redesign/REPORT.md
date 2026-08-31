# `Arr<T>` 타입 재설계 — 실측 보고

**날짜**: 2026-08-31
**도구**: `luau-analyze` (luau 0.734, new solver 기본)
**스파이크**: `spikes/00-baseline-negative-control.luau`

## TL;DR

문제는 "에러가 301건 난다" 가 아니었습니다. **타입 검사가 통째로 죽어
있었습니다.** 원인 셋을 분리해 고쳤고, 음성 대조군 6/6 이 살아났으며 진단은
**301 → 126**(재설계 몫), 테스트 헬퍼에 타입을 달아 **→ 41** 이 됐습니다.
런타임은 한 줄도 바뀌지 않았습니다. **다만 `arr.오타` 를 못 잡는 구멍이
하나 남아 있고**, 그걸 없애려면 `arr(1, 2, 3)` 호출 형태를 포기해야 합니다
(4번 절 — 사용자 결정 필요).

## 0. 판정 기준 — 건수가 아니라 음성 대조군

건수만 보면 **"301 → 5" 를 만들면서 `a:push("문자열")` 을 통과시키는 재설계**가
성공처럼 보입니다. 그래서 이 작업의 합격 기준은 다음 배터리입니다
(`spikes/00-baseline-negative-control.luau`):

- **POS 6건**: 정상 사용례. 에러가 나면 안 됨.
- **NEG 6건**: 일부러 틀린 코드. **전부 에러가 나야 함.**
- **CANARY 1건**: `local canary: string = 42` — `arr` 과 무관한 자명한 에러.
  이게 안 뜨면 그 파일이 애초에 검사되지 않고 있다는 뜻이라 **측정 자체가
  무효**입니다.

CANARY 가 없으면 "NEG 가 안 뜬다" 와 "파일이 검사되지 않는다" 를 구별할 수
없습니다. 실제로 첫 측정에서 이 구별이 결론을 좌우했습니다.

## 1. 기준선 — 타입 검사가 죽어 있었다

| | 결과 |
|---|---|
| POS 6건 | (판정 불가 — 아래) |
| **NEG 6건** | **0건 검출** ❌ |
| CANARY | 정상 검출 ✅ |
| 파일 전체 진단 | **1건** (`arr(1, 2, 3)` 이 ambiguous) |

CANARY 가 떴으므로 파일은 검사되고 있었습니다. 즉 **`arr` 을 거치는 순간
타입이 죽습니다.** 생성자 호출 한 줄이 ambiguous 해지면 그 결과가 에러
타입이 되고, 그 뒤 전부가 검사에서 빠집니다.

이것이 `typing-limits.md` 맨 위의 "진단 0건을 신뢰하지 마세요" 가 말하는
바로 그 상황입니다.

## 2. 원인 셋 — 변형별 실측

각 변형은 `src/arr.luau` 를 복사해 **꼬리(타입 선언부)만** 바꾼 것입니다.
본문은 손대지 않았습니다.

| 변형 | 바꾼 것 | 생성자 호출 | POS | NEG |
|---|---|---|---|---|
| S0 (기준선) | — | ❌ ambiguous | — | **0/6** |
| S2 | 가변인자에서 `\|any` 만 제거 | ❌ 여전히 ambiguous | — | 0/6 |
| S1 | 내보내는 값에서 `& Arr<any>` → `& ArrStatic` | ✅ 해소 | ❌ 3건 오탐 | 6/6 |
| S3 | 교집합 자체를 제거(통제군) | ✅ | ❌ 3건 오탐 | 5/5 |
| S4 | S1 + `Arr<T>` 를 `setmetatable<>` 로 | ✅ | ❌ 1건 오탐 | **6/6** |
| **S6** | **S4 + 콜백 타입 교집합 제거** | ✅ | **✅ 0건** | **6/6** |

### 원인 ① 내보내는 값에 인스턴스 타입을 교집합함

```lua
-- 이전
local Arr = (arr_ifce :: unknown) :: (<T>(...T|any) -> (Arr<T>)) & Arr<any>
```

`Arr<any>` 는 **인스턴스** 타입이라 `n: number` 와 `[number]: any` 를
가집니다. 모듈 테이블이 그런 걸 가진 것처럼 선언되고, 생성자 호출이 전부
ambiguous 해집니다. **S2 가 이걸 확정합니다** — `|any` 만 빼도 그대로
ambiguous 이므로 범인은 `& Arr<any>` 입니다.

→ 인스턴스 메소드를 뺀 `ArrStatic`(생성자류 9개)만 교집합합니다.
`arr.` 로 실제로 쓰이는 스태틱은 `sized`/`is_arr`/`merge`/`from_table`/
`clone_from_table` 뿐이라(테스트와 `init.luau` grep) 표면이 작습니다.

### 원인 ② 데이터부와 인터페이스를 `&` 로 합쳐 인덱서가 샘

```lua
-- 이전
export type Arr<T> = { n: number, [number]: T } & ArrInterface
```

`ArrInterface = typeof(arr_ifce)` 는 **추론된(봉인되지 않은)** 테이블
타입입니다. 구현부의 `self[idx] = ...` 쓰기가 교집합의 테이블 쪽으로 흘러
들어가 **모듈 테이블에 `[number]: T & nil` 인덱서가 붙습니다**
(`luau-analyze --annotate` 로 확인). 그 자유 `T` 때문에 정상 호출까지 거부됩니다:

```
a:push(4)
  → No valid instantiation could be inferred for generic type parameter T.
    It was expected to be at least:  number | T & nil
    and at most:                     number & T & nil
```

`T & nil` 이 그 누수의 지문입니다.

→ `setmetatable<ArrData<T>, { __index: ArrInterface }>` 로 선언합니다.
데이터부에 쓰는 것과 인터페이스를 읽는 것이 분리되어 누수가 사라집니다.

**quad 의 ② 쪼개기(`self: ArrData<T>`)는 이 모양에서 안 통했습니다**(S5,
실측). `self` 파라미터만 데이터부로 바꾸면 구현부가 `return self` 로 `Arr<T>`
를 만들 수 없고, S1 대비 오탐도 줄지 않았습니다. **quad 쪽에서 왜 이 비용이
안 드러나는지는 측정하지 않았습니다** — quad 코드를 돌려본 게 아니라 여기
`arr` 모양에 적용해 본 결과일 뿐입니다.

### 원인 ③ 콜백 타입이 교집합이라 정상 콜백을 거부함

```lua
-- 이전
type CallBack<T, Ret> =
	((element: T, index: number, arr: Arr<T>) -> Ret)
	& ((element: T, index: number) -> Ret)
	& ((element: T) -> Ret)
	& (() -> Ret)
```

**교집합은 "모든 arity 를 동시에 만족" 을 요구합니다.**
`function(x: number) return tostring(x) end` 은 `() -> Ret` 를 만족할 수
없으므로 `a:map(fn)` 이 막힙니다:

```
Expected the parameter types to be a supertype of `()`, but got `number`
```

Luau 는 **인자를 덜 받는 함수를 이미 서브타입으로 받아줍니다.** arity 별
오버로드를 손으로 나열할 이유가 없습니다.

→ 가장 넓은 시그니처 하나로 씁니다.

## 3. 결과

| | 이전 | **재설계만** | + 테스트 헬퍼 주석 |
|---|---|---|---|
| NEG 검출 | 0/6 ❌ | **6/6** ✅ | 6/6 ✅ |
| POS 오탐 | (판정 불가) | **0** ✅ | 0 ✅ |
| `src/arr.luau` | 72 | **20** | 20 |
| `tests/arr.luau` | 229 | **106** | **21** |
| 합계 | 301 | **126** | **41** |
| `luau tests/run.luau` | PASS | PASS | PASS (런타임 변경 없음) |

**두 변경을 섞어 세지 마세요.** 재설계 자체는 301 → **126** 입니다. 41 까지
가는 나머지 85건은 테스트 헬퍼 두 개(`fmt`, `assert_arr`)에 `arr.Arr<any>` 를
단 몫입니다. 그리고 그 주석은 **공짜가 아닙니다** — 원소 타입이 `any` 라
`assert_arr(arr(1, 2), arr("1", "2"))` 같은 비교가 타입 검사에서 통과합니다.
이종 배열을 비교하는 헬퍼라 의도한 절충이지만, 절충인 건 맞습니다.

## 4. ⚠️ 남은 구멍 — 교집합에 함수 타입이 끼면 속성 접근이 검사되지 않음

`arr` 모듈 값은 `(<T>(...T) -> Arr<T>) & ArrStatic` 입니다. **함수 타입과
테이블 타입의 교집합에서는 없는 속성 접근이 잡히지 않습니다.**

최소 재현(`spikes/11-intersection-prop-hole.luau`, 15줄):

```lua
type S = { a: number }
local table_only    = (nil :: any) :: S
local fn_and_table  = (nil :: any) :: (<T>(...T) -> T) & S

local neg1 = table_only.nope     -- ✅ "Key 'nope' not found in table 'S'"
local neg2 = fn_and_table.nope   -- ❌ 조용히 통과
```

실제 영향: **`arr.오타` 가 안 잡힙니다**(`spikes/10-static-surface.luau`).
`ArrStatic` 에 없는 인스턴스 메소드의 점 호출(`arr.push(a, 1)`)도 마찬가지로
조용히 통과합니다. **인스턴스 쪽은 멀쩡합니다** — `a:no_such_method()` 는
정상적으로 잡힙니다(NEG-3).

### 이걸 없애려면 `arr(1, 2, 3)` 을 포기해야 합니다 — **사용자 결정 필요**

내보내는 값을 **순수 테이블**(`:: ArrStatic`)로 두면 구멍이 사라집니다.
실측(S7):

| | `arr(1, 2, 3)` 유지 (**현재**) | 순수 테이블 (`arr.pack(1, 2, 3)`) |
|---|---|---|
| 생성자 호출 `arr(...)` | ✅ | ❌ `Cannot call a value of type ArrStatic` |
| 인스턴스 메소드 검사 | ✅ | ✅ |
| **`arr.오타` 검출** | ❌ 조용히 통과 | ✅ `Key '...' not found` |

`arr.pack(...)` 은 이미 `arr(...)` 과 같은 일을 하는 스태틱이라 대안은
있습니다. 다만 `tests/arr.luau` 만 해도 호출부가 200군데 가까이 되고 공개
API 모양이 바뀌는 일이라 **이 세션에서는 바꾸지 않았습니다.**
quad `typing-limits.md` §7 의 *"콜러블 팩토리는 `__call` 이 아니라 지정된
필드로 자기를 노출한다"* 가 같은 결론을 다른 경로로 말하고 있습니다.

## 5. 남은 것

- **`src/arr.luau` 20건**: 생성자 본문(`table.create(n)` 결과에 `n`/`__arr__`
  를 덧붙이는 패턴, 6건), `slice` 의 `to_start` 가 `number?` 인 실제 버그
  (`todos.md` 참고), 파일 끝의 `Arr` 캐스트. **이제 하나씩 볼 만한 진단**입니다.
- **`tests/arr.luau` 21건**: 이종 중첩 배열(`arr(1, arr(2), 3):flat()`)에서
  `T` 가 안 풀리는 것, 무주석 콜백 파라미터.
- **`arr(1, 2, 3)` 형태는 지켰습니다.** quad §7 이 "타입 레벨 `__call` 은 죽은
  경로" 라고 적어둬서 API 를 `arr.of(...)` 로 바꿔야 할 가능성을 염두에 뒀지만,
  실측 결과 **바꾸지 않고도 됩니다** — 문제는 `__call` 이 아니라 교집합의
  상대편(`Arr<any>`)이었습니다.

## 5. 재현

```bash
luau-analyze .claude/audit/arr-type-redesign/spikes/00-baseline-negative-control.luau
```

POS 무에러 + NEG 6건 + CANARY 1건 = **진단 정확히 7건**이 나와야 합니다.
숫자가 줄면 타입 검사가 다시 죽은 것일 수 있으니 **어느 NEG 가 사라졌는지**
확인하세요.

나머지 스파이크:

| 파일 | 무엇을 재는가 | 기대 진단 |
|---|---|---|
| `spikes/00-baseline-negative-control.luau` | 인스턴스 타입 안전성 | **7건** (NEG 6 + CANARY) |
| `spikes/10-static-surface.luau` | 스태틱 표면 + 위 4번의 구멍 | **1건** (CANARY 만 — `arr.오타` 가 안 잡히는 게 지금 상태) |
| `spikes/11-intersection-prop-hole.luau` | 4번 구멍의 최소 재현 | **2건** (`table_only.nope` + CANARY) |

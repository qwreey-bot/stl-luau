# 스파이크 목록 — `Arr<T>` 타입 설계

각 파일은 **기대 진단 건수**가 정해져 있습니다. 숫자가 달라지면 무언가 바뀐 것이니
어느 NEG 가 사라졌는지 확인하세요. 전부 `luau-analyze <파일>` 로 돌립니다.

| 파일 | 무엇을 재는가 | 기대 |
|---|---|---|
| `00-baseline-negative-control.luau` | 인스턴스 타입 안전성 (NEG 6 + CANARY) | 7건 |
| `10-static-surface.luau` | 스태틱 표면 + 교집합 속성 구멍 | 1건 |
| `11-intersection-prop-hole.luau` | 함수&테이블 교집합에서 오타가 안 잡히는 최소 재현 | 2건 |
| `22-export-shape-comparison.luau` | 모듈 export 모양 3종 비교 | 5건 |
| `23-chain-type-preservation.luau` | 현행 설계의 체이닝 타입 보존 (누수 재현) | 3건 |
| `24-typeof-named-fn-fix.luau` | quad ③ `typeof(named fn)` 이 누수를 고치는가 | 5건 |
| `25-quad-style-namespace.luau` | quad 스타일 네임스페이스 설계 전체 | 6건 |
| `26-setmetatable-selfhandle-boundary.luau` | setmetatable + self 핸들 콜백 경계 | 5건 |
| `27-constructor-organization.luau` | 생성자 조직 3안 (평평/콜러블/네임스페이스) | 9건 |
| `29-intersection-at-scale.luau` | 63개 규모에서 교집합이 버티는가 | 4건 |
| `30-final-design-at-scale.luau` | **확정 설계 전체** (63 메소드 + 네임스페이스) | 13건 |
| `31-callback-view-type.luau` | **콜백 뷰 타입** — 체이닝과 메소드 호출을 둘 다 얻는 경계 | 5건 |
| `32-iter-and-fold.luau` | `__iter` 타이핑 + `Fold` 인자 순서 | 5건 |
| `33-iter-typing-variants.luau` | `__iter` 선언 방식 3종 비교 | 3건 |
| `34-iter-boundary.luau` | for-in 타이핑이 죽는 경계 찾기 | 5건 |
| `35-intersection-breaks-forin.luau` | **교집합이 for-in 을 깬다는 최소 재현** | 6건 |

## 규모 실측 (2026-09-21, luau 0.734)

`setmetatable<Data<T>, { __index: Ifce }>` 는 **메소드 30개에서 무너집니다**:

| 메소드 수 | `setmetatable<>` | 교집합 `&` |
|---|---|---|
| 10, 20 | 클린 | 클린 |
| 30~63 | `Code is too complex` + `pending-expansion` 1700여 건 + 추론 실패 | 클린 |

**한도 플래그는 듣지 않습니다.** quad 가 쓰는 3종(`LuauTarjanChildLimit`,
`LuauSubtypingIterationLimit`, `LuauTypeInferIterationLimit`)에 3종을 더해도
`luau-analyze`/`luau-lsp` 양쪽에서 1590건 그대로입니다 — 예산이 아니라
`setmetatable<>` 타입 함수가 확장을 못 하는 구조 문제입니다.

## 콜백의 컨테이너 인자 (bisect 결과)

타입 변환 체이닝(`Map`)이 사는지 죽는지는 **콜백 3번째 인자 하나**가 가릅니다:

| 콜백 시그니처 | 1단 | 2단 | 3단 |
|---|---|---|---|
| `(el: T) -> G` | ✅ | ✅ | ✅ |
| `(el: T, idx: number) -> G` | ✅ | ✅ | ✅ |
| `(el, idx, arr: ArrData<T>) -> G` | ✅ | ✅ | ✅ |
| **`(el, idx, arr: Arr<T>) -> G`** | ❌ | ❌ | ❌ `ArrData<any>` |

전체 재귀 타입(`Arr<T>`)을 콜백에 넘기면 1단부터 죽습니다. 데이터부(`ArrData<T>`)를
넘기면 3단까지 정확합니다 — quad `typing-limits.md` §1-6 "데이터부/메소드부 쪼개기".

## 콜백 뷰 타입 — 체이닝과 메소드 호출을 둘 다 얻는다

앞 표는 "콜백에 데이터부만 넘겨야 한다"로 읽히지만, 더 정확한 규칙이 있습니다.
**콜백 타입이 `Arr<T>`(전체 타입)를 어디에서도 언급하지 않으면 됩니다.**

| 콜백 arr 타입 | 3단 체이닝 | 콜백서 메소드 |
|---|---|---|
| `ArrData<T>` (데이터부만) | ✅ | ❌ |
| **비재귀 메소드 포함** (`Len`, `Join`) | **✅** | **✅** |
| **자기폐쇄 재귀** (`Slice: ... -> ArrView<T>`) | **✅** | **✅** |
| 재귀 반환이 `Arr<T>` (`Slice: ... -> Arr<T>`) | ❌ | ✅ |
| 타입 변환 재귀 (`Map`) | ❌ | ✅ |
| 전체 `Arr<T>` | ❌ | ✅ |

그래서 `ArrView<T>` 는 **조회 메소드 + 자기폐쇄 재귀 메소드**를 담되, 그 반환이
`Arr<T>` 가 아니라 `ArrView<T>` 입니다. 타입을 바꾸는 `Map`/`FlatMap` 은 `Arr<G>`
를 낳아야 하므로 뷰에 넣을 수 없습니다 — 넣으면 바깥 체이닝이 죽습니다.

`31-callback-view-type.luau` 에서 콜백 안의 `arr.n` / `arr:Len()` / `arr:Join(",")`
/ `arr:Slice(1, idx):Len()` 이 전부 동작하면서 바깥 3단 타입 변환 체이닝이
`ArrData<number> & ArrIfce` 로 정확히 유지되는 것을 확인했습니다. 규모 증상 0건.

## ⭐ 교집합 타입은 `for-in` 루프 변수의 타입을 잃는다

`35-intersection-breaks-forin.luau` (최소 재현, 30줄):

| 타입 | `x[1]` 직접 인덱싱 | `for _, v in x` |
|---|---|---|
| `{ n: number, [number]: number }` (평범) | ✅ | ✅ `v: number` |
| **`{…} & { Len: … }` (교집합)** | ✅ | ❌ **`v: Unifiable<Error>`** |
| `setmetatable<{…}, {__index: …}>` | ✅ | ✅ `v: number` |

**`__iter` 와 무관합니다** — `__iter` 를 아예 안 달아도 교집합이면 죽습니다.
Luau 의 for-in 은 테이블의 **인덱서**를 보고 루프 변수를 타이핑하는데,
교집합의 인덱서를 못 봅니다. 진단은 0건이라 **조용히 죽습니다.**

### 이게 만드는 딜레마

| | 메소드 63개 규모 | `for-in` 타이핑 |
|---|---|---|
| 교집합 `&` | ✅ 클린 | ❌ 죽음 |
| `setmetatable<>` | ❌ 30개에서 붕괴 | ✅ 산다 |

둘 다 가질 수 없습니다. **교집합을 택했으므로 `for-in` 은 타입을 잃습니다.**

### 그래서 순회는 이렇게 안내한다

| 방법 | 속도 | 타입 |
|---|---|---|
| **`for i = 1, arr.n do … arr[i] …`** | **1.00x (가장 빠름)** | ✅ 살아있음 |
| `arr:Fold(init, fn)` 콜백 | 2.54x | ✅ 콜백 파라미터가 타이핑됨 |
| `for _, v in arr` (`__iter`) | 2.80x | ❌ 죽음 |

**세 축 모두에서 `for i = 1, arr.n` 이 이기거나 비깁니다.** 직접 인덱싱은
교집합에서도 타입이 살아있습니다(위 표 첫 열).

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

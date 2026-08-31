# Luau 타입 한계와 이 저장소의 현황

quad 의 같은 이름 문서(`/code/Projects/quad/.claude/base/typing-limits.md`)가
**훨씬 방대하고 실측이 잘 돼 있습니다 — 타입 문제로 막히면 거기부터
읽으세요.** 이 문서는 stl-luau 고유의 현황만 기록합니다.

## 원칙 (quad 에서 가져옴)

- **⭐ Luau 한계를 우회하려고 API/타입을 비틀지 마세요.** 한계를 문서화하고,
  그로부터 강제되는 사용 관례를 적고, 나중에 되돌릴 수 있게 RFC/이슈 링크를
  남기는 게 원칙입니다. 반환 타입을 `any` 로 열어버리는 식의 회피는 금지.
  (근거: quad 의 사용자 발언 — *"타입을 비틀어 해당 시도를 하는 건 전혀
  적합하지 않고, 이것은 상위의 Luau의 현 한계다."*)
- **⭐ "진단 0건" 을 신뢰하지 마세요.** 타입이 `any`/`Unifiable<Error>` 로
  조용히 새면 검사가 그냥 통과합니다. 반드시 (a) 실제 추론된 타입을 확인하고
  (b) **음성 대조군**(일부러 틀린 대입)을 넣어 에러가 나는지 봐야 합니다.
- **추론만으로 "된다/안 된다" 를 결론짓지 마세요.** 작은 스파이크 파일을
  만들어 실제로 돌려보세요.

## ⭐ [2026-08-31 실측] 체커: `luau-analyze` (luau-lsp 아님)

**결론부터**: 타입 검사는 `luau-analyze` 로 합니다. 예전에 쓰던
`luau-lsp analyze --platform=standard --flag:LuauSolverV2=true` 는 **진단을
조용히 빠뜨립니다.**

같은 `src/arr.luau` 를 두 체커로 돌려 진단을 줄 단위로 비교했습니다:

| | 건수 |
|---|---|
| `luau-analyze src/arr.luau` | 72 |
| `luau-lsp analyze --platform=standard --flag:LuauSolverV2=true src/arr.luau` | 68 |

겹치지 않는 부분이 전부입니다:

- **luau-analyze 만 잡는 것 (5건)**
  - `slice` 의 `to_start` 계산부(`arr.luau` 803~804): `to_start` 가
    `number?` 인데 `-`/`+` 에 그대로 들어갑니다. **이건 실제 버그가 있는
    바로 그 줄입니다**(`.claude/todos.md` 10번 — `to_start` 삽입 경로의
    소스 구간이 틀렸음). luau-lsp 는 이 줄에 대해 아무 말도 하지 않습니다.
  - `from_iter` 의 `arr_ifce(iter(...))` 호출(56행), `replace_inplace`
    (345행) 에서 각각 추가 진단.
- **luau-lsp 만 내는 것 (3건)**: 전부 345행의
  `Code is too complex to typecheck!` 와 그로 인해 잘린 메시지입니다.
  즉 luau-lsp 는 **같은 자리에서 검사를 포기**하고, luau-analyze 는 끝까지
  검사해서 구체적인 에러 3건을 냅니다.

즉 차이는 "두 도구가 서로 다른 의견을 낸다" 가 아니라 **luau-lsp 쪽이 덜
본다** 입니다. 이 문서 맨 위의 "진단 0건을 신뢰하지 마세요" 원칙이 도구
선택에도 그대로 적용됩니다.

**부수 효과**: 타입 검사 기준선이 `luau` 바이너리에 묶이므로 `mise.toml` 에
`luau = "0.734"` 를 고정했습니다. 아래 수치는 전부 그 버전 기준입니다.

## ⭐ [2026-08-31 실측] `.luaurc` 하나에 의존하면 검사가 통째로 꺼집니다

`.luaurc` 의 `"languageMode": "strict"` 를 `"nonstrict"` 한 단어로 바꾸고
`luau-analyze src tests` 를 돌리면:

| `.luaurc` | 파일 상단 `--!strict` | TypeError |
|---|---|---|
| `strict` | 없음 | 310 |
| **`nonstrict`** | 없음 | **0** |
| `nonstrict` | 없음 (+ `--mode=strict` 플래그) | **0** |
| `nonstrict` | **있음** | 301 |
| `strict` | 있음 | 301 |

- 한 단어가 바뀌면 **에러 310건이 소리 없이 0건이 됩니다.** 커밋 리뷰에서
  "타입 클린해졌다" 로 읽히기 딱 좋습니다.
- **`--mode=strict` 플래그는 `.luaurc` 를 덮어쓰지 않습니다.** 그 플래그는
  `.luaurc` 도 `--!` 지시자도 없을 때의 *기본값*만 정합니다. CLI 로
  강제할 방법이 없습니다.
- 그래서 **각 파일 상단의 `--!strict` 가 유일하게 믿을 수 있는 층**입니다.
  quad 가 292개 파일에 `--!strict` 를 다는 이유가 이것입니다.

## [2026-08-31] `--!strict` / `--!nocheck` 를 어디에 다는가

- **`--!strict`**: `src/arr.luau`, `src/common.luau`, `src/init.luau`,
  `src/fut.luau`, `src/record.luau`, `src/treeset.luau`, `tests/arr.luau`,
  `tests/run.luau`.
- **`--!nocheck`**: `src/tuple.luau`, `src/typeutil.luau`. 실험적
  `type function` 탐색 코드이고 `src/init.luau` 에서 export 되지 않으며
  다른 모듈이 의존하지 않습니다(`conventions.md`). 정식 API 로 승격할 때
  `--!strict` 로 바꾸세요. 이걸로 노이즈 9건이 기준선에서 빠졌습니다.
- **안 다는 것**: 0바이트 미착수 파일(`bsearch`/`heap`/`hashmap`/`hashset`/
  `treemap`). 헤더만 든 파일은 여전히 `require` 불가라 빈 파일보다 나을 게
  없습니다.
- **`tests/arr.luau` 는 strict 를 유지합니다** — quad 의 `test.sh` 는 느슨한
  스모크 테스트를 검사 대상에서 빼지만 여기서는 따라가지 않습니다. 아래
  301건 중 **229건이 테스트 파일에 있고 전부 같은 원인**(`arr(1, 2, 3)` 호출이
  ambiguous)이며, 이건 **사용자가 이 라이브러리를 쓸 때 그대로 겪을 문제**라
  가장 중요한 증거입니다. 검사에서 빼면 그 증거가 사라집니다.

## ⭐⭐ [2026-08-31 해소] `Arr<T>` 재설계 — 타입 검사가 죽어 있었다

**전문과 실측 전량: `.claude/audit/arr-type-redesign/REPORT.md`.** 여기엔
결론만 둡니다.

문제는 "에러가 301건 난다" 가 아니라 **`arr` 을 거치는 순간 타입 검사가
통째로 사라진다** 였습니다. 일부러 틀린 코드 6가지(`Arr<number>` 에 string
push, 없는 메소드, `n` 을 string 에 대입 등)를 넣었는데 **0건 검출**이었고,
같은 파일의 무관한 자명한 에러(CANARY)는 정상적으로 떴습니다.

원인 셋 — 전부 타입 선언부뿐이고 런타임은 안 건드렸습니다:

1. **내보내는 값에 인스턴스 타입을 교집합**했습니다
   (`... & Arr<any>`). 모듈 테이블이 `n`/`[number]` 를 가진 것처럼 되어
   `arr(1, 2, 3)` 이 전부 ambiguous → 그 뒤가 전부 검사에서 빠짐.
   → 스태틱만 담은 `ArrStatic` 을 교집합합니다.
2. **데이터부와 인터페이스를 `&` 로 합쳐 인덱서가 샜습니다.**
   구현부의 `self[idx] = ...` 가 `typeof(arr_ifce)` 쪽으로 흘러 모듈
   테이블에 `[number]: T & nil` 이 붙고, 그 자유 `T` 때문에 **정상 호출까지**
   `No valid instantiation` 으로 거부됐습니다. `T & nil` 이 이 누수의
   지문입니다. → `setmetatable<ArrData<T>, { __index: ArrInterface }>`.
3. **콜백 타입을 arity 별 교집합으로 나열**해서 정상 콜백이 거부됐습니다.
   교집합은 "모든 arity 를 동시에 만족" 을 요구합니다. Luau 는 인자를 덜
   받는 함수를 **이미 서브타입으로 받으므로** 교집합이 불필요합니다.
   → 가장 넓은 시그니처 하나.

**결과**: NEG 0/6 → **6/6**, POS 오탐 0. TypeError 는 **재설계 몫이
301 → 126**(`src/arr.luau` 72 → 20, `tests/arr.luau` 229 → 106)이고, 여기에
테스트 헬퍼 두 개에 `arr.Arr<any>` 를 달아 **→ 41** 이 됩니다. 그 주석은
공짜가 아니라 헬퍼 안에서 원소 타입 검사를 포기하는 절충입니다. 테스트는
그대로 통과(런타임 무변경).

**⚠️ 남은 구멍**: 내보내는 값이 `(<T>(...T) -> Arr<T>) & ArrStatic` 이라
**`arr.오타` 가 안 잡힙니다.** 함수 타입과 테이블 타입의 교집합에서는 없는
속성 접근이 검사되지 않습니다(최소 재현:
`.claude/audit/arr-type-redesign/spikes/11-intersection-prop-hole.luau`).
**인스턴스 쪽은 멀쩡합니다**(`a:no_such_method()` 는 잡힘). 이걸 없애려면
`arr(1, 2, 3)` 을 버리고 순수 테이블(`arr.pack(1, 2, 3)`)로 가야 하는데
공개 API 가 바뀌는 일이라 **사용자 결정 대기**입니다(`question.md`).

**여기서 배운 규칙 (새 컨테이너에도 적용)**:

- **인스턴스 타입을 `데이터 & 인터페이스` 교집합으로 만들지 마세요.**
  `setmetatable<Data<T>, { __index: Interface }>` 를 쓰세요. 런타임 구조와도
  이 쪽이 맞습니다.
- **모듈이 내보내는 값에 인스턴스 타입을 섞지 마세요.** 스태틱 표면만
  따로 선언하세요.
- **arity 오버로드를 교집합으로 나열하지 마세요.** 가장 넓은 시그니처 하나면
  됩니다.
- **모듈 값을 `함수 & 테이블` 교집합으로 내보내면 그 테이블 쪽 오타를 못
  잡습니다.** 호출 가능한 팩토리가 꼭 필요한 게 아니면 순수 테이블로 내보내세요.
- **건수를 성공 지표로 쓰지 마세요.** 반드시 음성 대조군 + CANARY 를 함께
  두세요. `.claude/audit/arr-type-redesign/spikes/00-baseline-negative-control.luau`
  가 그 배터리이고, **진단이 정확히 7건** 나와야 정상입니다.

## [2026-08-22 실측, 2026-08-31 재측정 — 아래 수치는 재설계 **이전** 기록입니다]

`./scripts/check.sh`(= `luau-analyze src tests`, 경로 정규화 후) 기준
**TypeError 301건**(2026-08-31). 내역:

| 파일 | 건수 |
|---|---|
| `src/arr.luau` | 72 |
| `tests/arr.luau` | 229 |
| 그 외 전부 | 0 |

**두 숫자를 항상 따로 보고하세요.** 229건은 "`Arr` 를 바깥에서 쓰면 호출이
ambiguous 하다" 하나의 문제이고, 72건은 "`Arr` 내부 구현이 solver 를 못
따라간다" 는 다른 문제입니다. 합쳐놓으면 둘 다 안 보입니다.

**측정 도구가 바뀌었습니다.** 이전 기록의 47건(2026-08-22)/68건은
`luau-lsp analyze` 기준이고 `src/arr.luau` 만 센 것입니다. 같은 시점의
`src/arr.luau` 를 두 도구로 재면 luau-lsp 68 / luau-analyze 72 입니다
(위 "체커" 절). 앞으로는 **`luau-analyze` 숫자만** 씁니다.

런타임 동작은 정상입니다(`tests/arr.luau` 전부 통과) — 즉 이건 "코드가 틀렸다"
가 아니라 **타입 표현이 solver 를 못 따라간다** 는 문제입니다. 다만 아래 표의
`to_start` 3건처럼 **진짜 버그도 섞여 있으니** 전부 노이즈로 넘기지 마세요.

`src/arr.luau` 72건의 유형별 내역:

| 건수 | 내용 |
|---|---|
| 47 | `No valid instantiation could be inferred for generic type parameter` — `table.move` 계열 호출에서 제네릭이 안 풀림 |
| 9 | `Expected this to be ...` — 메타테이블 + intersection 조합 (이 중 1건은 아래 `to_start`) |
| 7 | `Cannot add property 'n' / '__arr__' to table ...` — `table.pack(...)`/`table.create(n)` 의 결과에 필드를 덧붙이는 패턴 |
| 6 | `Expected type table, got ...` / `Type ... does not have key 'n'` — 위 원인에서 파생 |
| **2** | **`Operator '-'/'+' ... number?`** — `slice` 의 `to_start` 산술(803~804행). `to_start` 가 `number?` 인 채로 계산에 들어갑니다. **실제 버그가 있는 자리**(`todos.md` 10번)이고 **luau-lsp 는 못 잡던 것** |
| 1 | `Cannot cast 'unknown' into ...` — 파일 끝의 `Arr` 캐스트 |

(합 72)

`tests/arr.luau` 229건의 내역 — **205건이 한 줄짜리 원인**입니다:

| 건수 | 내용 |
|---|---|
| **205** | `Calling function ... is ambiguous` — 아래 |
| 12 | `No valid instantiation ...` — src 와 같은 원인 |
| 8 | `Cannot compare unrelated types ...` — `assert(a:max() == 5)` 처럼 결과를 비교할 때 |
| 3 | `Operator '%' could not be applied ...` |
| 1 | `Consider placing the following annotations on the argument` |

(합 229)

205건의 정체:

```
Calling function (<T>(...T | any) -> ArrInterface & { [number]: T, n: number })
& ArrInterface & { [number]: any, n: number } with argument pack ... is ambiguous.
```

`arr(1, 2, 3)` 처럼 **생성자를 호출할 때마다** 납니다. `Arr` 가
"호출 가능한 함수" 와 "인스턴스" 를 하나의 intersection 으로 합쳐놓은 탓
(`local Arr = (arr_ifce :: unknown) :: (<T>(...T|any) -> Arr<T>) & Arr<any>`)
이라, 재설계에서 이 둘을 분리하는 게 첫 번째 후보입니다.

**구현을 더할수록 이 숫자는 계속 늘어납니다** — 재설계 전까지는 개별 함수에
`:: any` 를 덧발라 숫자를 낮추지 마세요(원인을 가릴 뿐입니다).

**[2026-08-22 해소] `Argument count mismatch` 7건**은 `sized(length, fill)` 의
`fill: T` 를 `fill: T?` 로 고쳐 없앴습니다(`arr_sized(0)` 처럼 `fill` 을
생략하는 호출이 내부에 여럿 있는데 시그니처가 필수 인자로 돼 있었음).
54건 → 47건. 이건 타입 회피가 아니라 시그니처 자체가 틀렸던 것입니다.

### 근본 원인 (추정, 미확정)

`Arr<T>` 는 지금 이렇게 정의돼 있습니다(`src/arr.luau` 끝부분):

```lua
export type ArrInterface = typeof(arr_ifce)
export type Arr<T> = { n: number, [number]: T } & ArrInterface
local Arr = (arr_ifce :: unknown) :: (<T>(...T|any) -> (Arr<T>)) & Arr<any>
```

문제가 되는 지점 셋:

1. **`table.pack`/`table.create` 결과에 필드를 덧붙이는 생성 패턴.**
   solver 는 그 결과를 `{unknown}` 으로 보고 `n`/`__arr__` 추가를 거부합니다.
2. **`typeof(arr_ifce)` 로 만든 인터페이스와 데이터부의 intersection.**
   `arr_ifce` 는 자기 자신이 메타테이블이면서 생성자 메타테이블
   (`arr_constructor`)도 얹고 있어, `@metatable` 이 낀 타입과
   `ArrInterface` 가 서로 subtype 이 아니게 됩니다.
3. **메소드가 `Arr<T>` 를 받아 `Arr<U>` 를 돌려주는 자기재귀 제네릭**
   (`map`, `flatmap` 등). 이건 quad 문서 §1 이 다루는 바로 그 케이스입니다
   — RFC [`relax-recursive-type-restriction`](https://rfcs.luau.org/relax-recursive-type-restriction.html),
   이슈 [luau-lang/luau#2380](https://github.com/luau-lang/luau/issues/2380).

### 아직 시도하지 않은 것 (다음 작업)

quad 문서가 제시하는 회피법 중 이 저장소에 적용해볼 만한 것:

- **§1 워크어라운드 ③ — 메소드를 최상위 named function 으로 선언하고
  `typeof(fn)` 으로 타입에 넣기.** 인라인 함수 타입 리터럴 대신:
  ```lua
  local function map<T, U>(self: Arr<T>, fn: (T) -> U): Arr<U> ... end
  type Arr<T> = { map: typeof(map), ... }
  ```
  quad 는 이걸로 체인 깊이 50 까지 반환 타입 안전성을 확보했습니다
  (파라미터 추론은 별개 문제로 남음).
- **§1 워크어라운드 ② — 데이터부/메소드부 타입 분리**(`ArrData<T>` /
  `Arr<T>`). 콜백 파라미터 추론이 필요할 때.
- (`sized` 의 `fill` optional 화는 이미 적용했습니다 — 위 참고.)

**이 재설계는 아직 착수하지 않았습니다.** 착수 전에 quad 의 typing-limits.md
전문을 읽고, 스파이크 파일로 후보안을 먼저 측정하세요(음성 대조군 포함).

## 기타 모듈

- `tuple.luau` 9건, `typeutil.luau` 3건, `treeset.luau` 1건
  (`subtract` 의 미타입 파라미터). 전부 스텁/실험 코드라 우선순위가 낮습니다.

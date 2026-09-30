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

---

## ⚠️ 제네릭 컨테이너를 쓸 때 조용히 타입을 잃는 자리 셋 (2026-09-22)

전부 같은 뿌리입니다 — **Luau 는 기대 타입을 제네릭 호출 안으로 전파하지
않습니다.** 그래서 추론할 재료가 인자에 없으면 `unknown` 이 되고, **진단은
0건**이라 조용히 지나갑니다.

### ⭐ 해법: 명시적 타입 인자 `f<<T>>(...)`

**셋 다 이걸로 풀립니다**(2026-09-22 실측, luau 0.734). 캐스트보다 낫습니다 —
캐스트는 *"내 말을 믿어라"* 이고 이건 *"답을 알려준다"* 입니다.

```lua
local a = Arr.Of<<number>>()                          -- 빈 배열
local m = HashMap.New<<string, number>>()             -- 인자 없는 생성자
local h = HashMap.FromTable<<string, number>>({ a = 1 })  -- 테이블 리터럴
local f = nested:Flat<<number>>()                     -- 반환으로만 결정되는 것
local i = Arr.FromIter<<number>>(ipairs(list))
local s = Arr.Sized<<number?>>(5, nil)                 -- 구멍으로 시작(타입에 드러냄)
local mapped = nums:Map<<string>>(fn)                 -- 메소드에도 됩니다
```

tbox 가 이 문법을 **전역적으로 채택**했습니다 — *"추론 부작용을 피하기 위한
의도적 선택"*. 같은 이유입니다.

⚠️ **stylua 가 `<<`/`>>` 를 시프트 연산자로 잘못 재작성한다는 실측 경고가
tbox 에 있습니다.** 우리가 고정한 **2.5.2 에서는 재현되지 않습니다**(포맷
전후로 파싱·실행 동일함을 확인). **버전 고정이 값을 하는 자리이니
`mise.toml` 의 stylua 를 올릴 땐 이걸 먼저 확인하세요.**

⚠️ **가변 팩 자리의 명시적 타입 인자는 괄호로 감쌉니다.** `Fut<T...>` 처럼
팩을 받는 제네릭에 `Fut.Rejected<<number>>(e)` 라고 쓰면 *"Too many type
parameters"* 이고, **`Fut.Rejected<<(number)>>(e)`** 가 맞습니다(2026-09-26 실측).
여럿이면 `<<(number, string)>>`.

### 그래도 아래 셋이 무엇인지는 알아야 합니다

### 1. 인자 없는 생성자

```lua
local m: HashMap<string, number> = HashMap.New()   -- ❌ HashMap<unknown, unknown>
local m = HashMap.New<<string, number>>()          -- ✅ 이게 낫습니다
local m = HashMap.New() :: HashMap<string, number> -- ✅ 차선(캐스트)
```

**선언 주석은 안 됩니다.** `Arr.Of()`(빈 배열), `HashSet.New()` 도 같습니다.
(`Arr.Sized(5)` 도 여기 있었는데 2026-09-30 에 `fill` 이 필수가 되어 없어졌습니다.)

### 2. 테이블 리터럴을 `{ [K]: V }` 자리에 넘기기

```lua
HashMap.FromTable({ a = 1 })   -- ❌ HashMap<unknown, unknown>
```

`{ a = 1 }` 의 타입은 `{ [string]: number }` 가 **아니라** 이름 붙은 속성을
가진 레코드 `{ a: number }` 입니다. 맞출 `K`/`V` 가 없습니다.

```lua
local m = HashMap.FromTable<<string, number>>({ a = 1 })      -- ✅ 이게 낫습니다
local src: { [string]: number } = { a = 1 }
local m = HashMap.FromTable(src)                              -- ✅ 차선
```

**이게 제일 위험합니다.** 한 번 `unknown` 이 되면 그 뒤로 **무엇을 해도 안
잡힙니다** — 키 타입이 틀려도, 값 타입이 틀려도 조용합니다.
(`spikes/41` 의 "캐비엇" 절에 고정해뒀습니다.)

### 3. 반환 타입으로만 제네릭이 결정되는 함수

```lua
local flat: Arr<number> = nested:Flat()      -- ❌ T 가 unknown
local flat = nested:Flat<<number>>()         -- ✅ 이게 낫습니다
local flat = nested:Flat() :: Arr<number>    -- ✅ 차선(캐스트)
```

### ⚠️ 명시적 타입 인자가 **풀어주지 않는 것** — 콜백 파라미터 주석

이건 별개 문제이고 그대로 남습니다(실측):

```lua
nums:Map<<number>>(function(v)      -- ❌ "Consider placing the following
    return v * 2                    --     annotations on the arguments: v: number"
end)
nums:Map(function(v: number)        -- ✅ 지금은 이렇게 씁니다
    return v * 2
end)
```

원인이 다릅니다 — *"제네릭이 관여하는 함수 호출의 인자로 넘긴 함수 리터럴엔
Luau 가 컨텍스트 타입을 전파하지 않는다"* 는 더 일반적인 한계입니다
(RFC·이슈 없음, quad 이 20개 formulation 으로 재시도했으나 못 뚫음).

### 어떻게 지키는가

컨테이너마다 **실제 `src` 를 쓰는 음성 대조군 스파이크**를 두고
`scripts/check.sh` 가 기대 건수를 대조합니다. 위 셋은 잡히지 않으므로,
스파이크의 "캐비엇" 절에 *일부러 안 잡히는 것*으로 적어둡니다 — 나중에
Luau 가 좋아져 잡히기 시작하면 기대 건수가 올라가 게이트가 알려줍니다.

---

## ⚠️ 콜백 원소 파라미터를 **더 좁게** 적으면 안 잡힌다 (2026-09-30)

구멍을 타입에 드러내기로 한 뒤(`question.md` T) 음성 대조군을 쓰다 나왔습니다.

```lua
local holed = Arr.Sized<<number?>>(3, nil)       -- Arr<number?>
Arr.Map(holed, function(v: number) return v * 2 end)   -- ⚠️ 0건 (잡혀야 함)
holed:Map(function(v: number) return v * 2 end)        -- ✅ 잡힘
Arr.Map<<number?, number>>(holed, function(v: number) …) -- ✅ 잡힘
Arr.Map(holed, function(v: string) … end)              -- ✅ 잡힘 (넓은/다른 쪽)
```

`T?` 만의 문제가 아닙니다 — `Arr<number | string>` 에 `(v: number)` 도 같습니다.
**조건 셋이 겹칠 때** 뚫립니다(실측으로 하나씩 뺐습니다):

1. 제네릭 함수에 **이름으로**(네임스페이스·`local`) 부른다 — 콜론은 잡힘
2. 콜백 타입의 다른 인자가 **`T` 를 품은 테이블**이다 — `Mapper` 의 셋째
   인자 `arr: ArrView<T>`. `{ read [number]: T }` 도 같고, `(T) -> ()` 는 잡힘
3. 람다가 **그 인자를 생략**한다 — 셋 다 적으면 잡힘

평범한 `{ n: number, [number]: T }` 와 두 인자 콜백 `(T, number) -> G` 로
줄이면 잡힙니다. 셋째 인자를 `ArrView<any>` 로 바꾸면 **닫히지만** 대신
주석 없는 람다에 `to` 를 같이 넘기는 자리(`Arr.Of(1, 2):Map(function(v)
return v end, Arr.Of(0))`)에서 *"No valid instantiation"* 이 새로 납니다 —
`ArrView<T>` 가 그 자리에서 `T` 를 붙잡아 주고 있었습니다. 맞바꿈이라
`question.md` V 로 올렸습니다.

`spikes/50` 의 `hole7` 이 이 줄입니다(지금 0건이 기대치 — 막히면 배터리가
알려줍니다).

---

## ⚠️ 원소가 유니온인 컨테이너 — `self` 를 전체형으로 받으면 무너진다 (2026-09-26)

**증상**: `Arr<number?>` 나 `Arr<number | string>` 에서 `:Filter`/`:Map`/
`:Count`/`:Sort`/`:PushBack`/`:Clone` 이 전부 *"No valid instantiation could
be inferred for generic type parameter T"*. 명시적 타입 인자로도 안 풀립니다.
`:Len`/`:Max`/`:Get`/`:Join` 은 멀쩡했습니다.

**가른 결과**(최소 재현):

| 무엇 | 유니온 원소에서 |
|---|---|
| 똑같은 모양의 **자유 함수** (콜백·뷰 인자 포함) | ✅ |
| `self: Data<T> & Ifce` (계약 없음) | ✅ |
| `self: Data<T> & Ifce & Core<T>` (**계약 있음**) | ❌ |
| `self: Data<T>` 로 받고 **반환만** 전체형 | ✅ + 체이닝·NEG 전부 정상 |

**원인**: 전체형에 섞인 계약 조각(`ListCore<T, …>`)의 `Get` 이 `E?` 를
돌려줍니다. `T` 자체가 유니온이면 `self` 에서 `T` 를 역추론할 때 하한과
상한이 모순됩니다. 정상 동작하던 메소드들은 전부 `self: ArrData<T>` 였습니다.

**해법(적용 완료)**: 모든 메소드의 `self` 를 데이터부로 받고, 반환 타입만
전체형으로 둡니다. 자기 자신을 돌려줄 땐 `return self :: any`(런타임엔 같은
테이블). `Arr` 의 44개 메소드를 바꿨고 다른 컨테이너는 원래 이 모양이었습니다.

**고정**: `spikes/46-union-elements.luau` — 컨테이너 전부에 유니온 원소를 넣고
콜백 메소드·3단 체이닝이 사는지, 틀린 것은 잡히는지(NEG 9).

---

## ⚠️ 태그 유니온 — 좁히기 전에 필드를 읽으면 그 스코프에서 좁히기가 죽는다 (2026-09-26)

`Optional` 스파이크에서 발견했습니다(`spikes/45`).

```lua
local o: Opt<number> = …
print(o.value)              -- 합법적인 읽기 (number?)
if o.isPresent then
    local v: number = o.value   -- ❌ 여전히 number? — 좁혀지지 않음
end
```

| 상황 | 좁혀지나 |
|---|---|
| 같은 스코프에서 좁히기 **전에** `o.value` 를 읽음 | ❌ |
| 파라미터로 받아 같은 식으로 | ❌ |
| 읽은 뒤 **새 지역 별칭**(`local p = o`)으로 좁힘 | ✅ |
| 읽기가 **다른 함수 안** | ✅ |
| **태그만** 먼저 읽음 | ✅ |
| 읽기가 `if` **뒤** | ✅ |

진단이 나오긴 합니다(`number?` 를 `number` 에 대입). 다만 원인이 "좁히기가
안 됐다" 로 보이지 않아 헷갈립니다. **`Optional` 은 사용자가 `.value` 를
직접 읽을 일을 줄이도록 `UnwrapOr` 같은 함수를 줍니다.**

같은 스파이크의 다른 발견: **유니온 & 메소드 교집합**(컨테이너들과 같은
모양)은 메소드의 `T` 를 `number | nil` 로 잡아 무너집니다. 그래서 `Optional`
은 메소드 없는 **평범한 태그 테이블 + 네임스페이스 함수**입니다.

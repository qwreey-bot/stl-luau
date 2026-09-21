# 아키텍처 — 확정된 설계

이 문서는 **이미 코드로 확정된** 패턴만 담습니다(변경 검토 중인 건
`.claude/question.md`로). 새 모듈을 짤 때 여기 패턴에서 벗어나려면 먼저
`.claude/question.md`에 올려 사용자와 상의하세요.

## 패키지 매니저와 엔트리포인트

**사용자 결정(2026-08-22)**: pesde 도입, 엔트리포인트는 `src/init.luau`,
저장소는 단일 패키지 유지(tbox 같은 워크스페이스 모노레포 아님).
`pesde.toml`의 `name`은 `qwreey/stl_luau`입니다 — pesde는 패키지 이름에
하이픈을 허용하지 않아(소문자/숫자/`_`만) 저장소 디렉터리명(`stl-luau`)과
다릅니다.

## 런타임: 순수 luau (lune 아님)

**사용자 결정(2026-08-22)**: 이 저장소는 **`luau` CLI 로만** 실행/검증합니다.
lune 은 쓰지 않습니다. 근거(사용자 발언): *"lune 없이 순수 luau 로
테스트해야할것 같아. luau 로 안 하면 타입이 못 따라가서 문제들이 생김.
lune 자체가 반쯤 abandoned 프로젝트라는것도 생각해봐야함. quad 가 그래서
luau 만 사용하거든. 혹은 나중에 lute 로 갈아타는게 답이야."* — 즉
**나중에 갈아탈 대상은 lune 이 아니라 lute** 입니다.

이 결정에서 따라오는 실무 제약(전부 실측):

- **`luau` CLI 에는 `io` 도 `fs` 도 `warn` 도 없습니다.** 있는 것은
  `print`/`os`/`string`/`table`/`math`/`buffer`/`vector`/`utf8`/`bit32`/
  `coroutine`/`debug`/`require` 정도입니다. 파일을 읽어야 하는 기능은
  이 환경에서 원천적으로 불가능합니다.
- **`pesde run` 은 스크립트를 항상 lune 으로 실행**하므로 쓸 수 없습니다.
  `pesde.toml` 의 `[scripts]` 를 비워둔 이유입니다. pesde 는 의존성/배포
  메타데이터 용도로만 남습니다.
- `luau` 는 실패 시 exit 1, 성공 시 exit 0 을 반환하므로 CI 연동에 별도
  래퍼가 필요 없습니다.
- **`const` 지역 선언 문법을 쓰지 마세요.** `luau` CLI 는 파싱하지만
  lune 0.8.9 는 못 읽고, 무엇보다 **quad 가 툴링 문제로 이미 버린
  문법입니다**(사용자 확인, 2026-08-22 — "그거 quad 에서는 툴링때문에
  버린 문법이야 local 씀"). `local` 을 씁니다.

## require 경로 규칙 (luau CLI 기준, 실측)

`init.luau` 는 **자기가 들어있는 디렉터리 그 자체**로 취급됩니다. 그래서
`src/init.luau` 안의 상대 경로는 다른 파일과 기준이 다릅니다:

| 표기 (`src/init.luau` 안에서) | 실제로 가리키는 곳 |
| --- | --- |
| `@self/arr` | `src/arr.luau` — 자기 폴더 **안** |
| `./tests/x` | `<repo>/tests/x.luau` — `src/` 의 **형제** |
| `../tests/x` | `<repo-parent>/tests/x.luau` — 저장소 **바깥**, 거의 항상 버그 |

- **`@self` 는 luau CLI 의 예약 alias 라 `.luaurc` 선언 없이 동작합니다**
  (실측). 반면 `.luaurc` 의 **일반 alias 는 편집기 전용이고 런타임
  require 에서는 동작하지 않습니다** — quad 가 같은 걸 실측해서
  `base/project-setup-plan.md` 에 남겨뒀습니다. 그래서 alias 를 새로
  만들어 require 를 짧게 줄이려 하지 마세요.
- `init.luau` **가 아닌** 파일(`src/arr.luau`, `tests/*.luau` 등)은 평범한
  "파일이 있는 디렉터리 기준" 상대 경로입니다. `tests/arr.luau` 의
  `require("../src/arr")` 는 맞는 코드입니다.
- 저장소 루트에서 `require("./src")` 처럼 폴더를 요구하면 `src/init.luau`
  가 로드됩니다.
- **⚠️ lune 은 이 규칙이 정반대였습니다.** lune 0.8.9 에서는 `@self` 가
  `.luaurc` 없이는 실패했고 `./x` 가 `src/` 기준 평범한 상대 경로로
  동작했습니다. 이 저장소는 2026-08-22 에 lune 을 걷어내면서 luau 기준으로
  통일했으니, **옛 커밋에 남아 있는 `../libs/...` 류 경로를 보고 따라 하지
  마세요.** 나중에 lute 로 옮길 때 이 표를 다시 실측해야 합니다.

## 테스트: assert + print (프레임워크 없음)

**사용자 결정(2026-08-22)**: quad 방식을 따릅니다 — 테스트 프레임워크를
두지 않고 `assert(cond, "메시지")` + `print("PASS")` 로 씁니다.

- 실행: `luau tests/run.luau` (전체) 또는 `luau tests/arr.luau` (개별).
- 실패는 `assert` 가 그 자리에서 traceback 과 함께 터지는 것으로 표현됩니다.
  별도 리포터나 집계 로직이 없습니다.
- 파일 구조: 머리말 `--[[ ]]` 주석 → `=== N. 설명 ===` 로 번호 붙인 절 →
  각 절을 `do ... end` 로 감싸 지역 변수 격리 → 절 끝에 `print("PASS")` →
  파일 끝에 `print("=== ALL PASS (모듈명) ===")`.
- **`assert` 에는 반드시 메시지를 붙이세요.** 기대값과 실제값을 함께 담으면
  실패했을 때 바로 원인을 알 수 있습니다(`tests/arr.luau` 의 `assert_arr`
  헬퍼가 그 예시 — 배열 내용을 `[1,2,3] (n=3)` 형태로 찍습니다).
- **새 테스트 파일은 반드시 값을 하나 `return` 해야 합니다.** `tests/run.luau`
  가 `require` 로 끌어오는데, luau 의 require 는 모듈이 정확히 하나의 값을
  반환할 것을 요구합니다(`module must return a single value`). 그리고
  `tests/run.luau` 의 require 목록에도 추가하세요.
- 테스트 엔트리를 `init.luau` 로 이름 짓지 마세요 — luau 가 `init.luau` 를
  디렉터리 인덱스 모듈로 특별 취급해 require 가 모호해집니다.
- **⭐ 음성 대조군을 쓰세요.** quad 의 실측 교훈: *"진단 0건이 곧 타입이
  풀렸다는 뜻이 아니다."* 테스트가 실제로 실패를 잡는지 일부러 틀린
  기대값을 넣어 확인한 뒤에 지우세요. 2026-08-22 에 이 방식으로
  `arr` 의 버그 5건을 찾았습니다.

## 타입 체크

`luau` CLI 는 **실행만 하고 타입 검사를 하지 않습니다.** 타입 검사는 별도로
돌려야 합니다:

```bash
./scripts/check.sh          # 타입 검사 + 테스트 (권장)
luau-analyze src tests      # 타입 검사 + 린트
```

- **타입 검사기는 `luau-analyze` 입니다**(2026-08-31 전환, quad 방식).
  luau 배포판에 같이 오는 바이너리이고 플래그가 필요 없습니다 — new solver
  가 기본이고, strict 여부는 `.luaurc` 와 각 파일 상단의 `--!strict` 가
  정합니다. 예전에 쓰던
  `luau-lsp analyze --platform=standard --flag:LuauSolverV2=true` 는
  **진단을 일부 빠뜨립니다** — 근거와 실측은 `typing-limits.md` 의
  "체커: luau-analyze" 절.
- **진단은 stdout 이 아니라 stderr 로 나옵니다** — `2>/dev/null` 로 버리면
  "에러 0건" 으로 착각합니다(2026-08-22 에 실제로 이 착시를 겪었습니다).
- **모든 모듈 최상단에 `--!strict` 를 답니다.** `.luaurc` 의 `languageMode`
  하나에만 의존하면 그 한 단어가 바뀌는 순간 타입 검사가 통째로 조용히
  꺼집니다(실측: `nonstrict` 로 바꾸니 301건 → **0건**). 실험용
  `src/tuple.luau`/`src/typeutil.luau` 만 `--!nocheck` 입니다. 0바이트인
  미착수 파일에는 붙이지 않습니다.
- `luau-analyze` 에 `src` 와 `tests` 를 같이 주면 `tests` 가 `require` 로
  `src` 를 끌어와 **같은 파일이 두 경로로 중복 보고됩니다**
  (`src/arr.luau` 와 `./src/arr.luau`). `scripts/check.sh` 가 경로를
  정규화하고 중복을 지웁니다 — 직접 셀 때도 그렇게 하세요.
- 편집기(luau-lsp)는 기본이 구 solver 라 `.vscode/settings.json` 에
  `enableNewSolver` 를 켜뒀습니다. **편집기와 CLI 는 이제 다른 엔진입니다**
  — 숫자가 어긋나면 CLI(`luau-analyze`) 가 기준입니다.
- **린트도 `luau-analyze` 가 합니다**(`.luaurc` 의 `lint: *`). selene 은
  2026-09-21 폐기 — `const` 를 파싱하지 못하고 0.31.0 이 최신이라 올릴 곳이
  없었습니다. 잃은 것은 `empty_if`/`empty_loop` 과 미사용 변수 탐지 정밀도.

## 컨테이너 표현 — 종류마다 다릅니다

**[2026-09-22 전면 재작성 후 확정]**

| 컨테이너 | 표현 | 왜 |
|---|---|---|
| `Arr` | `{ n: number, [number]: T }` + `__arr__` 태그 | 연속 정수 인덱스. `#` 는 희소 배열에서 정의되지 않으므로 `n` 을 신뢰 |
| `HashMap` | `{ data: { [K]: V }, size: number }` | 키를 `self` 에 바로 넣으면 `Set("size", v)` 가 길이 필드를 덮어씀 |
| `HashSet` | `{ map: HashMap<T, true> }` | 맵 위에 단방향 |
| `TreeMap` | `{ records: { Record }, size, compare, probe }` | 정렬 레코드 배열 + 이분 탐색 |
| `TreeSet` | `{ map: TreeMap<T, true> }` | 맵 위에 단방향 |
| `Heap` | `{ items: { T }, size, less }` | 배열에 담은 완전이진트리 |

공통 규칙 셋:

- **길이는 명시 필드가 진실입니다.** `#` 를 믿지 않습니다.
- **해시/트리 계열은 래퍼**입니다. 사용자 키가 내부 필드를 덮어쓸 수 없게.
- **`data`/`records`/`items` 를 밖에서 건드리면 크기가 틀어집니다.** 읽기만
  하세요. 안쪽을 직접 다뤄야 하는 구현(예: `HashSet` 이 자기 `HashMap` 을)은
  같은 저장소 안이라 괜찮지만, 그게 아니면 공개 메소드를 쓰세요.

런타임 판별은 컨테이너마다 다릅니다 — `Arr` 만 태그 필드(`__arr__`)를 쓰고
(중첩 배열을 평탄화할 때 원소가 배열인지 봐야 하므로), 나머지는 메타테이블
동일성(`getmetatable(v) == Ifce`)으로 봅니다.

## 모듈 패턴

**[2026-09-22 확정]** 각 컨테이너 모듈은 다음 형태입니다. `src/Arr.luau` 가
정석이고 `src/HashMap.luau` 가 가장 작은 예입니다.

```lua
local Types = require("./Types")

export type XxxData<T> = { … }          -- 데이터부
local Ifce: XxxIfce & Types.SomeCore<…> -- 런타임 메소드 테이블 (전방 선언)

const function Foo<T>(self: Xxx<T>, …) … end   -- 이름 붙은 top-level 함수들

type XxxIfce = { Foo: typeof(Foo), … }  -- typeof 로 나열
export type Xxx<T> = XxxData<T> & XxxIfce & Types.SomeCore<…>  -- 교집합

Ifce = { Foo = Foo, … } :: any
;(Ifce :: any).__index = Ifce

return { New = New, … }                 -- 순수 테이블 네임스페이스
```

네 가지가 전부 실측으로 강제된 것입니다:

- **교집합(`&`)** — `setmetatable<>` 은 메소드 30개에서 무너집니다.
- **이름 붙은 함수 + `typeof`** — 인라인 제네릭은 반환이 `Unifiable<Error>`
  로 샙니다.
- **순수 테이블 네임스페이스** — `__call` 로 만들면 제네릭 생성자가 타입
  인자를 잃고 모듈 오타도 못 잡습니다.
- **계약이 주는 멤버는 `XxxIfce` 에 다시 쓰지 않음** — self 타입이 달라
  교집합이 충돌하고 메소드 타입이 통째로 죽습니다(진단 0건으로).

자세한 근거는 `.claude/base/typing-limits.md` 와
`.claude/audit/arr-type-redesign/REPORT.md`.

## 비교 — 통화가 둘입니다

**[2026-09-22 확정, 실측 근거 있음]**

| 타입 | 모양 | 어디에 |
|---|---|---|
| `Types.LessThan<T>` | `(a, b) -> boolean` | **정렬·최대·최소·힙** |
| `Types.Comparator<T>` | `(a, b) -> number` (3방향) | **정렬된 구조에서의 탐색** (`BSearch`, `TreeMap`, `TreeSet`) |

`table.sort` 가 불리언을 받으므로 3방향을 쓰면 비교마다 래퍼 클로저가 붙어
**1.82배** 느려집니다. 반대로 탐색은 "작다/같다/크다" 를 한 번에 알아야
하는데 불리언이면 두 번 물어야 합니다. 그래서 갈랐습니다.

둘 사이는 `Common.lessFrom` / `Common.compareFrom` 으로 건넙니다.
**자동 변환은 일부러 넣지 않았습니다** — 비용이 눈에 보여야 합니다.

옛 `common.luau` 의 "불리언과 숫자를 둘 다 받는 유니언 + `compareTo` 어댑터"
는 폐기했습니다. 비교마다 반환 타입을 분기해야 했습니다.

## 구간 정규화

`src/Arr.luau` 안의 비공개 헬퍼 **둘**입니다. 새 구간 함수를 만들 때 직접
정규화하지 말고 이걸 쓰세요.

| 헬퍼 | 유효 범위 | 쓰는 곳 |
|---|---|---|
| `resolveRange(len, start?, last?)` | `1 .. len` | 조회·삭제 (`Slice`, `Erase`, `Fill`, `Some`, `Every`, `Flat`, 순서 연산) |
| `resolveInsertPos(len, at)` | **`1 .. len + 1`** | 삽입 (`Insert`, `InsertMany`, `InsertArray`) |

⚠️ **둘을 나눈 것이 핵심입니다.** 삽입 위치는 원소 위치보다 범위가 하나
넓습니다(`len + 1` 이 "맨 뒤에 붙이기"). 같은 함수로 처리하면 **맨 뒤 삽입이
원리적으로 불가능해집니다** — 같은 저자의 예전 구현이 실제로 그 버그를
냈습니다(`.claude/base/container-design-notes.md` 6절).

규약은 Lua 관례를 따릅니다: 닫힌 구간 `[start, last]`, 음수 인덱스는 끝에서
부터, 범위를 넘으면 clamp, 뒤집히면 조용히 빈 결과 — `string.sub` 와 같습니다.

`TreeMap`/`TreeSet` 의 키 구간(`RangeRecords`/`RangeItems`)은 인덱스가 아니라
**키**로 자르므로 이 헬퍼가 아니라 `BSearch.LowerBound`/`UpperBound` 를 씁니다.

[테스트 방식은 위 "테스트: assert + print" 절이 소스입니다.]


## 파일이 커지면 어떻게 쪼개는가 (실측해둠)

지금은 안 쪼갭니다 — `Arr.luau` 가 1200줄 안팎인데, 비교 대상 표준
라이브러리들의 같은 파일이 1800~4000줄입니다.

쪼개야 할 때를 위해 **미리 재뒀습니다**:

⚠️ **컨테이너 타입을 반환하는 메소드는 그 타입이 선언된 곳과 같은 모듈에서
보여야 합니다.** 순진하게 쪼개면 체이닝이 **타입과 런타임 양쪽에서** 깨집니다
(`Key 'Map' not found`, `attempt to call missing method`).

쪼갠다면 **quad 방식**입니다: `Types` 에 시그니처만 있는 스텁 함수를 두고
`typeof` 로 인터페이스를 만들면, 구현 파일이 컨테이너 타입을 반환할 수
있습니다. 실측으로 체이닝·런타임 모두 정상이었습니다.
**비용은 시그니처 중복**입니다.

실측 전량: `.claude/audit/container-contracts/module-split/`.

## Luau 메타메소드 — 이 저장소가 쓰는 것

루트 `notes` 파일에 있던 전체 표를 대체합니다(그 파일은 2026-09-21 삭제).
전체 목록은 Luau 공식 문서에 있으므로 여기엔 **우리가 실제로 쓰거나 쓸지
판단해야 하는 것만** 둡니다.

| 메타메소드 | 우리 쓰임 |
|---|---|
| `__index` | 컨테이너 메소드 배선. 모든 컨테이너가 씁니다 |
| `__eq` | **쓰지 않습니다.** 양쪽 메타테이블이 같아야만 불리는 제약이 있어, 비교는 명시적인 `:Equal(other)` 메소드로 둡니다 |
| `__len` | `#` — **쓰지 않습니다.** 이 저장소는 `self.n` 을 신뢰합니다(희소 배열) |
| `__iter` | **쓰지 않습니다.** 교집합 타입에서 루프 변수의 타입이 죽습니다. 대신 각 컨테이너가 `Iter()` 메소드로 이터레이터 삼중항을 돌려줍니다 — for-in 이 인덱서가 아니라 함수의 반환 타입을 보므로 타입이 삽니다(`spikes/37`) |
| `__call` | **쓰지 않습니다.** 제네릭 생성자에서 타입 인자를 잃습니다(실측) |
| `__lt`, `__le` | 정렬 가능한 컨테이너에서 검토 대상 |
| `__tostring` | 디버깅 편의. 미착수 |
| `__mode` | 약한 참조 테이블. 현재 계획 없음 |
| `__gc` | **Roblox 에서 비활성화**라 쓸 수 없습니다 |


## require 경로 규칙 — 직관과 다르고, **정적 검사가 못 잡는다**

quad 가 먼저 겪고 기록한 것(`pre-implementation-qa-round5.md` PS-8/9/10,
`archive/surveys/2026-09-07-source-layout-plan.md`)이고, 2026-09-21 에
이 저장소에서도 동일하게 실측했습니다.

### 규칙

| 어디서 | 폴더 **안** 형제 | 폴더 **밖** 형제 |
|---|---|---|
| `Foo/init.luau` | **`@self/Bar`** | **`./Types`** (`../Types` ❌) |
| `Foo/Bar.luau` | `./Baz` | **`../Types`** (`./Types` ❌) |

`init.luau` 는 **그 폴더 자신**이라 거기서만 `./` 가 부모를 가리킵니다.
같은 폴더 안에서도 파일에 따라 경로가 다릅니다.

### ⭐ 이 실수는 조용히 지나갑니다

**`@self` 대신 `./` 를 쓰면 런타임에서 크래시하지만 `luau-analyze` 는 진단
0건으로 통과합니다**(타입이 `Unifiable<Error>` 로 샘). 정적 검사만 돌리는
작업은 이 실수를 **절대** 못 잡습니다.

→ **`init.luau` 를 새로 추가하거나 require 를 고친 커밋은 반드시 런타임으로
한 번 `require` 해봐야 합니다.** `scripts/check.sh` 가 이걸 게이트로 겁니다.

### 폴더로 접는 것은 공짜

`X.luau` → `X/init.luau` 로 바꿔도 안팎의 기존 `./` 경로가 그대로 유효합니다.
새로 생긴 형제 파일만 `@self/` 로 부르면 됩니다.
**단 `X.luau` 와 `X/` 를 동시에 두지 마세요**(해석 우선순위 미검증).

### symlink 함정

`pesde install` 은 워크스페이스 의존성을 symlink 로 거는데, Luau CLI 의
require-by-string 은 **보안상 의도적으로 symlink 를 따라가지 않습니다.**
`luau`/`luau-analyze` CLI 만의 문제이고 Rojo 경로는 투명하게 통과합니다.

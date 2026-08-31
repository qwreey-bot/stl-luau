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
luau-analyze src tests      # 타입 검사만
selene src tests            # 린트
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
- selene 은 설정 파일을 **CWD 기준 `./selene.toml`** 로만 찾습니다(상위
  디렉터리를 거슬러 올라가지 않음). 항상 저장소 루트에서 실행하세요.
- `type function` 블록 앞에는 `-- selene: allow(undefined_variable)` 를
  붙입니다(`types` 는 그 안에서만 주입되는 특수 전역이라 오탐).
  **파일 최상단에 한 번 붙이는 방식은 안 먹습니다 — 각 선언 바로 앞에
  붙여야 합니다**(실측).

## 컨테이너 표현: length-tagged table

`arr` 컨테이너는 Lua 배열을 `{ n: number, [number]: T }`로 감쌉니다
(`src/arr.luau:727-730`의 `Arr<T>` 타입 정의). 기본 `#` 연산자는 쓰지 않고
항상 `self.n`을 신뢰합니다. 추가로 `rawget(value, "__arr__")`로 런타입
판별이 가능하도록 태그 필드를 심습니다(`arr_ifce.is_arr`, `src/arr.luau:163`).
이유로 추정되는 것: Lua의 `#`는 희소 배열(trailing `nil`)에서 정의되지
않은 동작을 하므로, 명시적 길이 필드로 이를 피합니다.

새 컨테이너(`hashmap`/`hashset`/`treemap`/`treeset` 등)도 이 규약(길이
필드 + 태그 필드 + `is_*` 판별 함수)을 따를지, 아니면 컨테이너 종류별로
다른 표현이 필요한지는 아직 결정되지 않았습니다 — hash/tree 기반 구조는
연속 정수 인덱스가 아니므로 `n` 필드가 그대로 적용되지 않을 수 있습니다.
`.claude/question.md` 참고.

## 모듈 팩토리 패턴

각 컨테이너 모듈은 다음 형태를 따릅니다(`src/arr.luau:1-16` 참고):

```lua
local X_ifce = {}
local X_constructor = {}
X_ifce.__index = X_ifce

function X_constructor.__call<T>(_, ...): X<T>
    local result = ...
    setmetatable(result, X_ifce)
    return result
end
setmetatable(X_ifce, X_constructor)
```

즉 모듈 자체(`X_ifce`)가 인스턴스의 메타테이블이면서, 동시에 `X_constructor`를
메타테이블로 얹어 **모듈을 직접 호출하면 생성자로 동작**합니다(`arr(1,2,3)`
처럼). `src/tuple.luau`도 같은 패턴을 따르되 아직 완성되지 않았습니다.

## Comparator

`src/common.luau`의 `Comparator<T> = (a,b)->boolean & (a,b)->number` 유니온과
`compareTo` 어댑터가 정렬/비교 관련 함수의 공통 인터페이스입니다. `arr.max`/
`arr.min`은 시그니처에 `comp`를 받지만 **아직 실제로 쓰지 않습니다**
(`src/arr.luau:544,555`, `--FIXME: comp 를 사용하도록 재작성` 주석 있음).

## range 정규화

`arr_ifce.range(arr_len, start, last)`가 음수 인덱스(끝에서부터)를 양수로
정규화하는 공통 헬퍼입니다(`src/arr.luau:157-160`). `slice`, `erase_inplace`,
`some`, `every`, `rangeflat` 등이 이걸 공유합니다. 새 range 기반 함수는
직접 정규화 로직을 짜지 말고 이 헬퍼를 재사용하세요.

[테스트 방식은 위 "테스트: assert + print" 절이 소스입니다. 예전에 여기
있던 `libs/test-luau` 프레임워크 계약 서술은 2026-08-22 lune 제거와 함께
폐기됐고, 서브모듈도 같은 날 제거했습니다.]

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

**`init.luau`의 require 경로 규칙은 tbox `CLAUDE.md`가 서술한 것과 이
저장소의 `lune 0.8.9`에서 다르게 동작함을 실측으로 확인했습니다**:

- tbox 문서 주장: `init.luau` 안에서 `./x`는 **자기가 든 폴더(`src/`)의
  형제**를 가리키고, 같은 폴더 안 형제 파일(`src/` 안 다른 모듈)은
  `@self/x`로만 접근 가능(별도 설정 없이 동작하는 내장 alias인 것처럼 서술).
- 이 저장소에서 실제로 확인된 동작: `@self`는 **`.luaurc`에 alias로
  선언하지 않으면 `failed to find alias 'self' (no .luaurc)` 에러**로
  실패합니다. 그래서 `src/.luaurc`에 `{"aliases": {"self": "./"}}`를 직접
  선언해뒀습니다(`src/init.luau`가 `@self/arr`로 형제 모듈에 접근). 그리고
  `./x`는 **평범한 파일과 똑같이 `src/`에 대한 상대 경로**로 동작했습니다
  (`./libs/...`를 시도하면 `src/libs/...`를 찾으려 함) — tbox가 말하는
  "형제 폴더로 튀는" 동작이 재현되지 않았습니다. 그래서 `src/init.luau`가
  저장소 루트의 `libs/`, `tests/`를 가리킬 땐 `../libs/...`, `../tests/...`처럼
  **일반 파일과 동일한 상대 경로**를 씁니다.
- 이 차이의 원인은 확인하지 않았습니다(lune/luau 버전 차이일 가능성이
  높음). **tbox 저장소로 작업을 옮기거나 lune 버전을 올릴 땐 이 가정을
  다시 실측하세요** — `luau`/`lune` 버전에 따라 `init.luau`의 require
  해석이 달라질 수 있습니다.
- `run_test.luau`(저장소 루트)에서 `require("./src")`로 폴더를 요구하면
  자동으로 `src/init.luau`가 로드됩니다(표준 Luau require-by-string
  동작, 특이사항 없음).

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

## 테스트 프레임워크 계약

`libs/test-luau`가 제공하는 `test` 함수는 다음과 같이 체이닝됩니다:

```lua
test("suite-name")(
    test("nested-name")
        "case description":assume_equal(actual, expected)
        "case description 2":assume(boolean_expr)
)
```

`test(...)`는 이름을 받으면 새 테스트 그룹을, 여러 `test` 결과를 받으면
병합을 수행합니다(`test.__call`, `libs/test-luau/lib.luau:63-71`). 최종
결과에 `:solve()`를 호출해야 실제로 출력됩니다(`run_test.luau` 참고) —
`solve()`를 빼먹으면 아무 것도 출력되지 않고 조용히 끝납니다.

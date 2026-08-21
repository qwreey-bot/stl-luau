# 아키텍처 — 확정된 설계

이 문서는 **이미 코드로 확정된** 패턴만 담습니다(변경 검토 중인 건
`.claude/question.md`로). 새 모듈을 짤 때 여기 패턴에서 벗어나려면 먼저
`.claude/question.md`에 올려 사용자와 상의하세요.

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

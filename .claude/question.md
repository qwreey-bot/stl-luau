# 열린 질문 (우선순위순)

사용자가 답해야 하는 것만. 답이 나오면 `.claude/base/`에 확정 사실로
반영하고 이 파일에서 지우세요.

## [해소됨, 2026-08-22] 패키지 매니저 / 엔트리포인트 / 저장소 구조 / 런타임 / 테스트 방식

**사용자 결정(2026-08-22)**, 전부 `.claude/base/architecture.md` 에 반영됨:

- pesde 도입, 엔트리포인트 `src/init.luau`, 단일 패키지 유지.
- **런타임은 순수 luau — lune 제거.** 나중에 갈아탈 대상은 lute.
- **테스트는 quad 식 `assert` + `print`, 프레임워크 없음.**
- 타입 체크/린트 툴체인(luau-lsp + selene)을 `mise.toml` 로 도입.
- `const` 문법은 쓰지 않음(quad 가 툴링 문제로 이미 버린 문법).

require 경로 규칙은 lune 시절과 **정반대**로 바뀌었으니
`base/architecture.md` 의 "require 경로 규칙" 절 표를 보세요.

## 1. `tuple.luau`/`typeutil.luau`의 type function 실험을 계속 밀 것인가?

Luau의 `type function`은 upstream에서도 실험적 기능입니다. 지금 두 파일은
`return {}` placeholder이고 타입 레벨 튜플 확장(`TuplePush` 등)은 주석
처리된 채로 막혀 있습니다(`src/tuple.luau:55-90`). 이 방향을 계속
탐색할지, 아니면 (a) 런타임 전용으로 단순화하거나 (b) `tbox`의
`packages/tbox/src/types.luau`가 이미 비슷한 type function 유틸을
갖고 있으니 거기서 재사용/참고할 부분이 있는지 먼저 살펴볼지 판단이
필요합니다.

## [해소됨, 2026-08-22] hash/tree 컨테이너 표현

**사용자 결정**: 크기는 **래퍼 구조로 분리**(`{ data = {...}, size = n }`).
인스턴스에 `n` 을 직접 두면 `hashset<string>` 에서 `add(s, "n")` 이 길이
필드를 덮어쓰기 때문. 그리고 지금 `treeset.luau` 내용은 사실 해시셋이므로
`hashset.luau` 로 옮기고, `treeset` 은 정렬 구조로 새로 작성합니다.
실제 작업은 `.claude/todos.md` 2번 항목.

## [해소됨, 2026-08-22] tbox 코드 스타일(`const`) 이식 여부

**이식하지 않습니다.** `local` 을 씁니다. 사용자 확인: *"그거 quad 에서는
툴링때문에 버린 문법이야 local 씀"* — quad 가 이미 툴링 문제로 폐기한
문법이고, 실측으로도 lune 0.8.9 가 파싱하지 못했습니다.

## 2. `arr(1, 2, 3)` 호출 형태를 지킬까, 타입 안전성을 택할까?

**[2026-08-31 실측, `.claude/audit/arr-type-redesign/REPORT.md` 4번 절]**

`arr` 모듈 값을 `(<T>(...T) -> Arr<T>) & ArrStatic` 로 내보내야 `arr(1, 2, 3)`
이 됩니다. 그런데 **함수 타입과 테이블 타입의 교집합에서는 없는 속성 접근이
검사되지 않아** `arr.오타` 가 조용히 통과합니다.

| | `arr(1, 2, 3)` 유지 (**현재**) | 순수 테이블 (`arr.pack(1, 2, 3)`) |
|---|---|---|
| 생성자 호출 `arr(...)` | ✅ | ❌ |
| 인스턴스 메소드 검사 | ✅ | ✅ |
| `arr.오타` 검출 | ❌ | ✅ |

`arr.pack(...)` 이 이미 `arr(...)` 과 같은 일을 합니다. 다만 `tests/arr.luau`
만 해도 호출부가 200군데 가까이 되고 공개 API 모양이 바뀝니다. 지금은
**`arr(1, 2, 3)` 을 유지한 상태**입니다.

## 3. 라이선스와 README 를 어떻게 할까?

`tbox`/`quad` 둘 다 MIT + README 를 갖췄지만 stl-luau 엔 둘 다 없습니다.
공개 배포(pesde publish)를 염두에 둔다면 필요합니다 — 라이선스를 MIT 로
할지, 저작자 표기를 어떻게 할지 확인이 필요합니다.

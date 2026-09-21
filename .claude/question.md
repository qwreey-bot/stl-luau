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

## [해소됨, 2026-09-21] `arr(1, 2, 3)` 호출 형태

**사용자 결정**: 순수 네임스페이스(`Arr.Of(1, 2, 3)`)로 갑니다 — *"java 에서
List.of() 형태로 이미 외부에 선례 사례가 존재함"*. 이걸로 모듈 오타 검출까지
같이 얻습니다. 근거와 실측은 `.claude/base/rewrite-plan.md` 1-4 절.

## [해소됨, 2026-09-21] const / selene

**사용자 결정**: `const` 를 채택하고 **selene 을 폐기**합니다. selene 0.31.0
(최신)이 `const` 를 파싱하지 못하고 갈아탈 상위 버전이 없습니다. `pesde` 는
0.7.4 로 올려야 합니다. 예전 기록("quad 가 툴링때문에 버린 문법")은 낡았습니다
— quad 는 2026-09-10 에 `const` 를 채택했습니다.

## 3. 라이선스와 README 를 어떻게 할까?

`tbox`/`quad` 둘 다 MIT + README 를 갖췄지만 stl-luau 엔 둘 다 없습니다.
공개 배포(pesde publish)를 염두에 둔다면 필요합니다 — 라이선스를 MIT 로
할지, 저작자 표기를 어떻게 할지 확인이 필요합니다.

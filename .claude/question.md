# 열린 질문 (우선순위순)

사용자가 답해야 하는 것만. 답이 나오면 `.claude/base/`에 확정 사실로
반영하고 이 파일에서 지우세요.

## [해소됨, 2026-08-22] 패키지 매니저 / 엔트리포인트 / 저장소 구조

**사용자 결정(2026-08-22)**: pesde 도입, 엔트리포인트는 `src/init.luau`로
이동(tbox/quad 관례), 저장소는 단일 패키지 유지(모노레포 아님). 확정된
내용과 실제 동작 확인 결과는 `.claude/base/architecture.md`의
"패키지 매니저와 엔트리포인트" 절 참고 — **tbox `CLAUDE.md`가 서술하는
`init.luau`의 require 경로 규칙은 이 저장소의 lune 0.8.9에서 그대로
재현되지 않았습니다** (실측: `./x`는 `src/`에 대한 평범한 상대 경로였고,
`@self`는 `.luaurc` alias 선언 없이는 동작하지 않았음). 그 차이를
`base/architecture.md`에 실측 그대로 남겨뒀으니, 다른 Luau/Lune 버전으로
옮길 때 이 가정이 유효한지 다시 확인하세요.

## 1. `tuple.luau`/`typeutil.luau`의 type function 실험을 계속 밀 것인가?

Luau의 `type function`은 upstream에서도 실험적 기능입니다. 지금 두 파일은
`return {}` placeholder이고 타입 레벨 튜플 확장(`TuplePush` 등)은 주석
처리된 채로 막혀 있습니다(`src/tuple.luau:55-90`). 이 방향을 계속
탐색할지, 아니면 (a) 런타임 전용으로 단순화하거나 (b) `tbox`의
`packages/tbox/src/types.luau`가 이미 비슷한 type function 유틸을
갖고 있으니 거기서 재사용/참고할 부분이 있는지 먼저 살펴볼지 판단이
필요합니다.

## 2. 컨테이너 표현 규약을 hash/tree 구조에도 그대로 적용할까?

`.claude/base/architecture.md`의 "컨테이너 표현" 절 참고 — `arr`의
길이 필드(`n`) + 태그 필드(`__arr__`) 규약이 정수 인덱스가 없는
`hashmap`/`hashset`/`treemap`/`treeset`에도 그대로 적용 가능한 개념인지,
아니면 컨테이너별로 다른 표현(예: 크기 캐시 필드만 공유)이 필요한지
설계가 필요합니다. `hashmap`/`hashset`/`treemap`이 전부 빈 파일이라
지금이 이 결정을 내리기 좋은 시점입니다.

## 3. `../tbox/`(`/code/Projects/tbox`)의 코드 스타일(`const` 지역 선언,
`f<<T>>` 명시적 타입 인자)을 stl-luau에도 들여올 것인가?

tbox의 `.claude/conventions.md`는 이 스타일을 표준으로 못 박아뒀지만
(재할당 없으면 `const`, 명시적 타입 인자 호출), stl-luau 기존 코드는
전부 `local`만 쓰고 명시적 타입 인자 호출도 없습니다. 스타일을 맞출지
독자적으로 갈지 결정 필요 — 맞춘다면 tbox의 "stylua가 `f<<T>>`를 시프트
연산자로 오인식해 조용히 코드를 깨뜨리는" 알려진 위험(tbox `CLAUDE.md`
참고)도 같이 감안해야 합니다.

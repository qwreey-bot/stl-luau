# 열린 질문 (우선순위순)

사용자가 답해야 하는 것만. 답이 나오면 `.claude/base/`에 확정 사실로
반영하고 이 파일에서 지우세요.

## 1. 패키지 매니저를 도입할지 — pesde? 아니면 계속 미도입?

`qwreey/tbox`, `qwreey/quad` 둘 다 pesde(`scope = "qwreey"`)를 씁니다.
stl-luau는 아직 `pesde.toml`/`wally.toml`이 전혀 없어서, 다른 프로젝트가
이 라이브러리를 의존성으로 못 가져갑니다(수동 서브모듈/파일 복사만 가능).

- 도입한다면 `[target] lib = "?"` 경로를 뭘로 할지도 같이 정해야 합니다 —
  tbox/quad 둘 다 `src/init.luau`를 엔트리포인트로 삼는데, stl-luau는
  이번 세션에 루트 `lib.luau`로 리네임했습니다(구 `init.luau`). pesde
  관례를 따라 `src/init.luau`로 다시 옮길지, `lib = "lib.luau"`로
  현재 구조를 유지할지 결정 필요.
- `qwreey` scope로 publish할지, private 워크스페이스로만 쓸지도 확인 필요.

## 2. 저장소 구조 — 단일 패키지 유지 vs pesde 워크스페이스(모노레포)?

`tbox`는 `packages/tbox`, `packages/tbox_squish` 등 여러 작은 패키지로
쪼갠 모노레포입니다(패키지 간 런타임 의존성이 분리되기 때문). stl-luau의
현재 모듈(`arr`/`hashmap`/`treeset`/`tuple`/...)은 전부 순수 컨테이너로
서로 강하게 얽혀 있고 외부 의존성 차이도 없어 보여서, 지금 판단으로는
**단일 패키지가 더 맞아 보입니다** — 하지만 이건 제 추정이라 확인이
필요합니다. 이후 예를 들어 "mlua 바인딩"(`todo` 파일의 "rust mlua gate"
항목)처럼 런타임 요구사항이 다른 하위 기능이 생기면 그때 tbox처럼
쪼개는 게 나을 수도 있습니다.

## 3. `tuple.luau`/`typeutil.luau`의 type function 실험을 계속 밀 것인가?

Luau의 `type function`은 upstream에서도 실험적 기능입니다. 지금 두 파일은
`return {}` placeholder이고 타입 레벨 튜플 확장(`TuplePush` 등)은 주석
처리된 채로 막혀 있습니다(`src/tuple.luau:55-90`). 이 방향을 계속
탐색할지, 아니면 (a) 런타임 전용으로 단순화하거나 (b) `tbox`의
`packages/tbox/src/types.luau`가 이미 비슷한 type function 유틸을
갖고 있으니 거기서 재사용/참고할 부분이 있는지 먼저 살펴볼지 판단이
필요합니다.

## 4. 컨테이너 표현 규약을 hash/tree 구조에도 그대로 적용할까?

`.claude/base/architecture.md`의 "컨테이너 표현" 절 참고 — `arr`의
길이 필드(`n`) + 태그 필드(`__arr__`) 규약이 정수 인덱스가 없는
`hashmap`/`hashset`/`treemap`/`treeset`에도 그대로 적용 가능한 개념인지,
아니면 컨테이너별로 다른 표현(예: 크기 캐시 필드만 공유)이 필요한지
설계가 필요합니다. `hashmap`/`hashset`/`treemap`이 전부 빈 파일이라
지금이 이 결정을 내리기 좋은 시점입니다.

## 5. `../tbox/`(`/code/Projects/tbox`)의 코드 스타일(`const` 지역 선언,
`f<<T>>` 명시적 타입 인자)을 stl-luau에도 들여올 것인가?

tbox의 `.claude/conventions.md`는 이 스타일을 표준으로 못 박아뒀지만
(재할당 없으면 `const`, 명시적 타입 인자 호출), stl-luau 기존 코드는
전부 `local`만 쓰고 명시적 타입 인자 호출도 없습니다. 스타일을 맞출지
독자적으로 갈지 결정 필요 — 맞춘다면 tbox의 "stylua가 `f<<T>>`를 시프트
연산자로 오인식해 조용히 코드를 깨뜨리는" 알려진 위험(tbox `CLAUDE.md`
참고)도 같이 감안해야 합니다.

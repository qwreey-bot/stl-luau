# CLAUDE.md

**stl-luau**: Roblox 엔진 언어 **Luau** 용 표준 라이브러리 스타일 유틸리티 모음
(배열/셋/맵/튜플 등 컨테이너, range 계열 알고리즘). 지금은 초기 단계이고 대부분의
모듈이 스캐폴딩 상태입니다 — 자세한 현황은 아래 import된 문서를 보세요.

**이 파일에 내용을 직접 쌓지 말 것** — 짧은 진입점으로 유지합니다. 새 내용은
아래 import된 파일 중 맞는 곳에 넣으세요.

이 구조는 `qwreey/quad`, `qwreey/tbox` 저장소의 `.claude/` 관례를 참고했습니다
(짧은 진입점 + `@import` + `base/`는 확정된 결정만). 다만 stl-luau는 아직
1인 초기 프로젝트라 두 레포에 있는 `doc-check.py`, session 아카이브,
agent-memory 같은 무거운 장치는 아직 없습니다 — 필요해지면 그때 추가합니다.

## 항상 로드되는 컨텍스트

관례와 작업 방식 @.claude/conventions.md

프로젝트 컨텍스트와 모듈 구조 @.claude/project-context.md

지금 할 일 @.claude/todos.md

## 온디맨드 자료

| 무엇이 궁금할 때 | 어디를 볼 것 |
|---|---|
| 확정된 설계/현재 아키텍처 (런타임, require 규칙, 테스트 방식) | `.claude/base/architecture.md` |
| **타입이 안 잡힐 때 / 새 컨테이너 타입을 어떻게 선언할지 / 왜 체커가 `luau-analyze` 인지** | `.claude/base/typing-limits.md` |
| `Arr<T>` 재설계 실측 전량(음성 대조군, 변형별 비교) | `.claude/audit/arr-type-redesign/REPORT.md` |
| 사용자가 답해야 할 열린 질문 | `.claude/question.md` |
| **전면 재작성 계획(확정된 설계·개명표·순서)** | `.claude/base/rewrite-plan.md` |
| 다른 언어 표준 라이브러리에서 얻은 설계 교훈 | `.claude/base/container-design-notes.md` |
| **성능 실측 전량 (메타테이블 세금, `table.move`, 순회, 비교자)** | `.claude/base/perf-measurements.md` |
| 문서화 계획과 백로그 (quad `docs/` 구조를 따름) | `.claude/base/docs-plan.md` |
| **아직 안 정한 것의 설계 페이퍼** (`Fut` / `Optional` / `Tuple` / **빠진 표면 04**) | `.claude/papers/` |

**참고 자료** (전부 `.gitignore` 의 `*-ignoreme*` 로 무시됨 — 거기서 얻은 건
원문을 옮기지 않고 **자기설명적으로 다시 써서** `.claude/` 에 남깁니다):

| 어디 | 무엇 |
|---|---|
| `refs-ignoreme/openjdk` | OpenJDK `java.util` — List/Map/Set/Iterator 계열 |
| `refs-ignoreme/rust` | Rust `alloc` — Vec/VecDeque/BTree/BinaryHeap/LinkedList |
| `refs-ignoreme/ms-stl` | MSVC 표준 라이브러리 헤더 |
| `old-homeworks-ignoreme` | 예전 학교 과제 — ADT 구현, visitor, Node/Tree |
| `refs-ignoreme/qwreey-js` | 사용자의 TS 유틸 모음 — `ts-util/src/result.ts` 의 `Result` 가 `Optional` 설계 참고 |

**quad** 는 `/code/Projects/quad` (무시 대상 아님, 별도 저장소). Luau 타입 한계
연구가 방대합니다 — `.claude/base/typing-limits.md` 와 `.claude/audit/`.
**읽기 전용으로만 보세요** — 다른 세션이 활발히 수정 중입니다.
참고 Luau 저장소들(fusion/vide/charm/tbox/rbvm)은 `/code/Projects/quad-scratch/refs/`
에 있습니다(예전에 문서가 가리키던 `initreq` 경로는 없어졌습니다).

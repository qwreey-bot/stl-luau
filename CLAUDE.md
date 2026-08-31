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
| **타입이 안 잡힐 때 / `Arr<T>` 가 왜 301건씩 에러를 내는지 / 왜 체커가 `luau-analyze` 인지** | `.claude/base/typing-limits.md` |
| 사용자가 답해야 할 열린 질문 | `.claude/question.md` |
| 예전 방식 스크래치 노트(Luau 메타메소드 참고, 초기 API 아이디어) | 루트 `notes`, `todo` |

**참고 저장소**: quad 는 `/code/Projects/quad` 에 클론돼 있습니다(Luau 타입
한계 연구가 방대함 — `.claude/base/typing-limits.md` 와 `.claude/audit/`).
**tbox 는 이 환경에 클론돼 있지 않습니다** — 문서에 나오는 tbox 이야기는
과거 세션의 기록이고, 지금 열어볼 수는 없습니다. (경로 정정 2026-08-31:
예전에 적혀 있던 `/code/Projects/stl-luau-refs/quad` 와 `/code/Projects/tbox`
는 둘 다 존재하지 않습니다.)

# 문서화 계획과 백로그

**[2026-09-22 사용자 결정]** *"문서를 만들 땐 quad 에 docs 폴더 구조를
그대로 따라도 좋음. 폴리싱 된 starlight와 동기화 구조 그대로 택해도 돼.
이건 기록해두고, 문서화에 대한 백로깅 문서를 써두는걸로 두자."*

**아직 아무것도 안 썼습니다.** 이 문서는 "무엇을 어떤 틀로 쓸 것인가" 의
기록이고, 실제 착수는 API 가 더 굳은 뒤입니다(아래 "언제 시작하나").

---

## 1. 따라갈 틀 — quad 의 `docs/`

quad(`/code/Projects/quad/docs/`, **읽기 전용**)는 Diátaxis 4분면을 따릅니다.

```
                   실용적 / 행동 중심
                          ▲
       [How-To]           │          [Getting Started]
       태스크 지향 레시피    │          선형 학습
 ◀────────────────────────┼────────────────────────▶
 이론적 / 구조 중심         │           구체적 / 참조 중심
       [설명 트랙]          │          [API Reference]
       내부 설계론          │          공개 표면 룩업
                          ▼
                   정보적 / 지식 중심
```

폴더 모양:

```
docs/
  README.md          문서 안내 — 트랙 정의와 전체 목록. **여기가 정본**
  getting-started/   선형 튜토리얼
  how-to/            태스크별 레시피
  reference/         타입/심볼당 1페이지
  <설명 트랙>/        내부 설계 에세이 (quad 은 quadnomicon)
  assets/            그림
  site/              astro + starlight. sync 스크립트가 md → 사이트로 옮김
```

**동기화 구조**: 본문은 평범한 `.md` 로 쓰고 상대 경로로 링크합니다.
`site/sync-docs.py` 가 사이트 경로로 치환하고, 코드펜스 확장(퀴즈 등)을
starlight 컴포넌트로 펼칩니다. **GitHub 에서 그대로 읽히고 사이트에서도
읽히는 것**이 이 구조의 요점입니다.

## 2. stl-luau 에 맞게 줄인 안

quad 은 UI 프레임워크라 22편짜리 튜토리얼이 필요하지만, 여기는 **컨테이너
라이브러리**입니다. 배우는 것이 아니라 **찾아 쓰는 것**이라 무게중심이
다릅니다.

| 트랙 | quad | stl-luau 제안 | 왜 |
|---|---|---|---|
| Getting Started | 22편 | **1~2편** | 설치 + "배열 하나 만들어 써보기" 면 충분 |
| How-To | 여러 편 | **3~5편** | 아래 목록 |
| **Reference** | 타입당 1페이지 | **⭐ 여기가 본체** | 컨테이너 7 + 계약 + Common/Algorithm/BSearch |
| 설명 트랙 | quadnomicon 11편 | **4~6편** | 아래 목록. `.claude/` 에 이미 내용이 있음 |
| Overview | 3편 | **1편** | "왜 이게 있나" — Lua 기본 테이블 대비 |
| Agents/Skills | 있음 | **안 함** | 규모가 아직 아님 |

## 3. 백로그 — 무엇을 써야 하나

### 3-1. Reference (본체)

컨테이너마다 1페이지. 공개 표면은 **이미 소스 주석에 다 있습니다** —
옮기는 작업이지 새로 쓰는 게 아닙니다.

- [ ] `Arr` — 메소드 60 + 생성자 8. 가장 큽니다
- [ ] `HashMap` / `HashSet`
- [ ] `TreeMap` / `TreeSet`
- [ ] `Heap`
- [ ] `BSearch`
- [ ] `Common` (비교자 어댑터) / `Algorithm` (계약 기반 공용 함수)
- [ ] `Types` — 계약 셋(`ListCore`/`MapCore`/`SetCore`)과 `Record`
- [ ] **공통 규약 페이지** — 구간 규약, `n` 이 진실인 것, `nil` 구멍,
      checked/unchecked, 위치를 저장하면 안 되는 것

### 3-2. How-To

- [ ] 정렬하기 — 불리언과 3방향 비교자를 언제 어느 쪽으로
- [ ] 순회하기 — 네 가지 방법과 각각의 대가(표는 이미 있음)
- [ ] 집합 연산 — `HashSet` 과 `TreeSet` 중 어느 것을
- [ ] 상위 k 개 고르기 — `Heap` 으로 (실측 근거 있음)
- [ ] 타입이 `unknown` 이 됐을 때 — 캐스트가 필요한 세 자리

### 3-3. 설명 트랙

**`.claude/` 에 이미 쓰여 있는 것을 다듬어 옮기면 됩니다.**

- [ ] 왜 교집합 타입인가 — `setmetatable<>` 이 30개에서 무너지는 이야기
      (출처: `base/typing-limits.md`, `audit/arr-type-redesign/REPORT.md`)
- [ ] 메타테이블 세금과 `table.move` — 이 라이브러리 성능관의 뿌리
      (출처: `base/perf-measurements.md` 1·2절)
- [ ] 정렬 병합이 해싱을 못 이기는 이유 — 차수가 아니라 상수
      (출처: `base/perf-measurements.md` 9·10절)
- [ ] 계약을 왜 말단 모듈에 두는가 — 선언 순서 누수
      (출처: `base/architecture.md`, `audit/container-contracts/`)
- [ ] 무엇을 막고 무엇을 문서로 넘기는가
      (출처: `base/container-design-notes.md` 2절)
- [ ] 다른 언어 표준 라이브러리에서 얻은 것
      (출처: `base/container-design-notes.md` 전체)

### 3-4. 사이트

- [ ] `docs/site/` — astro + starlight 스캐폴딩
- [ ] `sync-docs.py` — 상대 경로 치환. quad 것을 참고해 줄여서
- [ ] 배포 — quad 은 `deploy.sh`. 도메인은 미정

## 4. 언제 시작하나 — **지금은 아닙니다**

**이유 둘:**

1. **공개 API 가 아직 굳지 않았습니다.** `Fut`/`Optional`/`Tuple` 이
   미정이고(`.claude/papers/`), 그것들이 들어오면 Reference 목차가 바뀝니다.
2. **문서는 낡으면 없는 것만 못합니다.** 이 저장소는 이미 그걸 겪었습니다 —
   재작성 후 `conventions.md` 가 `snake_case` 를 쓰라고 적고 있었고
   `architecture.md` 가 지워진 코드의 줄 번호를 가리켰습니다.

**착수 조건**: 열린 질문(`question.md`)이 정리되고 공개 표면이 한 바퀴
안정되면. 그때까지 **설계 근거는 `.claude/` 에 계속 쌓습니다** — 위 3-3 이
보여주듯 그게 곧 설명 트랙의 원고입니다.

## 5. 미리 정해둘 것

- **언어**: 한국어. quad 도 그렇습니다(스킬 본문만 영문).
- **코드 스니펫은 실제로 돌려서 검증**합니다. quad 은 mock 백엔드 위에서
  실행하고 strict 로 타입 검사합니다. 여기는 순수 luau 라 더 쉽습니다 —
  **스니펫을 `tests/` 에 넣고 같이 돌리면** 낡은 예제가 원천적으로 막힙니다.
  (quad 의 `scripts/doc-coverage.py` 가 같은 일을 합니다)
- **Reference 는 소스 주석이 정본**이고 문서는 그걸 옮긴 것입니다. 둘이
  갈리면 소스가 이깁니다. 자동 추출을 할지는 착수할 때 정합니다.

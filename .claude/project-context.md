# 프로젝트 컨텍스트

## 이게 뭔가

**stl-luau**는 Roblox 엔진 언어 **Luau**용 표준 라이브러리 스타일 유틸리티
모음입니다. 이름 그대로 C++ STL/JS 배열 메소드에 대응하는 컨테이너와
알고리즘을 Luau 문법과 성능 특성에 맞게 제공하는 게 목표로 보입니다
(range 기반 API, `_inplace` 변형, `table.move` 기반 벌크 연산 등 —
자세한 관례는 `.claude/conventions.md`).

**저장소 상태(2026-08-22 기준)**: 커밋 3개(`Init commit`, `Add test library`,
`Organize files`)까지만 있던 저장소에, 오랫동안 미커밋 상태로 쌓여있던
변경을 7개 커밋으로 정리하며 이 문서가 만들어졌습니다. 여전히 대부분의
모듈이 스캐폴딩/실험 단계입니다 — 아래 "모듈 현황"이 소스.

## 이 프로젝트의 출처 (2026-09-21 사용자 확인)

**실제로 mlua(Rust) 바인딩을 하는 프로젝트에서, Luau 쪽 자료형이 미흡해
문제가 되어 개선하다 갈라져 나온 것**입니다. 그래서 mlua 바인딩은 실제
수요가 있지만, 사용자 판단으로 **얹는 구조로 나중에** 조정합니다 —
*"여기에 얽메일 필요는 없어."* 설계를 이것에 맞추지 마세요.

## 실행 환경

- 런타임: **순수 `luau` CLI** (`luau tests/run.luau`). **lune 은 쓰지
  않습니다** — 근거와 그로부터 오는 제약(`io`/`fs` 없음, `pesde run` 불가)은
  `.claude/base/architecture.md`의 "런타임: 순수 luau" 절.
  **`const` 는 2026-09-21 에 채택했습니다**(quad 가 2026-09-10 에 채택;
  luau 0.734 통과). 예전의 "const 금지" 기록은 낡은 것입니다.
- 타입 체크 + 린트: **`luau-analyze`** 하나로 합니다(2026-08-31 전환).
  `./scripts/check.sh` 가 타입 검사와 테스트를 같이 돕니다.
  **selene 은 2026-09-21 폐기** — `const` 를 파싱 못 하고 최신 버전이
  0.31.0 이라 대안이 없었습니다(`check.sh` 에 원래 없어서 동작 변화 0). **`luau` 실행기 자체는 타입 검사를 하지
  않습니다.** 모든 모듈 상단에 `--!strict` 를 답니다 — `.luaurc` 하나에만
  의존하면 한 단어로 검사가 통째로 꺼집니다(실측).
- 패키지 매니저: **pesde**(2026-08-22 도입). `pesde.toml`의 `name`은
  `qwreey/stl_luau`, `[target] lib = "src/init.luau"`. **`[scripts]`는
  비어 있습니다** — `pesde run`이 항상 lune으로 실행하기 때문. pesde는
  의존성/배포 메타데이터 용도로만 씁니다.
- 포매터: **stylua 2.5.2**(`mise.toml` 고정, `stylua.toml`). `check.sh` 가
  `--check` 로 게이트를 겁니다.

## 모듈 구조 (2026-09-22 전면 재작성 후)

```
pesde.toml, pesde.lock  패키지 매니페스트 (qwreey/stl_luau, lib = src/init.luau)
mise.toml               툴체인 고정 (luau, luau-lsp, stylua)
stylua.toml             포매터 설정
README.md, LICENSE      간단한 소개(API 가 굳으면 다시 씀), MIT
.luaurc                 languageMode strict + 전체 lint on
.vscode/settings.json   luau-lsp new solver 강제
default.project.json    Rojo 매핑 (src -> ReplicatedStorage.StlLuau)
src/
  init.luau        배럴. 공개 표면 재수출 + 술어(isArr, isHashMap …)
  Types.luau       ⭐ 공유 계약만. **말단 모듈** — 아무것도 require 안 함
  Common.luau      비교자 어댑터와 기본 3방향 비교자
  Algorithm.luau   계약만 알고 구현은 모르는 공용 알고리즘
  BSearch.luau     컨테이너를 모르는 이분 탐색. Tree 계열의 백엔드
  Arr.luau         배열. 메소드 60(checked/unchecked 포함) + 생성자 8
  HashMap.luau     해시 맵. { data, size } 래퍼
  HashSet.luau     HashMap 위에 단방향으로 얹음
  TreeMap.luau     정렬 유지 맵. 정렬 레코드 배열 + 이분 탐색
  TreeSet.luau     TreeMap 위에 단방향. 집합 연산은 병합
  Heap.luau        이진 힙. 계약을 만족하지 않는 유일한 컨테이너

  ⭐ src 전체가 --!strict 이고 예외가 없습니다. type function 을 쓰던
     Tuple/TypeUtil 은 2026-09-22 에 내렸습니다
     (.claude/research/type-function-experiment/).
tests/
  run.luau         전체 엔트리 (luau tests/run.luau)
  spec.arr.luau    이하 컨테이너별 테스트. assert + print, 프레임워크 없음
  spec.bsearch.luau  spec.hashmap.luau  spec.hashset.luau
  spec.heap.luau     spec.treemap.luau  spec.treeset.luau
  spec.common.luau   spec.contracts.luau  (계약 — 구현을 바꿔 끼워봄)
scripts/
  check.sh               타입 + 음성 대조군 배터리 + require + 포맷 + 테스트
  spike-expectations.tsv 스파이크별 기대 진단 건수 (배터리의 단일 진실)
refs-ignoreme/          (gitignore) Java/Rust/C++ 표준 라이브러리 — 설계 참고
old-homeworks-ignoreme/ (gitignore) 예전 학교 과제 — ADT, visitor, Node/Tree
```

**서브모듈은 없습니다.** 예전에 `libs/test-luau` 서브모듈이 있었지만
2026-08-22 에 제거했습니다 — 그 프레임워크가 lune 에 의존했기 때문입니다.
저장소 자체는 살아 있으니 나중에 lute 로 옮기고 싶어지면 거기서 이어가면
됩니다.

## 검증 장치 — 이 저장소에서 가장 중요한 부분

`./scripts/check.sh` 하나가 다섯 가지를 봅니다(아래 넷 + stylua 포맷).
**앞의 넷이 같이 있어야 뜻이 있습니다.**

| 게이트 | 무엇을 막는가 |
|---|---|
| **TypeError 총계 0건** | 새 타입 에러가 들어오는 것 |
| ⭐ **음성 대조군 배터리** | *타입 검사가 죽는 것* — 0건이 "깨끗한 0건" 인지 "검사가 죽은 0건" 인지 가름 |
| **require 게이트** | 잘못된 require 경로. 정적 검사는 **진단 0건으로 통과**하고 런타임에서만 터짐 |
| **테스트** | 동작 |

둘째가 핵심입니다. 2026-08-31 에 음성 대조군이 **0/6** 이던 적이 있습니다 —
타입 검사가 통째로 죽어 있었는데 진단은 0건이었습니다. 그래서 스파이크마다
"이만큼의 에러가 나야 정상" 을 `scripts/spike-expectations.tsv` 에 고정하고,
**줄어들면 실패시킵니다.** 컨테이너를 새로 만들면 음성 대조군 스파이크를
반드시 같이 만드세요.

## 모듈 현황

전부 **재작성 후 상태**입니다. `src` 는 TypeError 0건이고 각 컨테이너마다
테스트와 음성 대조군 스파이크가 있습니다.

| 모듈 | 상태 | 음성 대조군 |
|---|---|---|
| `Types` / `Common` / `Algorithm` | 완성(작음) | — |
| `Arr` | 메소드 60 + 생성자 8 | `spikes/40` |
| `HashMap` / `HashSet` | 완성 | `spikes/41` |
| `BSearch` | 완성 | `spikes/42` |
| `TreeMap` / `TreeSet` | 완성 | `spikes/43` |
| `Heap` | 완성 | `spikes/44` |

**없어진 것들**: 옛 `fut.luau`(뼈대만 2줄)는 지웠고 `Fut`/`Optional` 은
설계 페이퍼(`.claude/papers/`) 단계입니다. `Tuple`/`TypeUtil` 은
`type function` 을 접으면서 `.claude/research/` 로 내렸습니다. 옛 `record.luau`(타입 별칭 한 줄)는 **`Types.Record` 로
흡수**됐습니다. 옛 `set.luau`/`treeset.luau` 의 내용은 사실 해시셋이었고
지금 `HashSet` 이 그 자리입니다.

## 다른 저장소와의 관계

- **`qwreey/quad`** (`/code/Projects/quad`에 클론됨): Roblox용
  DOMless UI 렌더러 재작성 프로젝트. 규모가 훨씬 크고 `.claude/` 문서
  체계가 매우 정교합니다(`doc-check.py`, session 아카이브, agent-memory,
  `quad-doc-auditor` 서브에이전트 등). stl-luau는 이 저장소의 **문서
  구조 패턴**(짧은 `CLAUDE.md` + `@import` + `base/`는 확정 결정만 +
  `question.md`)만 참고하고, 무거운 도구는 프로젝트가 그 정도 복잡도에
  도달하기 전까진 들이지 않습니다.
- **`Sol-s-Studio/tbox`** (`refs-ignoreme/tbox` 에 클론, 2026-09-22 공개):
  Luau 스키마 라이브러리. pesde 워크스페이스(모노레포)지만 stl-luau 는 **단일
  패키지 유지**(2026-08-22 결정). 여기서 건진 것 — **명시적 타입 인자
  `f<<T>>(...)`**, **팬텀 필드로 가변 타입 팩 보관**(`_tup: (T...) -> ()`) —
  은 `base/typing-limits.md` 와 `papers/03-tuple.md` 에 있습니다.

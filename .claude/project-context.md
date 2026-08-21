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

## 실행 환경

- 런타임: **Lune** (`lune run run_test.luau`). `luau` CLI로 개별 파일 문법
  체크도 가능(`luau src/foo.luau`).
- 패키지 매니저: **아직 없음** — `pesde.toml`도 `wally.toml`도 없습니다.
  `qwreey/tbox`, `qwreey/quad`는 둘 다 pesde를 씁니다. 도입 여부는
  `.claude/question.md` 참고.
- 포매터: 로컬에 `stylua` 바이너리는 있지만 이 저장소엔 `stylua.toml`이
  없습니다. 현재 파일들 인덴트가 탭(`src/arr.luau`)/스페이스(`src/tuple.luau`)로
  혼재돼 있습니다.

## 모듈 구조

```
lib.luau            엔트리포인트 (구 init.luau). arr만 export, run_test() 포함
run_test.luau        lune 실행 스크립트: require("lib").run_test():solve()
src/
  arr.luau            배열 컨테이너 — 가장 성숙한 모듈, 스트림형 API 다수 구현
  common.luau         Comparator<T> 타입 + compareTo 어댑터. 20줄, arr가 씀
  bsearch.luau        완전히 빈 파일 (0바이트)
  heap.luau           완전히 빈 파일 (0바이트)
  hashmap.luau        완전히 빈 파일 (0바이트)
  hashset.luau        완전히 빈 파일 (0바이트)
  treemap.luau        완전히 빈 파일 (0바이트)
  treeset.luau        구 set.luau를 그대로 옮긴 것 — 함수 시그니처만 있고
                       본문 대부분이 비어있거나 버그(아래 "알려진 문제" 참고)
  tuple.luau          실험적 type function 기반 튜플. 런타임 pack()은 동작,
                       모듈 자체는 아직 `return {}` (미완성)
  typeutil.luau       tuple.luau가 쓰는 type-level 헬퍼(Merge/SetMetaProp/
                       ExtractTagged/Tagged)
  fut.luau            2줄, 네임스페이스+메타테이블만 있고 메소드 없음
  record.luau         1줄, 타입 별칭만 있고 모듈 패턴을 안 따름
tests/
  arr.luau            arr.slice_inplace만 테스트 (6케이스)
libs/test-luau/        서브모듈, 자체 테스트 프레임워크 (github.com/qwreey/test-luau)
notes, todo             (루트) 예전 스크래치 노트 — Luau 메타메소드 참고표, API 아이디어
```

## 모듈 현황 (구현 정도)

| 모듈 | 상태 |
|---|---|
| `arr` | 구현 다수 — 생성자, push/insert/unshift 계열, map/filter/reduce, flat, slice, equal 등. `shuffle`/`reverse`/`reverse_inplace`/`rotate`/`rotate_inplace`/`sorted`/`replace`/`replace_inplace`/`erase`는 **시그니처만 있고 본문이 빈 함수**(`function arr_ifce.reverse(...) end` 등, `src/arr.luau:186-201`) |
| `common` | 완성(작음) |
| `bsearch`, `heap` | 미착수 (빈 파일) |
| `hashmap`, `hashset`, `treemap` | 미착수 (빈 파일) |
| `treeset` | 구 `set` 스텁 그대로 — **버그 있음**: `set.has`/`set.add`가 `self`가 아니라 모듈 테이블 `set`을 읽고 씀(`src/treeset.luau:14-19`), `export type set<T>`도 이름이 `treeset`이 아니라 `set`으로 남아있음. 실사용 전 재작성 필요 |
| `tuple`, `typeutil` | 실험 중, 미export |
| `fut` | 뼈대만 |
| `record` | 타입 별칭 하나, 모듈 아님 |

## 다른 저장소와의 관계

- **`qwreey/quad`** (`/code/Projects/stl-luau-refs/quad`에 클론됨): Roblox용
  DOMless UI 렌더러 재작성 프로젝트. 규모가 훨씬 크고 `.claude/` 문서
  체계가 매우 정교합니다(`doc-check.py`, session 아카이브, agent-memory,
  `quad-doc-auditor` 서브에이전트 등). stl-luau는 이 저장소의 **문서
  구조 패턴**(짧은 `CLAUDE.md` + `@import` + `base/`는 확정 결정만 +
  `question.md`)만 참고하고, 무거운 도구는 프로젝트가 그 정도 복잡도에
  도달하기 전까진 들이지 않습니다.
- **`qwreey/tbox`** (`/code/Projects/tbox`): Luau용 스키마 라이브러리.
  pesde **워크스페이스(모노레포)** 구조(`packages/tbox`, `packages/tbox_squish`
  등 여러 작은 패키지)를 씁니다. stl-luau가 pesde를 도입한다면, 이 저장소가
  현재는 **단일 패키지**(여러 패키지로 쪼갤 이유가 아직 없음 — 서로 다른
  런타임 의존성이 없는 순수 컨테이너 모음)이므로 tbox의 모노레포보다는
  `packages/tbox` 안 단일 패키지 구조(하나의 `pesde.toml` + `src/`)가 더
  가까운 참고 대상입니다.
- **`../tbox/`** (사용자가 언급): 위와 동일 저장소, Luau 타입 시스템을
  깊이 쓰는 부분(특히 `packages/tbox/src/types.luau`의 type function
  유틸)이 `src/tuple.luau`/`src/typeutil.luau`와 접근이 비슷합니다 —
  이 둘을 더 다듬을 때 참고할 만합니다.

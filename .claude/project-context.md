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
- 포매터: 로컬에 `stylua` 바이너리는 있지만 이 저장소엔 `stylua.toml`이
  없습니다. 현재 파일들 인덴트가 탭(`src/arr.luau`)/스페이스(`src/tuple.luau`)로
  혼재돼 있습니다.

## 모듈 구조

```
pesde.toml, pesde.lock  패키지 매니페스트 (qwreey/stl_luau, lib = src/init.luau)
mise.toml               툴체인 고정 (luau, luau-lsp)
.luaurc                 languageMode strict + 전체 lint on
.vscode/settings.json   luau-lsp new solver 강제
default.project.json    Rojo 매핑 (src -> ReplicatedStorage.StlLuau)
src/
  init.luau           엔트리포인트 (구 루트 lib.luau, 그 전엔 init.luau). arr만 export
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
  run.luau            전체 테스트 엔트리 (luau tests/run.luau)
  arr.luau            arr 스모크 테스트 10개 절 (assert + print, 프레임워크 없음)
scripts/check.sh        타입 검사 + 테스트
refs-ignoreme/          (gitignore) Java/Rust/C++ 표준 라이브러리 — 설계 참고
old-homeworks-ignoreme/ (gitignore) 예전 학교 과제 — ADT, visitor, Node/Tree
```

**서브모듈은 없습니다.** 예전에 `libs/test-luau` 서브모듈
(`github.com/qwreey/test-luau`)이 있었지만 **2026-08-22 에 제거했습니다** —
그 테스트 프레임워크가 `@lune/fs`·`@lune/stdio` 에 의존하는데 이 저장소가
lune 을 걷어냈기 때문입니다(순수 luau 엔 `fs` 가 없어 소스 라인 뷰 기능이
원천적으로 불가능). **test-luau 저장소 자체는 그대로 살아 있고** 제거 전에
로컬 커밋도 전부 push 해뒀으니, 나중에 lute 로 옮겨서 다시 쓰고 싶어지면
그 저장소에서 이어가면 됩니다.

## 모듈 현황 (구현 정도)

| 모듈 | 상태 |
|---|---|
| `arr` | 구현 다수 — 생성자, push/insert/unshift 계열, map/filter/reduce, flat, slice, equal 등. **[2026-08-22]** 테스트를 처음 제대로 붙이면서 버그 5건(`sized` 공유 테이블 오염, `filter_inplace` 전면 오동작, `flat` 오동작, `flat_inplace` 크래시, `max`/`min` 반전)을 찾아 고치고 회귀 테스트를 붙였습니다. **[2026-08-31]** 비어 있던 함수 10개를 구현했습니다(`shuffle(_inplace)`, `reverse(_inplace)`, `rotate(_inplace)`, `sorted`/`sort_inplace`, `replace(_inplace)`, `erase`) — **이제 `arr` 에 빈 본문은 없습니다**. 같이 버그 2건(`clear` 가 `__arr__` 태그 삭제, `erase_inplace` 가 뒤집힌 구간에서 배열을 늘림)도 고쳤습니다. **[2026-08-31] `Arr<T>` 타입 재설계** — 음성 대조군이 0/6 이던(= 타입 검사가 죽어 있던) 상태를 6/6 으로 되살렸습니다. TypeError 301 → 126(재설계) → 41(테스트 헬퍼 주석). 런타임 무변경. `arr.오타` 를 못 잡는 구멍이 하나 남음(`question.md` 2번). `.claude/audit/arr-type-redesign/REPORT.md` |
| `common` | 완성(작음) |
| `bsearch`, `heap` | 미착수 (빈 파일) |
| `hashmap`, `hashset`, `treemap` | 미착수 (빈 파일) |
| `treeset` | **[2026-08-22 수정]** `has`/`add`의 `self` vs 모듈 테이블 버그 고침, 타입도 `TreeSet<T>`로 리네임 + `{ [T]: boolean }` 형태로 정정. `intersect`/`union`/`subtract`/`exclusive`/`is_subset_of`/`size`/`from_function`은 여전히 빈 함수. **생성자/메타테이블 배선이 없어 아직 인스턴스를 만들 수 없음** — `arr` 패턴(`.claude/base/architecture.md`의 "모듈 팩토리 패턴")을 따를지는 hash/tree 컨테이너 표현 결정(`.claude/question.md` #2)에 달림 |
| `tuple`, `typeutil` | 실험 중, 미export |
| `fut` | 뼈대만 |
| `record` | 타입 별칭 하나, 모듈 아님 |

## 다른 저장소와의 관계

- **`qwreey/quad`** (`/code/Projects/quad`에 클론됨): Roblox용
  DOMless UI 렌더러 재작성 프로젝트. 규모가 훨씬 크고 `.claude/` 문서
  체계가 매우 정교합니다(`doc-check.py`, session 아카이브, agent-memory,
  `quad-doc-auditor` 서브에이전트 등). stl-luau는 이 저장소의 **문서
  구조 패턴**(짧은 `CLAUDE.md` + `@import` + `base/`는 확정 결정만 +
  `question.md`)만 참고하고, 무거운 도구는 프로젝트가 그 정도 복잡도에
  도달하기 전까진 들이지 않습니다.
- **`qwreey/tbox`** (예전엔 `/code/Projects/tbox`, **지금은 이 환경에
  클론돼 있지 않습니다** — 아래 내용은 과거 세션의 기록입니다):
  Luau용 스키마 라이브러리.
  pesde **워크스페이스(모노레포)** 구조(`packages/tbox`, `packages/tbox_squish`
  등 여러 작은 패키지)를 씁니다. stl-luau는 **단일 패키지로 유지하기로
  결정**(2026-08-22, `.claude/question.md`의 옛 "저장소 구조" 질문 참고 —
  지금은 지워졌고 이 결정만 남음)했으므로, tbox의 모노레포보다는
  `packages/tbox` 안 단일 패키지 구조(하나의 `pesde.toml` + `src/`)가
  더 가까운 참고 대상입니다.
- **`../tbox/`** (사용자가 언급): 위와 동일 저장소, Luau 타입 시스템을
  깊이 쓰는 부분(특히 `packages/tbox/src/types.luau`의 type function
  유틸)이 `src/tuple.luau`/`src/typeutil.luau`와 접근이 비슷합니다 —
  이 둘을 더 다듬을 때 참고할 만합니다.

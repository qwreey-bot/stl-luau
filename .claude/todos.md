# 지금 할 일

우선순위순. 가장 자주 바뀌는 문서입니다. 완료하면 지우고, 방향이 바뀌면
바로 갱신하세요.

## 막힌 것 (사용자 결정 필요)

| 무엇 | 어디 |
|---|---|
| (없음) | |

## 📍 지금 여기 (2026-09-30)

**M1(이름 정리) 끝, 다음은 M2(정렬 가족).** 전면 재작성(09-22) 이후 기반이 서 있습니다.
`./scripts/check.sh` 가 **exit 0** 이고 게이트 다섯이 전부 섭니다:

| 게이트 | 상태 |
|---|---|
| TypeError 총계 | **0건** |
| 음성 대조군 배터리 | 스파이크 33개 전부 기대치 일치 (2026-09-30) |
| require 게이트 | 통과 |
| **포맷 (stylua)** | 통과 (바이너리 없으면 건너뜀) |
| 테스트 | 11개 스펙 통과 |

### 2026-09-22 에 반영한 사용자 결정

| 질문 | 결정 | 결과 |
|---|---|---|
| C. `nil` 구멍 | **checked / unchecked 로 가름** | `*Unchecked` 여섯(메소드 60). `Max`/`Min` 1.83배 |
| D. 위치 저장 | **문서 규약**. 세대 카운터 없음 | 판단 기준을 표로 |
| E. `Record` | `Types.Record` 로 흡수 | 완료 |
| F. `Fut` | **스케줄러 주입**, 순수 luau 기본은 즉시 실행 | `papers/01` |
| F. `Optional` | **태그형** + `Arr:Fillholes()` 방향. 이름은 **`Present`/`Absent`**(Java 계보), 태그 `isPresent` | `papers/02` |
| 1. `type function` | **안 씀. `Tuple`/`TypeUtil` 을 내림** | `research/type-function-experiment/` — **`src` 전체가 strict** |
| 3. 라이선스 | **MIT** | `LICENSE` + `pesde.toml` |
| 4. stylua | **도입** | `mise.toml` 고정 + check.sh 게이트 |
| 문서화 | **quad `docs/` 구조** | `base/docs-plan.md` |

### ⭐ 같이 건진 것 — 명시적 타입 인자 `f<<T>>(...)`

tbox 조사에서 나왔고 실측으로 확인했습니다. **"제네릭을 못 푸는 세 자리" 를
전부 해결합니다** — 인자 없는 생성자, 테이블 리터럴, 반환으로만 결정되는 함수.

```lua
local m = HashMap.New<<string, number>>()
local h = HashMap.FromTable<<string, number>>({ a = 1 })
local f = nested:Flat<<number>>()
```

캐스트보다 낫습니다(캐스트는 단언, 이건 통지). **단 콜백 파라미터 주석
요구는 이걸로 안 없어집니다** — 원인이 다른 한계입니다.
전량은 `base/typing-limits.md`.

## 마일스톤 (2026-09-30~)

빠진 표면 리서치(`papers/04-surface-gaps.md`)와 사용자 결정(`question.md` W)을
작업 순서로 옮긴 것입니다. **순서·범위는 제게 맡기셨습니다** — *"지금은 작게
두고 나오는걸 잡아가다 나중에 넓혀도 좋고, 오늘 멈춘다 해서 프로젝트가 끝나진
않아."* 각 마일스톤은 **구현 → 재현·경계 테스트 → 음성 대조군 → check.sh →
관심사별 커밋**으로 닫습니다. 성능 주장은 `perf-measurements` 에 실측으로.

| # | 마일스톤 | 왜 이 순서 |
|---|---|---|
| ~~M1~~ | **✅ 2026-09-30** 이름 정리 — `Arr.Merge`/`MergeInplace` → `Concat`/`ConcatInplace`, `Replace`/`ReplaceInplace` → `Splice`/`SpliceInplace`(+"JS 와 다름" 주석), `At(idx)`(음수) 신설 | 새 표면이 옛 이름 위에 쌓이기 전에. `Merge` 라는 이름을 비워 `HashMap.Merge` 에 줌 |
| **M2** | **정렬 가족** — `StableSort`(+Inplace), `SortBy`(+Inplace, 키 한 번 계산), `NthElement`, `PartialSort`(+Inplace), `MergeSorted`, `IsSorted` 노출 | 사용자가 짚은 것. 실측 근거가 가장 확실(perf 15절) |
| **M3** | **`Arr` 빈 조각** — `PopBack`/`PopFront`, `SwapRemove`, `Contains`/`IndexOf`/`LastIndexOf`, `FindLast`, `Zip`/`ZipWith`, `Dedup`(+Inplace)/`Unique`, `Partition`, `Chunks`/`Windows`, `Scan`, `MinMax`, `MaxBy`/`MinBy`, `TakeWhile`/`DropWhile` | 작고 독립적. 한 절씩 |
| **M4** | **맵·셋** — `HashMap.GetOrInsert`/`GetOrInsertWith`, `Merge(other)`, `Accumulate(k, v, combine)`, 네 컨테이너의 `Retain`, `TreeMap`/`TreeSet` 의 `LowerKey`/`HigherKey`·`PopFirst`/`PopLast`, `Arr.GroupBy`/`CountBy`/`KeyBy` | `Accumulate`/`GetOrInsertWith` 가 `GroupBy` 의 재료 |
| **M5** | **`Deque`**(링 버퍼) | 세 출처 공통. 새 컨테이너 = 새 음성 대조군 스파이크 |
| **M6** | `Multiset`, `OrderedMap` | M4 위에 얇게. 부르는 곳이 보이면 |
| **M7** | `Fut` — `Race`, `AllSettled`, `Finally`, `Retry`, `Timeout`(provider 에 타이머 필요) | 부르는 곳 기준(기존 방침) |
| 연구 | `buffer` 기반 `BitSet`/packed 숫자 배열, `Freeze`, 비교 없는 정렬 | 실측 주제. 수요가 보이면 |
| **마지막** | **문서 사이트** — *"다른거 다 구현되면, quad처럼 마지막 스테이지에서 하자."* `base/docs-plan.md` | 사용자 결정 |

**이름 어휘 (W 결정)**: `Has` = 키를 가짐(맵·셋), `Contains` = 값을 포함함(배열).
`Merge` = 맵 덮어 합치기, `MergeSorted` = 정렬 병합, `Concat` = 이어붙이기.
문서로 못박을 것: `Splice`(JS 와 기본값이 반대), `Partition`(두 배열 반환,
C++ 식 제자리 아님), `Retain`(술어를 받음, Java `retainAll` 아님).

### 끝난 것 (2026-09-26~30)

`Optional`, `Fut`(`All` + provider), 네임스페이스 함수 노출, 전 모듈 리뷰(버그
19건), 질문 T (b) 구멍을 타입에 드러냄, 질문 V 콜백 셋째 인자 `ArrView<any>`,
빠진 표면 리서치와 이름 검토(W).

## 백로그 (당장 안 함)

- **mlua(Rust) 바인딩** — 이 프로젝트가 갈라져 나온 출처. 사용자 판단으로
  *"얹는 구조로 나중에"*. 설계를 여기에 맞추지 않습니다.
- **구간 인자를 받는 스트림**: 옛 스크래치의 `rangefilter`/`rangefind`/
  `rangemap` 아이디어. `Flat(start?, last?)` 처럼 `Filter`/`Find`/`Map` 이
  구간을 받게 하면 별도 이름이 필요 없습니다. 부르는 곳이 생기면.
- **pesde 0.7.4** — `const` 가 든 패키지를 0.7.3 은 게시 검증에서 거부합니다.
  게시할 때가 되면(`pesde self-upgrade`, 사용자 작업).

재작성 이전의 작업 기록(2026-08-22 / 08-31 세션)은 git 히스토리에 있습니다.

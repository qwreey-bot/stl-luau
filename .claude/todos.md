# 지금 할 일

우선순위순. 가장 자주 바뀌는 문서입니다. 완료하면 지우고, 방향이 바뀌면
바로 갱신하세요.

## 막힌 것 (사용자 결정 필요)

| 무엇 | 어디 |
|---|---|
| **T. 콜백 계열의 구멍 정책** — 건너뛸지, 타입을 정직하게(`Arr<T?>`) 할지 | `question.md` T |

## 📍 지금 여기 (2026-09-22)

**전면 재작성 완료. 사용자 결정 일곱 건 반영 완료.**
`./scripts/check.sh` 가 **exit 0** 이고 게이트 다섯이 전부 섭니다:

| 게이트 | 상태 |
|---|---|
| TypeError 총계 | **0건** |
| 음성 대조군 배터리 | 스파이크 27개 전부 기대치 일치 |
| require 게이트 | 통과 |
| **포맷 (stylua)** | 통과 (바이너리 없으면 건너뜀) |
| 테스트 | 10개 스펙 통과 |

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

## 다음 할 일 (2026-09-26~)

1. ~~**`Optional`**~~ — **2026-09-26 구현 완료.** `src/Optional.luau` + `Arr` 의
   구멍 다루기 넷. 그 과정에서 **원소가 유니온인 컨테이너가 전부 무너지던
   문제**를 찾아 고쳤습니다(`spikes/46`).
2. ~~**`Fut`**~~ — **2026-09-26 첫 판, 09-30 `All` 과 provider 세 갈래.**
   아직 없는 것(`Race`/재시도/`Finally`)은 `papers/01-fut.md`.
3. ~~**네임스페이스 함수 노출**~~ — **2026-09-30.** 절차적 호출이 정식 모양
   (사용자 방향). 콜론보다 18% 빠름(`perf-measurements` 14절).
4. ~~**전 모듈 리뷰**~~ — **2026-09-30.** opus 리뷰어 셋이 재현한 버그 18개 +
   고치다 찾은 1개(TreeMap/TreeSet `Iter`)를 전부 고침. 남은 1개는 정책 질문 T.
5. **문서 사이트** — API 가 한 바퀴 안정된 뒤. `base/docs-plan.md`.

## 백로그 (당장 안 함)

- **mlua(Rust) 바인딩** — 이 프로젝트가 갈라져 나온 출처. 사용자 판단으로
  *"얹는 구조로 나중에"*. 설계를 여기에 맞추지 않습니다.
- **구간 인자를 받는 스트림**: 옛 스크래치의 `rangefilter`/`rangefind`/
  `rangemap` 아이디어. `Flat(start?, last?)` 처럼 `Filter`/`Find`/`Map` 이
  구간을 받게 하면 별도 이름이 필요 없습니다. 부르는 곳이 생기면.
- **`splice`** — 지금은 `Replace`/`ReplaceInplace` 가 그 자리입니다.
- **pesde 0.7.4** — `const` 가 든 패키지를 0.7.3 은 게시 검증에서 거부합니다.
  게시할 때가 되면(`pesde self-upgrade`, 사용자 작업).

재작성 이전의 작업 기록(2026-08-22 / 08-31 세션)은 git 히스토리에 있습니다.

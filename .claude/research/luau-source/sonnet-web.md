# 웹·GitHub 검색 보고 (2026-10-14, sonnet)

방법의 한계: `gh` 가 없어 GitHub REST API(`api.github.com/...`)를 WebFetch 로 읽었습니다. **WebFetch 는 작은 모델이 요약한 결과**라
본문을 원문 그대로 읽은 것이 아닙니다(아래 "요약만"). 이슈 번호·제목·상태·날짜는 API JSON 에서 나온 것이라 믿을 만하고, 본문 해석은 덜합니다.
라이브러리/블로그 쪽(항목 2·3)은 **검색이 거의 비었습니다** — 끝에 적었습니다.

## 1. 상류 이슈·PR·RFC

### 1-A. DRAFTS 3번(제네릭 몸통이 검사되지 않음) — 가장 가까운 이슈 **#2733**
- https://github.com/luau-lang/luau/issues/2733 "No type error reported when using generic within function in unsafe manner" — **Closed(Completed) 2026-09-19**, 댓글 7, 라벨 bug·analysis. (API 직접 + 댓글 요약)
- 본문: `local function call<T>(fn: (T) -> T) fn(nil) end; call(function(x: number) ... end)` 에 에러가 없다는 것.
- 메인테이너 **aatxe** (댓글 요약): *"The type parameter is quantified on `call`, not on `fn`"*, 즉 **함수 몸통 안에서 그 스코프가 도입한 타입 매개변수는 불투명(opaque)이어야 한다**. 기여자 PhoenixWhitefire 가 "version 739 에서 고쳐짐"
  (테스트 `generic_function_parameter_rejects_incompatible_argument`), 메인테이너 말: 단순한 직접 불일치만 잡고 더 넓은 서브타이핑 개선은 앞으로.
- **프로브(0.742)**: `/tmp/.../sonnet/p1.luau` — `fn(nil)` 은 **잡힘**(`Expected this to be 'T', but got 'nil'`). 그러나 DRAFTS 3번의 `return v` (V → number)는 **여전히 0건**,
  `3-generic-body-unchecked.luau` 도 제어 줄(mono)만 보고되고 `3b` 는 0건. 즉 **#2733 은 "함수 타입 매개변수에 인자를 넘기는" 한 갈래만 고쳤고, 우리 3번(타입 변수를 구체 타입 자리에, 구체 값을 타입 변수 자리에)은 아직 열려 있음.**
  (단 `p2.luau` 의 `v + 1` 에는 "Consider placing annotations" 에러가 남 — 산술은 타입 변수에 대해 걸림.)
- 쓰임: ① 3번을 올릴 때 **#2733 을 Related 로 인용**하고 "aatxe 가 말한 불투명성 원칙이 이 경우엔 적용 안 됨" 이라 쓸 수 있다. 메인테이너가 **의도(불투명)를 공개적으로 밝혔으므로** "결함이라 고쳐질 수 있는 방향" 이라는 신호 → 몸통 검사에 의존하는 설계는 **지금 안 잡히는 것에 기대지 말 것**(오히려 나중에 잡히기 시작할 수 있음). ② 중복 보고는 아님(확인한 범위에서 `return v` 모양의 이슈 못 찾음 — 검색 한계 있음).

### 1-B. DRAFTS 4번(표 리터럴을 인덱서 파라미터에 넘기면 값 타입 안 봄)
- **#2463** https://github.com/luau-lang/luau/issues/2463 "Indexer type in function parameter doesn't type-check table literal contents" — **Open**(2026-06-26, 갱신 07-24), 라벨 bug·analysis, 댓글 1(우회: `keyof<T>` 교집합, 기여자 nnullcolumn). `f({ X = 99 })` 가 `{[keyof<T>]: boolean}` 에서 0건, 같은 값을 지역 변수에 대입하면 에러. (API 직접 + 요약)
- 고치려던 PR 묶음이 **2026-09-08 에 한꺼번에 머지 없이 닫힘**(API 로 확인한 것: #2843 "Check table properties against the supertype's indexer in subtyping"(#2463 용, `LuauFixTablePropsAgainstSuperIndexer` 플래그, 머지 안 됨), #2818·#2937 "Infer generic table indexer types from table literal/unsealed properties", #2754·#2825, #2856, #2919, #2886, #2791 … 전부 closed·not merged). 닫은 이유는 못 읽음 — 같은 날 닫힌 무더기라 **외부 기여 PR 일괄 정리**로 보이나 이건 **추측**.
- 쓰임: 4번은 **이미 보고돼 있음(#2463)** — 새로 올리지 말고 거기에 우리 재현(`{ [string]: number }` + `{ x = "bad" }`, 제네릭 아님)을 댓글로. 0.742 에서 `4-...luau` 재현 확인(제어 줄만 보고됨). 고쳐지는 시점은 불확실(PR 이 닫혔으므로 메인테이너가 직접 해야 함).

### 1-C. DRAFTS 1·2번 이웃
- **#2168** https://github.com/luau-lang/luau/issues/2168 — Open, bug·analysis, 댓글 0(2025-12-26). 맨 람다 `map(5, function(x) return x*2 end)` 가 에러. (DRAFTS 가 이미 인용.) 아직 열려 있음.
- 같은 영역 열린 이슈(제목만 확인): **#2598** "Infer generic callback parameters from earlier arguments"(Open), **#2713** 빌더 체이닝에서 `T` 를 잃음(Open, 본문 요약), **#2670** "Generic leaking out of function call and subsequent accesses result in `any`"(Open, 담당 hgoldstein, 제보자 말: 알 수 없으면 `any` 가 아니라 `unknown` 이어야), **#2647** "Generic left as a free type"(Open) — 우리 2번(자유 타입이 새는 것)과 같은 메커니즘 후보. 2번은 DRAFTS 에서 0.742 에서 고쳐졌다 했으니, **#2670·#2647 의 상태만 추적**.
- 쓰임: 이 이슈들은 "제네릭 호출 결과의 자유 타입 누수" 계열이 아직 진행 중이라는 근거. `f<<T>>` 명시 인자 규약을 유지할 근거가 됨.

### 1-D. 우리 설계에 직접 닿는 열린 이슈(요약만)
- **#2637** `{ T }` 를 `{ read [unknown]: V }` 에 못 넘김(Open) — read 인덱서 공변을 쓰는 우리 `ArrRead`·`ListMarker` 와 가까움(우회: 인덱서 타입을 제네릭으로 하나 더). https://github.com/luau-lang/luau/issues/2637
- **#1766** 팬텀 제네릭(정의에서 안 쓰이는 `T`)은 추론에 안 쓰임(Open, 제보자도 의도일 수 있다 함). https://github.com/luau-lang/luau/issues/1766 — **우리 팬텀 필드(`__list: T` 등)는 "안 쓰이는 제네릭"이 아니라 필드에 쓰이는 것이라 다름**, 하지만 "팬텀을 추론 재료로 믿지 말 것" 경고로 읽을 만함.
- **#2608** `index<Map, T>` 를 파라미터로 쓸 때 형제 인자 `T` 가 정해지기 전에 표 리터럴을 검사해 오류(Open) https://github.com/luau-lang/luau/issues/2608 — `index<>` 를 두 보기에 쓴 v5 에 해당: **`index<>` + 표 리터럴 인자는 위험**. #1524(`index<T>` 에 제네릭이면 never 로 줄어듦)도 과거에 있었음.
- **#2390** 제네릭 경계(bounds) 추론이 표 타입에서 틀림(Open); PR #2767·#2771·#2783·#2834 (교집합 분기에서 제네릭 경계 기록 롤백) 전부 머지 없이 닫힘. 교집합 + 제네릭 추론은 **구조적으로 약한 지점** — 우리 "교집합 쓰면 192곳 추론 깨짐" 관찰(DRAFTS 5번)과 일치. **#2625** "Generic instantiation fails in intersection-typed parameter fields"(Open), **#2621** 도 같은 계열.
- **#2116** 제네릭 반환 타입이 변수에 대입되면 사라짐(Open), **#1690** 제네릭이 인덱서에 쓰이면 인스턴스화 안 됨 `unknown`(Open, 2025-02), **#2986/#2711/#2706** 제네릭 타입 팩(Open).
- 쓰임: 전부 "새 솔버의 제네릭 + 교집합/인덱서/타입 함수 조합은 아직 흔들린다" 는 방증. v6 가 **제네릭을 단순한 자리(탐침 타입, 단순 함수 타입)에만 쓰는 쪽**으로 간 것과 맞음.

### 1-E. RFC (rfcs.luau.org / luau-lang/rfcs, 목록은 API 로 직접 읽음)
- **`explicit-type-parameter-instantiation`** — 상태 **Implemented**. 부분 인스턴스화 허용(`f<<number>>` 로 앞쪽만, 나머지는 익명), 메타메서드 경유는 명시적으로 거부("타입 오류를 내야 함, full stop"), `<<` 를 닫아 비트시프트 연산자는 영영 못 씀. https://raw.githubusercontent.com/luau-lang/rfcs/master/docs/explicit-type-parameter-instantiation.md (요약 읽음)
  → **의도된 안정 기능**: `f<<T>>` 규약은 믿어도 됨. (단, 부분 인스턴스화의 나머지 제네릭이 자유 타입으로 남는 버그: #2647, 그리고 PR #2791 "Infer omitted generics in partial explicit instantiations" 는 머지 없이 닫힘 → **부분 인스턴스화는 피하고 모든 인자를 적을 것**.)
- **`index-type-operator`** — **Implemented**; `index<Person,"age">`, 유니온에 분배, `__index` 존중. 제네릭 미해결 인자의 의미는 RFC 에 안 적혀 있음(→ #1524·#2608 같은 이슈가 생긴 이유). https://raw.githubusercontent.com/luau-lang/rfcs/master/docs/index-type-operator.md
- **`generic-function-subtyping`** — 제네릭 함수 타입은 **공변 위치에서만** 인스턴스화되어 단형 함수 타입의 서브타입이 됨; 반공변(파라미터) 위치 인스턴스화는 **의도적으로 금지**(불건전), 표 속성은 불변이므로 막힘, 랭크-2 다형성 파라미터에는 단형 함수를 못 넘김. (요약, 상태 필드는 모호) https://raw.githubusercontent.com/luau-lang/rfcs/master/docs/generic-function-subtyping.md
  → **"표 리터럴을 인자로 넘기면 제네릭 함수가 구체 함수 타입에 안 맞춰짐" 이슈는 이 RFC 의 의도(반공변 금지)와 겹칠 수 있음** — 보고 전에 이 RFC 를 정독해 "의도된 동작인지" 가를 것(내가 그 정확한 사례를 프로브하진 않음).
- **`generic-functions`** (원 RFC): 검색 요약에 따르면 **HKT 와 제약(F-bounded)은 지원하지 않는다고 명시** — 트레이트/연관 타입을 타입 수준에서 직접 표현하는 길은 언어 설계상 열려 있지 않음. https://rfcs.luau.org/generic-functions.html (검색 요약만)
- 열린/닫힌 제안(API 목록, 본문 요약):
  - **luau-lang/rfcs#50 "Constraints on generic parameters"** — Open(2024-07 ~ 2026-09-19 갱신, 담당 andyfriesen). https://github.com/luau-lang/rfcs/pull/50
  - #87 "Generic Constraints" — Closed·not merged(2026-03-18). #207 "Generic Subtyping Constraints" — Closed(2026-05). 즉 **제약 제네릭은 두 번 시도되었다 닫힘, #50 만 열림**.
  - #122 `noinfer` 타입 연산자 — Open(2025-05~). https://github.com/luau-lang/rfcs/pull/122 — 인자 위치가 제네릭 추론에 기여하지 않게 하는 도구. **우리가 "콜백 인자는 추론 재료가 되지 않게" 하려는 것(`ArrView<unknown>` 우회)의 정식 도구가 될 수 있으나 미채택.**
  - #123 Nominal typing — Open. #106 eager inference 주석 — Open.
  - 놀라운 점: luau 이슈 #732 ("generics 에 힌트") 는 "제네릭 constraints 구현으로 닫힘"(2022-11) 이라 적혀 있는데 RFC #50/#87 이 아직 안 합쳐졌으니 요약 오독 가능성 — **무시할 것**. 다만 PR #3004 가 `GenericBoundsMismatch` 진단을 언급하므로 내부적으로 "제네릭 경계" 개념은 존재(**언어 기능으로 노출된 건 확인 못 함**).
- 쓰임: **트레이트용 bounded generics 는 올해 안에 기대하지 말 것**(RFC 미채택, 두 건 닫힘). 설계는 "구조 타입 + 팬텀 마커 + 탐침" 이라는 현재 방향이 현실적.

### 1-F. 상류 동향 일반
- 새 솔버 관련 열린 이슈가 100+ (최근 것: #3045 2026-10-13). 2026-09-08 에 외부 PR 다수가 머지 없이 닫힘. **즉 "외부 기여로 곧 고쳐진다" 에 기대면 안 되고, 메인테이너(aatxe, hgoldstein 등)가 직접 고치는 것만 반영됨.**
- 0.739 에서 #2733 수정이 들어갔다는 것은 **몸통 불투명성 쪽 작업이 진행 중**이라는 신호 → 3번을 올리면 반응을 얻을 가능성이 비교적 높음.

## 2. 같은 문제를 푼 라이브러리·사람 — **거의 못 찾음**
- jecs(https://github.com/ukendio/jecs): 검색 요약만, `world.component<TData>()` 같은 제네릭 컴포넌트 타입이 있다는 정도. 소스의 타입 트릭은 **읽지 않음**.
- DevForum "New Type Solver [Beta]" 스레드(https://devforum.roblox.com/t/new-type-solver-beta/3155804): 검색 요약에 "제약 제네릭 요청이 있었다" 정도. 스레드를 실제로 읽지 않음.
- 트레이트/인터페이스를 타입으로 표현한 Luau 라이브러리, 팬텀·브랜드 패턴 글은 **검색으로 확인되지 않음**(해당 키워드의 결과가 일반 새 솔버 안내뿐). 나온 것: 비 Luau 프로젝트 Runic(type-class-lite) — 관련 없음.
- 추천 후속(내가 안 한 것): `/code/Projects/quad-scratch/refs/` 의 fusion/vide/charm/tbox 소스를 직접 grep (팬텀·`index<>`·교집합 사용), jecs 의 `src/jecs.d.luau`·타입 정의 읽기.

## 3. 새 솔버 함정 정리 글 — 검색으로는 못 찾음
- 정리된 글은 발견하지 못했고, 이슈 트래커가 사실상 유일한 "함정 목록"입니다. 위 1-C~1-D 가 그 정리. 공식 문서: https://luau.org/typecheck (읽지 않음).

## 우리 결정에 쓸 요약
1. 3번 결함: **#2733 이 가장 가까운 선례**(부분 수정). 새 이슈로 올리되 #2733 과 aatxe 의 "opaque" 문장을 인용 — 올릴 가치 높음. 0.742 재현 확인함.
2. 4번 결함: **#2463 이 이미 있음(Open)** — 새 이슈 대신 댓글(제네릭 아닌 단순 재현 추가).
3. `f<<T>>` 는 RFC 가 구현됨으로 표시 → 안정. 부분 인스턴스화는 피할 것(#2647).
4. 교집합 + 제네릭 추론은 상류에서도 흔들리는 영역(#2390·#2625·#2621, 고치려던 PR 전부 닫힘) — 교집합 의존 설계는 보수적으로.
5. `index<>` 는 구현된 기능이나 표 리터럴 인자와 섞이면 실패(#2608) — v5 의 `index<>` 두 보기를 되살릴 때 주의.
6. 제약 제네릭(트레이트 bound)은 RFC 미채택 — 타입 수준 트레이트 바운드를 전제로 한 설계는 하지 말 것.

프로브 파일(같은 폴더): `p1.luau`, `p2.luau`, `p3.luau`, `3b-…`, `4-…`, `5-…` (DRAFTS 재현 복사본).

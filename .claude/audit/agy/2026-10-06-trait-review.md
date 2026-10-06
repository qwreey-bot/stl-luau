# Gemini(agy) 트레이트 설계 검토 — 원문 + 메인 검증 (2026-10-06)

> **작성**: Gemini 3.8 Flash(High), `delegate-agy` 과제 `trait-review`(기준 `41f9639` — 리뷰
> 1라운드 수정 `c5fd700` 이전). 과제: "방금 들인 트레이트를 바깥 시선으로 — M3~M7 에서 어디서
> 삐걱거릴지, 런타임 토큰과 타입 마커가 어긋나는 자리, API 이름의 객관성". 위조는 결함 아님으로 알림.
>
> **메인 검증(2026-10-06)**:
> - **진짜, 고침(`c5fd700` 뒤 커밋)**: 뿌리 1 의 실측 둘 — 다른 종류 컨테이너를 리스트 진입점
>   (`HashSet.FromList` 등 — `Common.listLength`)에 넘기면 조용히 빔, `HashMap.FromTable` 에 넘기면
>   내부 필드가 키로 쏟아짐 → 둘 다 사용자 줄 에러. 뿌리 2 Case 1 — 마커가 토큰을 요구하지 않아
>   토큰 없는 테이블이 타입을 통과 → `Token` 을 `Types` 로 옮기고 마커에 `read __type` (`spikes/55`
>   neg10). 질문 4-1 — 다른 사본의 값에 "got a Arr" → "그 종류가 구현하지 않거나 다른 사본의 값"
>   안내.
> - **이미 고쳐져 있었음(1라운드)**: 중복 Impl 덮어쓰기, Impl 무결성(토큰·트레이트 소속), `Stamp`/
>   `Implements` 미사용(테스트에 들어감 — 사용자 컨테이너용 공개 API 로 둠).
> - **합의된 결정이라 그대로**: 뿌리 3(마커를 읽으면 nil — 타입에만 있는 필드, 질문 AG 3; `Types`
>   에 "읽지 말 것" 주석을 더함), Case 4(구조적 토큰 복제 — 위조), 사본 간 비호환.
> - **설계 메모로(M5/M6)**: 리스트 진입점이 `Trait.List` 를 구현한 비-Arr(Deque)을 받는 길, Multiset
>   은 `SetOps` 의 `Add -> boolean` 의미와 안 맞음, `MapOps` 에 `Len`/`Has` 가 없음 — `todos.md`.
> - **이름 → 질문 AH**: `TypeOf` → `TokenOf`, `Impl` 의 이름, 토큰을 `Trait` 밑에 둘지.
> - **알던 것**: 뿌리 6(`Algorithm.IndexOf` 는 직접 루프보다 6배 느림)은 `Algorithm.luau` 머리가
>   "느린 게 정상" 으로 적어 둔 성격(구현을 모르는 코드용). `Arr.IndexOf`(M3)가 빠른 판.

---

# 트레이트(Trait) 설계 정밀 리뷰 — 외부 모델(Gemini/agy) 분석 보고서

- **기준 커밋**: `41f963971db3103150680508250ec45162a580cd` (`git rev-parse HEAD` 실측 확인)
- **작업 환경**: `/code/Projects/stl-luau-agy/trait-review` (브랜치 `agy/trait-review`)
- **실행 환경**: Pure Luau 0.734 (`-O1` / `-O2`)
- **작성 원칙**: 직접 실행해 검증한 것은 **[실측]**, 코드를 읽고 분석·추론한 것은 **[추정]**, 설계 변경 아이디어는 **[제안]**으로 명시.

---

## 1. 총평: 관점의 전환과 핵심 요약

최근 반영된 트레이트 설계(`596436a`, `c1f54d4`, `41f9639`)는 **"메타테이블 없는 평범한 엔티티 테이블"** 구조를 보존하면서도 공용 알고리즘에 모듈을 직접 주입하던 번거로움을 크게 덜어낸 기민한 시도입니다. 특히 런타임 테이블 토큰의 참조 동일성(identity)을 이용해 위조 검사 오버헤드를 걷어내고 술어 판별 성능을 0.62~0.66배로 끌어올린 점은 실측 기반 엔지니어링의 훌륭한 성과입니다.

그러나 **바깥 시선(Gemini)**에서 전체 아키텍처와 로드맵(M3~M7)을 조망했을 때, 현재의 트레이트 도입은 **"공용 알고리즘(`Algorithm.luau`) 4개 함수만을 위한 고립된 섬"**으로 머물러 있으며, 타입 시스템의 팬텀 마커와 런타임 토큰 등록 간의 **원천적 단절**, 그리고 컨테이너 간의 **상호 변환 불능**이라는 깊은 구조적 균열을 안고 있습니다.

아래에서는 이 문제의 뿌리를 6가지 근본 테마로 묶어 분석하고, 질의하신 4가지 핵심 질문에 실측 근거를 바탕으로 상세히 답합니다.

---

## 2. 근본 원인 (뿌리 6가지)

### [뿌리 1] 트레이트의 "고립된 섬" — 라이브러리 내부는 여전히 트레이트를 모른다
- **현상**: `Trait.List`, `Trait.Map`, `Trait.Set`이 도입되었지만, 라이브러리 전체에서 이 트레이트를 소비하는 곳은 오직 `src/Algorithm.luau`의 4개 함수(`IndexOf`, `Count`, `Keys`, `Values`)뿐입니다.
- **모순**: 정작 컨테이너 간 상호 변환 진입점인 `HashSet.FromList`, `TreeSet.FromList`, `Heap.FromList`, `HashMap.FromTable`, `Fut.All`, `Common.denseList`, `Common.listLength`는 **트레이트 인터페이스를 전혀 사용하지 않고**, `Arr`의 구체적인 내부 구조(필드 `n`, 1..n 직접 배열 인덱싱 `tbl[i]`)를 하드코딩으로 전제하고 있습니다.
- **실측**:
  - `probe_deque_fromlist.luau` [실측]: `Trait.List`를 완벽하게 구현한 `Deque` 인스턴스를 `HashSet.FromList(deque)`에 넘기면, `Common.listLength`가 `n` 필드가 없어 `#deque == 0`으로 계산하고, `deque[i]`도 nil이므로 원소가 0개인 빈 셋이 생성됩니다(`HashSet.Len: 0`). 데이터가 소리 없이 유실됩니다.
  - `probe_deque_hashmap.luau` [실측]: `HashMap.FromTable(deque)`에 넘기면, `src/HashMap.luau:240`의 `if Trait.TypeOf(tbl) == Trait.Types.Arr` 검사를 빗겨가 일반 사전 순회(`for k, v in tbl`)를 타면서 `head`, `tail`, `buf`, `__type` 등 Deque의 내부 구현 필드 7개가 해시맵 키로 오염되어 들어갑니다(`HashMap.Len: 7`).

### [뿌리 2] 팬텀 마커(타입)와 런타임 등록(토큰)의 원천적 비동기화 — 아무것도 지키지 않는다
- **현상**: 정적 타입 마커(`Types.ListMarker<E, I>` 등)와 런타임 트레이트 등록(`Trait.Impl`) 사이에는 컴파일러가 강제하는 연결고리가 **단 1개도 존재하지 않습니다**.
- **실측**:
  - **어긋남 A (타입 통과, 런타임 폭발 — 토큰 부재)**: `Types.ListMarker`(`src/Types.luau:88`) 정의에 `read __type`이 빠져 있어, 토큰이 아예 없는 일반 테이블도 타입 검사를 무사 통과합니다. 런타임에 호출 즉시 크래시합니다(`probe_trait_divergence.luau` Case 1 [실측]).
  - **어긋남 B (타입 통과, 런타임 폭발 — Impl 누락)**: 타입에 토큰과 마커를 모두 적었으나 `Trait.Impl` 등록을 빠뜨린 경우, `luau-analyze`는 0건으로 통과하고 런타임에 `Algorithm: IndexOf needs a List (got a Fake)`로 폭발합니다(`probe_trait_divergence.luau` Case 2 [실측]).
  - **어긋남 C (런타임 정상, 타입 거부 — 마커 누락)**: 런타임 등록을 완벽히 마쳐 런타임 실행은 정상이나, 타입에 팬텀 마커(`read __list`)를 적지 않으면 `luau-analyze`가 `TypeError: Expected this to be 'ListMarker<...>'`로 거부합니다(`probe_trait_divergence.luau` Case 3 [실측]).
  - **어긋남 D (명목성 vs 구조적 타이핑)**: 런타임 토큰은 참조 동일성(Nominal)으로 검사되지만, Luau 타입 시스템에서 `TraitToken<"Arr">`는 `{ read name: "Arr" }` 구조적 타입(Structural)입니다. 임의로 만든 `{ name = "Arr" :: "Arr" }`는 정적 타입을 완벽히 속이지만 런타임에 거절됩니다(`probe_token_structural.luau` [실측]).
- **판정 [실측]**: 이 둘의 일치를 지켜주는 시스템 장치는 0개입니다. 오직 `tests/spec.contracts.luau`에 사람이 작성한 수동 단언에만 의존합니다.

### [뿌리 3] 팬텀 필드 누출(Leak)로 인한 정적 타입 건전성(Soundness) 파괴
- **현상**: Luau에는 순수 팬텀 타입 선언이 없어 트레이트 마커(`read __list: T`, `read __listIndex: number`, `read __mapKey: K`, `read __mapValue: V`, `read __setItem: T`)가 일반 읽기 전용 속성으로 선언되었습니다.
- **실측** (`probe_phantom_leak.luau` [실측]):
  - `local a = Arr.Of(10, 20)`
  - `local x: number = a.__list`
  - `local i: number = a.__listIndex`
  - `luau-analyze`: **TypeError 0건 통과!** 컴파일러는 `x`와 `i`가 non-nil `number`라고 확신합니다.
  - 런타임 출력: `x: nil`, `i: nil`.
  - **결과**: `T?`가 아닌 확정형 `T`로 선언된 필드에서 런타임에 `nil`이 튀어나오는 **타입 건전성 구멍(Soundness Hole)**이 발생하며, IDE 자동완성 목록에 실제로는 존재하지 않는 `__list`, `__listIndex`가 오염 노출됩니다.

### [뿌리 4] Trait API의 Rust 문법 편향, 어휘 충돌, 그리고 사장된 죽은 코드
- **현상**: API 모양(`NewType/New/Impl/TypeOf/ImplOf/Implements/Stamp`)이 Rust의 문법적 키워드를 무리하게 차용하면서 일관성이 결여되었고, 실제로는 쓰이지 않는 데드코드가 포함되어 있습니다.
- **실측 및 근거**:
  - `Stamp` [실측]: `Trait.luau:83`에 "생성자들이 씁니다"라고 정의되었으나, `src/`와 `tests/` 전체에서 **단 한 번도 쓰이지 않습니다**. (컨테이너들이 성능 최적화를 위해 리터럴 `__type = TOKEN`을 직접 작성하도록 강제되었기 때문).
  - `Implements` [실측]: `src/` 및 `tests/` 전역에서 **0회 사용**된 데드코드입니다.
  - `TypeOf` vs Lua 내장 `type`/`typeof`: `Trait.TypeOf`는 타입 이름(문자열)이 아니라 `Token` 객체를 반환하므로 명명이 오도적입니다. 정직한 이름은 `TokenOf`입니다.
  - `Impl` 어휘 편향: 함수 이름도 `Impl`, 3번째 매개변수도 `impl`(`Impl(trait, token, impl)`)입니다. 동사가 아닌 Rust 예약어 축약 명사를 함수명으로 사용하여 어색합니다.
  - `Trait.ImplOf`의 내부 우회: `src/Algorithm.luau:38`은 `Trait.ImplOf` 호출 오버헤드(16%)를 피하기 위해 `trait.impls[rawget(value, "__type")]`로 API를 직접 우회(바이패스)하고 있습니다. 제공자 자신조차 느려서 쓰지 않는 API가 공개되어 있는 모순입니다.

### [뿌리 5] 컨테이너 생성·변환 다형성의 부재와 공용 알고리즘의 극심한 빈혈
- **현상**: 현재의 트레이트 계약(`ListOps`, `MapOps`, `SetOps`)에는 컨테이너를 **생성(Create)**하거나 **변환(Transform)**하는 메커니즘이 전혀 없습니다.
- **추정 및 실측**:
  - `Algorithm.luau`에 왜 `Filter`, `Map`, `Partition`, `Slice`, `Concat` 같은 일반적인 컬렉션 연산이 없는가? -> 트레이트만으로는 "결과를 어떤 컨테이너로 반환해야 하는지(Higher-Kinded Types/Factory)"를 알 수 없기 때문입니다.
  - 심지어 `Algorithm.Keys`와 `Algorithm.Values`조차 `Arr`를 반환하지 못하고, 메타데이터 없는 날것의 Lua 배열 `{ K }`, `{ V }`를 반환합니다(`src/Algorithm.luau:94, 102`).
  - `Trait.Set`의 방치: `HashSet`과 `TreeSet`이 `Trait.Set`을 등록하지만(`src/HashSet.luau:316`, `src/TreeSet.luau:456`), `Algorithm.luau`에는 Set 트레이트를 소비하는 알고리즘이 **단 0개**입니다.

### [뿌리 6] 성능의 역설과 공용 알고리즘의 당위성 약화
- **실측** (`probe_perf_algo.luau` [실측]):
  - 100개 원소 배열에서 `Algorithm.IndexOf` vs 네이티브 `Arr` 루프 비교 (`-O2`, 5만 회 반복):
    - `Algorithm.IndexOf`: **0.1723초**
    - 네이티브 루프: **0.0285초**
    - **결과: `Algorithm.IndexOf`가 6.04배 느림!**
- **추정**: 루프 반복마다 `ops.Get`과 `ops.NextIndex`라는 간접 함수 호출 2회가 발생하기 때문입니다. 페이퍼 06에서는 구형 간접 호출 대비 신형 간접 호출을 비교하여 "1.00배(차이 없음)"라고 보고했으나, 컨테이너 자체의 직접 연산과 비교하면 **6배 세금**이 붙습니다. M3에서 `Arr.IndexOf`가 추가되면, 사용자 입장에서 6배 느린 `Algorithm.IndexOf`를 사용할 유인이 완전히 사라집니다.

---

## 3. 질문별 상세 분석 및 실측 검증

### 질문 1: M3~M7 로드맵에서 어디서 삐걱거릴까?

#### 1) M5 Deque 가 List 트레이트를 구현할 때
- **삐걱거리는 지점 [실측]**:
  1. `HashSet.FromList(deque)`, `TreeSet.FromList(deque)`, `Heap.FromList(deque)`에 Deque를 넘기면 **크기 0인 빈 컨테이너가 생성**됩니다(`probe_deque_fromlist.luau` [실측]).
     - 이유: 이 함수들이 `Common.denseList`를 쓰고, `Common.denseList`는 `Common.listLength`(`rawget(list, "n")` or `#list`)로 길이를 잰 후 `list[idx]`로 직접 읽기 때문입니다. 링 버퍼 기반 Deque는 `n`이 없고 `#deque == 0`이며, `deque[idx]`로 직접 조회할 수 없습니다.
  2. `HashMap.FromTable(deque)`에 넘기면 Deque의 내부 구현 필드(`head`, `tail`, `buf`, `__type` 등)가 해시맵의 Key-Value 항목으로 고스란히 덤프됩니다(`probe_deque_hashmap.luau` [실측]).
  3. `Fut.All(deque_of_futs)`에 넘기면 Deque의 원소를 순회하지 못하고 실패합니다(`src/Fut.luau:453`의 `Common.listLength` 의존).
- **결론 [추정]**: `List` 트레이트를 아무리 정교하게 구현해도, 라이브러리 내부의 수많은 리스트 수용 진입점들이 여전히 `Arr` 전용 메모리 모델(`list.n`, `list[i]`)에 갇혀 있어 Deque는 외톨이가 됩니다.

#### 2) M6 OrderedMap 이 Map 을 구현할 때
- **삐걱거리는 지점 [추정]**:
  1. `MapOps`(`src/Types.luau:69`)는 `Get`, `Set`, `Records` 3개 함수만 요구합니다. `OrderedMap`이 이를 만족하기는 쉽습니다.
  2. 그러나 M4의 `HashMap.Merge(other)`나 `Retain` 등에서 `other`로 `OrderedMap`을 받을 때, `other.data`를 직접 읽는 구조라면 타입 에러나 런타임 오류가 발생합니다.
  3. `MapOps`에는 `Len(map)`과 `Has(map, key)`가 없습니다. 공용 알고리즘이 맵의 크기를 알거나 키 존재 여부만 가볍게 확인하려 해도, 반드시 `Records()`를 호출해 전체 배열을 새로 생성(할당)해야 하는 무거운 오버헤드가 발생합니다.

#### 3) M6 Multiset 이 Set 을 구현할 때
- **삐걱거리는 지점 [추정]**:
  1. `SetOps`(`src/Types.luau:78`)의 명세:
     `Add: (set: C, item: T) -> boolean` (새로 들어갔는가)
     `Has: (set: C, item: T) -> boolean`
     `Remove: (set: C, item: T) -> boolean`
     `Items: (set: C) -> { T }`
  2. `Multiset`은 동일 원소의 다중도(Count/Multiplicity)를 관리하는 컨테이너입니다.
     - `Add`: 중복 원소 삽입 시 항상 개수가 증가하는데, `boolean`으로 무엇을 반환해야 하는가?
     - `Remove`: 원소를 1개만 감소시키는가, 전부 제거하는가?
     - `Count(set, item)`이 `SetOps`에 없어 다중도 조회가 불가능합니다.
  3. 따라서 `Multiset`은 현재의 `SetOps`에 억지로 끼워 맞출 수 없습니다.

#### 4) 사용자가 자기 컨테이너를 붙일 때
- **삐걱거리는 지점 [실측]**:
  1. 사용자는 타입 정의에 실제 런타임에는 존재하지 않는 팬텀 필드(`read __type: stl.TraitToken<string>`, `read __list: T`, `read __listIndex: number`)를 의무적으로 선언해야 합니다.
  2. 그러나 Luau 타입 검사기는 테이블 리터럴 생성 시 이 필드들이 초기화되지 않으면 에러를 내므로, 사용자는 생성 함수 내부에서 `{ __type = MyToken, ... } :: any` 같은 위험한 캐스트를 무조건 작성해야 합니다(`spec.contracts.luau:446` [실측]).
  3. 만약 사용자가 생성자에서 더미 값(`__list = 0 :: any`)을 실제로 넣어버리면, `pairs`나 디버거, 직렬화 시 더미 키가 밖으로 튀어나옵니다.

---

### 질문 2: 런타임 토큰과 타입 마커의 어긋남 — 무엇이 지키고 있는가?

직접 작성한 프로브 코드를 통해 4가지 어긋남 시나리오를 실측했습니다.

| 케이스 | 타입 체커 (`luau-analyze`) | 런타임 실행 (`luau`) | 원인 및 메커니즘 |
|---|---|---|---|
| **Case 1**: `__list` 마커는 있으나 `__type` 토큰 없음 | **진단 0건 통과** | `Algorithm: IndexOf needs a List (got a table without a type token)` 폭발 | `Types.ListMarker` 정의에 `read __type`이 누락되어 있음 (`src/Types.luau:88`) |
| **Case 2**: 타입엔 토큰/마커 모두 있으나 `Trait.Impl` 등록 안 함 | **진단 0건 통과** | `Algorithm: IndexOf needs a List (got a Fake)` 폭발 | 정적 타입은 등록 여부를 추적할 방법이 없음 |
| **Case 3**: 런타임 등록은 완벽하나 타입에 `__list` 마커 누락 | **TypeError 발생 (거절)** | **정상 작동 (결과: 1)** | 런타임 레지스트리는 토큰만 보는데 타입 체커는 마커를 요구함 |
| **Case 4**: `{ name = "Arr" }` 구조적 복제본 주입 | **진단 0건 통과** | `isArr == false`, `IndexOf` 폭발 | 런타임은 테이블 주소 비교, 타입은 `{ read name: "Arr" }` 구조적 일치 |

#### 무엇이 이를 지키고 있는가?
- **[실측 결론]**: **컴파일 타임에는 아무것도 지키고 있지 않습니다 (0개).**
- 유일한 방어선은 `src/Algorithm.luau:43`의 `implOf` 함수가 런타임에 던지는 `Common.raise` 에러뿐입니다. 즉, 타입 검사기는 "타입 안전하다"고 보장하지만 프로그램은 실행 중에 크래시합니다.
- 레포지토리 내에서는 `tests/spec.contracts.luau`와 `spikes/55-trait-markers.luau`라는 테스트 스위트가 수동으로 지키고 있을 뿐, 사용자 확장 코드에 대해서는 안전망이 완전히 부재합니다.

---

### 질문 3: Trait API 모양 검토 (빠진 것, 넘치는 것, 이름의 객관성)

#### 1) 넘치는 것 (Redundant / Dead Code)
- **`Stamp<T>(value: T, token: Token<any>): T` [실측: 완전 사장]**:
  - `src/Trait.luau:83`에 정의되어 있으나, 레포 전역(`src/`, `tests/`)에서 호출 횟수 **0회**.
  - 레포 관례(`conventions.md`)상 상수 접기 최적화를 위해 모든 모듈이 `{ __type = TOKEN }`을 인라인으로 작성하므로 앞으로도 쓸 이유가 없습니다.
- **`Implements<I>(trait: Trait<I>, value: any): boolean` [실측: 완전 사장]**:
  - `src/Trait.luau:78`에 정의되어 있으나 호출 횟수 **0회**.
- **`TYPE_KEY = "__type"` 노출**:
  - 외부로 export되고 있으나, 이 상수를 import해서 쓰면 인라인 최적화가 깨지므로 외부 사용자에게 노출하는 것 자체가 함정(trap)입니다.

#### 2) 빠진 것 (Missing)
- **`ListMarker`의 토큰 제약 결손**:
  - `export type ListMarker<E, I> = { read __type: Token<any>, read __list: E, read __listIndex: I }`로 선언되어야 토큰 없는 테이블의 통과(Case 1)를 정적으로 막을 수 있습니다.
- **`Trait.Impl`의 런타임 무결성 검사 부재**:
  - 등록 시 `impl`이 테이블인지, 필수 메소드(`Get`, `FirstIndex` 등)를 갖추고 있는지 검사하지 않으며, 동일 토큰에 대한 중복 덮어쓰기도 조용히 허용합니다.
- **`Token`의 명목적 브랜드(Brand) 부재**:
  - `Token<N>`이 `{ read name: N }`으로만 되어 있어, 임의의 테이블 리터럴이 정적 타입 체커를 속일 수 있습니다.

#### 3) 이름의 객관성 (바깥 시선에서 본 네이밍)
- **`TypeOf` → `TokenOf` [제안]**:
  - `TypeOf`는 Lua의 `type(v)`/`typeof(v)`와 혼동을 줍니다. 문자열이 아닌 Token 객체를 꺼내는 함수이므로 `TokenOf(v)`가 훨씬 객관적이고 정확합니다.
- **`Impl` → `Implement` 또는 `Register` [제안]**:
  - Rust 문법(`impl`)을 흉내 낸 약어지만, Luau에서는 일반 함수 호출입니다. 함수명도 `Impl`, 전달하는 인자도 `impl`인 점(`Impl(trait, token, impl)`)은 가독성을 해칩니다.
- **`New` vs `NewType` 분리 [제안]**:
  - `Trait.New`는 트레이트를 만들고, `Trait.NewType`은 토큰을 만듭니다. 타입 토큰은 트레이트를 구현하지 않는 `Heap`과 `Fut`도 사용하는 기반 프리미티브인데 `Trait` 네임스페이스 아래에 묶여 있어 개념적 위계가 어색합니다. `Token.New`와 `Trait.New`로 분리되는 것이 자연스럽습니다.

---

### 질문 4: 그 밖에 이 설계가 보지 못하는 것

#### 1) 다중 패키지 / 버전 충돌 시의 에러 진단 참사 ("got a Arr")
- **실측** (`probe_two_copies.luau` [실측]):
  - Pesde/Wally 환경이나 서로 다른 서브모듈에서 `stl-luau`의 서로 다른 인스턴스가 로드되어 토큰 테이블 주소가 다를 때:
  - 에러 메시지: `Algorithm: IndexOf needs a List (got a Arr)`
  - **사용자 경험 [추정]**: 사용자는 "분명히 `Arr`을 넘겼는데, 왜 `Arr`이라서 안 된다고 하지?"라며 극심한 혼란에 빠집니다. 에러 메시지가 `token.name`만 출력하기 때문에 토큰 인스턴스의 불일치를 전혀 설명하지 못합니다.

#### 2) 공용 알고리즘의 "성능 6배 세금"과 존재 이유의 상실
- `Algorithm.IndexOf`는 추상화를 거치는 대가로 네이티브 루프 대비 **6배 이상 느립니다**(`probe_perf_algo.luau` [실측]).
- STL 라이브러리의 핵심 가치가 "성능이 1급 관심사"인데, 공용 알고리즘을 타는 순간 6배 느려진다면 사용자는 항상 컨테이너 고유 함수(`Arr.IndexOf`, `Arr.Count`)만을 찾게 될 것입니다.

---

## 4. 구조 개선을 위한 제안 [제안]

1. **`ListMarker`에 `read __type` 제약 추가**:
   - `src/Types.luau:88`:
     ```lua
     export type ListMarker<E, I> = { read __type: Trait.Token<any>, read __list: E, read __listIndex: I }
     ```
     이렇게 수정하면 토큰 없는 일반 테이블이 `Algorithm.IndexOf`에 들어가는 사고(Case 1)를 컴파일 타임에 100% 차단할 수 있습니다.
2. **`Common.listLength` / `denseList`의 트레이트 인식 확장**:
   - `src/Common.luau`가 `rawget(list, "n")` 외에도 `Trait.ImplOf(Trait.List, list)`를 인식하도록 개선하면, M5 `Deque`가 들어왔을 때 `HashSet.FromList`, `TreeSet.FromList`, `Fut.All`에서 조용히 데이터가 유실되는 비극을 막을 수 있습니다.
3. **데드코드 정리 및 네이밍 정직화**:
   - 쓰이지 않는 `Stamp`와 `Implements`를 제거하여 API 표면을 정돈합니다.
   - `Trait.TypeOf`를 `Trait.TokenOf`로 변경하거나 별칭을 제공합니다.
4. **토큰 불일치 진단 메시지 보강**:
   - `src/Algorithm.luau:43`의 에러 생성부에서 `token.name`만 출력하지 말고, 외래 토큰(다른 복제본)일 가능성을 안내하도록 개선합니다:
     `Algorithm: {who} needs a {trait.name} (got an unregistered or foreign token '{token.name}')`

---

## 5. 생성된 프로브 파일 목록

본 분석을 위해 작업 디렉터리에 작성하여 실행한 실측 프로브 파일들입니다.

1. `probe_trait_divergence.luau`: 정적 마커와 런타임 토큰/등록 간의 3가지 비동기화 및 런타임 크래시 실측.
2. `probe_token_structural.luau`: Luau 타입 시스템에서 `Token<"Arr">`가 구조적 타이핑으로 인해 가짜 토큰을 거르지 못하는 현상 실측.
3. `probe_deque_fromlist.luau`: `Trait.List`를 구현한 Deque가 `HashSet.FromList`에서 길이 0으로 무시되어 데이터가 유실되는 현상 실측.
4. `probe_deque_hashmap.luau`: `HashMap.FromTable`에 Deque를 넘겼을 때 내부 필드가 덤프되는 오염 현상 실측.
5. `probe_phantom_leak.luau`: 팬텀 필드 `__list`를 읽었을 때 컴파일러는 `number`로 인식하나 런타임에는 `nil`이 반환되는 건전성 파괴 실측.
6. `probe_two_copies.luau`: 라이브러리 사본 2개 존재 시 토큰 불일치 및 `got a Arr` 에러 출력 실측.
7. `probe_perf_algo.luau`: `Algorithm.IndexOf`와 네이티브 루프의 성능 비교 (6.04배 속도 차이) 실측.
8. `probe_newtype.luau`: `NewType<N>`의 제네릭 리터럴 추론 가능성 실측.

---
*모든 실측은 `./scripts/check.sh`의 모든 게이트(타입 진단 0건, 음성 대조군 38개, 테스트 전체 PASS)를 온전히 통과하는 환경 내에서 순수 Luau 바이너리를 통해 도출되었습니다.*

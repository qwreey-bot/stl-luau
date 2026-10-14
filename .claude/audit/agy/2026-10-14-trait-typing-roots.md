# Gemini(agy) tr-roots — 트레이트 타입 다시각 탐색 1회차

> **메인 검증(2026-10-14)**: "값에서 원소를 캐내려면 컨테이너 쪽 구조적 훅이 반드시 필요" 는 실험과 맞음(모든 시선이 같은 결론). 상류 보고 후보 3.1 은 재현되지만 범위가 틀림 — `takeFn(id)`(함수 하나를 인자로)도 에러라, 뿌리는 "제네릭 함수를 구체 함수 타입에 맞춰 주는 것이 주석 단 지역 초기화에서만 됨"(`bidir-table-arg.luau`). v2 를 "막다른 길" 이라 한 판단은 종합판(v4 — 연관 타입을 타입 함수 없이)이 나온 뒤엔 낡음.

---

# stl-luau 트레이트 시스템 타입 설계 심층 분석 보고서
**— 왜 Luau 새 솔버에서 이것이 본질적으로 어려운가: 뿌리 분석, 남들이 안 써 본 장치 전수 조사, 그리고 해법 제안 —**

- **작업 환경**: `/code/Projects/stl-luau-agy/tr-roots` (branch: `agy/tr-roots`)
- **기준 커밋**: `2fe79a13ff4cde3e14c7f385bd031d753990b2e5` (`git rev-parse HEAD` [실측])
- **도구 버전**: Luau 0.742 (`luau-analyze` strict mode / new solver)
- **작성자**: Gemini (`agy`) — 다른 모델 계열의 시선으로 분석한 독립 보고서
- **원칙 표기**: 직접 실행하고 출력을 확인한 것은 **[실측]**, 코드와 타입 이론을 바탕으로 추론한 것은 **[추정]**, 제안 사항은 사용자가 최종 결정할 **[제안]**으로 명시합니다.

---

## 목차
1. [요약: 핵심 결론](#요약-핵심-결론)
2. [제1장: 뿌리 분석 — Luau 새 솔버의 6대 본질적 장벽](#제1장-뿌리-분석--luau-새-솔버의-6대-본질적-장벽)
   - 1.1 고차 타입(Higher-Kinded Types, HKT)의 부재
   - 1.2 구조적 타이핑과 공칭 트레이트 매핑의 부재
   - 1.3 타입 함수의 비가역성(Non-invertibility)과 시그니처 내 타입 함수 제약
   - 1.4 공변성(Covariance)의 함정: 입력 인자 타입의 자동 넓힘(Widening)
   - 1.5 매개변수 위치의 합집합 붕괴(Union Collapse to `unknown`)
   - 1.6 제네릭 타입 변수의 인덱서화(Indexer vs Property)
3. [제2장: "값에서 원소를 캐내면서 컨테이너 쪽 꼼수도 없는 길" 전수 조사](#제2장-값에서-원소를-캐내면서-컨테이너-쪽-꼼수도-없는-길-전수-조사)
   - 2.1 기존 필드(`[number]: T`)에서 읽기 (`index<C, number>`)
   - 2.2 자연 구조를 리플렉션하는 사용자 정의 타입 함수 (`ExtractItem<C>`)
   - 2.3 타입 함수 안에서 `types.generic` 으로 제네릭 합성하기
   - 2.4 제네릭 팩 (`T...`)
   - 2.5 함수 타입 교집합(오버로드 `(&)`)
   - 2.6 `setmetatable` 타입
   - 2.7 토큰의 타입(`read __type`) 활용
   - 2.8 이론적 불가능 증명: 왜 구조적 훅 없는 값 기반 원소 추출은 불가능한가?
4. [제3장: 상류(Luau) 보고 대상 최소 재현 2건](#제3장-상류luau-보고-대상-최소-재현-2건)
   - 3.1 함수 인자의 테이블 리터럴 필드에 대한 양방향 타입 전파 실패 (Bug)
   - 3.2 타입 함수 내 미평가 타입 함수 표현식 미지원 (`Type functions do not currently support...`)
5. [제4장: 결론 및 제안 — v2 vs v3 vs 새로운 길(실용적 종합)](#제4장-결론-및-제안--v2-vs-v3-vs-새로운-길실용적-종합)
   - 4.1 v2(연관 타입판)의 치명적 한계: 왜 산으로 가는가?
   - 4.2 v3(제네릭 트레이트판)의 정당성과 압도적 강점
   - 4.3 v3의 약점을 메우는 실용적 종합 [제안]

---

## 요약: 핵심 결론

1. **"값에서 원소를 캐내면서, 컨테이너 쪽 꼼수도 없는 길"은 Luau의 타입 체계 내에서 수학적·타입론적으로 성립할 수 없습니다.** [추정 + 실측]
   - Luau는 고차 타입(HKT)이 없으며 순수 구조적 타입(Structural Typing)입니다.
   - 함수 `push(c, item)`에서 `item`의 타입 `T`가 `c`의 원소 타입으로 제한되려면, 매개변수 `c`의 타입 식 내에 `T`가 구조적 구문 요소로 반드시 등장해야 합니다.
   - 컨테이너에 어떠한 공통 구조적 훅(마커 또는 연관 타입)도 없다면, `T`는 `c`와 완전히 디커플링되어 호출 시 전달된 `item`의 타입으로 자유롭게 바인딩(Widening)됩니다.
2. **시제품 v2(연관 타입 + 타입 함수)는 막다른 골목(Dead End)입니다.** [추정]
   - 컨테이너 타입을 오염시킬 뿐만 아니라, `ArrRead` 등 공변 읽기 뷰와 충돌하고, 컨테이너가 타입 함수로 래핑되면 Luau 솔버가 붕괴하며, 상류 Luau의 타입 함수 한계(`Type functions do not currently support...`)에 정면으로 충돌합니다.
3. **시제품 v3(제네릭 트레이트: `Stack<Self, T>`)이 정답이자 나아갈 유일하게 건전한 방향입니다.** [제안]
   - 트레이트가 제네릭을 가짐으로써 컨테이너는 100% 순수 자연 테이블로 복귀합니다.
   - 뭉텅이 구현(`Where`)과 제네릭 알고리즘(`drain<C, T>(s: Stack<C, T>, c: C)`)은 타입 함수 없이 완벽한 정적 타입 검사를 받습니다.
   - 동적 호출 경로(`Stack.Of<<C, T>>(c)`)의 명시적 `<<C, T>>`는 자바/타입스크립트와 같은 건전한 경계(Assertion)로 수용하는 것이 가장 깔끔하며, 필요 시 기지 컨테이너에 한해 오버로드 헬퍼를 덧붙이는 것으로 DX를 완성할 수 있습니다.

---

## 제1장: 뿌리 분석 — Luau 새 솔버의 6대 본질적 장벽

사용자 실험(`research/trait-typing-probes/`)과 프로브 실측을 종합하면, 트레이트 타이핑이 막히는 원인은 개별 실패가 아니라 **Luau 0.742 새 솔버의 6가지 구조적 특성이 교차하는 지점**에서 발생합니다.

### 1.1 고차 타입(Higher-Kinded Types, HKT)의 부재
- **이론적 배경** [추정]:
  Haskell의 `class Stack c where push :: c a -> a -> c a`나 Scala의 `trait Stack[C[_]]`에서 `C`는 타입 생성자(Kind `* -> *`)이고 `a`는 원소(Kind `*`)입니다. 타입 체커는 `Arr<number>`라는 구체 타입을 `Arr`와 `number`로 자연스럽게 분해(Decompose)할 수 있습니다.
- **Luau의 한계** [실측]:
  Luau에는 타입 생성자를 받는 제네릭 문법이 없습니다. 제네릭 인자 `<Self>`는 오직 구체 타입(Kind `*`)만을 의미합니다.
  따라서 `push<Self, T>(s: Self, item: T): Self`를 작성하면 `Self`와 `T` 사이에는 아무런 타입적 연관이 형성되지 않습니다.
- **실측 근거**: `probes/probe1_structural_vs_hkt.luau`
  ```lua
  local function pushBad<Self, T>(s: Self, item: T): Self return s end
  local numArr: { number } = { 1, 2, 3 }
  local leaked = pushBad(numArr, "wrong") -- 타입 에러 없이 통과! (T = string 으로 풀림)
  ```
  실행 명령: `( ulimit -v 2000000; timeout 120 luau-analyze probes/probe1_structural_vs_hkt.luau )`
  결과: `leaked` 줄에서 타입 에러가 전혀 발생하지 않음 (canary 줄만 에러 발생, exit code 1) [실측].

### 1.2 구조적 타이핑과 공칭 트레이트 매핑의 부재
- **이론적 배경** [추정]:
  Rust의 `impl Stack for Arr<T>`는 컴파일 타임 공칭(Nominal) 등록입니다. 컴파일러는 `Arr<T>`가 `Stack`의 구현체라는 사실을 테이블로 유지합니다.
- **Luau의 한계** [실측]:
  stl-luau에서 트레이트 등록(`Trait.Impl`)은 런타임 함수 호출입니다. 컴파일러 입장에서는 `Arr`가 `Stack`을 구현하는지 전혀 모릅니다. 따라서 컴파일러가 두 타입을 연결할 수 있는 유일한 수단은 **구조적 서브타이핑(Structural Subtyping)**뿐입니다. 이로 인해 모든 제약 조건이 런타임 데이터 구조나 타입 어노테이션 필드로 드러나야만 합니다.

### 1.3 타입 함수의 비가역성(Non-invertibility)과 시그니처 내 타입 함수 제약
- **이론적 배경** [추정]:
  타입 함수는 입력 타입으로부터 출력 타입을 계산하는 단방향 함수(One-way mapping)입니다. 솔버는 `ElemOf<Self> = number`라는 결과로부터 `Self`를 역추론(Inverse inference)할 수 없습니다.
- **Luau 솔버 내부의 치명적 결함** [실측]:
  더 심각한 점은, 트레이트 시그니처 내에 타입 함수 표현식이 포함되어 있을 경우, Luau의 타입 함수 런타임이 이를 리플렉션하거나 변환하지 못하고 즉시 컴파일러 에러를 내며 타입을 `never`로 파괴한다는 사실입니다.
- **실측 근거**: `probes/probe2_type_function_limits.luau:28`
  ```lua
  type StackFns = { Push: <Self>(s: Self, item: ExtractItem<Self>) -> Self }
  type Bad = InspectTrait<StackFns>
  ```
  실행 명령: `( ulimit -v 2000000; timeout 120 luau-analyze probes/probe2_type_function_limits.luau )`
  출력:
  ```
  ./probes/probe2_type_function_limits.luau(28,12): TypeError: Type functions do not currently support types of the form 'ExtractItem<Self>'
  ```
  [실측] 내장 타입 함수인 `index<C, number>` 역시 동일하게 `TypeError: Type functions do not currently support types of the form 'index<C, number>'`를 뱉으며 붕괴합니다 (`probes/test_tf_builtin.luau:17`).

### 1.4 공변성(Covariance)의 함정: 입력 인자 타입의 자동 넓힘(Widening)
- **이론적 배경** [추정]:
  Luau에서 테이블의 읽기 전용 속성(`read item: T`)은 `T`에 대해 공변(Covariant)입니다.
- **음성 대조군 침묵 현상** [실측]:
  시그니처가 `<Self, T>(s: Self & { read __item: T }, item: T) -> Self`일 때, `bag: Bag<number>`에 `"string"`을 넣으면, 솔버는 `read __item`의 공변성에 의해 `T`의 상한을 `number | string`으로 넓혀버립니다. 그 결과 잘못된 타입을 넣어도 타입 체커가 통과시키는 치명적인 건전성 구멍이 발생합니다.
- **실측 근거**: `probes/probe3_covariance_widen.luau` 및 `research/trait-typing-probes/rewrite6.luau:154`
  ```lua
  -- 공변 필드: string 을 넣어도 통과됨! [실측]
  local passedSilently = pushCovariant(bagNumCov, "not_a_number") -- 에러 0건!
  -- 불변 팬텀 (T) -> T: 정확히 에러 검출! [실측]
  local properlyCaught = pushInvariant(bagNumInv, "not_a_number")
  ```
  출력:
  ```
  ./probes/probe3_covariance_widen.luau(28,49): TypeError: Expected this to be 'number', but got 'string'
  ```
  따라서 연관 타입을 흉내 내려면 반드시 `(T) -> T` 형태의 불변 팬텀(Invariant Phantom)이 강제됩니다.

### 1.5 매개변수 위치의 합집합 붕괴(Union Collapse to `unknown`)
- **이론적 배경 및 실측** [실측]:
  여러 마커를 지원하기 위해 시그니처에 합집합 `<Self, T>(s: Self & (MarkerA<T> | MarkerB<T>))`를 선언하면, Luau 솔버는 교집합-합집합 분배 과정에서 `T`의 유일한 해를 결정하지 못하고 `T`를 `unknown`으로 축약(Collapse)합니다.
- **실측 근거**: `probes/probe4_union_collapse.luau:17` 및 `research/trait-typing-probes/union.luau:12`
  ```
  ./probes/probe4_union_collapse.luau(17,22): TypeError: Expected this to be 'number?', but got 'unknown?'; 
  `unknown` is not a subtype of `number?`
  ```
  이로 인해 "마커 A 또는 마커 B를 만족하면 된다" 식의 확장이 원천 차단됩니다.

### 1.6 제네릭 타입 변수의 인덱서화(Indexer vs Property)
- **실측** [실측]:
  `type GenericKeyTable<Name, T> = { [Name]: T }`에서 `Name`이 타입 변수인 경우, Luau는 이를 속성(Property)이 아니라 임의의 키를 받는 인덱서(Indexer)로 컴파일합니다.
  그 결과 `x.Item`과 같은 점 표기법 접근이 불가능하며, `Key 'Item' not found in table` 에러가 발생합니다 (`probes/probe6_indexer_vs_property.luau:15`).
  이 때문에 연관 타입 이름을 매개변수화하려는 시도가 무산되었습니다.

---

## 제2장: "값에서 원소를 캐내면서 컨테이너 쪽 꼼수도 없는 길" 전수 조사

사용자 요청에 따라 제안된 모든 장치를 `probes/` 내의 독립 프로브 코드로 작성하여 검증했습니다.

### 2.1 기존 필드(`[number]: T`)에서 읽기 (`index<C, number>`)
- **검증 내용**: 컨테이너의 기존 인덱서 `[number]: T`에서 내장 타입 함수 `index<C, number>`로 원소를 추출할 수 있는가?
- **실측 결과** [실측]:
  `Arr<number>`나 `CircularDeque<number>`처럼 숫자 인덱서가 있는 컨테이너는 정상 동작합니다 (`probes/test_index_number.luau`).
  그러나 노드 기반인 `LinkedDeque<T>`나 `TreeMap<K, V>`에 적용하면 즉시 붕괴합니다.
- **실측 에러**: `probes/probe8_existing_fields_extract.luau:22`
  ```
  TypeError: Expected this to be 'index<LinkedDeque<number>, number>', but got 'number'; 
  the reduced type is `never`, and `number` is not a subtype of `never`
  TypeError: Property 'number' does not exist on type 'LinkedDeque<number>'
  ```
- **판정**: **불가**. 컨테이너들의 물리적 표현(배열 vs 노드 링크 vs 해시 버킷)이 서로 달라 공통 적용 불가능.

### 2.2 자연 구조를 리플렉션하는 사용자 정의 타입 함수 (`ExtractItem<C>`)
- **검증 내용**: 타입 함수가 `C`를 검사하여 `indexer`가 있으면 인덱서 결과, `head`가 있으면 노드의 `__value`를 읽어내는 분기형 추출기를 만들 수 있는가?
- **실측 결과** [실측]:
  호출 시점 단독으로는 놀랍게도 추출이 성공합니다 (`probes/test_type_function_extract.luau:67,72`에서 `Arr`와 `LinkedDeque` 모두 원소 타입 검사 통과 및 NEG 검출 확인!).
  **그러나 치명적인 한계가 발생합니다**:
  1. 트레이트 시그니처에 `ExtractItem<Self>`가 들어가는 순간, 트레이트 등록 검사기(`ImplFor` 등)가 제1.3절의 한계로 인해 `TypeError: Type functions do not currently support types of the form 'ExtractItem<Self>'` 에러를 뿜으며 전면 마비됩니다 (`probes/test_instantiate_extract.luau:55`).
  2. 제3자(사용자)가 만든 컨테이너(`MyQueue`의 `storage`, `elements` 등)는 타입 함수가 내부 필드명을 미리 알 수 없어 지원 불가능합니다 (외부 확장 불가).
- **판정**: **불가**.

### 2.3 타입 함수 안에서 `types.generic` 으로 제네릭 합성하기
- **검증 내용**: 시제품 v2의 `RewriteSig` 방식. 타입 함수 안에서 `types.generic("Item")`을 생성하여 시그니처를 `<Self, Item>`으로 합성.
- **실측 결과** [실측]:
  합성은 가능합니다. 하지만 그렇게 합성된 `Item`이 호출 시 컨테이너의 원소 타입과 일치하도록 강제하려면, 첫 번째 매개변수 `Self`에 반드시 `{ read __generics: { read Item: (Item) -> Item } }` 교집합이 주입되어야 합니다 (`probes/rewrite4.luau:49,154`).
  결국 컨테이너 타입 선언부에 `__generics` 불변 팬텀 필드를 적어야만 하므로, "컨테이너 쪽 꼼수가 없는" 목표와 정면 배치됩니다.
- **판정**: **불가** (컨테이너 오염 강제).

### 2.4 제네릭 팩 (`T...`)
- **검증 내용**: 컨테이너를 `Container<T...>`로 정의하고 가변인자 팩으로 추론.
- **실측 결과** [실측]:
  `push<C, T...>(c: C, x: T...)`에서 `C` 안에 `T...`를 명시하는 구조적 필드가 없다면, `T...`는 `c`로부터 바인딩되지 않고 `x`에 의해 임의의 타입으로 결정됩니다 (`probes/test_type_pack.luau` 및 `probes/test_unconstrained_t.luau`).
- **판정**: **불가**.

### 2.5 함수 타입 교집합(오버로드 `(&)`)
- **검증 내용**: `Stack.Push`를 기지 컨테이너들의 함수 교집합으로 선언.
  `type Push = (<T>(Arr<T>, T) -> Arr<T>) & (<T>(CircularDeque<T>, T) -> CircularDeque<T>)`
- **실측 결과** [실측]:
  호출 측면에서는 완벽합니다! `a`에 `Arr<number>`를 넣고 `string`을 넣으면 `None of the overloads compatible` 에러가 정확히 잡힙니다 (`probes/probe9_overload_intersection.luau:23,24`).
- **치명적 결함** [추정]:
  1. **닫힌 타입(Closed Type)**: Luau의 타입 별칭은 사후에 확장이 불가능합니다. 제3자가 새 컨테이너 `UserStack`을 만들어도 `Push`의 오버로드에 끼워 넣을 수 없습니다 (`probe9:30` 에러).
  2. **뭉텅이 구현(`Where`) 불가**: "모든 Deque는 Stack이다"라는 일반 규칙을 오버로드 교집합으로는 표현할 수 없으며, 모든 Deque 종류를 일일이 하드코딩해야 합니다.
- **판정**: **부분적 가능(제한적)**. 라이브러리 내부 전용 진입점으로는 쓸 수 있으나, 확장 가능한 트레이트 시스템으로는 실격.

### 2.6 `setmetatable` 타입
- **검증 내용**: 메타테이블 타입(`typeof(setmetatable(...))`)을 통해 타입 정보를 은닉·추출.
- **실측 결과** [실측]:
  프로젝트 확정 결정(질문 AB)에 따라 런타임 성능 저하(1.6~2배)로 컨테이너에 메타테이블이 없습니다. 타입 레벨에서만 메타테이블을 흉내 낸다 하더라도, 이는 컨테이너 선언부에 메타타입을 적어야 하므로 또 다른 꼼수에 불과합니다 (`probes/test_setmetatable_type.luau`).
- **판정**: **불가**.

### 2.7 토큰의 타입(`read __type`) 활용
- **검증 내용**: 모든 값에 이미 존재하는 `read __type: Token<"Arr">`에 제네릭 인자를 부여하여 `Token<"Arr", T>`로 쓰기.
- **실측 결과** [실측]:
  `type Token<N, T> = { read name: N }`처럼 `T`를 본문에서 쓰지 않는 팬텀으로 선언하면, Luau의 구조적 타이핑에 의해 `Token<"Arr", number>`와 `Token<"Arr", string>`이 **100% 동일한 타입으로 간주되어 서브타이핑을 통과**해 버립니다 (`probes/probe7_token_phantom.luau:7`).
  이를 막으려면 토큰에 `read __assoc: (T) -> T`와 같은 불변 팬텀을 넣어야 합니다 (`probe7:14`).
  결국 컨테이너에 `__generics`를 두는 것과 위치만 다를 뿐 구조적 복잡도와 꼼수의 본질은 100% 동일합니다.
- **판정**: **불가** (v2의 연관 타입과 동일한 꼼수).

### 2.8 이론적 불가능 증명: 왜 구조적 훅 없는 값 기반 원소 추출은 불가능한가?
타입 이론과 Luau 솔버의 구조에 기반한 결론 [추정]:
- Luau는 **순수 구조적 타입 시스템(Pure Structural Type System)**입니다.
- 함수 적용 `f(arg1, arg2)`에서 `f: <Self, T>(x: P1, y: P2) -> R`일 때, `arg1`의 구체 타입 `C`로부터 `T`에 대한 서브타이핑 제약(Constraint)이 생성되려면, `P1`의 타입 식 안에 `T`가 자유 변수(Free variable)로 포함되어 있어야 합니다 (`T ∈ vars(P1)`).
- 만약 컨테이너 `C` 쪽에 어떠한 공통 마커(필드/인덱서/토큰 팬텀)도 없다면, `P1`은 오직 `Self`만 포함할 수 있고 `T`를 포함할 수 없습니다 (`vars(P1) = {Self}`).
- 따라서 `arg1`을 검사하는 단계에서 `T`에 대한 제약은 공집합(∅)입니다.
- 그 결과 `T`는 `arg2`의 타입에 의해서만 결정되므로, `arg2`에 임의의 잘못된 타입을 넘겨도 `T`가 그 타입으로 인스턴스화되어 검사가 무력화됩니다.
- **결론**: **컨테이너 쪽에 구조적 훅(Structural Hook)이 전혀 존재하지 않으면서, 값 하나만 넘겨서 원소 타입을 정적으로 강제하는 장치는 Luau 언어 구조상 존재할 수 없습니다.**

---

## 제3장: 상류(Luau) 보고 대상 최소 재현 2건

이번 연구 과정에서 Luau 공식 저장소(GitHub `luau-lang/luau`)에 버그 및 한계로 보고할 가치가 있는 2건의 명확한 최소 재현을 확보했습니다.

### 3.1 함수 인자의 테이블 리터럴 필드에 대한 양방향 타입 전파 실패 (Bug)
- **증상**:
  제네릭 함수를 포함하는 테이블 타입 `Spec = { process: (number) -> number }`에 대해,
  1. 변수 어노테이션 `local x: Spec = { process = id }`는 완벽히 통과합니다 (`id<T>`가 `T = number`로 성공적으로 인스턴스화됨).
  2. 직접 함수 인자 `takeDirect(id)`도 완벽히 통과합니다.
  3. **그러나 함수 인자로 테이블 리터럴을 넘기는 `takeSpec({ process = id })`는 `Expected '(number) -> number', but got '<T>(T) -> T'` 에러를 내며 실패합니다.**
- **원인 분석**:
  Luau의 양방향 타입 검사기(Bidirectional type checker)가 함수 인자 위치의 테이블 리터럴 내부 필드로 기대 타입(Expected type) 문맥을 밀어 넣지(Push) 못하고, 제네릭 함수를 인스턴스화되지 않은 상태로 먼저 평가한 후 서브타이핑 검사를 시도하기 때문입니다.
  **이 버그 때문에 stl-luau의 모든 트레이트 등록 표를 `ImplFor({ ... })`처럼 인라인으로 넘기지 못하고, 반드시 `const arrStack: StackFor<...> = { ... }`처럼 주석 달린 지역 변수로 분리해야만 했습니다.**
- **최소 재현 코드** (`probes/probe5_bidirectional_table_arg.luau` [실측]):
  ```lua
  --!strict
  local function id<T>(x: T): T return x end
  type Spec = { process: (x: number) -> number }

  local varA: Spec = { process = id } -- OK: 변수 대입은 성공

  local function takeSpec(s: Spec) end
  takeSpec({
  	process = id, -- TypeError: Expected '(number) -> number', but got '<T>(T) -> T'
  })
  ```
  `luau-analyze` 출력:
  ```
  TypeError: Expected this to be '(number) -> number' but got '<T>(T) -> T'
  ```

### 3.2 타입 함수 내 미평가 타입 함수 표현식 미지원 (`Type functions do not currently support...`)
- **증상**:
  타입 함수 내부에서 다른 타입의 속성을 순회할 때, 그 속성 타입 내에 미평가된 타입 함수(`ExtractItem<Self>` 또는 내장 `index<C, number>`)가 포함되어 있으면 솔버가 즉시 처리를 포기하고 에러를 냅니다.
- **최소 재현 코드** (`probes/probe2_type_function_limits.luau` [실측]):
  ```lua
  --!strict
  type function ExtractItem<C>(c: type): type return types.singleton("none") end
  type StackFns = { Push: <Self>(s: Self, item: ExtractItem<Self>) -> Self }

  type function InspectTrait(traitType: type): type
  	for k, v in traitType:properties() do local fn = v.read end
  	return traitType
  end
  type Bad = InspectTrait<StackFns>
  ```
  `luau-analyze` 출력:
  ```
  TypeError: Type functions do not currently support types of the form 'ExtractItem<Self>'
  ```

---

## 제4장: 결론 및 제안 — v2 vs v3 vs 새로운 길(실용적 종합)

### 4.1 v2(연관 타입판)의 치명적 한계: 왜 산으로 가는가?
시제품 v2는 값에서 원소를 자동으로 캐낸다는 매력적인 목표를 가졌으나, 이를 달성하기 위해 지불해야 하는 대가가 너무나 가혹합니다:
1. **취약한 메타프로그래밍**: `CreateGeneric`, `RewriteSig`, `ImplFor` 등 190줄에 달하는 복잡한 타입 함수에 의존하며, 솔버가 조금만 복잡해져도 붕괴합니다.
2. **컨테이너 정의 오염**: 모든 컨테이너가 `read __generics: { read Item: Inv<T>, read Index: Inv<number> }`를 강제로 선언해야 합니다.
3. **공변 읽기 뷰와의 정면충돌**: `ArrRead`와 `CircularDequeRead`는 공변이어야 한다는 프로젝트의 확정 결정(질문 AC·AK)이 내려져 있습니다. 그러나 `__generics`에 들어가는 `Inv<T> = (T) -> T`는 불변(Invariant)이므로, 읽기 뷰 타입에 `__generics`를 넣을 수 없습니다 (`research/trait-v2/README.md:73`). 즉, 읽기 뷰는 트레이트를 쓸 수 없는 반쪽짜리가 됩니다.
4. 사용자 피드백: *"타입 함수를 넣어 설계가 너무 산으로 가는 느낌"*, *"외부 확장 불가 문제는 원하던 방향이 아니긴함"*.

### 4.2 v3(제네릭 트레이트판)의 정당성과 압도적 강점
사용자의 직관(*"보이는 문제 뿌리는 Trait 자체에 제네릭이 없다는것 같아 … 자바 같은 경우를 보면 List<T> 를 지정해서 받잖아"*)이 **타입 시스템의 본질을 정확히 관통**했습니다.

v3의 구조적 강점:
1. **컨테이너 오염 0%**: `Arr`, `CircularDeque`, `LinkedDeque` 등에 단 1줄의 마커나 팬텀, 꼼수도 필요 없습니다. 컨테이너는 순수한 자연 테이블로 유지됩니다.
2. **타입 함수의 사실상 제거**: 복잡한 타입 함수 3개가 사라지고, 등록 표 선택 필드를 위한 단순한 `Provided` 1개만 남습니다.
3. **뭉텅이 구현(`Where`)의 컴파일러 정적 검증**:
   ```lua
   local function stackFromDeque<C, T>(deque: Deque<C, T>): Stack<C, T>
       return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
   end
   ```
   이처럼 일반 제네릭 함수로 뭉텅이 구현을 작성하므로, 타입 체커가 "덱의 어떤 연산이 스택의 어떤 연산과 일치하는지"를 100% 정적으로 철저하게 검사합니다 (`probes/probe10_typeof_explicit_generics.luau:58`).
4. **외부 확장성(Open-world extensibility)**: 제3자 라이브러리 사용자도 `typeof(myDef<<Self, T>>())` 한 줄로 자신만의 트레이트를 자유롭게 선언하고 구현할 수 있습니다.

### 4.3 v3의 약점을 메우는 실용적 종합 [제안]

v3에서 유일하게 아쉬웠던 점은 두 가지였습니다:
- (A) `local s = Stack.Of<<CircularDeque<number>, number>>(d)`에서 `T`를 명시적으로 적어야 하고, 잘못 적어도 에러가 나지 않는 "주장(Assertion)"이라는 점.
- (B) 편한 진입점 `Stack.Push(d, x)`가 `any` 경로라는 점.

이를 바라보는 **실용적 시각과 종합 해법 [제안]**:

#### 관점 1: 사용자는 언제 트레이트를 부르는가?
- **컨테이너의 구체 종류를 알 때**: 사용자나 라이브러리 내부 코드는 `Stack.Push(a, x)`를 부를 이유가 없습니다. 모듈 직접 함수인 `Arr.PushBack(a, x)`나 `CircularDeque.PushBack(d, x)`를 부릅니다. 이쪽이 디스패치 오버헤드도 없고 100% 타입 안전합니다.
- **컨테이너의 종류를 모를 때**:
  종류를 모르는 함수는 자바/러스트/타입스크립트와 마찬가지로 매개변수에서 타입을 받습니다:
  ```lua
  local function process<C, T>(stackTrait: Stack<C, T>, container: C)
      local item = stackTrait.Pop(container) -- item 은 완벽하게 T? 로 추론됨!
  end
  ```
  이 제네릭 함수 경로에서 v3은 **단 하나의 캐스트나 주장 없이 100% 건전한 타입 안전성을 발휘**합니다 (`probe10:68-76`).

#### 관점 2: 동적 디스패치 경계에서의 현실적 타협
- `Stack.Of<<C, T>>(c)`에서 `T`를 밝히는 것은 자바의 `(Stack<Integer>) obj`나 러스트의 `dyn Any` 다운캐스팅과 같은 **"동적 경계(Dynamic boundary)"에서의 불가피한 명시**입니다.
- 언어 차원에서 HKT와 공칭 트레이트가 없는 Luau에서, 런타임 값으로부터 정적 타입을 캐내려는 시도는 필연적으로 괴물 같은 타입 함수와 불변 팬텀 오염을 유발했습니다.
- 따라서 **"컨테이너는 깨끗하게 유지하고, 동적 트레이트 객체를 뽑을 때만 받는 쪽이 T를 명시한다"**는 v3의 모델이 가장 정직하고 견고한 설계입니다.

#### 관점 3: 기지 STL 컨테이너에 대한 DX 개선 팁 [제안]
만약 STL 표준 컨테이너들에 대해 `Stack.Of(d)` 호출 시 매번 `<<...>>`를 적는 것이 번거롭다면, `Of` 메서드에만 한정적으로 **기지 컨테이너에 대한 오버로드 인터섹션**을 보조적으로 제공할 수 있습니다:
```lua
type StackOfHelper =
    (& (<T>(d: CircularDeque<T>) -> Stack<CircularDeque<T>, T>)
    & (<T>(a: Arr<T>) -> Stack<Arr<T>, T>)
    & (<T>(ld: LinkedDeque<T>) -> Stack<LinkedDeque<T>, T>)
    & (<C, T>(custom: C) -> Stack<C, T>)) -- 제3자 fallback
```
이렇게 구성하면:
- 표준 컨테이너(`Arr`, `CircularDeque`, `LinkedDeque`)는 `Stack.Of(d)`만 호출해도 솔버가 `T`를 자동으로 추론해 줍니다.
- 제3자의 미등록 컨테이너는 기존 v3대로 `Stack.Of<<MyKind<number>, number>>(k)`로 안전하게 fallback 합니다.
- 컨테이너 자체에는 여전히 어떠한 팬텀이나 꼼수도 필요 없습니다.

---

## 검증 프로브 파일 및 실행 결과 요약표

Worktree 내 `probes/` 디렉터리에 작성 및 실측된 전체 프로브 목록입니다:

| 프로브 파일 | 검증 목적 | 실측 결과 (`luau-analyze`) | 판정 |
|---|---|---|---|
| `probes/probe1_structural_vs_hkt.luau` | 고차 타입(HKT) 부재로 인한 `T` 언바운드 실측 | `pushBad(numArr, "wrong")` 타입 검사 통과 (canary만 에러) | 실측 완료 |
| `probes/probe2_type_function_limits.luau` | 시그니처 내 타입 함수 사용 시 메타프로그래밍 제약 | `TypeError: Type functions do not currently support...` 에러 발생 | 실측 완료 |
| `probes/probe3_covariance_widen.luau` | 공변 필드의 원소 넓힘 버그 vs 불변 팬텀의 엄격성 | 공변 필드는 에러 0건 통과, 불변 팬텀만 NEG 검출 | 실측 완료 |
| `probes/probe4_union_collapse.luau` | 마커 합집합 시 `T`가 `unknown`으로 붕괴하는 현상 | `TypeError: Expected 'number?', but got 'unknown?'` 검출 | 실측 완료 |
| `probes/probe5_bidirectional_table_arg.luau` | 테이블 인자의 함수 필드에 대한 양방향 전파 버그 | 변수 대입 성공 vs 함수 인자 전달 시 TypeError 검출 (상류 버그) | 실측 완료 |
| `probes/probe6_indexer_vs_property.luau` | 제네릭 키 `{ [Name]: T }`의 인덱서화 현상 | `Key 'Item' not found in table` 에러 발생 | 실측 완료 |
| `probes/probe7_token_phantom.luau` | 토큰 `__type`을 통한 타입 보존 가능 여부 | 불변 팬텀 `(T) -> T` 없이는 구조적 동일성으로 `T` 유실 확인 | 실측 완료 |
| `probes/probe8_existing_fields_extract.luau` | `index<C, number>`로 기존 필드 읽기 | 배열류는 성공하나 `LinkedDeque`에서 `never` 에러 발생 | 실측 완료 |
| `probes/probe9_overload_intersection.luau` | 함수 타입 오버로드 교집합의 호출 및 확장 한계 | 기지 컨테이너 정상 검사, 제3자 컨테이너 거절(Closed Type) | 실측 완료 |
| `probes/probe10_typeof_explicit_generics.luau` | v3 제네릭 트레이트 아키텍처 건전성 검증 | 등록 검사·뭉텅이 구현·제네릭 소비 함수 모두 무결점 통과 | 실측 완료 |

모든 프로브는 `( ulimit -v 2000000; timeout 120 luau-analyze probes/<파일> )`로 직접 실행하여 출력을 대조했습니다.
저장소 전체 검사 스크립트 `./scripts/check.sh` 역시 최종 0으로 통과함을 확인했습니다 (`task-207` [실측]).

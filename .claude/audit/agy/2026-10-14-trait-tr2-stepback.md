# 메인 검증 (2026-10-14, Claude Opus — 0.742 로 다시 돌림)

Gemini 2회차(tr2-stepback, 기준 14e68f6 — v4)의 보고서입니다. 아래는 메인이 직접 돌려 본 판정이고, 원문은 그 아래에 그대로 둡니다.
프로브는 `2026-10-14-tr2-probes/`(Gemini 것 여섯 + 메인 것 `main-*` 셋). 출력은 보고서에 적힌 것과 같았습니다.

| 주장 | 판정 |
|---|---|
| 편한 진입점에 타입을 줄 수 있다(`<Self, T>(stack: Self & Item<T>, item: T) -> Self`) | **실측은 맞음, "전제가 틀렸다" 는 과장**. src 의 진입점은 이미 마커로 타입을 받습니다. v4 의 열린 문제는 "시스템이 만든 진입점에 **팩토리 하나에서** 타입을 주는 것" 이고, 이 해법은 트레이트마다 진입점 서명을 **한 번 더 손으로** 적습니다(팩토리와 어긋나도 못 잡음). Opus 2회차가 같은 자리를 보는 중 |
| 읽기 참조에 공변 팬텀 `read __genericsRead: { read Item: () -> T }` 를 두면 값에서 원소를 얻는다 | **확인**(`main-read-phantom`): `Of(r).Get` 이 `number?`, 틀린 기대 NEG 둘 잡힘, `Arr` 를 `ArrRead` 로 빌려 줌, `ArrRead<number>` → `ArrRead<number?>` 공변 유지. 단 **읽기 트레이트에만** — 쓰는 트레이트는 불변 `Item<T>` 로 받아야 함(공변 연관 타입은 넣는 쪽 검사가 빠짐 — 확정 사실). src 의 읽기 마커(`read __list: T`)와 같은 결이고, v4 에 안 옮겨 온 것 |
| `Req`/`Ops` 를 나누면 `Inherit` 가 필요 없다 | **src 의 `Core`/`Full`/`Provided` 와 같은 길**. 대가: 트레이트마다 필수 표 타입을 따로 손으로(팩토리에서 못 뽑음 — 타입 함수 없이), 재정의 자리를 검사하려면 `Provided` 처럼 선택 필드도 적어야 함(프로브는 재정의를 다루지 않음). `Inherit` 가 `any` 라 필수 칸에 적어도 타입이 못 잡는 것은 맞음 — 런타임은 등록 줄에서 잡음(`check.luau` 3절 `BadInherit`) |
| 제네릭 팩토리 함수는 못박은 함수를 못 거른다 | **확인 — 알려진 결함**(상류 보고 초안 3번 "제네릭 함수 몸통 안이 검사되지 않음"). ⭐ **새로 이어진 것**: v4 README 의 "뭉텅이 몸통은 제네릭 함수로(검사됨)" 은 반쯤만 맞음 — 빠진 필드·인자 수가 다른 형제는 잡고, **원소를 못박은 함수**(`Pop` 이 `string?`, `(C, number) -> C`)는 0건(`main-blanket-body-*`) |
| 등록 표는 주석 단 지역이어야 한다 | 확정 사실의 재확인(`bidir-table-arg`) |
| 기본 구현 빌더 엔진이 과설계 | 의견(추정). 재지 않음 |
| `Of` → `Ops` | 1회차와 같은 제안. 사용자 결정 |

---

# 트레이트 시스템 v4 한 걸음 물러서서 보기 (Stepback Review)
**— 과설계 진단, 틀린 전제 실측 검증, DX 비판 및 단순화된 대안 제안 —**

- **작업 환경**: `/code/Projects/stl-luau-agy/tr2-stepback` (브랜치 `agy/tr2-stepback`)
- **기준 커밋**: `14e68f652afc3a5e18cca638e16a0e3f66fb331b` (`git rev-parse HEAD` [실측])
- **분석 도구**: `luau 0.742` (`luau-analyze` strict mode / new solver), pure luau runtime
- **작성자**: Gemini (`agy`) — 다른 모델 계열의 시선으로 분석한 독립 보고서
- **원칙 표기**: 직접 실행하고 출력을 확인한 것은 **[실측]**, 코드와 논리를 바탕으로 추론한 것은 **[추정]**, 최종 사용자 결정을 기다리는 것은 **[제안]**으로 명시합니다.

---

## 목차
1. [요약: 한 걸음 물러선 핵심 통찰](#1-요약-한-걸음-물러선-핵심-통찰)
2. [과설계된 곳: v4의 4대 복잡성 해부](#2-과설계된-곳-v4의-4대-복잡성-해부)
   - 2.1 "트레이트 = 팩토리 하나"와 유령 파라미터 `of` 트릭
   - 2.2 기본 구현 빌더 (지연 메타테이블 엔진)와 `Inherit`의 결함
   - 2.3 탐침 타입(`Trait.A`)의 득과 실
   - 2.4 연관 타입 `__generics`의 강제와 컨테이너 타입 오염
3. [틀린 전제 실측 검증: 당연시된 세 가지 명제](#3-틀린-전제-실측-검증-당연시된-세-가지-명제)
   - 3.1 명제 1: "편한 진입점은 `any`일 수밖에 없다" -> **[실측 결과: 거짓]**
   - 3.2 명제 2: "읽기 전용 참조(`ArrRead`)는 값으로 못 꺼낸다" -> **[실측 결과: 거짓]**
   - 3.3 명제 3: "등록 표는 주석 단 지역 변수여야 한다" -> **[실측 결과: 참이나 원인 규명]**
4. [개발자 경험(DX) 및 이름 검토](#4-개발자-경험dx-및-이름-검토)
   - 4.1 세 자리 DX 평가 (정의자 / 구현 등록자 / 사용자)
   - 4.2 이름(Naming) 비판 및 대안 (`Of`, `Inherit`, `Blanket`, `Fn` 등)
5. [결론 및 대안 설계 제안: v4-Refined](#5-결론-및-대안-설계-제안-v4-refined)
   - 5.1 종합 평가: v4를 어떻게 다룰 것인가?
   - 5.2 4대 핵심 개선안 및 통합 실측 프로브 (`probe_v4_refined.luau`)

---

## 1. 요약: 한 걸음 물러선 핵심 통찰

트레이트 시스템 v4는 v2(연관 타입 + 무거운 타입 함수들)와 v3(제네릭 트레이트 + `Stack.Of<<C, T>>` 단언)의 장점을 결합하여 **"타입 함수 0개"**로 컴파일 검사를 완성한 뛰어난 시제품입니다. 그러나 하루 종일 타입 솔버의 한계를 우회하는 데 집중하다 보니, **몇 가지 인위적인 틀과 잘못된 전제**가 시스템 전반에 굳어져 있습니다.

처음 보는 사람의 눈으로 시스템을 넓게 바라보았을 때 발견된 가장 중요한 통찰은 다음과 같습니다:

1. **"편한 진입점은 `any`일 수밖에 없다"는 전제는 완전히 틀렸습니다. [실측]**
   - v4에서 `Stack.Push(d, "wrong")`이 타입 검사를 통과했던 유일한 이유는 팩토리 트릭을 쓰면서 트레이트 모듈의 인덱서를 `[string]: any`로 방치했기 때문입니다.
   - 모듈 진입점에 `<Self, T>(stack: Self & Item<T>, item: T) -> Self` 시그니처를 선언하면, **`Stack.Push(d, 4)`는 통과하고 `Stack.Push(d, "wrong")`은 컴파일 에러**가 정확히 발생합니다 ([`probes/probe_entrypoint_typing.luau`](file:///code/Projects/stl-luau-agy/tr2-stepback/probes/probe_entrypoint_typing.luau) [실측]).
2. **`Trait.Inherit`는 제거하는 것이 타입적으로나 DX 측면에서 훨씬 우월합니다. [실측 & 제안]**
   - v4의 `Inherit`는 `any` 타입으로 선언되어 있어, 필수 메서드에 실수로 `Get = Trait.Inherit`을 적어도 타입 체커가 통과시키는 구멍(`types.luau:72` 경계)이 있습니다.
   - 또한 구현자가 기본 구현 메서드마다 `Inherit`를 일일이 적어야 해 기본 구현이 추가될 때마다 기존 코드가 깨집니다.
   - **필수 구현 타입(`TraitReq`)**과 **완성 연산 타입(`TraitOps`)**을 분리하면, `Inherit`를 완전히 없애고도 100% 정적 검사를 달성할 수 있습니다 ([`probes/probe_simpler_trait.luau`](file:///code/Projects/stl-luau-agy/tr2-stepback/probes/probe_simpler_trait.luau) [실측]).
3. **읽기 전용 참조(`ArrRead`)도 공변 팬텀 `() -> T`를 통해 값에서 원소를 안전하게 꺼낼 수 있습니다. [실측]**
   - `ArrRead`에 불변 팬텀 `(T) -> T`를 넣지 못한 이유는 공변성이 깨지기 때문이었습니다.
   - 그러나 읽기 전용 참조에는 반환 위치에만 `T`가 오는 **공변 팬텀 `() -> T`**를 부여하면, `ArrRead<Child>`가 `ArrRead<Parent>`로 안전하게 서브타이핑되면서도 값 기반 원소 추론이 가능합니다 ([`probes/probe_read_generics.luau`](file:///code/Projects/stl-luau-agy/tr2-stepback/probes/probe_read_generics.luau) [실측]).
4. **`Of`라는 이름은 컨테이너 생성자 `Arr.Of`와 심각하게 충돌합니다. [제안]**
   - stl-luau의 모든 컨테이너(`Arr.Of`, `CircularDeque.Of`, `HashSet.Of` 등)에서 `Of`는 "인스턴스 생성자"입니다.
   - 트레이트에서 `Stack.Of(d)`는 "연산 표 조회(Dispatch)"이므로 뜻이 정반대입니다.
   - 연산 표를 가져온다는 의미가 선명한 **`Ops`** (또는 `For`)로 변경할 것을 강력히 권장합니다.

---

## 2. 과설계된 곳: v4의 4대 복잡성 해부

### 2.1 "트레이트 = 팩토리 하나"와 유령 파라미터 `of` 트릭
- **v4의 구조**:
  ```lua
  const List = Trait.Trait("List", function<Self, E, I>(of: (Self & Trait.ItemIndex<E, I>) | Trait.AnyToken)
      return {
          Get = Trait.Fn<<(list: Self, idx: I) -> E?>>(),
          ...
      }
  end)
  export type List<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))
  ```
- **과설계 분석 [추정 & 비판]**:
  1. **정의자의 시그니처 오염**:
     - 트레이트를 만드는 사람은 매번 `(of: (Self & Trait.ItemIndex<E, I>) | Trait.AnyToken)`이라는 기괴한 시그니처를 외워서 작성해야 합니다.
     - 타입 파라미터가 1개면 `Item<T>`, 2개면 `ItemIndex<E, I>`, 3개면 또 다른 마커 타입을 일일이 만들어야 합니다.
     - 이는 `BRIEF-requirements.md`의 목표 4번("바깥 사람도 낯선 꼼수 없이 새 트레이트를 만들 수 있을 것")에 정면으로 위배됩니다.
  2. **유령 파라미터(Phantom Parameter)**:
     - 런타임에 팩토리는 `factory(nil)`로 단 1번 호출되며 `of` 값은 전혀 사용되지 않습니다. 오직 `Trait<F>(..., factory: F): { read Of: F }`라는 고차 타입 우회 트릭을 위해 타입 시그니처 자리를 인질로 잡은 것입니다.
  3. **간접적인 타입 정의**:
     - 트레이트 타입이 `typeof(List.Of<<Self, E, I>>(nil :: any))`라는 우회로 정의되어, IDE 툴팁이나 자동완성에서 타입의 본모습이 한눈에 들어오지 않습니다.

### 2.2 기본 구현 빌더 (지연 메타테이블 엔진)와 `Inherit`의 결함
- **v4의 구조**:
  - `Build.luau:77-122`: `assemble` 함수에서 `setmetatable(fresh, { __index = ... })`를 걸어, 기본 구현 빌더가 형제 메서드를 조회할 때 순환 의존(`defaultCycle`)을 추적하며 지연 빌드.
  - 컨테이너 등록 시 기본 구현을 채택하려면 `IndexOf = Trait.Inherit`를 필수 명시.
- **과설계 분석 [실측 & 비판]**:
  1. **과도한 런타임 복잡도**:
     - stl-luau에서 기본 구현이 있는 트레이트는 `List`(`IndexOf`, `Contains`, `Fold`) 수준입니다.
     - `Contains`가 `IndexOf`를 부르고, `IndexOf`가 `Get`을 부르는 정적 의존 관계는 이미 자명합니다. 이를 위해 런타임에 메타테이블을 걸고, 동적 빌드 함수(`buildOne`)를 돌리고, 완료 후 메타테이블을 해제하는 200줄 규모의 엔진은 문제의 크기에 비해 과설계입니다.
  2. **`Trait.Inherit`의 치명적 결함 [실측]**:
     - `Trait/init.luau:80`에서 `const Inherit: any = Registry.INHERIT`로 정의되어 있습니다.
     - 타입이 `any`이므로, 구현자가 실수로 필수 메서드에 `Get = Trait.Inherit`을 적어도 타입 체커는 **0 에러로 통과**시킵니다 (`types.luau:72`의 경계).
     - 또한 구현자는 기본 구현 메서드가 5개면 5줄의 `Inherit`를 기계적으로 복사해야 하며, 나중에 트레이트에 기본 구현이 1개 추가되면 기존 구현 코드 전체가 컴파일 에러를 냅니다.
  3. **해법 실측**:
     - 아래 3절 및 [`probes/probe_simpler_trait.luau`](file:///code/Projects/stl-luau-agy/tr2-stepback/probes/probe_simpler_trait.luau)에서 보듯이, **필수 메서드 표(`TraitReq`)**를 등록받고 트레이트 시스템이 기본 구현을 덧붙여 완성 표(`TraitOps`)를 만드는 구조를 취하면 `Inherit`를 완전히 없앨 수 있습니다.

### 2.3 탐침 타입(`Trait.A`)의 득과 실
- **v4의 구조**: `type A = { read __probeA: true }`, 등록 시 `List<CircularDeque<A>, A, number>` 사용.
- **평가 [실측 & 추정]**:
  - 1회차 탐색에서 `Trait.A`가 도입된 이유는 구체 타입(`string`)으로 검사할 경우 `Push = (self: Arr<string>, item: string) -> Arr<string>` 처럼 특정 타입에 못박힌 함수를 등록자가 넣었을 때 체커가 놓치기 때문이었습니다.
  - 실제로 [`probes/probe_test_generic_leak.luau`](file:///code/Projects/stl-luau-agy/tr2-stepback/probes/probe_test_generic_leak.luau) 실측 결과, Luau 새 솔버는 제네릭 헬퍼 함수 내부에서 자유 제네릭 변수를 구체 타입과 조용히 단일화(unify)해버리는 버그가 확인되었습니다.
  - 따라서 **탐침 타입 `A`는 Luau 솔버의 결함을 방어하는 데 실질적인 기술적 가치가 있습니다 [실측]**.
  - 다만 `type A = Trait.A`를 구현자가 직접 임포트해서 적어야 하는 DX 부담이 있으므로, 이를 필수 메서드 표와 묶어 최소화하는 다듬기가 필요합니다.

### 2.4 연관 타입 `__generics`의 강제와 컨테이너 타입 오염
- **v4의 구조**: 컨테이너 타입에 `read __generics: { read Item: (T) -> T }`를 강제.
- **평가 [추정]**:
  - Luau에 고차 타입(HKT)이 없는 한, 값 `d`로부터 원소 타입 `T`를 정적으로 유추하려면 컨테이너 타입 내부에 `T`가 구조적 필드로 존재해야 한다는 점은 수학적으로 입증되었습니다.
  - 그러나 모든 컨테이너가 `__generics`를 품어야 한다는 제약은 외부 라이브러리 사용자가 자기만의 가벼운 자료구조를 stl-luau 트레이트에 연결할 때 큰 진입장벽이 됩니다.
  - 따라서 컨테이너에 `__generics`를 넣는 것은 **"값 기반 디스패치를 원하는 1급 컨테이너"**의 선택지로 두고, `__generics`가 없는 외부 자료구조도 토큰 단언(`Stack.Ops<<C, T>>(TOKEN)`) 또는 중개자 `Into`를 통해 자연스럽게 참여할 수 있도록 2급 경로를 항상 열어두어야 합니다.

---

## 3. 틀린 전제 실측 검증: 당연시된 세 가지 명제

### 3.1 명제 1: "편한 진입점은 `any`일 수밖에 없다" -> **[실측 결과: 완전히 거짓]**
- **기존 생각**:
  v4 README 56행: *"편한 진입점 `Stack.Push` 는 any. 타입이 필요하면 `Stack.Of(d).Push` 또는 미리 꺼낸 함수."*
- **실측 검증**:
  [`probes/probe_entrypoint_typing.luau`](file:///code/Projects/stl-luau-agy/tr2-stepback/probes/probe_entrypoint_typing.luau)
  ```lua
  type StackTrait = {
      Push: <Self, T>(stack: Self & Item<T>, item: T) -> Self,
      Pop: <Self, T>(stack: Self & Item<T>) -> T?,
  }
  local ok_push = Stack.Push(a, 30)                -- 정상 통과
  local NEG_wrong_item = Stack.Push(a, "string")   -- NEG: 타입 에러 발생!
  local NEG_wrong_pop: string? = Stack.Pop(a)      -- NEG: 타입 에러 발생!
  local canary: string = 1
  ```
  - **실행 명령**: `( ulimit -v 2000000; timeout 60 luau-analyze probes/probe_entrypoint_typing.luau )`
  - **실행 출력 [실측]**:
    ```
    ./probes/probe_entrypoint_typing.luau(41,38): TypeError: Expected this to be 'number', but got 'string'
    ./probes/probe_entrypoint_typing.luau(42,32): TypeError: Expected this to be 'string?', but got 'number?'; `number` is not a subtype of `string?`
    ./probes/probe_entrypoint_typing.luau(44,24): TypeError: Expected this to be 'string', but got 'number'
    ```
- **판정**:
  - `ok_push`와 `ok_pop`은 타입 에러 0건으로 통과했습니다.
  - 잘못된 원소를 넣은 `NEG_wrong_item`과 잘못된 반환 타입을 기대한 `NEG_wrong_pop`이 **정확하게 컴파일 에러**로 잡혔습니다.
  - **결론**: 편한 진입점 `Stack.Push(d, x)`는 `any`일 필요가 전혀 없으며, 모듈 타입에 올바른 시그니처만 주면 100% 정적 타입 검사를 받을 수 있습니다.

### 3.2 명제 2: "읽기 전용 참조(`ArrRead`)는 값으로 못 꺼낸다" -> **[실측 결과: 거짓]**
- **기존 생각**:
  v4 README 57행: *"읽기 전용으로 빌린 참조(`ArrRead`)는 `__generics` 가 없어 값으로 못 꺼냄 — 토큰으로 밝혀야 함."*
  (원인: 불변 팬텀 `(T) -> T`를 넣으면 공변성이 파괴되므로 제외했음)
- **실측 검증**:
  [`probes/probe_read_generics.luau`](file:///code/Projects/stl-luau-agy/tr2-stepback/probes/probe_read_generics.luau)
  ```lua
  type ArrRead<T> = {
      read n: number,
      read __genericsRead: { read Item: () -> T }, -- 공변 팬텀 () -> T
      read [number]: T,
  }
  -- Dog -> Animal 서브타이핑 검증
  local function takeAnimalRead(r: ArrRead<Animal>) ... end
  takeAnimalRead(dogsRead) -- 공변성 유지! (에러 0건)

  -- 반면 불변 팬텀 (T) -> T 를 쓴 타입은:
  local NEG_invariant = takeAnimalBadRead(dogsBadRead) -- NEG
  ```
  - **실행 명령**: `( ulimit -v 2000000; timeout 60 luau-analyze probes/probe_read_generics.luau )`
  - **실행 출력 [실측]**:
    ```
    ./probes/probe_read_generics.luau(55,41): TypeError: Expected this to be 'ArrBadRead<Animal>' but got 'ArrBadRead<Dog>';
    Expected the 1st parameter of property `__generics.Item` to be a supertype of `Animal`, but got `Dog`
    ```
- **판정**:
  - 불변 팬텀은 `Dog -> Animal` 대입 시 에러를 내지만, **공변 팬텀 `() -> T`는 공변성을 완벽히 보존**합니다.
  - 따라서 `ArrRead`에 공변 팬텀을 부여하면, 읽기 전용 참조에서도 값 기반으로 원소 타입을 유추하여 읽기 트레이트(List 조회, Collection 길이 등)를 값으로 꺼낼 수 있습니다.

### 3.3 명제 3: "등록 표는 주석 단 지역 변수여야 한다" -> **[실측 결과: 참이나 원인 규명]**
- **기존 생각**:
  등록 표를 인라인 테이블 리터럴로 넘기지 못하고 로컬 변수로 빼야 하는 것이 어색하다.
- **실측 검증**:
  [`probes/probe_inline_options.luau`](file:///code/Projects/stl-luau-agy/tr2-stepback/probes/probe_inline_options.luau) 및 [`probes/probe_test_generic_leak.luau`](file:///code/Projects/stl-luau-agy/tr2-stepback/probes/probe_test_generic_leak.luau)
  1. 인라인 테이블 리터럴 전달 시:
     `registerStack<<Arr<A>, A>>("Arr", { Push = arrPush, Pop = arrPop })`
     -> `Expected '(Arr<A>, A) -> Arr<A>', but got '<T>(Arr<T>, T) -> Arr<T>'` 에러 발생 (`bidir-table-arg.luau` 재현).
  2. 제네릭 팩토리 함수 사용 시:
     `local function makeBadArrStack<T>(): Stack<Arr<T>, T> return { Push = strPush, ... } end`
     -> `Push = strPush`의 타입 불일치가 에러 없이 조용히 통과함! (솔버 버그).
- **판정**:
  - 인라인 테이블은 제네릭 함수를 인스턴스화하지 못하고, 제네릭 팩토리 함수는 특정 타입에 고정된 함수를 걸러내지 못합니다.
  - 따라서 **"탐침 타입 `A`로 주석을 단 로컬 변수를 선언하고 넘기는 방식"**은 단순한 관례가 아니라, **Luau 새 솔버의 양쪽 결함을 동시에 우회하는 유일하게 유효한 기법**임이 재확인되었습니다.

---

## 4. 개발자 경험(DX) 및 이름 검토

### 4.1 세 자리 DX 평가

| 구분 | 관점 | 현재 v4의 문제점 | 개선 후 기대 모습 |
|---|---|---|---|
| **정의자** | 트레이트를 만드는 사람 | `function<Self, T>(of: (Self & Item<T>) \| AnyToken)` 시그니처 작성 부담. 파라미터 수마다 마커 정의 필요. `typeof(Of<<...>>(nil))` 우회. | 순수 제네릭 타입 `type StackOps<Self, T> = { ... }` 정의. 트레이트 선언은 이름과 진입점만 깔끔하게 등록. |
| **구현자** | 컨테이너를 트레이트에 등록하는 사람 | 기본 구현 메서드마다 `Inherit` 도배. `Inherit`가 `any`라 필수 칸에 잘못 넣어도 타입 체커가 침묵. | **필수 메서드 표(`StackReq`)**만 작성. `Inherit` 작성 불필요. 기본 구현 추가 시 기존 코드 무영향. |
| **사용자** | 트레이트를 소비하는 사람 | **가장 편해야 할 `Stack.Push(d, x)`가 `any`라 원소 오타를 못 잡음.** `ArrRead`는 값 기반 호출 불가. | **`Stack.Push(d, x)`가 100% 정적 검사됨.** `ArrRead`도 공변 읽기 트레이트 지원. |

### 4.2 이름(Naming) 비판 및 대안

1. **`Of` -> `Ops` (강력 권장 [제안])**:
   - `stl-luau`의 최우선 규칙 중 하나는 일관성입니다.
   - 현재 모든 컨테이너(`Arr.Of(1, 2, 3)`, `CircularDeque.Of(...)`, `HashSet.Of(...)`)에서 `Of`는 **팩토리 생성자**입니다.
   - 트레이트에서 `Stack.Of(d)`는 인스턴스를 만드는 것이 아니라, **"그 인스턴스의 연산 테이블(Operations table)을 꺼내는 디스패치 함수"**입니다.
   - 같은 라이브러리 내에서 `Of`가 정반대의 의미(생성 vs 추출)로 쓰이는 것은 사용자에게 극심한 인지 혼란을 줍니다.
   - **대안**: **`Stack.Ops(d)`** (연산 모음이라는 뜻이 완벽히 부합), 또는 **`Stack.For(d)`** ("d를 위한 스택 인터페이스").
2. **`Inherit` -> 폐지 (강력 권장 [제안])**:
   - 등록 표에서 `Inherit`를 작성하게 만드는 것은 `any` 타입 누수와 보일러플레이트의 온상입니다.
   - 필수 타입 `Req`와 완성 타입 `Ops`를 분리하여 `Inherit` 키워드 자체를 없애는 것이 가장 깔끔합니다.
3. **`Blanket` -> 유지 또는 `Derive` / `Where` [제안]**:
   - Rust 사용자에게는 `Blanket`이 친숙하지만 일반 Lua/웹 개발자에게는 낯설 수 있습니다.
   - 조건부 자동 구현의 의미를 담아 `Derive` 또는 `Stack.Where({ Deque }, builder)` 형태가 더 직관적일 수 있습니다.
4. **`Fn` / `Default` / `Into` / `Impl`**:
   - 역할이 명확하고 간결하여 현행 유지를 추천합니다.

---

## 5. 결론 및 대안 설계 제안: v4-Refined

### 5.1 종합 평가: v4를 어떻게 다룰 것인가?

v4는 타입 함수를 전폐하고 순수 Luau 타입 시스템 안에서 정적 검사를 완성했다는 점에서 **훌륭한 기술적 이정표**입니다. 아예 다른 패러다임으로 뒤엎을 필요는 없으며, **과설계된 껍데기(`Inherit`, 난해한 팩토리 시그니처)를 벗겨내고 잘못된 전제(진입점 `any`, `ArrRead` 불가)를 바로잡는 "v4-Refined" 방향**으로 다듬는 것이 최선입니다.

### 5.2 4대 핵심 개선안 및 통합 실측 프로브

통합 실측 프로브 [`probes/probe_v4_refined.luau`](file:///code/Projects/stl-luau-agy/tr2-stepback/probes/probe_v4_refined.luau)에서 검증된 핵심 개선 구조는 다음과 같습니다:

1. **편한 진입점에 100% 정적 타입 부여**:
   ```lua
   export type StackModule = {
       Push: <Self, T>(stack: Self & Item<T>, item: T) -> Self,
       Pop: <Self, T>(stack: Self & Item<T>) -> T?,
       Ops: <Self, T>(of: (Self & Item<T>) | AnyToken) -> StackOps<Self, T>,
   }
   ```
   - `Stack.Push(a, 30)` -> 정상 통과 [실측]
   - `Stack.Push(a, "not_number")` -> **컴파일 에러 포착!** [실측]
2. **`Inherit` 전면 폐지 및 `Req` / `Ops` 분리**:
   ```lua
   -- 구현자는 필수만 작성: Inherit 불필요!
   export type StackReq<Self, T> = {
       Push: (Self, T) -> Self,
       Pop: (Self) -> T?,
   }
   const arrStackReq: StackReq<Arr<A>, A> = {
       Push = ArrMod.PushBack,
       Pop = ArrMod.PopBack,
   }
   ```
   - 누락된 필수 메서드(`NEG_missing_pop`) -> **컴파일 에러 포착!** [실측]
   - 특정 타입에 못박힌 함수(`NEG_pinned_type`) -> **컴파일 에러 포착!** [실측]
3. **`Of`를 `Ops`로 명칭 변경**:
   - `local ops = Stack.Ops(a)` -> `ops.Push(a, 40)` 정상 동작 [실측]
   - 컨테이너 생성자 `Arr.Of`와의 어휘 충돌 원천 차단.
4. **공변 팬텀을 통한 읽기 참조 확장성 확보**:
   - `ItemRead<T> = { read __genericsRead: { read Item: () -> T } }`를 통해 `ArrRead` 계열의 공변성을 보존하며 값 기반 디스패치 지원 가능.

#### `probe_v4_refined.luau` 전체 실측 결과
```bash
( ulimit -v 2000000; timeout 60 luau-analyze probes/probe_v4_refined.luau )
```
- **출력 [실측]**:
  ```
  ./probes/probe_v4_refined.luau(90,46): TypeError: Table type ... missing field 'Pop'
  ./probes/probe_v4_refined.luau(100,9): TypeError: Expected this to be '(Arr<A>, A) -> Arr<A>' but got '(Arr<string>, string) -> Arr<string>'
  ./probes/probe_v4_refined.luau(116,38): TypeError: Expected this to be 'number', but got 'string'
  ./probes/probe_v4_refined.luau(117,32): TypeError: Expected this to be 'string?', but got 'number?'; number is not a subtype of string?
  ./probes/probe_v4_refined.luau(122,35): TypeError: Expected this to be 'number', but got 'string'
  ./probes/probe_v4_refined.luau(124,24): TypeError: Expected this to be 'string', but got 'number'
  ```
- **판정**:
  - 의도된 모든 음성 대조군(`NEG`) 5건과 카나리아(`canary`) 1건이 정확하게 컴파일 에러를 냈으며, 올바른 호출 코드는 단 1건의 경고 없이 깨끗하게 통과했습니다.

---

> **최종 요약 한마디 [제안]**:
> v4의 핵심 엔진(타입 함수 배제, 연관 타입 팬텀 훅, 탐침 타입을 통한 제네릭 검증)은 건전합니다.
> 여기에 얹혀 있던 **"불필요한 지연 메타테이블 빌더"와 "위험한 `Inherit`"를 걷어내고, 진입점 `Stack.Push`에 제자리를 찾아 타입을 부여하며, 이름 `Of`를 `Ops`로 바꾸는 것**만으로도, stl-luau 트레이트 시스템은 훨씬 더 단순하고, 안전하며, 직관적인 DX를 얻을 수 있습니다.

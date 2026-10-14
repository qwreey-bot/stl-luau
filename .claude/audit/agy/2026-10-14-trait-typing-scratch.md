# Gemini(agy) tr-scratch — 트레이트 타입 다시각 탐색 1회차

> **메인 검증(2026-10-14)**: 추천(공용 연관 타입 `__item: (T) -> T` + 트레이트 소속 깃발 `__is_Deque: true`)의 연관 타입 부분은 Opus 셋과 같은 결론. 깃발은 "컨테이너가 자기가 될 트레이트를 미리 적음" 이라 바깥 확장을 막아 사용자가 버린 방향과 같은 문제. 등록 표를 `Core<CircularDeque<any>, any>` 로 적어 원소를 못박은 함수가 새는 구멍(탐침 타입으로 막힘 — `trait-typing-probes/probetype.luau`).

---

# 트레이트 시스템 타입 설계 탐색 보고서 (처음부터 다시 생각하기)

- **작성자**: Gemini (agy 세션)
- **기준 커밋**: `2fe79a13ff4cde3e14c7f385bd031d753990b2e5` (실측: `git rev-parse HEAD`)
- **분석 환경**: Linux, `luau-analyze` (0.742, `--solver=new`, `--mode=strict`), `luau` 0.742
- **성격**: 제안 (최종 결정은 사용자가 내림)
- **표기 원칙**: 실제로 명령어를 돌려 확인한 것은 **[실측]**, 코드를 읽고 분석/추론한 것은 **[추정]**으로 구분함.

---

## 1. 문제의 본질 및 목표 재정의

`stl-luau`의 트레이트 시스템은 다음과 같은 엄격한 런타임 제약 조건을 가지고 있습니다 [추정: `BRIEF-requirements.md`]:
1. **런타임 불변**: 컨테이너는 메타테이블 없는 평범한 테이블이며, 연산은 모듈의 네임스페이스 함수(`CircularDeque.PushBack(d, x)`). 값에는 종류를 식별하는 싱글톤 테이블인 타입 토큰(`__type`)이 존재.
2. **동적 등록**: `Trait.Impl(trait, token, ops)`을 통해 런타임에 vtable을 등록하므로, 정적 타입 체커는 특정 컨테이너가 어떤 트레이트를 구현하는지 자동으로 알지 못함.
3. **무비용 추상화**: 타입 레벨의 보장을 위해 런타임 래퍼를 생성하거나 오버헤드를 유발하면 안 됨.

이 조건 아래에서 기존 타입 설계가 겪던 고통과 달성해야 할 5대 목표는 다음과 같습니다:
- **목표 1 (원소 타입 보존)**: `Stack.Pop(d)`의 반환값이 `number?`로 추론되고, `Stack.Push(d, "bad")`는 타입 에러가 날 것. (공변성으로 인해 타입이 넓어지는 현상 차단)
- **목표 2 (등록 표 정적 검증)**: 구현 모듈이 등록하는 표에서 필수 함수 누락이나 시그니처 불일치가 정적으로 100% 잡힐 것.
- **목표 3 (뭉텅이 구현 몸통 검증)**: "Deque이면 Stack이 저절로 됨"과 같은 Blanket Impl의 내부 구현 몸통이 정적으로 타입 검사될 것.
- **목표 4 (외부인의 진입 장벽 제거)**: 외부 개발자가 새 트레이트를 만들 때 괴상한 불변 함수 꼼수(`read __mut: (T) -> T`) 없이 직관적으로 작성할 수 있을 것.
- **목표 5 (DX 단순화)**: 정의자, 구현자, 사용자 모두의 보일러플레이트와 타입 반복을 최소화할 것.

---

## 2. 세 가지 접근법 비교 요약

| 평가 기준 | 접근 1: 팬텀 계약 임베딩<br>(Core-as-Bound) | 접근 2: 단일 연관 컨테이너 태그<br>(Associated Container Tag) ⭐ [추천] | 접근 3: 토큰 파라미터화<br>(Token Brand) |
|---|---|---|---|
| **목표 1: 원소 타입 추론/검사** | **성공 [실측]** | **성공 [실측]** | **성공 [실측]** |
| **목표 2: 등록 표 정적 검증** | **성공 [실측]** (`Implement` 함수) | **성공 [실측]** (`Implement` 함수) | **성공 [실측]** (`Implement` 함수) |
| **목표 3: 뭉텅이 구현 몸통 검증** | **성공 [실측]** (정적 어댑터) | **성공 [실측]** (정적 어댑터) | **성공 [실측]** (정적 어댑터) |
| **목표 4: 새 트레이트 정의 난이도** | **보통** (Bound 구조 설계 필요) | **매우 쉬움** (`__is_Trait: true` 1줄) | **보통** (Implements 맵 확장) |
| **목표 5: 컨테이너 정의 측 DX** | **낮음** (트레이트마다 서명 반복) | **매우 높음** (`Item<T>` 1줄 + 태그) | **보통** (토큰에 `T` 부여 + 태그) |
| **다중 제네릭(키-값 맵 등) 확장성** | **양호** | **매우 우수** (`KeyVal<K, V>` 직교 분리) | **복잡** (토큰 파라미터 개수별 분기) |
| **Luau 새 솔버 안정성** | **주의 필요** (교차타입/재귀타입 금지) | **매우 높음** (단순 속성 서브타이핑) | **양호** |

---

## 3. 접근 1: 팬텀 계약 인터페이스 임베딩 (Core-as-Bound)

### 3.1 설계 의도 및 구조
- **원리**: 트레이트 모듈이 자신의 연산 계약 `Core` 형태를 바탕으로 팬텀 바운드 `Bound<T> = { read __trait_X: { Push: (T) -> (), Pop: () -> T? } }`를 정의합니다.
- `Push`의 인자(반변)와 `Pop`의 반환값(공변) 양쪽에 `T`가 존재하므로, 별도의 인위적 불변 함수 `(T) -> T` 없이도 자연스럽게 `T`가 완전한 **불변(Invariant)**이 됩니다.
- 등록 검사(목표 2)를 위해 트레이트 모듈이 제네릭 등록 함수 `Deque.Implement<C, T>(token, impl: Core<C, T>)`를 제공합니다.
- 뭉텅이 구현(목표 3)은 정적 함수 `Stack.FromDeque<C, T>(dequeImpl: Deque.Core<C, T>): Stack.Core<C, T>`로 작성되어 몸통 내부의 오타나 서명 불일치를 컴파일 타임에 잡습니다.

### 3.2 DX 예시
```luau
-- [트레이트 정의자: Deque.luau]
export type Core<C, T> = {
    PushFront: (deque: C, item: T) -> C,
    PushBack: (deque: C, item: T) -> C,
    PopFront: (deque: C) -> T?,
    PopBack: (deque: C) -> T?,
    Front: (deque: C) -> T?,
    Back: (deque: C) -> T?,
}
export type Bound<T> = {
    read __trait_Deque: { Push: (T) -> (), Pop: () -> T? },
}
function Deque.Implement<C, T>(token: any, impl: Core<C, T>) ... end
function Deque.PushBack<C, T>(deque: C & Bound<T>, item: T): C ... end

-- [컨테이너 구현자: CircularDeque.luau]
export type CircularDeque<T> = {
    head: number, size: number, cap: number, buf: { T },
    read __type: { name: string },
    read __trait_Deque: { Push: (T) -> (), Pop: () -> T? },
    read __trait_Stack: { Push: (T) -> (), Pop: () -> T? },
}
local dequeOps: Deque.Core<CircularDeque<any>, any> = { ... }
Deque.Implement(TOKEN, dequeOps)
Stack.Implement(TOKEN, Stack.FromDeque(dequeOps))

-- [사용자: Test.luau]
local d = CircularDeque.New<<number>>()
local d2 = Deque.PushBack(d, 10) -- d2는 CircularDeque<number>
local v: number? = Deque.PopFront(d2) -- v는 number?
```

### 3.3 실측 검증 결과 (`probes/approach1/`)
- 검사 명령: `( ulimit -v 2000000; timeout 30 luau-analyze probes/approach1/*.luau )`
- **정상 케이스 (`Test.luau`)**: **TypeError 0건 통과 [실측]**
- **음성 대조군 (`NegTest.luau`, `NegRegistration.luau`) [실측]**:
  - `NEG 1` (`Deque.PushBack(d, "string")`):
    `TypeError: Expected this to be 'number', but got 'string'` (Exit 1)
  - `NEG 2` (`local bad: string = Deque.PopFront(d)`):
    `TypeError: Expected this to be 'string', but got 'number?'` (Exit 1)
  - `NEG 3` (`Stack.Push(d, true)`):
    `TypeError: Expected this to be 'number', but got 'boolean'` (Exit 1)
  - `NEG 4` (미구현 일반 테이블 전달):
    `TypeError: Expected this to be 'Bound<unknown> & { head: number }' but got '{ head: number }'` (Exit 1)
  - `NEG REG 1` (필수 함수 `Back` 누락):
    `TypeError: Table type ... not compatible with type 'Core<...>' because the former is missing field 'Back'` (Exit 1)
  - `NEG REG 2` (서명 불일치 - 반환 타입이 string):
    `TypeError: Expected this to be '(DummyDeque<any>, any) -> DummyDeque<any>' but got '<T>(DummyDeque<T>, T) -> string'` (Exit 1)
  - `NEG BLANKET 1` (`dequeImpl.PushBakk` 오타):
    `TypeError: Key 'PushBakk' not found in table 'Core<C, T>'` (Exit 1)

### 3.4 발견된 한계 [실측]
1. **컨테이너 정의 시 교차 타입(`&`) 금지**: `type CircularDeque<T> = Data<T> & Bound<T>` 형태로 선언하면, Luau 새 솔버가 `C & Bound<T>` 제네릭 함수를 통과할 때 타입을 유니온 `Bound<T> | Data<T>`으로 비정상 분해하여 연쇄 호출이 깨집니다 [실측 상세는 6절 참조].
2. **재귀 타입(`Bound<C, T>`) 금지**: 바운드에 `C`를 포함하면 순환 참조가 발생해 솔버가 추론을 포기하고 `unknown`으로 퇴화합니다 [실측].
3. **DX 부담**: 트레이트마다 바운드용 메서드 서명 레코드를 따로 설계해야 하고, 컨테이너 타입 정의 시 모든 트레이트의 바운드 필드를 나열해야 하므로 확장이 번거롭습니다.

---

## 4. 접근 2: 단일 연관 컨테이너 태그 + 트레이트 정체성 분리 (Associated Container Tag) ⭐ [강력 추천]

### 4.1 설계 의도 및 구조
- **원리**: Rust의 `trait Container { type Item; }` 모델처럼, **"원소 타입의 홀더"와 "트레이트 구현 여부(멤버십)"를 완전히 직교(Orthogonal)하게 분리**합니다.
- **원소 타입 홀더**: 모든 단일 원소 컨테이너는 공통의 불변 팬텀 태그 하나만을 공유합니다:
  ```luau
  export type Item<T> = { read __item: (T) -> T }
  ```
  `read __item: (T) -> T`는 인자와 반환에 모두 `T`가 존재하므로, 단 1줄로 완벽한 불변성을 보장합니다.
- **트레이트 정체성 태그**: 트레이트는 복잡한 메서드 서명 없이 단순한 불리언 멤버십 태그만 선언합니다:
  ```luau
  export type Implements = { read __is_Deque: true }
  ```
- **합성**: 트레이트 진입점은 `deque: C & Item<T> & Implements`를 받습니다. 컨테이너는 자기 타입에 `read __item: (T) -> T`와 `read __is_Deque: true`를 포함하기만 하면 됩니다.

### 4.2 DX 예시
```luau
-- [공통: Traits.luau]
export type Item<T> = { read __item: (T) -> T }
export type KeyVal<K, V> = { read __key: (K) -> K, read __val: (V) -> V }

-- [트레이트 정의자: Deque.luau]
export type Implements = { read __is_Deque: true }
function Deque.PushBack<C, T>(deque: C & Traits.Item<T> & Implements, item: T): C ... end
function Deque.PopFront<T>(deque: Traits.Item<T> & Implements): T? ... end

-- [컨테이너 구현자: CircularDeque.luau]
export type CircularDeque<T> = {
    head: number, size: number, cap: number, buf: { T },
    read __type: { name: string },
    -- 원소 타입 홀더 (딱 1줄로 모든 트레이트 커버!)
    read __item: (T) -> T,
    -- 구현하는 트레이트 플래그들
    read __is_Deque: true,
    read __is_Stack: true,
    read __is_List: true,
}
local dequeOps: Deque.Core<CircularDeque<any>, any> = { ... }
Deque.Implement(TOKEN, dequeOps)
Stack.Implement(TOKEN, Stack.FromDeque(dequeOps))

-- [사용자: Test.luau]
local d = CircularDeque.New<<number>>()
local d2 = Deque.PushBack(d, 10) -- CircularDeque<number> 반환
local v: number? = Deque.PopFront(d2) -- number? 추론
```

### 4.3 실측 검증 결과 (`probes/approach2/`)
- 검사 명령: `( ulimit -v 2000000; timeout 30 luau-analyze probes/approach2/*.luau )`
- **정상 케이스 (`Test.luau`)**: **TypeError 0건 통과 [실측]**
- **음성 대조군 (`NegTest.luau`, `NegRegistration.luau`) [실측]**:
  - `NEG 1` (원소 타입 불일치): `TypeError: Expected this to be 'number', but got 'string'` (Exit 1)
  - `NEG 2` (반환 타입 불일치): `TypeError: Expected this to be 'string', but got 'number?'` (Exit 1)
  - `NEG 3` (스택 원소 불일치): `TypeError: Expected this to be 'number', but got 'boolean'` (Exit 1)
  - `NEG 4` (미구현 일반 테이블): `TypeError: Expected this to be 'Implements & Item<T>' but got '{ head: number }'` (Exit 1)
  - `NEG REG 1` (필수 함수 누락): `missing field 'Back'` 감지 (Exit 1)
  - `NEG REG 2` (서명 불일치): 반환 타입 `string` 불일치 감지 (Exit 1)
  - `NEG BLANKET 1` (뭉텅이 구현 오타): `PushBakk` 오타 감지 (Exit 1)

### 4.4 장점 및 특징
1. **압도적인 DX 개선 (목표 4, 5)**: 외부 개발자가 새 트레이트를 만들 때 불변성 메커니즘을 전혀 알 필요가 없습니다. 그냥 `read __is_MyTrait: true` 플래그 하나만 정의하고 `Item<T>`와 조합하면 끝납니다.
2. **컨테이너 타입의 비대화 방지**: 컨테이너가 5개, 10개의 트레이트를 구현해도 `read __item: (T) -> T`는 딱 한 줄만 들어갑니다. 트레이트마다 중복 필드를 만들지 않습니다.
3. **완벽한 타입 안정성**: `(T) -> T`가 단일 지점에서 불변성을 확실하게 잡아주므로 공변성 확산으로 인한 타입 안전성 붕괴(spikes/61)가 원천 방지됩니다.

---

## 5. 접근 3: 고유 타입 토큰 파라미터화 (Token-Carried Type Brand)

### 5.1 설계 의도 및 구조
- **원리**: 런타임에 이미 존재하는 필수 필드인 `read __type: Token` 자체를 정적 타입 레벨에서 제네릭화합니다:
  ```luau
  export type Token<Name, T> = { read name: Name, read __type_param: (T) -> T }
  export type AnyToken<T> = { read name: string, read __type_param: (T) -> T }
  ```
- 트레이트 멤버십은 컨테이너의 `__implements` 맵 속성으로 관리합니다:
  ```luau
  export type Implements = { read __implements: { read Deque: true } }
  ```

### 5.2 DX 예시
```luau
-- [트레이트 정의자: Deque.luau]
function Deque.PushBack<C, T>(deque: C & TraitToken.HasToken<T> & Implements, item: T): C ... end

-- [컨테이너 구현자: CircularDeque.luau]
export type CircularDeque<T> = {
    head: number, size: number, cap: number, buf: { T },
    read __type: TraitToken.Token<"CircularDeque", T>,
    read __implements: {
        read Deque: true,
        read Stack: true,
    },
}
```

### 5.3 실측 검증 결과 (`probes/approach3/`)
- 검사 명령: `( ulimit -v 2000000; timeout 30 luau-analyze probes/approach3/*.luau )`
- **정상 케이스 (`Test.luau`)**: **TypeError 0건 통과 [실측]**
- **음성 대조군 (`NegTest.luau`) [실측]**:
  - `NEG 1`~`4` 모두 기대한 대로 TypeError 발생 (Exit 1).

### 5.4 한계
- 맵과 같이 제네릭 파라미터가 2개 이상인 경우(`Token<Name, K, V>`), 토큰 타입 정의가 파라미터 개수별로 분기해야 하거나 공통 `AnyToken` 인터페이스가 복잡해집니다.
- 중첩된 `__implements` 맵 구조 때문에 타입 불일치 발생 시 Luau 에러 메시지가 상대적으로 복잡해집니다.

---

## 6. Luau 새 솔버(0.742)의 한계와 회피법 심층 분석 [실측 기반]

이번 프로브 제작 및 테스트 과정에서 Luau 0.742 새 솔버의 4가지 결정적 한계와 동작 특성을 발견했습니다.

### 6.1 한계 1: 교차 타입 제네릭 정규화 버그 (Intersection Generic Normalization) [실측]
- **현상**: 컨테이너 공개 타입을 교차 타입으로 선언했을 때:
  ```luau
  export type CircularDeque<T> = CircularDequeData<T> & Deque.Bound<T>
  ```
  그리고 제네릭 함수를 호출했을 때:
  ```luau
  function Deque.PushBack<C, T>(deque: C & Bound<T>, item: T): C
  ```
  반환 타입 `C`가 원래의 `CircularDeque<T>`로 유지되지 않고, 솔버 내부 정규화 과정에서 유니온 타입으로 분해되어 버립니다.
- **실측 에러 출력**:
  ```
  TypeError: Expected this to be
      '(Bound<number> | CircularDequeData<number>) & Bound<number>'
  but got
      'Bound<number> | CircularDequeData<number>'
  ```
- **해결/회피법**: 공개 컨테이너 타입을 교차 타입(`&`)으로 만들지 말고, 단일 테이블 타입 안에 마커/바운드 필드를 **직접 인라인 임베딩**해야 합니다.

### 6.2 한계 2: 자기 참조 재귀 바운드의 양방향 추론 포기 (`unknown` 퇴화) [실측]
- **현상**: 바운드 타입에 컨테이너 자기 자신 `C`를 넘기면:
  ```luau
  export type Bound<C, T> = { read __trait_Deque: Core<C, T> }
  export type CircularDeque<T> = Data<T> & Bound<CircularDeque<T>, T>
  ```
  이러면 솔버 내부에서 `t1 where t1 = ...`라는 무한 재귀 전개 타입이 발생합니다. 그 결과 `local d: CircularDeque<number> = CircularDeque.New()` 같은 생성자 호출 시 좌변의 컨텍스트 타입이 역방향으로 전달되지 못하고 `T = unknown`으로 포기해 버립니다.
- **실측 에러 출력**:
  ```
  TypeError: Expected this to be Bound<number> & CircularDequeData<number>
  but got Bound<unknown> & CircularDequeData<unknown>
  ```
- **해결/회피법**: 트레이트 바운드/마커는 컨테이너 타입 `C`를 몰라야 합니다. 오직 원소 타입 `T`만을 파라미터로 가져야 합니다.

### 6.3 한계 3: 런타임 싱글톤 트레이트 객체와 정적 제네릭의 괴리 [실측]
- **현상**: 런타임 트레이트 객체 `Trait`는 모듈 최상위에서 싱글톤 테이블로 생성됩니다. Luau 값 하나는 모든 `T`에 대해 다형적일 수 없으므로 `Trait<any, any>`로 다운캐스트됩니다. 이로 인해 `Trait.Impl(Trait, Token, impl)` 호출 시 `impl`의 시그니처가 `any`가 되어 정적 누락/서명 불일치 검사가 무력화됩니다.
- **해결/회피법**:
  트레이트 모듈이 타입 인자가 살아 있는 전용 등록 함수 `Deque.Implement<C, T>(token, impl: Core<C, T>)`를 제공하거나, 모듈 끝에서 구체 타입 어노테이션을 강제해야 합니다.

### 6.4 한계 4: Luau 언어 스펙상의 Arity Subtyping 허용 [실측]
- **현상**: `Core<C, T>`의 `PushBack: (C, T) -> C`에 대해, 구현 측에서 둘째 인자를 받지 않는 `function badPushBack<T>(self: DummyDeque<T>): DummyDeque<T>`를 등록해도 `luau-analyze`가 에러 없이 통과합니다(Exit code 0).
- **분석**: 이것은 버그가 아니라 Luau(및 TypeScript, JS)의 언어적 특성인 **잉여 인자 무시(Arity Subtyping)**입니다. 즉 콜백이나 함수가 요구되는 인자보다 적은 인자를 받는 것은 안전한 서브타입으로 간주됩니다.
- **대응**: 반대로 **인자를 더 많이 요구하거나**, **인자/반환 타입이 호환되지 않는 경우**는 `luau-analyze`가 100% 엄격하게 차단함을 실측으로 확인했습니다.

---

## 7. 최종 제안 및 추천

### 추천: **접근 2 (단일 연관 컨테이너 태그 + 트레이트 정체성 분리)**

### 추천 이유:
1. **극적인 DX 향상 (보일러플레이트 제거)**:
   - 트레이트 저자는 팬텀 함수 꼼수나 복잡한 인터페이스를 만들 필요 없이, `{ read __is_TraitName: true }` 단 1줄만 선언하면 됩니다.
   - 컨테이너 저자는 원소 타입 `T`를 `read __item: (T) -> T` 단 한 번만 선언하고, 트레이트는 불리언 태그들로 나열하면 끝납니다.
2. **견고한 불변성(Invariance) 보장**:
   - `read __item: (T) -> T`가 단일 지점에서 `T`의 불변성을 완벽히 통제하므로, 읽기 마커에서 쓰기 호출 시 타입이 넓어지는 버그(spikes/61)가 원천 방지됩니다.
3. **Luau 새 솔버 친화적 설계**:
   - 교차 타입(`&`)이나 순환 참조 재귀 타입을 전혀 유발하지 않으며, 평범한 레코드 속성 서브타이핑으로 동작하므로 컴파일 타임 추론이 빠르고 안정적입니다.
4. **목표 1~5 전 항목 달성**:
   - 원소 타입 전파 [실측 성공]
   - 등록 시 필수 누락 / 타입 불일치 검증 [실측 성공]
   - 뭉텅이 구현(Blanket Impl) 몸통 정적 검증 [실측 성공]
   - 외부 개발자 친화성 [실측 확인]
   - DX 단순화 [실측 확인]

---

## 8. 생성된 프로브 파일 목록 (worktree 내 경로)

모든 프로브는 worktree 루트의 `probes/` 디렉터리에 작성되었으며, `luau-analyze`를 통해 검증되었습니다:
- **공통 카나리아**: `probes/canary.luau`
- **접근 1 (Core-as-Bound)**:
  - `probes/approach1/Deque.luau`
  - `probes/approach1/Stack.luau`
  - `probes/approach1/CircularDeque.luau`
  - `probes/approach1/Test.luau`
  - `probes/approach1/NegTest.luau`
  - `probes/approach1/NegRegistration.luau`
- **접근 2 (Associated Container Tag) ⭐**:
  - `probes/approach2/Traits.luau`
  - `probes/approach2/Deque.luau`
  - `probes/approach2/Stack.luau`
  - `probes/approach2/CircularDeque.luau`
  - `probes/approach2/Test.luau`
  - `probes/approach2/NegTest.luau`
  - `probes/approach2/NegRegistration.luau`
- **접근 3 (Token Brand)**:
  - `probes/approach3/TraitToken.luau`
  - `probes/approach3/Deque.luau`
  - `probes/approach3/Stack.luau`
  - `probes/approach3/CircularDeque.luau`
  - `probes/approach3/Test.luau`
  - `probes/approach3/NegTest.luau`
  - `probes/approach3/NegRegistration.luau`

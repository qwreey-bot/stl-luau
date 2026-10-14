# Gemini(agy) tr-dx — 트레이트 타입 다시각 탐색 1회차

> **메인 검증(2026-10-14)**: 표 리터럴을 인자로 넘기면 검사가 안 서는 것은 확인(`trait-typing-probes/bidir-table-arg.luau`). "고차 타입이 없어 `Trait` 이 `Of` 의 타입을 대신 적을 수 없다" 는 **틀림** — `Trait<F>(name, factory: F): { read Of: F }` 로 팩토리가 곧 `Of` 의 타입이 됨(Opus 종합, 메인 확인 — `factoryof.luau`). "`types.newgeneric` 부재" 도 틀림(`types.generic` 이 있고 v2 가 씀). `Of` 가 `Arr.Of`(생성자)와 이름이 겹친다는 지적은 유효.

---

# 트레이트 API 의 DX — 정의·구현·사용 세 자리 종합 분석 보고서

- **작성자**: Gemini (다른 모델 계열 `agy`)
- **작업 환경**: `/code/Projects/stl-luau-agy/tr-dx` (브랜치 `agy/tr-dx`)
- **기준 커밋**: `2fe79a13ff4cde3e14c7f385bd031d753990b2e5` (`git rev-parse HEAD` 실측)
- **분석 도구**: `luau 0.742` (strict mode, new solver), `ulimit -v 2000000`

---

## 1. 개요 및 요약

본 보고서는 `stl-luau`의 트레이트 시스템(v2 연관 타입 기반, v3 제네릭 트레이트 기반)을 바탕으로, 세 가지 관점인 **(가) 트레이트를 정의하는 사람**, **(나) 컨테이너가 구현을 등록하는 사람**, **(다) 종류를 모르고 쓰는 사람**의 **개발자 경험(DX)**을 극대화하기 위한 구조를 탐구하고 검증한 결과를 담고 있습니다.

### 핵심 요약
1. **사용자 열린 생각 실측 검증**:
   - **(a) 기본 구현을 팩토리 안에 합치기**: `Default<<sig>>(impl)` 형태로 시그니처와 구현을 팩토리 안으로 합치는 것은 타입적으로 가능합니다. 그러나 Luau 새 솔버의 제네릭 함수 내부 유니피케이션 특성상 인자 타입 불일치는 느슨하게 통과하고 반환 타입 불일치만 엄격히 잡히며, **"기본 구현 몸통에서 필수 함수를 어떻게 호출할 것인가"**(동적 디스패치 vs `ops` 고차 함수 주입)의 설계 트레이드오프가 존재합니다.
   - **(b) & (d) 인라인 등록 시도와 등록 표 분리의 이유**: `Impl:For(TOKEN)({ Push = Arr.PushBack })`처럼 인라인 테이블 리터럴로 넘기면, Luau 새 솔버가 중첩 프로퍼티의 제네릭 함수(`Arr.PushBack`)를 기대 타입(`Stack<Arr<string>, string>`)으로 자동 인스턴스화하지 못해 타입 에러가 발생합니다(실측). 이를 해결하려면 등록자가 모든 함수에 `Arr.PushBack<<string>>`처럼 타입 인자를 덕지덕지 붙여야 합니다. 따라서 **"구체 타입 주석을 단 로컬 변수 `const arrStack: Stack<...> = { ... }`를 선언하고 넘기는 패턴"**은 단순한 어색함이 아니라, **Luau 타입 솔버의 한계를 우회하는 최선의 DX 패턴**입니다.
   - **(c) `Trait`이 제네릭을 받아 `Of`·`For` 타입 대신 적기**: Luau에 고차 타입(HKT)이 없으므로 단일 제네릭 함수 `Trait.Trait`이 임의의 팩토리 `<Self, T>`를 받아 `Of: <C, T>(C) -> Shape<C, T>`를 자동으로 합성하는 것은 불가능합니다. 다만 트레이트 객체 타입 정의를 규격화하거나 네임스페이스 함수로 축약할 수 있습니다.
2. **API 모양 후보 3종 비교 및 실측**:
   - **[후보 1] Builder Refined**: 기존 v3에서 끝의 불필요한 커링 괄호 `(impl)`를 제거한 `Trait.Impl(Stack):For(TOKEN, arrStack)`.
   - **[후보 2] Trait-Centric / Module DX (강력 추천)**: 주어를 `Trait`에서 개별 트레이트(`Stack`)로 전환하여 `Stack.Register(TOKEN, arrStack)`, `Stack.Where({ Deque })(builder)`로 단축.
   - **[후보 3] Integrated Factory**: 팩토리 내부에 `Default`와 `ops` 주입을 내장하여 시그니처와 기본 구현을 완전 통합.
3. **이름(가칭) 검토**:
   - `Of`는 기존 stl-luau의 컨테이너 팩토리 생성자(`Arr.Of(1, 2, 3)`)와 **의미가 심각하게 충돌**합니다. 디스패치 목적에 맞게 `Ops` 또는 `From`, `Cast`로의 변경을 제안합니다.
   - `For`, `Impl`, `Fn`, `Default`, `Where`의 타 언어(Rust, Java, Kotlin, TS, Swift) 비교 및 개선안 제시.

---

## 2. 사용자의 열린 생각 실측 검증

### (a) 기본 구현을 팩토리 안에 합치기
> `Trait "Stack" (function<Self, T>() return { a = Default<<sig>>(완성된 함수), b = Fn<<sig>>() } end)`

- **검증 프로브**: [`probes/probe_a_default_in_factory.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/probe_a_default_in_factory.luau)
- **실행 명령**: `( ulimit -v 2000000; timeout 120 luau-analyze probes/probe_a_default_in_factory.luau )`

#### 실측 결과
1. **타입 함수 `Provided`와의 연계 (실측)**:
   - 팩토리 반환 테이블에서 필수 함수는 `Fn<<sig>>()`, 기본 구현은 `Default<<sig>>(impl)`로 반환하고 `Default`에 `{ read __default: true }` 꼬리표를 붙였습니다.
   - 타입 함수 `Provided<List<...>>`는 정상적으로 `Default` 꼬리표가 붙은 필드를 선택 필드(`optional`)로 변환했습니다. 필수 함수(`Get`)가 빠지면 에러(`Table type ... missing field 'Get'`)가 정확히 잡힙니다.
2. **기본 구현 몸통(`impl`)의 타입 검증 한계 (실측)**:
   - **반환 타입 오류**: `Default<<(list: Self, item: E) -> boolean>>(function(...) return "wrong" end)`는 즉시 `Expected the return type to be boolean, but got string` 에러가 잡힙니다.
   - **인자 타입 오류**: `Default<<(list: Self, item: E) -> boolean>>(function(list: string, item: E) ... end)`는 **에러가 나지 않고 통과했습니다!**
   - **심층 원인 분석 ([`probes/test_generic_unify.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/test_generic_unify.luau) 실측)**:
     제네릭 함수 `function<Self, E>()` 본문 내부에서 로컬 람다의 인자 타입(`string`)과 제네릭 파라미터(`Self`)를 비교할 때, Luau 새 솔버는 반공변 위치의 `Self`를 `string`으로 좁히는(unify) 방식으로 제약 조건을 만족시킵니다. 즉, 팩토리 내부에서는 `Self`가 자유 제네릭 변수이므로 인자 타입 불일치를 엄격히 거절하지 못합니다.
3. **핵심 설계 맹점: 기본 구현 내부에서 필수 함수를 어떻게 호출하는가? (추정 & 분석)**:
   - stl-luau는 메서드가 없는 순수 테이블 구조(`list:Get(i)` 불가)입니다.
   - **방식 1 (트레이트 진입점 동적 호출)**: 기본 구현 안에서 `List.Get(list, idx)`를 호출.
     - 대가: 호출마다 `rawget(list, "__type")` 및 테이블 조회가 발생하여 인라인 모듈 직접 호출에 비해 1.5~2배의 런타임 오버헤드가 누적됩니다.
   - **방식 2 (`ops` 주입형 고차 함수)**: `Default`가 `(ops: Ops) -> impl`을 받도록 구성.
     - 대가: 팩토리 시그니처가 복잡해지며 정의자의 부담이 증가합니다(후보 3 참고).

---

### (b) & (d) 팩토리로 등록 모양을 얻기 & 등록 표를 별도 변수로 적어야 하는 어색함
> `Impl(Stack<<Arr<T>, T>>()):For(TOKEN)` 같은 것
> `Trait.Impl(Stack):For(TOKEN)(impl)` 의 어색함(등록 표를 주석 단 지역으로 따로 적어야 함)을 덜 수 있는 모양

- **검증 프로브**: [`probes/probe_b_inline_registration.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/probe_b_inline_registration.luau), [`probes/test_explicit_in_inline.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/test_explicit_in_inline.luau)
- **실행 명령**: `( ulimit -v 2000000; timeout 120 luau-analyze probes/probe_b_inline_registration.luau )`

#### 실측 결과: 인라인 등록이 실패하는 근본 메커니즘
많은 개발자들이 `Impl(Stack):For(TOKEN)({ Push = Arr.PushBack, Pop = Arr.PopBack, Peek = arrPeek })` 처럼 인라인으로 깔끔하게 등록하기를 원합니다. 그러나 실제로 돌려본 결과:

```
./probes/probe_b_inline_registration.luau(78,9): TypeError: Expected this to be
	'(Arr<string>, string) -> Arr<string>'
but got
	'<T>(ArrData<T>, T) -> ArrData<T>'
```

- **실측 현상**:
  - `RegisterStack<<Arr<string>, string>>(TOKEN, { Push = Arr.PushBack })`
  - `ImplFactory(stackDef<<Arr<string>, string>>()):For(TOKEN)({ Push = Arr.PushBack })`
  - `StackObj.Register<<Arr<string>, string>>(TOKEN, { Push = Arr.PushBack })`
  **위의 모든 인라인 호출 형태가 예외 없이 컴파일 에러를 냈습니다.**
- **원인 분석 (실측)**:
  - `Arr.PushBack`은 제네릭 함수 `<T>(ArrData<T>, T) -> ArrData<T>`입니다.
  - Luau 새 솔버는 함수 인자로 전달된 중첩 테이블 리터럴(`{ Push = Arr.PushBack }`)을 타이핑할 때, 바깥 함수의 기대 매개변수 타입(`Stack<Arr<string>, string>`)을 테이블 내부 프로퍼티의 제네릭 함수로 전파(push down)하지 못합니다.
  - 결과적으로 테이블은 `{ Push: <T>(ArrData<T>, T) -> ArrData<T> }`로 독립 타이핑되고, 이것이 기대 타입 `{ Push: (Arr<string>, string) -> ... }`에 대입될 때 **"제네릭 함수는 구체 함수 타입의 서브타입이 아니다"**라는 이유로 거절당합니다.
- **해결책 대조 (실측)**:
  1. 인라인 테이블에서 풀기: `{ Push = Arr.PushBack<<string>>, Pop = Arr.PopBack<<string>>, ... }`처럼 모든 함수마다 `<<string>>`을 붙여야 함 (`test_explicit_in_inline.luau` 실측 통과). -> **DX 최악**.
  2. **주석 단 지역 변수 선언**:
     ```lua
     const arrStack: Stack<Arr<string>, string> = {
         Push = Arr.PushBack,
         Pop = Arr.PopBack,
         Peek = arrPeek,
     }
     ```
     변수 선언문에 타입 주석이 달리면 Luau 솔버가 양방향 타입 추론을 완벽히 수행하여, **함수들에 `<<string>>`을 단 하나도 붙이지 않아도 자동으로 `string`으로 인스턴스화**됩니다!

#### 결론 (b & d에 대한 진단)
"등록 표를 주석 단 지역 변수로 따로 적어야 하는 것"은 어색한 제약이 아니라, **Luau 타입 솔버의 중첩 제네릭 추론 한계를 우회하여 개발자가 모든 함수에 명시적 타입 인자를 적지 않도록 만들어주는 가장 우아한 보호 장치**입니다.
따라서 진짜 해결해야 할 어색함은 "지역 변수를 만드는 것"이 아니라, 등록 호출부의 **불필요한 3단계 커링 `Trait.Impl(Stack):For(TOKEN)(impl)`**입니다!

---

### (c) `Trait` 이 제네릭을 받아 `Of`·`For` 의 타입을 대신 적어 주기
> 트레이트 정의 시 `:: Stack<any, any> & { read Of: <C, T>(C) -> Stack<C, T>, ... }` 반복 제거 가능 여부

- **검증 프로브**: [`probes/probe_c_trait_generics_helper.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/probe_c_trait_generics_helper.luau)

#### 실측 및 이론적 분석
- Luau 타입 시스템에는 **고차 타입(Higher-Kinded Types, HKT)**이 없습니다.
- 즉, `Trait.Trait` 함수 하나가 임의의 팩토리 함수 타입 `F = <Self, T>() -> Shape`를 매개변수로 받아서, 그 `F`의 제네릭 매개변수 목록 `Self, T`를 그대로 복제한 `Of: <C, T>(C) -> Shape<C, T>` 함수 타입을 동적으로 합성해내는 것은 타입 시스템 상 불가능합니다.
- 타입 함수(`type function`)를 통해서도 새로운 제네릭 매개변수를 임의로 생성(`types.newgeneric` 부재)할 수 없습니다.
- **해결 방안 (제안)**:
  트레이트 객체 타입을 정의할 때 보일러플레이트를 줄이는 가장 깔끔한 방법은:
  1) 트레이트 파일 상단에 해당 트레이트 전용 `TraitObj` 타입을 명확히 정의하거나 (가독성 최우선),
  2) 아래 후보 2처럼 트레이트 모듈이 제공하는 `Register`, `Of`, `For`를 네임스페이스 함수로 일원화하는 것입니다.

---

## 3. API 모양 후보 3종 세 자리 DX 비교

세 가지 자리:
- **(가) 정의하는 자리**: 새 트레이트를 작성하는 라이브러리/외부 개발자
- **(나) 구현하는 자리**: 컨테이너 모듈(`Arr`, `CircularDeque`)에 트레이트를 등록하는 개발자
- **(다) 사용하는 자리**: 컨테이너의 종류를 모르고 트레이트를 통해 다형적으로 사용하는 개발자

---

### [후보 1] Builder Pattern Refined (기존 v3 정제형)
- **프로브**: [`probes/probe_candidate_1_builder.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/probe_candidate_1_builder.luau) (NEG 4건 + canary 1건 정확히 검출, 정상 코드 0 에러)
- **핵심 변경**: `Trait.Impl(Stack):For(TOKEN)(impl)`의 끝 커링을 없애고 `Trait.Impl(Stack):For(TOKEN, impl)` 2단계로 단순화.

```lua
-- (가) 트레이트 정의 자리
local function stackDef<Self, T>()
    return {
        Push = Fn<<(stack: Self, item: T) -> Self>>(),
        Pop = Fn<<(stack: Self) -> T?>>(),
        Peek = Fn<<(stack: Self) -> T?>>(),
    }
end
export type Stack<Self, T> = typeof(stackDef<<Self, T>>())
const Stack = Trait.Trait("Stack", stackDef) :: Stack<any, any> & {
    read Of: <C, T>(value: C) -> Stack<C, T>,
    read For: <C, T>(token: Token) -> Stack<C, T>,
}
-- 뭉텅이 구현
Trait.Impl(Stack):Where({ Deque })(function(deps)
    return stackFromDeque(deps[Deque])
end)

-- (나) 구현하는 자리 (컨테이너)
const arrStack: Stack<Arr<string>, string> = {
    Push = Arr.PushBack,
    Pop = Arr.PopBack,
    Peek = arrPeek,
}
Trait.Impl(Stack):For(ARR, arrStack) -- 괄호 커링 1회 제거!

-- (다) 사용하는 자리
local s = Stack.Of<<CircularDeque<number>, number>>(d)
s.Push(d, 10)
local function drain<C, T>(s: Stack<C, T>, c: C): { T } ... end
Stack.Push(d, 42) -- 편한 길 (any)
```

- **평가**:
  - 장점: 기존 v3 런타임 및 구조를 거의 그대로 유지하면서 어색한 마지막 `(impl)` 호출을 제거.
  - 단점: 등록 시 여전히 `Trait` 글로벌 모듈을 require해야 하고, `:For` 체이닝이 남아 있음.

---

### [후보 2] Trait-Centric / Module DX (강력 추천 ⭐)
- **프로브**: [`probes/probe_candidate_2_trait_centric.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/probe_candidate_2_trait_centric.luau) (NEG 4건 + canary 1건 정확히 검출, 정상 코드 0 에러)
- **핵심 변경**:
  - 등록과 조회의 주어를 `Trait` 전역 모듈이 아니라 **개별 트레이트 객체(`Stack`)**로 전환!
  - `Stack.Register(TOKEN, impl)` (단일 1단계 함수 호출)
  - `Stack.Where({ Deque })(builder)` (트레이트가 직접 뭉텅이 수용)

```lua
-- (가) 트레이트 정의 자리
local function stackDef<Self, T>()
    return {
        Push = Fn<<(stack: Self, item: T) -> Self>>(),
        Pop = Fn<<(stack: Self) -> T?>>(),
        Peek = Fn<<(stack: Self) -> T?>>(),
    }
end
export type Stack<Self, T> = typeof(stackDef<<Self, T>>())

type StackTrait = Stack<any, any> & {
    read Of: <C, T>(value: C) -> Stack<C, T>,
    read For: <C, T>(token: Token) -> Stack<C, T>,
    read Register: (token: Token, impl: any) -> (),
    read Where: (deps: { any }) -> (build: (deps: { [any]: any }) -> any) -> (),
}
const Stack: StackTrait = Trait.Define("Stack", stackDef) :: any

-- 뭉텅이 구현: 주어가 Stack!
Stack.Where({ Deque })(function(deps)
    return stackFromDeque(deps[Deque])
end)

-- (나) 구현하는 자리 (컨테이너)
const arrStack: Stack<Arr<string>, string> = {
    Push = Arr.PushBack,
    Pop = Arr.PopBack,
    Peek = arrPeek,
}
-- 극적인 단축: Trait 모듈 require 불필요, 1단계 호출!
Stack.Register(ARR, arrStack)

-- (다) 사용하는 자리
local s = Stack.Of<<CircularDeque<number>, number>>(d)
s.Push(d, 10)
local function drain<C, T>(s: Stack<C, T>, c: C): { T } ... end
Stack.Push(d, 42) -- 편한 길 (any)
```

- **평가**:
  - **압도적인 구현자(나) 경험**: `Trait.Impl(Stack):For(TOKEN)(arrStack)` (3단계) -> `Stack.Register(ARR, arrStack)` (1단계).
  - 어순이 자연스러움: "Stack에 Arr 토큰으로 구현체를 등록한다" (Rust의 `impl Stack for Arr`와 일맥상통).
  - 컨테이너 모듈에서 `local Trait = require("...")`를 의존하지 않고, 등록하려는 해당 트레이트(`Stack`)만 require하면 됨.

---

### [후보 3] Integrated Factory (일체형 팩토리 + 기본 구현 팩토리 내장)
- **프로브**: [`probes/probe_candidate_3_integrated_factory.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/probe_candidate_3_integrated_factory.luau) (NEG 3건 + canary 1건 정확히 검출, 정상 코드 0 에러)
- **핵심 변경**: 질문 (a)의 사용자 아이디어를 완전 구현. 팩토리 내부에서 `Default<<(ops) -> impl>>(builder)` 형태로 선언하여 기본 구현과 필수 구현을 한 곳에 통합.

```lua
-- (가) 트레이트 정의 자리
type ListOps<Self, E, I> = {
    Get: (list: Self, idx: I) -> E?,
    FirstIndex: (list: Self) -> I?,
    NextIndex: (list: Self, idx: I) -> I?,
}

local function listDef<Self, E, I>()
    return {
        -- 필수 (Fn)
        Get = Fn<<(list: Self, idx: I) -> E?>>(),
        FirstIndex = Fn<<(list: Self) -> I?>>(),
        NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),

        -- 기본 구현 (Default): ops 를 주입받아 직접 호출!
        IndexOf = Default<< (list: Self, item: E) -> I?, ListOps<Self, E, I> >>(function(ops)
            return function(list: Self, item: E): I?
                local idx = ops.FirstIndex(list)
                while idx ~= nil do
                    if ops.Get(list, idx) == item then return idx end
                    idx = ops.NextIndex(list, idx)
                end
                return nil
            end
        end),
    }
end
export type List<Self, E, I> = typeof(listDef<<Self, E, I>>())
export type ListFor<Self, E, I> = Trait.Provided<List<Self, E, I>>

-- (나) 구현하는 자리 (컨테이너)
-- 필수만 채우고 기본 구현(IndexOf)은 생략 가능!
const arrList: ListFor<Arr<string>, string, number> = {
    Get = Arr.Get,
    FirstIndex = Arr.FirstIndex,
    NextIndex = Arr.NextIndex,
}
List.Register(ARR, arrList)

-- (다) 사용하는 자리
local l = List.Of<<Arr<string>, string, number>>(a)
local found: number? = l.IndexOf(a, "item")
```

- **평가**:
  - 장점: 시그니처와 기본 구현이 단 하나의 팩토리 안에 모이고, 기본 구현이 `ops`를 통해 구체 함수를 직접 호출하므로 동적 디스패치 오버헤드가 없음.
  - 단점: 정의하는 사람(가) 입장에서 `ListOps` 같은 필수 연산 모음 타입을 별도로 선언해야 하고, `Default<<(sig, Ops)>>(...)` 고차 함수 타이핑이 복잡해짐.

---

## 4. 이름(가칭) 검토 및 타 언어 관례 대조

| 가칭 | 현재 용도 | 타 언어 관례 (Rust·Java·Kotlin·TS·Swift) | 문제점 및 평가 | 대안 제안 |
|---|---|---|---|---|
| **`Of`** | 인스턴스에서 구현 표 추출<br>`Stack.Of(d)` | **Java**: `List.of(...)` (팩토리 생성자)<br>**Rust**: `as &dyn Trait`, `From/Into`<br>**TS**: `as`, `satisfies`<br>**Swift**: `as? AnyTrait` | ⚠️ **심각한 의미 충돌**.<br>`stl-luau`에서 `Arr.Of(...)`, `CircularDeque.Of(...)`는 **원소로부터 컨테이너를 만드는 팩토리**임.<br>`Stack.Of(d)`는 원소 팩토리가 아니라 **인스턴스의 구현표 디스패치**이므로 완전히 충돌함. | **`Stack.Ops(d)`** (연산자 표를 꺼냄)<br>또는 **`Stack.From(d)`**<br>또는 **`Stack.Cast(d)`** |
| **`For`** | 토큰으로 구현 표 추출<br>`Stack.For(TOKEN)` | **Rust**: `impl Trait for Type` (전치사)<br>**Swift**: `extension Type: Trait` | 조회 시 `Of`와 `For`의 구분이 모호함(값 vs 토큰).<br>등록 시 `Impl:For`는 Rust 문법을 흉내 냈으나 동사가 빠져 어색함. | 조회: **`Stack.Ops(TOKEN)`** (오버로딩)<br>등록: **`Stack.Register(TOKEN, impl)`** |
| **`Impl`** | 구현 등록 진입점<br>`Trait.Impl(...)` | **Rust**: `impl` (키워드)<br>**Scala**: `given`, `implicit`<br>**Haskell**: `instance` | 체이닝 중간 단계로 쓰여 호출 단계가 늘어남. 축약어(`Impl`)보다 명확한 동사 권장. | **`Register`** 또는 **`Implement`** |
| **`Fn`** | 필수 함수 시그니처 마커 | **Rust**: `fn`<br>**Kotlin**: `fun`<br>**TS**: 메서드 시그니처 | 2글자로 가장 짧고 명확함. Rust 사용자에게 익숙함. | **유지 (`Fn`)** |
| **`Default`**| 기본 구현 마커 | **Java**: `default` 메서드<br>**Rust**: 트레이트 기본 구현<br>**Swift**: 프로토콜 익스텐션 | Java의 `default` 키워드와 정확히 일치하며 의미 전달이 명확함. | **유지 (`Default`)** |
| **`Where`** | 뭉텅이/의존성 구현<br>`Where({ Deque })` | **Rust**: `where` 절 (`impl<T> Stack for T where T: Deque`)<br>**Swift/C#/Kotlin**: `where` 절 | 모든 메이저 언어의 제약 조건 키워드와 일치하여 개발자 직관에 가장 완벽히 부합함. | **유지 (`Where`)** |

---

## 5. 최종 추천안 및 이유

### 💡 추천: **[후보 2] Trait-Centric / Module DX + 어휘 개선**

```lua
-- [1. 트레이트 정의: src/Traits/Stack.luau]
local function stackDef<Self, T>()
    return {
        Push = Trait.Fn<<(stack: Self, item: T) -> Self>>(),
        Pop = Trait.Fn<<(stack: Self) -> T?>>(),
        Peek = Trait.Fn<<(stack: Self) -> T?>>(),
    }
end
export type Stack<Self, T> = typeof(stackDef<<Self, T>>())

type StackTrait = Stack<any, any> & {
    read Ops: <C, T>(value: C) -> Stack<C, T>,
    read Register: (token: Trait.Token<any>, impl: any) -> (),
    read Where: (deps: { any }) -> (build: (deps: { [any]: any }) -> any) -> (),
}
const Stack: StackTrait = Trait.Define("Stack", stackDef) :: any

-- Deque 로부터의 뭉텅이 구현
Stack.Where({ Deque })(function(deps)
    return { Push = deps[Deque].PushBack, Pop = deps[Deque].PopBack, Peek = deps[Deque].Back }
end)
return Stack

-- [2. 컨테이너 구현 등록: src/Collections/Arr.luau 끝]
const arrStack: Stack<Arr<string>, string> = {
    Push = Arr.PushBack,
    Pop = Arr.PopBack,
    Peek = arrPeek,
}
Stack.Register(ARR_TOKEN, arrStack)

-- [3. 다형적 사용자 코드]
local s = Stack.Ops<<Arr<string>, string>>(a)
s.Push(a, "item")
Stack.Push(a, "any_item") -- 편한 길
```

### 추천 이유 4가지
1. **컨테이너 등록자 DX의 극대화**:
   - `Trait.Impl(Stack):For(ARR)(arrStack)` (3단계)라는 번거로운 호출이 `Stack.Register(ARR, arrStack)` (1단계)로 단축됩니다.
   - 불필요하게 `Trait` 인프라 모듈을 require할 필요가 없어집니다.
2. **Luau 새 솔버의 특성에 완벽히 부합**:
   - 중첩 제네릭 추론 한계로 인해 인라인 테이블 리터럴 등록은 불가능하거나 극도로 장황(`<<string>>` 남발)해집니다.
   - 로컬 변수 `const arrStack: Stack<...> = { ... }`를 선언하고 넘기는 구조와 `Stack.Register(...)`의 결합이 가장 가독성이 높고 안전합니다.
3. **`Of`의 네이밍 충돌 완벽 해소**:
   - 컨테이너 생성자인 `Arr.Of(...)`와의 혼선을 피하고, "연산자 표를 얻는다"는 의미인 `Stack.Ops(d)`로 변경하여 라이브러리 전체의 개념적 일관성을 확보합니다.
4. **기본 구현의 성능과 복잡도 균형**:
   - 후보 3의 일체형 팩토리는 정의자의 타입 선언 부담이 과중합니다. 기본 구현은 기존처럼 `defaults(ops)` 형태로 분리하고 런타임에 클로저로 캡처하여 직접 호출하게 함으로써, **정의 단순성**과 **최고 수준의 런타임 성능**을 동시에 달성합니다.

---

## 6. 프로브 파일 및 검증 증거 목록

모든 프로브는 worktree 루트의 `probes/` 디렉터리에 위치하며, `luau-analyze` (0.742)를 통해 정적으로 검증되었습니다.

1. [`probes/probe_a_default_in_factory.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/probe_a_default_in_factory.luau):
   - 생각 (a) 실측: `Default<<sig>>(impl)` 검증, 반환 타입 검출 확인, Provided 타입 함수 연계 확인.
2. [`probes/test_generic_unify.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/test_generic_unify.luau):
   - Luau 새 솔버에서 제네릭 함수 내부 인자 타입 유니피케이션 특성 실측.
3. [`probes/probe_b_inline_registration.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/probe_b_inline_registration.luau):
   - 생각 (b) & (d) 실측: 인라인 등록 시 중첩 제네릭 함수 인스턴스화 실패(`Arr.PushBack`) 현상 실측.
4. [`probes/test_explicit_in_inline.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/test_explicit_in_inline.luau):
   - 명시적 `<<string>>` 부착 시 통과 vs 변수 주석 시 통과 비교 실측.
5. [`probes/probe_candidate_1_builder.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/probe_candidate_1_builder.luau):
   - 후보 1 (Builder Refined) 전체 세 자리 구현 및 음성 대조군(NEG 4건 + canary 1건) 검증.
6. [`probes/probe_candidate_2_trait_centric.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/probe_candidate_2_trait_centric.luau):
   - 후보 2 (Trait-Centric) 전체 세 자리 구현 및 음성 대조군(NEG 4건 + canary 1건) 검증.
7. [`probes/probe_candidate_3_integrated_factory.luau`](file:///code/Projects/stl-luau-agy/tr-dx/probes/probe_candidate_3_integrated_factory.luau):
   - 후보 3 (Integrated Factory) 전체 세 자리 구현 및 음성 대조군(NEG 3건 + canary 1건) 검증.
8. `./scripts/check.sh` 전체 통과:
   - 본 연구 중 추가된 프로브들이 기존 stl-luau 테스트 스위트 및 린트에 영향이 없음을 확인 (종료 코드 0).

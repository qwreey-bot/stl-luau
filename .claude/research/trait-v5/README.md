# 시제품 v5 — 두 보기(`index<>`)와 빌린 읽기 참조 (2026-10-14, 다시각 2회차 Opus)

Opus 2회차가 v4(14e68f6)를 바깥 사용자 코드로 깨 보고 구멍 둘을 메운 판입니다. 원래 시제품 파일은 사본에서 지워졌고,
여기 있는 것은 **메인이 보고의 코드로 다시 짠 타입 프로브**입니다(런타임은 v4 그대로에 `ImplOf = Of` 와 두 겹 팩토리를 벗기는 것뿐).
실행: `( ulimit -v 2097152; luau-analyze .claude/research/trait-v5/two-views.luau )` — `-- NEG` 줄과 canary 만 에러(메인 확인).

## 무엇이 바뀌나

- **두 보기**: 정의를 모드 `M` 을 받는 한 겹으로 감싸고(`stackDef<M>(mode: M)` 안에 v4 팩토리), `Trait.Trait(name, def<<"full">>, def<<"impl">>)`.
  기본 구현 칸은 `Default(mode, build)` 의 타입이 **내장** `index<{ full: F, impl: F? }, M>` — 완성 보기(`Of`)에선 `F`, 등록 보기
  (`ImplOf`)에선 `F?`. → **`Inherit` 가 없어지고**, 트레이트에 기본 구현을 더해도 예전 등록 표·뭉텅이 몸통이 안 깨짐(v4 는 둘 다
  "missing field" 로 깨졌음 — Opus 실측). 재정의 칸은 여전히 검사됨(틀린 재정의, `Fold` 의 `<U>` 를 못박은 것 모두 잡힘 — 메인 확인).
- **빌린 읽기 참조**: 컨테이너에 공변 팬텀을 하나 더 — `read __readGenerics: { read Item: () -> T, read Index: () -> I }`(전체 타입과
  읽기 타입 둘 다, 불변 `__generics` 는 전체 타입에만). 팩토리는 `(Self & ItemRead<T>) | AnyToken` 으로 받고, 쓰는 함수의 self 는
  `Mut<Self, T, M> = index<{ full: Self & Item<T>, impl: Self }, M>`. → `Stack.Of(borrowed).Peek` 는 되고 `.Push(borrowed, …)` 는
  잡힘 — 예전 `MarkerMut` 규칙이 **함수 단위**로 돌아옴. 등록 보기에서 self 를 `Self` 그대로 두는 것은 교집합 인자에 제네릭
  구현이 안 맞춰져서(Opus 실측). 공변 필드는 `() -> T` 꼴(맨 `read Item: T` 는 `Self &` 와 섞이면 결함 — `assocfields`).
  `Index` 도 공변이어야 `spikes/65` 가 그대로(Opus 실측: 불변이면 52 → 53).

## 대가

- 정의하는 쪽: 한 겹 더(`def<M>`), `Default(mode, …)`, 쓰는 함수에 `Mut<Self, T, M>`, `XImpl` 별칭 하나.
- 컨테이너: 팬텀 둘(`__generics` 불변 + `__readGenerics` 공변). 바깥 컨테이너도 `__readGenerics` 를 적어야 `Of(값)` 이 됨.
- ⚠️ **내장 타입 함수 `index<>`** 를 씀 — 규약의 "`type function` 을 쓰지 않음" 은 사용자 타입 함수의 함정 셋 때문이었고, 셋째(거치면
  제네릭이 깨짐)는 여기서 `Fold` 의 `<U>`·종류를 모르는 제네릭 알고리즘(`two-views-generic.luau`)으로 재 봤을 때 안 깨졌음. 사용자 결정.
- 에러 문구에 `index<…>` 가 펼쳐져 조금 시끄러움.
- `Stack<C, T>` 를 받는 제네릭 알고리즘에서 `st.Pop(c)` 가 `c: C` 로 통과하는 것은 제네릭 몸통 결함(AA 3번)의 관대함 덕 — 고쳐지면
  `c: C & Item<T>` 를 적어야 함(Opus 추론).

## 못 한 것 / 그대로인 것

- **편한 진입점의 타입은 서명을 한 곳에만 적고는 못 얻음**(Opus): 진입점은 필드마다 `∀Self, T`, 팩토리는 표 전체에 묶여 있음 — 묶는
  자리를 옮기려면 타입 함수나 고차 타입. 손으로 적은 ∀ 진입점은 호출은 정확하나, 팩토리와의 일치를 보는 줄이 맞는 것에도 에러.
  (Gemini `tr3-entry` 가 같은 문제를 다른 각도로 보는 중.) 지금 `src` 는 손으로 쓴 진입점이라 `stl.Stack.Push(d, "x")` 를 잡음 — v4/v5 는 후퇴.
- `Trait.Impl` 에 타입을 주는 길 없음 — 주석 단 지역이 유일(커링한 `ImplWith(Stack.ImplOf<<…>>)(tok, {…})` 은 맞는 리터럴도 거절).
- 타입·런타임 둘 다 못 잡는 등록 실수: `Stack` 표를 `Queue` 에(이름이 같음), `Pop = Len`(서명이 하위 타입). 주석 단 표의 오타 칸은
  타입이 못 잡고 런타임(`unknownName`)이 잡음. → `spec.contracts` 19절 같은 배선 전수 표가 계속 필요.
- 제약 없는 `<C>(c: C)` 로 값을 받으면 `T = unknown` 으로 다 통과 — 트레이트가 아니라 AA 3번(0.742 에서도 그대로, `k(c)` 0건).
- 런타임 `entryMiss` 는 구현이 없을 때도 "(or the value was copied: Trait.Restore it)" 을 붙여 오해를 부름.

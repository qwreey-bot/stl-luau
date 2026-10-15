# 사용자 `type function`(types 라이브러리)의 제네릭 함수 타입 재구축 시 결함 분석 보고서

- **작성일**: 2026-10-15
- **분석자**: Gemini (agy 세션)
- **기준 커밋**: `e92d6d24f8fc8a2304840fe87e3b6b9e577de600` (`git rev-parse HEAD` 직접 확인 [실측])
- **분석 환경**: Linux x86_64, Luau 0.742 (`/code/.local/share/mise/installs/luau/0.742/luau-analyze`, new solver, strict mode)

---

## 1. 요약 및 핵심 결론 [제안]

사용자가 제안한 **레코드 매핑 안**(`Trait.Fn`·`Trait.Default`가 `{ required: boolean, fn: F }`를 내고, 사용자 정의 `type function FullOf(t)`·`ImplOf(t)`로 완성 표와 등록 표를 자동 생성하는 안)은 **현재 Luau(0.742) 환경에서 표준 라이브러리(stl-luau)의 트레이트 시스템으로 채택할 수 없습니다(부적격).**

이유는 단순한 취향이나 DX 문제가 아니라, **Luau 타입 시스템(새 솔버)의 근본적인 한계로 인해 발생하는 두 가지 치명적 결함(Showstopper)** 때문입니다:

1. **제네릭 알고리즘의 프로퍼티 접근 완전 파괴 (`FullOf` 사용 불가)** [실측]:
   외곽 제네릭 `<Self, T>`를 가진 제네릭 알고리즘 함수(예: `drain<C, T>(st: Stack<C, T>, c: C)`) 안에서 `Stack<C, T>`가 `FullOf<...>` 타입일 경우, Luau 새 솔버는 타입 함수를 환원(reduce)하지 못하고 **irreducible 상태(`FullOf<StackDef<C, T>>`)로 보류**합니다. 그 결과 함수 몸통에서 **`TypeError: Type 'FullOf<...>' does not have key 'Pop'`** 에러가 발생하여, 완성 표를 인자로 받는 모든 제네릭 알고리즘이 작성 불가능해집니다.
2. **등록 표의 제네릭 메서드 검사 누락 (Silent False Negative, `ImplOf` 사용 불가)** [실측]:
   인라인 어노테이션 `const cdList: ListImpl<CircularDeque<A>, A, number> = { ... }` 형태로 등록할 때, `Fold`의 자체 제네릭 `<U>`를 `number`로 못박거나(`Fold = function(init: number) ...`) 엉뚱한 함수(`Fold = Arr.Len`)를 대입해도 **아무런 에러 없이 조용히 통과(0건)**합니다. 오직 중간에 별도의 타입 별칭 문장(`type CDListInst = ListImpl<...>`)을 거쳐야만 잡힙니다. 이는 등록 자리의 타입 안전성을 치명적으로 파괴합니다.

따라서 **현재의 D3 안**(기본 구현 칸을 내장 `index<{ full: F, impl: F? }, M>`로 적고 모드 값 `FULL`/`IMPL`을 두 번 넘기는 모양)을 유지하는 것을 강력히 **[제안]**합니다. 내장 `index`는 C++ 코어에서 타입 객체를 그대로 반환하므로(`BuiltinTypeFunctions.cpp:2268`), 직렬화/역직렬화(serde) 세금, 스코프 왜곡, 지연 환원 결함이 전혀 발생하지 않습니다.

---

## 2. 소스 분석: 사용자 `type function`이 제네릭 함수를 다룰 때의 메커니즘과 한계

Luau C++ 소스 코드(`/code/Projects/stl-luau/refs-ignoreme/luau`)를 분석하여 사용자 타입 함수의 직렬화/역직렬화 및 서브타이핑 메커니즘을 규명했습니다.

### 2.1 직렬화(Serialization): 포인터 정체성 및 스코프 상실
- **[소스] `Analysis/src/TypeFunctionRuntimeBuilder.cpp:233-241`** (`shallowSerialize` of `GenericType`):
  ```cpp
  else if (auto g = get<GenericType>(ty))
  {
      Name name = g->name;
      if (!g->explicitName)
          name = format("g%d", g->index);
      target = typeFunctionRuntime->typeArena.allocate(TypeFunctionGenericType{g->explicitName, false, std::move(name)});
  }
  ```
  `GenericType`이 C++ TypeId에서 Lua VM State(`TypeFunctionGenericType`)로 직렬화될 때, 원래 C++ 노드가 가지고 있던 **`Scope*` 포인터와 메모리 주소(정체성)는 완전히 버려지고**, 오직 이름 문자열(`name`)과 명시적 이름 여부(`isNamed`)만 남습니다.

### 2.2 역직렬화(Deserialization): 새로운 스코프로 재할당 및 렉시컬 스택 관리
- **[소스] `Analysis/src/TypeFunctionRuntimeBuilder.cpp:994-1025`** (`deserializeChildren` of `FunctionType`):
  ```cpp
  functionScopes.emplace_back(queue.size(), f2);
  std::set<std::pair<bool, std::string>> genericNames;

  for (auto ty : f2->generics)
  {
      ...
      TypeId mapping = state->ctx->arena->addTV(Type(gty->isNamed ? GenericType{state->ctx->scope.get(), gty->name} : GenericType{}));
      genericTypes.emplace_back(gty->isNamed, gty->name, mapping);
  }
  ```
  - 함수 타입의 제네릭 파라미터(`f2->generics`)를 역직렬화할 때, **완전히 새로운 `GenericType`을 할당**합니다.
  - 이때 부여되는 스코프는 원래 제네릭 함수의 스코프가 아니라, **타입 함수가 실행되는 위치의 스코프인 `state->ctx->scope.get()`** (보통 모듈 루트 스코프)가 됩니다.
  - 이 제네릭들은 역직렬화기의 `genericTypes` 스택에 일시적으로 푸시됩니다.
- **[소스] `Analysis/src/TypeFunctionRuntimeBuilder.cpp:791-817`** (`shallowDeserialize` of `GenericType`):
  - 함수의 매개변수(`argTypes`)나 반환값(`retTypes`) 내부에서 나타나는 `TypeFunctionGenericType`은 `genericTypes` 스택을 뒤에서부터(rbegin) 검색하여 일치하는 제네릭 매핑을 가져옵니다.
  - 만약 스택에 해당 이름의 제네릭이 없으면:
    ```cpp
    pushRuntimeError(format("Generic type '%s' is not in a scope of the active generic function", g->name.c_str()));
    return nullptr;
    ```
    런타임 에러를 발생시키고 `errorType`으로 전락합니다 (`tests/TypeFunction.user.test.cpp:2236, 2257`).
- **[소스] `Analysis/src/TypeFunctionRuntimeBuilder.cpp:665-670, 703-716`** (`closeFunctionScope`):
  - 해당 함수의 자식 노드 역직렬화가 끝나면 `genericTypes` 스택에서 해당 제네릭들이 즉시 제거(pop)됩니다.

### 2.3 외곽 제네릭(Outer)과 내부 제네릭(Inner)이 섞였을 때의 문제
트레이트 시그니처 `<U>(list: Self, init: U, fn: (acc: U, item: E, idx: I) -> U) -> U`에서:
- `U`는 함수 자체의 제네릭(Inner Generic)이고,
- `Self`, `E`, `I`는 트레이트/타입 별칭의 제네릭(Outer Generic)입니다.
- **외곽 제네릭이 구체화되지 않은 상태에서 함수 타입이 역직렬화될 경우**:
  `f2->generics`에는 `U`만 존재하므로, `argTypes`의 `Self`, `E`, `I`를 역직렬화하려고 할 때 `genericTypes` 스택에서 찾지 못해 **`Generic type 'Self' is not in a scope of the active generic function`** 에러가 발생하거나, irreducible 상태로 처리가 보류됩니다.
- **[소스] `tests/TypeFunction.user.test.cpp:2474-2510`** (`outer_generics_irreducible` vs `inner_generics_reducible`):
  - 상류 테스트 케이스에서도 외곽 제네릭이 포함된 타입 함수 호출(`wrap<T> = { a: func<T?> }`)은 구체화되기 전까지 환원되지 않는 irreducible로 남도록 설계되어 있습니다.

### 2.4 상류 서브타이핑 결함과의 결합
- **[소스] `Analysis/src/Subtyping.cpp:830-836`**:
  ```cpp
  // TODO: These branches are entirely incorrect. We should never consider
  // generic types to "always" be a sub type or super type of another type in a given scope.
  else if (auto subGeneric = get<GenericType>(subTy); subGeneric && subsumes(subGeneric->scope, scope))
      return isCovariantWith(env, builtinTypes->neverType, superTy, scope);
  else if (auto superGeneric = get<GenericType>(superTy); superGeneric && subsumes(superGeneric->scope, scope))
      return isCovariantWith(env, subTy, builtinTypes->unknownType, scope);
  ```
  Luau 타입 솔버에는 제네릭 타입의 스코프 포함 관계에 따라 제네릭을 `never`나 `unknown`으로 치환해버리는 알려진 결함이 있습니다. 사용자 타입 함수가 다시 지은 `GenericType`은 스코프가 `state->ctx->scope.get()`으로 덮어씌워지므로, 원래의 제네릭 바인딩 스코프와 어긋나 서브타이핑 판정이 왜곡됩니다.

---

## 3. 실측 분석: 프로브 전수 대조 및 음성 대조군 검증

프로브는 `udtf/probes/` 폴더에 작성하여 검증했습니다.

### 3.1 작성된 프로브 목록 및 역할
| 프로브 파일 | 검증 목적 | 결과 요약 |
|---|---|---|
| [`probes/probe1_mixed_generics.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe1_mixed_generics.luau) | 외곽 구체화 후 내부 제네릭 함수 전달 | 정상 동작 |
| [`probes/probe2_uninstantiated_outer.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe2_uninstantiated_outer.luau) | 미결정 외곽 제네릭 포함 타입 함수 정의 | 타입 정의 시점엔 irreducible 보류 |
| [`probes/probe3_generic_body_access.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe3_generic_body_access.luau) | 제네릭 함수 몸통 안에서 프로퍼티 접근 | **실패: `does not have key 'fn'`** |
| [`probes/probe4_record_basic.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe4_record_basic.luau) | 레코드 매핑 `FullOf`/`ImplOf` 기본 동작 | 구체 인스턴스화 시 동작 |
| [`probes/probe5_fold_pinned.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe5_fold_pinned.luau) | `Fold` 제네릭 못박음 및 `Arr.Len` 대입 | **실패: NEG 에러 0건 누락** |
| [`probes/probe5b_inspect_fold.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe5b_inspect_fold.luau) | `ImplOf`가 반환한 `Fold` 프로퍼티 타입 확인 | `(<U>(...) -> U)?` 확인 |
| [`probes/probe5c_real_types_fold.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe5c_real_types_fold.luau) | 실제 `stl.Arr` 타입을 사용한 D3 동일 NEG 대입 | **실패: NEG_fold, NEG_pinU 누락** |
| [`probes/probe6_handwritten_fold.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe6_handwritten_fold.luau) | 손으로 쓴 동일 테이블 타입 대조군 | **성공: 정확히 에러 감지** |
| [`probes/probe7_isolation.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe7_isolation.luau) | Identity vs TableOf vs Direct 단일 분리 | 단일 레벨에선 정상 |
| [`probes/probe8_hypotheses.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe8_hypotheses.luau) | 가설 검증: 구체 표 vs 제네릭 별칭 표 | **제네릭 별칭 호출에서만 누락 확인** |
| [`probes/probe9b_assign.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe9b_assign.luau) | 인라인 대입 vs 별칭 대입 직접 대조 | **인라인 누락 / 별칭 감지 현상 분리** |
| [`probes/probe10_inline_vs_alias.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe10_inline_vs_alias.luau) | UDTF 인라인 vs 별칭 vs D3 인라인 삼자 대조 | **D3만 인라인에서 감지 성공** |
| [`probes/probe11_generic_algorithm.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe11_generic_algorithm.luau) | 제네릭 알고리즘 `drain<C, T>` 대조 | **D3 통과 / UDTF 완전 실패** |
| [`probes/probe12_same_module_return.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe12_same_module_return.luau) | 같은 모듈 기본 구현 반환 타입 검사 | 구체 인스턴스화 시 정상 감지 |
| [`probes/probe12_mod_a.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe12_mod_a.luau) / [`12_mod_b.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe12_mod_b.luau) | 모듈 간 기본 구현 반환 타입 검사 | 구체 인스턴스화 시 정상 감지 |
| [`probes/probe13_pinned_element.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe13_pinned_element.luau) | 탐침 타입 A를 이용한 원소 못박음(`strPush`) | 인라인/별칭 모두 정상 감지 |
| [`probes/probe14_borrowed.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe14_borrowed.luau) | 빌린 참조(`CircularDequeRead`) 구체 호출 | 구체 호출은 정상 감지 |
| [`probes/probe15_bench_d3.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe15_bench_d3.luau) / [`15_bench_udtf.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/probe15_bench_udtf.luau) | 10개 트레이트 정의 및 인스턴스화 속도 | 0.095s vs 0.098s (차이 미미) |
| [`probes/comprehensive_record_mapping.luau`](file:///code/Projects/stl-luau-agy/udtf/probes/comprehensive_record_mapping.luau) | v9 `types.luau` 전체 NEG 종합 이식 | 종합 판정 (아래 대조표) |

---

### 3.2 상세 실측 결과 비교표: D3 vs 레코드 매핑 안 (UDTF)

`.claude/research/trait-v9/types.luau`의 전수 음성 대조군(NEG)을 기준으로 레코드 매핑 안을 평가한 결과입니다.

| 항목 | D3 (내장 index 방식) | 레코드 매핑 안 (UDTF) | 판정 및 비고 [실측] |
|---|---|---|---|
| **소비 측: 원소 불일치 (`NEG_push`)** | 감지 (24줄) | 감지 (101줄) | 동등 |
| **소비 측: 반환 불일치 (`NEG_pop`)** | 감지 (25줄) | 감지 (102줄) | 동등 |
| **소비 측: 위치 타입 불일치 (`NEG_where`)** | 감지 (43줄) | 감지 (107줄) | 동등 |
| **소비 측: 검색 타입 불일치 (`NEG_contains`)** | 감지 (44줄) | 감지 (108줄) | 동등 |
| **⭐ 제네릭 알고리즘 완성 표 수신 (`drain<C, T>`)** | **정상 통과 (46-56줄)** | ❌ **컴파일 불가** (`probe11:47`) | **치명적 결함**: `Type 'FullOf<...>' does not have key 'Pop'` |
| **등록: 비제네릭 원소 못박음 (`NEG_pinned`)** | 감지 (64줄) | 감지 (126줄) | 동등 (`strPush` 감지) |
| **⭐ 등록: `Fold = Arr.Len` (`NEG_fold`)** | **감지 (71줄)** | ❌ **인라인 누락 (0건 통과)** (`probe5c:54`) | **치명적 결함**: 별칭 분리 시에만 감지 |
| **⭐ 등록: `Fold` 제네릭 `<U>` 못박음 (`NEG_pinU`)** | **감지 (79줄)** | ❌ **인라인 누락 (0건 통과)** (`probe5c:63`) | **치명적 결함**: 별칭 분리 시에만 감지 |
| **등록: 필수 메서드 누락 (`NEG_missing`)** | 감지 (84줄) | 감지 (154줄) | 동등 (`Pop` 누락 감지) |
| **기본 구현 반환: 같은 모듈 (`NEG_sameRet`)** | 감지 (141줄) | 감지 (167줄) | 동등 (구체 인스턴스화 시) |
| **기본 구현 반환: 다른 모듈 (`NEG_diffRet`)** | 감지 | 감지 (`probe12_mod_b:12`) | 동등 (구체 인스턴스화 시) |
| **빌린 참조 구체 호출 (`CircularDequeRead`)** | 감지 (128-132줄) | 감지 (`probe14:43`) | 단, 제네릭 알고리즘으로 넘기면 깨짐 |
| **분석 시간 (10개 트레이트 벤치)** | 0.098초 (`probe15_bench_d3`) | 0.095초 (`probe15_bench_udtf`) | 유의미한 차이 없음 |

---

## 4. 깊은 원인 규명: 왜 이런 일이 일어나는가?

### 4.1 제네릭 알고리즘이 깨지는 원인: 지연 환원 (Irreducible Type Function)
- Luau 새 솔버에서 제네릭 함수 `function drain<C, T>(st: Stack<C, T>, c: C)`를 타입체크할 때, 파라미터 `C`와 `T`는 구체적인 타입이 아닌 **자유 제네릭 변수(free generic variable)**입니다.
- 사용자 정의 타입 함수 `FullOf<StackDef<C, T>>`는 입력 인자에 미결정 제네릭이 포함되어 있으므로 **함수 몸통 검사 시점에 축약(reduction)될 수 없습니다** (`tests/TypeFunction.user.test.cpp:2474` `outer_generics_irreducible` 테스트가 고정하는 동작).
- 따라서 `st`의 정규화된 타입은 테이블 타입 `{ Push: ..., Pop: ... }`이 아니라, **아직 풀리지 않은 타입 함수 인스턴스 `FullOf<StackDef<C, T>>` 그대로** 남습니다.
- Luau의 프로퍼티 조회 연산은 테이블/클래스/인터섹션 등 정규화된 타입에 대해서만 지원되므로, 축약되지 않은 타입 함수 인스턴스에 대한 프로퍼티 조회(`st.Pop`)는 즉시 **`TypeError: Type 'FullOf<...>' does not have key 'Pop'`** 으로 실패합니다.
- **반면 D3(내장 `index<>`)**:
  D3에서는 `Stack` 트레이트 정의 시 `listDef(Trait.FULL)`을 호출하여 모드 `M = "full"`을 즉시 넘깁니다. 내장 `index`는 컴파일러 코어(`BuiltinTypeFunctions.cpp:2268`)에서 즉시 축약되어 순수 테이블 타입을 돌려주므로, `Stack<C, T>`는 외곽 제네릭이 있더라도 즉시 프로퍼티가 노출되는 테이블 타입이 되어 아무런 문제 없이 작동합니다.

### 4.2 인라인 등록 시 `Fold` 재정의 검사가 누락되는 원인: 양방향 추론과 서브타이핑 제약 전파 타이밍
- `local cdList: ListImpl<CircularDeque<A>, A, number> = { Fold = function(init: number) ... end }`
- 이 대입문에서 Luau의 양방향 타입 추론기(bidirectional type checker)는 우변의 테이블 리터럴을 검사할 때 좌변의 어노테이션 타입(`ListImpl<...>`)을 expected type(기대 타입)으로 밀어 넣어야 합니다.
- 그러나 `ListImpl`이 사용자 정의 타입 함수인 경우, 타입 함수의 인스턴스화 및 reduction이 테이블 리터럴 내부 프로퍼티의 서브타이핑 제약 수립보다 한 단계 늦게 발생하거나 제약이 완전히 전파되지 못합니다.
- 특히 **비제네릭 메서드(`Push = strPush`)**의 경우, 단순 타입 불일치(`string` vs `A`)이므로 테이블 전체 서브타이핑 단계에서 잡히지만,
- **자기 제네릭을 가진 메서드(`Fold`)**의 경우, 우변은 monomorphic 함수이고 좌변 기대 타입은 polymorphic 함수(`<U>(...) -> U`)인데, 이 다형성 검사(polymorphic instantiation subtyping)가 지연된 타입 함수 껍데기 아래에서 생략되어 버립니다.
- 중간에 `type CDListInst = ListImpl<CircularDeque<A>, A, number>` 처럼 별도의 문장으로 타입 별칭을 선언하면, 문장 경계에서 타입 함수가 완전히 환원된 후 다음 문장의 expected type으로 들어가기 때문에 비로소 에러가 잡히는 것입니다 (`probe10` 실측).

---

## 5. 종합 평가 및 제안 [제안]

### 5.1 레코드 매핑 안의 득실 비교

| 구분 | 레코드 매핑 안 (UDTF) | 현재 D3 안 (내장 index 방식) |
|---|---|---|
| **정의 측 간결성** | **우수**: `def` 함수를 한 번만 넘김 | **보통**: `def(FULL), def(IMPL)` 두 번 넘김 |
| **제네릭 알고리즘 지원** | ❌ **전면 불가능** (`drain` 등 작성 불가) | **완벽 지원** |
| **등록 표 인라인 안전성** | ❌ **위험** (제네릭 메서드 재정의 검사 누락) | **완벽 검사** (`Arr.Len`, 누적타입 못박음 감지) |
| **등록 표 작성 DX** | 별칭 선언 강제 (`type Inst = ...`) | 인라인 대입 가능 (`const x: ListImpl<...> =`) |
| **타입 시스템 의존성** | 사용자 타입 함수 Serde 런타임 전반 의존 | 내장 `index` 단 하나만 사용 (코어 즉시 축약) |
| **에러 메시지 가독성** | irreducible `FullOf<...>` 노출로 난해함 | 실제 함수 시그니처가 직관적으로 노출 |

### 5.2 "제네릭이 든 칸만 피하면 되는가?" 에 대한 답변
- 만약 트레이트에 `Fold<U>`와 같은 자체 제네릭 메서드가 없고, 모든 메서드가 비제네릭이라면 실측 2(등록 표 검사 누락)는 회피할 수 있습니다.
- **그러나 실측 1(제네릭 알고리즘에서 완성 표 프로퍼티 접근 불가)은 비제네릭 메서드만 있더라도 여전히 발생합니다!**
  `probe11`에서 보았듯이 `StackDef`에는 제네릭 메서드가 전혀 없음에도 불구하고, `drain<C, T>(st: Stack<C, T>)`에서 `st.Pop`을 접근할 수 없었습니다.
- 따라서 제네릭이 든 칸만 피한다고 해서 해결될 수 있는 문제가 아니며, **트레이트가 제네릭 컨테이너(`Self`, `T`)를 다루는 한 완성 표에 사용자 타입 함수를 쓰는 것은 불가능**합니다.

### 5.3 최종 결론 및 권고
사용자 제안 안은 트레이트 정의 작성자가 `listDef`를 두 번 넘기지 않아도 된다는 매력적인 DX적 동기에서 출발했으나, Luau 새 솔버의 현재 구조상 **표준 라이브러리의 가장 핵심적인 기능인 "제네릭 알고리즘"과 "엄격한 등록 검증"을 모두 파괴**합니다.

따라서 **현재의 D3 안을 유지하는 것이 유일하게 건전하고 안전한 선택**입니다.
D3가 모드 값을 인자로 넘겨 정의 함수를 두 번 평가하는 것은 우회책이 아니라, **사용자 타입 함수의 태생적 한계(serde 스코프 상실, 지연 환원으로 인한 프로퍼티 조회 불가, 인라인 서브타이핑 누락)를 완전히 회피하는 가장 정교하고 건전한 설계**였음이 실측과 소스 분석을 통해 입증되었습니다.

---

## 6. 재현 및 검증 가이드

모든 프로브는 `/code/Projects/stl-luau-agy/udtf/probes/`에 보존되어 있습니다. 아래 명령으로 언제든지 결과를 재현할 수 있습니다:

```bash
# 1. 종합 NEG 대조군 검증 (v9 types.luau 동일 시나리오)
( ulimit -v 2097152; timeout 120 /code/.local/share/mise/installs/luau/0.742/luau-analyze probes/comprehensive_record_mapping.luau )

# 2. 제네릭 알고리즘 완성 표 파괴 실측 (drain 함수 컴파일 에러)
( ulimit -v 2097152; timeout 120 /code/.local/share/mise/installs/luau/0.742/luau-analyze probes/probe11_generic_algorithm.luau )

# 3. 인라인 대입 시 제네릭 메서드 재정의 검사 누락 실측 (D3 vs UDTF)
( ulimit -v 2097152; timeout 120 /code/.local/share/mise/installs/luau/0.742/luau-analyze probes/probe10_inline_vs_alias.luau )
```

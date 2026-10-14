# Luau 0.742 소스에서 찾은 트레이트 설계의 근거 (2026-10-14)

`luau-analyze` 로 겉에서 관찰해 정한 솔버 사실들의 **원인을 소스에서** 찾은 기록. 소스는 `refs-ignoreme/luau`(태그 0.742 = 지금 master, gitignore).

| 무엇 | 누가 | 어디 |
|---|---|---|
| 제네릭 몸통이 검사되지 않는 원인, 표 리터럴 인자가 안 되는 원인 | Opus(직접 빌드·고친 판으로 확인) | 아래 본문, 프로브·고친 판 `opus-probes/` |
| 내장 `index<>`·오버로드 해석 | Gemini | `../../audit/agy/2026-10-14-src-index.md` |
| 명시적 타입 인자·`typeof` 별칭 | Gemini | (돌고 있음) |
| 상류 이슈·RFC 검색 | Sonnet | `sonnet-web.md` |

## 메인이 확인한 결론

1. **제네릭 몸통 결함의 뿌리는 `Subtyping.cpp:830-835`** — 스코프 안 제네릭을 서브타입 쪽이면 `never`, 슈퍼타입 쪽이면 `unknown` 으로(상한·하한을
   뒤바꾼 모양). 상류 주석 *"TODO: These branches are entirely incorrect"*, 내부 티켓 CLI-225132, 739 의 땜질은 기대 타입이 **정확히** 그 제네릭일 때만
   (그래서 맨 `T` 는 잡히고 `T?` 는 안 잡힘). Opus 와 Gemini 가 독립적으로 같은 줄을 짚음, 메인이 줄 확인. → **탐침 타입 몸통은 원리상 맞는 우회**(구체 타입이라
   그 갈래를 안 탐 — 결함이 고쳐져도 유효).
2. ⭐ **"표 리터럴은 주석 단 지역에서만" 은 설계 사실이 아니라 결함(캐시 오염)의 부작용** — 받는 타입의 필드가 읽기·쓰기면 불변 비교가 실패하고 그
   거짓이 캐시에 남아 리터럴용 검사와 **같은 모듈의 뒷줄**까지 실패. **받는 타입의 필드를 `read` 로 적으면 인자 자리에서도 됨**(메인 확인 — 실패하는
   줄과 같은 파일에 두면 오염돼 안 되는 것처럼 보임: 메인이 처음엔 그래서 "안 된다" 고 잘못 결론냈음). 함수 값에 `PushBack<<A>>` 를 붙여도 됨.
   **캐스트는 검사가 아님**(함수끼리는 늘 통과). 상류에 흔적 없음 → `DRAFTS.md` 6번.
3. 덜 줄어든 `index<>` 는 서브타입 검사에서 `never` 로 떨어짐 → 정의와 같은 모듈에서 v8 모양(모드를 추론에 맡김)을 쓰면 기본 구현 칸 반환 검사가 사라짐
   (`../../audit/agy/2026-10-14-src-index-probes/main-v8-same-module-hole.luau`). 모드를 밝혀 적으면(`def<<"full">>, def<<"impl">>`) 안정.

---

# Opus 보고서 원문 (하네스가 파일 쓰기를 막아 메인이 옮김)

- 소스: `refs-ignoreme/luau` @ `8387cfb`(0.742). 설치된 0.742 와 같은 소스를 직접 빌드(무수정판 출력 = 설치판), 한 군데씩 고친 판으로 원인 확인.
- 표기: [소스] 소스에서 읽음, [실측] 프로브, [추측]. 프로브·출력·고친 소스는 `opus-probes/`(빌드한 바이너리는 옮기지 않음 — 다시 만들려면 소스 복사 후
  `cmake -DLUAU_BUILD_TESTS=OFF`, `make Luau.Analyze.CLI`, 4코어 약 10분).

## 요약

| | 원인 | 의도된 것인가 | 우리 설계에 뜻하는 것 |
|---|---|---|---|
| 1. 제네릭 몸통이 검사되지 않음 | `Subtyping` 이 지금 스코프 안의 제네릭을 서브타입 쪽이면 `never`, 슈퍼타입 쪽이면 `unknown` 으로 바꿔 끼움(Subtyping.cpp:830-835). 맨 `T` 자리만 잡히는 것은 땜질 플래그 `LuauSoundGenericMismatches`(TypeChecker2.cpp:3944-3990, `HACK(CLI-225132)`) — 기대 타입이 정확히 그 제네릭일 때만 | 결함으로 인정(CLI-225132, 테스트의 `FIXME … unsound`). 고치기 어렵다고 적혀 있고, 순진하게 고친 판은 우리 저장소에서 4522건 | 몸통 검사는 "모양만 잡음". 탐침 타입 몸통이 원리상 맞는 우회 — 고쳐져도 유효 |
| 2. 표 리터럴 안의 제네릭 함수가 지역 초기화에서만 됨 | 인자·`return`·대입 자리는 표 전체를 먼저 일반 서브타입으로 비교. 읽기쓰기 필드는 불변이라 반대 방향 비교가 실패하고, 그 실패가 캐시에 남아 뒤따르는 리터럴용 공변 검사까지 실패 | 캐시 오염은 결함(소스에 TODO·테스트 없음 — 상류에 안 알려진 듯[추측]). 두 줄 고친 판(P1)에서 사라지고 우리 저장소 0건 그대로 | 받는 타입의 필드를 `read` 로 적으면 지금도 인자 자리에서 되고 검사도 됨. 함수 값에 `PushBack<<A>>` 도 됨. 캐스트는 검사가 아님 |

부수: 캐시 오염은 모듈 전체에 퍼짐(한 줄이 실패하면 뒤의 멀쩡한 줄에도 가짜 에러 — `p6/23`). `bidir-table-arg.luau` 의 `takeFn(id)` 실패는 오염의 결과(혼자 두면 통과 — `p5/6`).

## 1. 제네릭 함수 몸통 안이 검사되지 않음

### 1-1. 몸통 안의 타입 매개변수 [소스]
`checkFunctionSignature` 가 `signatureScope = childScope(fn, parent)`, `bodyScope = childScope(fn->body, signatureScope)` 를 만듦(ConstraintGenerator.cpp:4442-4449).
`createGenerics(signatureScope)`(4453 → 5257)가 `GenericType{scope = signatureScope}` 를 만들어 함수 타입의 `generics` 에 넣음(4663). 몸통 안의 `T` 는
끝까지 `GenericType`(자유 타입 아님, 일반화도 안 거침). 에러는 `TypeChecker2` 가 `subtyping->isSubtype(sub, super, scope)`(scope 는 몸통 안이면 bodyScope —
예: TypeChecker2.cpp:4177-4180)로 냄.

### 1-2. 검사가 빠지는 곳 [소스]
Subtyping.cpp:830-835 — `subsumes`(Scope.cpp:301-307)는 몸통 안에서 늘 참이라 `T <: X` 가 `never <: X`, `X <: T` 가 `X <: unknown`(둘 다 참). 경직된 변수라면
서브타입 쪽은 상한(`unknown`), 슈퍼타입 쪽은 하한(`never`)이어야 함 — 뒤바뀜. 이 갈래가 유니온·교집합 분해(910줄 이후)보다 **앞**이라 `T?`·`{ T }` 도 안쪽
`T` 비교에서 샘. 갈래는 release 595(2023-09)부터, TODO 주석은 718(2026-04)에서(`git log -S`).

### 1-3. 왜 맨 `T` 만 잡히나 [소스·실측]
땜질 플래그 `LuauSoundGenericMismatches`(TypeChecker2.cpp:44, release 739 = 2026-09-18): 기대 타입을 follow 한 결과가 **정확히** 스코프 안의 `GenericType` 일
때만 직접 거절(식의 타입이 그 제네릭 자신·free·never·그 제네릭을 품은 교집합이면 거절 안 함). `T?` 는 유니온이라 해당 없음. 닿는 자리는
`testLiteralOrAstTypeIsSubtype` 를 거치는 곳뿐 — `return`(795·842·855), 대입(1338), 제네릭이 아닌 함수의 호출 인자(2204). **지역 초기화는 아님**
(`AstStatLocal` 은 `testPotentialLiteralIsSubtype` 를 바로, 921-924). CLI 는 실험적이지 않은 `Luau*` 플래그를 다 켬(CLI/src/Flags.cpp:40-45) — Studio·luau-lsp 는
꺼져 있을 수 있음[추측].

| 몸통 안의 줄 | 0.742 | 땜질 플래그를 끈 판 |
|---|---|---|
| `return x`(`T`) → `string` 자리 | 0건 | 0건 |
| `return 5` → `T` 자리 | 잡힘 | 0건 |
| `return 123` → `T?` 자리 | 0건 | 0건 |
| `return x`(`number?`) → `T?` 자리 | 0건 | 0건 |
| `local y: number = x`(`x: T`) | 0건 | 0건 |
| `local y: T = "s"`(지역이라 땜질 밖) | 0건 | 0건 |
| `y = 5`(`y: T`, 대입) | 잡힘 | 0건 |
| `inner(5)`(`inner(z: T)`) | 잡힘 | 0건 |
| `innerOpt(5)`(`z: T?`) | 0건 | 0건 |
| `xs[1] = 5`(`xs: { T }`) | 0건 | 0건 |
| `return x`(`T`) → `U` 자리 | 잡힘 | 0건 |
| `return { 5 }` → `{ T }` 자리 | 0건 | 0건 |
| `return function(v: number) end` → `(T) -> ()` 자리 | 0건 | 0건 |

(`p1-body.luau`, `p3-hack-reach.luau`, `out-0.742-flagoff.txt`)

### 1-4. 의도된 것인가 [소스]
결함 인정 흔적 셋: Subtyping.cpp:830 의 TODO, TypeChecker2.cpp:3950 의 `HACK(CLI-225132)`, `TypeInfer.generics.test.cpp:118-140` 의 `FIXME(CLI-225132): This is
unsound`(지금의 무에러를 고정 — 고쳐지면 뒤집힘). 반대로 `Subtyping.test.cpp:1789-1813` 의 `"unknown <: X"` 는 지금 동작을 단언. HACK 주석에 *"not been making
good headway"*. 직접 고친 판 P1+P2+P3(스코프 안 제네릭을 경직된 변수로, 유니온·교집합 먼저 분해): 프로브 NEG 는 전부 잡혔으나 우리 `src tests` 에서 **4522건**
(대부분 `assert<T>` 같은 내장 선언의 제네릭 — 정의 파일의 제네릭은 전역 스코프라 `subsumes` 가 어디서나 참). 가까운 시일에 고쳐지리라 기대하지 않음[추측].

### 1-5. 몸통 안에서도 검사되게 적는 법
- **(가) 탐침 타입 몸통 — 원리상 맞는 우회** [실측 `p7-probe-type.luau`]: `{ read __probeA: true }` 는 봉인된 구체 테이블이라 830-835·895-908 의 제네릭
  갈래를 안 타고 구조적 비교를 받음(교과서의 "스콜렘으로 몸통 검사" 를 손으로). `A <: A?` 같은 정상 코드 통과, NEG 넷 잡힘. 경계(구조적이라 0건): `A <: {}`,
  필드 이름을 아는 `{ read __probeA: boolean }`, `any`. 결함이 고쳐져도 영향 없음.
- **(나) 주석 단 지역 + 제네릭 없는 람다** [실측 `p2-annotated-lambda.luau`]: `const f: <T>(x: T) -> T? = function(x) … end` — 람다가 주석의 제네릭을 쓰는데
  그 스코프가 주석 쪽(4989-4992)이라 몸통이 자손이 아님 → 895 의 "묶이지 않은 제네릭" 갈래로 거짓 → p1 의 실수가 전부 잡힘. 그러나 이 갈래도 유니온 분해보다
  앞이라 `T <: T?` 까지 거짓 — `return x` 같은 정상 코드가 에러. 실용적이지 않음.
- **(다) 기대 타입을 정확히 `T` 로** — 땜질에 기대고 `T?` 에 무력. 권하지 않음.

## 2. 표 리터럴 안의 제네릭 함수는 지역 초기화에서만 됨

### 2-1. 경계 [실측 `p5/`, 한 파일에 한 줄씩]
| 모양 | 결과 |
|---|---|
| 제네릭 함수 하나를 그대로: `local f: (number)->number = id`, `return id`, `takeFn(id)` | 전부 됨 |
| 표 리터럴, 지역 초기화 | 됨 |
| 표 리터럴, 대입·`return`·`takeSpec({ process = id })` | 실패 |
| `takeSpec({…})` 다음 줄의 `takeFn(id)`(p5/12) | 실패 — 앞 줄을 빼면 됨(p5/13·6) |

### 2-2. 원인 [소스]
① 양방향 추론은 여기서 아무것도 안 함 — `BidirectionalTypePusher` 는 값이 리터럴·람다·괄호·if 식일 때만 기대 타입을 밀어 넣음(TableLiteralInference.cpp,
`isCheckableExpr` 110-118, 165-170). `id` 는 지역 변수라 그대로 → 표의 타입은 어느 자리든 `{ process: <T>(T)->T }`(읽기쓰기 필드).
② 진입 함수가 자리마다 다름 — **지역 초기화**는 `testPotentialLiteralIsSubtype`(921-924): 표 리터럴이면 필드마다 기대 필드의 읽기 타입과 공변 비교(4102-4137),
sub 쪽 함수의 제네릭은 묶을 수 있는 변수로 올라가(Subtyping.cpp:2446-2460) 경계를 모아 확인(2522-2535)하고 통과. **인자·`return`·대입**은
`testLiteralOrAstTypeIsSubtype`: 먼저 표 전체를 일반 서브타입으로(3992) — 읽기쓰기 필드는 불변(2669-2674 → `isInvariantWith` 1578-1582)이라 반대 방향
`(number)->number <: <T>(T)->T` 도 봄. super 쪽 제네릭은 안 묶여 895-908 에서 거짓. 실패하면 리터럴용 검사로(3997).
③ 캐시 오염 — 그 거짓이 `isCacheable` 기본 참(Subtyping.h:113)이라 `cache()`(693-698, 1007)에 남음. 다시 하는 공변 검사에서는 `T` 가 묶여 통과해야 하는데
`isCovariantWith` 가 묶였는지 보기 **전에** 캐시부터 봄(722-733). 캐시는 모듈 검사 내내 삶(`Subtyping` 인스턴스 하나, TypeChecker2.cpp:362).
**증명** [실측]: 묶이지 않은 제네릭의 결과를 캐시하지 않게 두 줄 고친 P1 으로 2-1 과 p6 의 실패가 전부 사라지고 NEG(원소를 못박은 `strPush`)는 그대로
잡힘(p6/04·11·13·19·25). 변수에 담은 읽기쓰기 표(p6/18)는 여전히 거절 — 상류가 의도로 고정(`TypeInfer.tables.test.cpp:3976-4000`
*"invariant_table_properties_means_instantiating_tables_in_call_is_unsound"*; 리터럴만 공변으로 봐도 건전해서 리터럴 경로가 따로 있음). 우리 `src tests` 는 P1 에서도 0건.

### 2-3. 지금 인자 자리에서도 되게 하는 모양 [실측 `p6/`]
| 모양 | 정상 | NEG | 비고 |
|---|---|---|---|
| 받는 타입의 필드를 `read` 로 | 됨(인자 03, 반환 20, 변수 17) | 잡힘(04·19) | 표 전체 비교가 처음부터 공변이라 실패·오염이 없음. 제네릭 등록 함수에 `<<Arr<A>, A>>` 도 됨(10·11) |
| 필드 값에 `Push = PushBack<<A>>` | 됨(24) | 잡힘(25) | 정식 기능(`AstExprInstantiate`, ConstraintGenerator.cpp:3839; `TypeInfer.typeInstantiations.test.cpp:263`) |
| 주석 단 지역에 먼저 담고 넘기기(지금 방식) | 됨(05) | 잡힘(13) | |
| 등록 함수를 제네릭으로 + `<<…>>`, 필드는 읽기쓰기 | 실패(08·09) | — | |
| 필드마다 캐스트 | 됨(06) | **0건(07)** | 캐스트는 두 타입의 교집합이 비어 있지 않은지만 봄(TypeChecker2.cpp:3256-3262) — 검사가 아님 |

설계 결론: conventions 의 "계약 필드는 `read`" 가 이 원리. 트레이트 타입(`typeof(Stack.Of<<…>>(nil))`)은 표 리터럴의 타입이라 읽기쓰기 필드 → 인자 자리에서 실패.
팩토리의 반환이나 `ImplFor` 의 파라미터를 `read` 필드 타입으로 적으면 `Stack.ImplFor(토큰, { Push = Arr.PushBack, … })` 처럼 리터럴을 그대로 넘겨도 검사됨[메인 주:
`ImplFor` 의 파라미터를 트레이트마다 타입으로 적는 길은 아직 없음 — 아래 토론 참고]. 이 모양은 결함이 고쳐진 뒤에도 유효.
⚠️ 스파이크 배터리에서 원인 줄이 아닌 곳에 에러가 보이면 오염을 의심(거짓 양성 — 숨지는 않음).

## 3. 상류 상태 (소스 수준)
| 결함 | 소스의 흔적 | 판단 |
|---|---|---|
| 1. 몸통이 검사되지 않음 | Subtyping.cpp:830 TODO, `HACK(CLI-225132)`, generics 테스트의 `FIXME(CLI-225132)`, `Subtyping.test.cpp:1789` | 내부에 알려짐, 739 에서 부분 땜질. DRAFTS 3번은 공개 추적용으로 가치 — 본문에 830-835 와 CLI-225132 |
| 2. 캐시 오염 | 없음 | 새 이슈 후보 — DRAFTS 6번. 재현 `p5/12-poison.luau`, 원인 Subtyping.cpp:722 와 895-908, 고침 P1 두 줄 |
| (참고) 자유 타입 상한의 제네릭 | Subtyping.cpp:783·800 `FIXME CLI-185582` | 별개 |

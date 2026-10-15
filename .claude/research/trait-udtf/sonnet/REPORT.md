# 사용자 type function 으로 완성 표·등록 표를 짓는 안 (레코드 매핑) — Sonnet 보고

## 결론 (먼저)
- **된다.** `Trait.Fn`/`Trait.Default` 가 `{ required: true|false, fn: F }` 를 내고, 사용자 `type function RebuildFactory(f, mode)` 가 정의 함수의 **함수 타입 전체**를 받아
  (같은 매개변수·같은 제네릭, 반환의 표만 바꿔) 완성 표·등록 표를 지으면, **D3 의 음성 대조군을 전부 같은 줄에서 잡고 맞는 쓰임은 0건**이었습니다.
  `Fold` 의 `<U>` 를 못박은 재정의, `Fold = Arr.Len`, 원소 못박기, 기본 구현 칸의 반환(같은 모듈·다른 모듈), 빌린 참조, 제네릭 알고리즘이 완성 표를 받을 때 — 전부 D3 와 같은 결과.
  v2 때 놓쳤다는 `<U>` 재정의는 **여기서는 잡힘**(재현 안 됨 — 아래 3절).
- **조건은 하나**: 타입 함수에 넘기는 것은 **제네릭 함수 타입 자체**(`typeof(listDef)`)여야 하고, `Self`/`E`/`I` 를 그 함수의 제네릭으로 둔 채 `f:generics()` 를 `types.newfunction` 에 되넘깁니다.
  제네릭이 든 칸을 피할 필요는 없었습니다. (정의 결과 표 `typeof(listDef(nil::any))` 를 넘기는 길은 이 보고서에서 쓰지 않음 — 제네릭이 구체화/소거됨.)
- **얻는 것**: 정의를 한 번만 넘김(모드 값·`listDef(FULL), listDef(IMPL)` 두 번 호출 불필요), 정의자의 모드 실수 세 NEG(맞바꿈·글자 리터럴·부르지 않고 넘김)가 **해당 없음**으로 사라짐, 내장 `index<>` 의 `never`-경보 의존이 없어짐.
- **잃는 것**: 에러·호버 표시가 별칭을 잃고 풀려 길어짐, 정의자 실수 메시지가 타입 함수 런타임 에러 문구(중복 출력), 제네릭의 기본값 등 메타 소실 가능(추측 아닌 소스 근거), 새 의존(types 라이브러리가 아직 진화 중인 API).

## 1. 소스
- **직렬화**(Luau→타입함수): `GenericType` → `TypeFunctionGenericType{explicitName, isPack=false, name}` — **이름만** 담음 (`Analysis/src/TypeFunctionRuntimeBuilder.cpp:233-240`; 이름 없는 제네릭은 `g<index>`). 바운드·기본값 같은 것은 안 실림 [소스; 기본값 소실은 필드가 없다는 근거의 추론].
  함수의 `generics`/`genericPacks` 도 같이 직렬화(438-444).
- **역직렬화**(타입함수→Luau): `deserializeChildren(FunctionType)` 가 함수마다 `genericTypes` 스코프 스택에 **새 `GenericType{ctx->scope, name}`** 을 만들어 넣음 (1000-1060, 특히 1022·1049). 본문 쪽 제네릭은 **이름으로** 가장 안쪽에서 찾음(799-812, 주석 573-575 *"resolved by name even if runtime generic pointers are different"*).
  → 같은 이름의 안쪽 제네릭이 바깥을 가림(그림자는 올바르게 동작), **함수가 선언하지 않은 제네릭이 본문에 나오면 `Generic type 'X' is not in a scope of the active generic function` 에러**(811).
  즉 새로 지은 제네릭의 **스코프는 타입 함수를 적용한 자리의 스코프(`ctx->scope`)**이지 원래 정의 함수의 스코프가 아님. `Subtyping.cpp:830` 의 결함(스코프 안 제네릭을 never/unknown)이 이 스코프와 맞물릴 여지는 있으나, 아래 실측에서는 드러나지 않음 [소스+추측].
- **API**: `types.newfunction(params, rets, generics)`, `f:generics()`, `f:setgenerics()`, `types.generic(name, ispack?)` (`TypeFunctionRuntime.cpp:591, 1327-1380, 1460-1510`). 팩(`T...`)도 지원, "제네릭 뒤에 팩이 올 수 없음" 같은 에러 있음(1206).
  한계: 제네릭 바운드·기본값을 만들 API 없음 [소스: `getGenerics` 가 이름·팩 여부만 받음]. 별칭은 직렬화 때 풀려서 돌아오는 타입에 별칭 이름이 없음 [실측: 아래 4절].
- **테스트가 고정한 동작**: `tests/TypeFunction.user.test.cpp:1888-2300` `udtf_generic_serialization_1~3`(항등 타입 함수가 제네릭 함수·팩·`typeof(m)` 를 왕복해도 같음), `udtf_generic_api_1~8`, 에러 1~6(스코프 밖 제네릭 에러 문구 2236·2257 등). 왕복이 **항등**임을 직접 고정 — 이번 실측과 일치.
- 상류 RFC 디렉터리(`refs-ignoreme/luau/rfcs`)는 이 체크아웃에 없음 — 확인 못 함 [미확인].

## 2. 실측 (모두 luau-analyze 0.742)
하네스: 현재 작업 트리의 `src/` 를 복사(`repo/` = D3 그대로, `repoB/` = 제 변경). 변경은 두 파일뿐:
- `src/Trait/init.luau`: `Fn<F>(): {required:true, fn:F}`, `Default<F>(build): {required:false, fn:F}`(모드 인자 제거, 런타임 표식은 그대로), `export type function RebuildFactory(f, mode)`, `Trait = <F>(name, factory:F) -> Object<RebuildFactory<F,"full">, RebuildFactory<F,"impl">>`.
- `src/Traits/List.luau`: `listDef` 가 모드 없는 단일 정의, `Trait.Trait("List", listDef)`.
`repoC/` = `tail = ps.tail` 를 뺀 변형(5절).

결과 ([실측], `run.sh`):
| 대상 | D3 (repo) | 레코드 안 (repoB/C) |
|---|---|---|
| `src` 전체 analyze | 0건 | 0건 (시간 129ms 대 137ms) |
| 기존 스파이크 27~67 (55·69 제외 25+개) | 기준 | **줄 번호까지 전부 동일** |
| 55 (모드 정의가 든 Shape) | 22건 | 같은 22건 (정의 부분만 새 API 로 고치고 줄이 -2 이동) |
| 69 (D3 판 트레이트 정의 스파이크) | 23건 | 정의자 실수 NEG 4건(Swapped/Literal2/Uncalled + 5중복)이 **모드가 없어 해당 없음**, 나머지 전부 같은 줄(…65, same-module 99→97, negOverride 104→102, negBody 121→119, canary) |
| 70 (신규: 아래 6가지) | 8건 | **8건, 같은 줄** |
| 전체 spike 69 시간 | 105ms | 108–111ms |
- 70 의 내용: ① U 를 지킨 `Fold` POS ② `Fold` 가 `U` 를 `number` 로 못박음 NEG ③ 원소를 `string` 으로 못박음 NEG ④ 반환을 `number` NEG ⑤ `Find = Arr.Len` NEG ⑥ `Fold = Arr.Fold`·필수만 POS ⑦ 완성 표 `l.Fold` 의 `U` 가 호출처에서 정해짐(반환 타입·콜백 타입 NEG 둘) ⑧ `useFull<Self,E,I>(t: ListFull<Self,E,I>, v)` 제네릭이 완성 표 수신(POS + 반환 NEG). 전부 D3 와 일치.
- 같은 모듈에서 정의하고 같은 모듈에서 쓰는 기본 구현 반환(`Sized.Of(box).IsEmpty(box)` 가 `string` 에 못 들어감)도 잡힘 — `index<>` 의 `never` 문제 없음 (69 의 97줄).
- 제네릭 몸통 안(`genericBody<C,E,I>`)에서 `List.Of(x)` 의 완성 표를 쓰는 것도 D3 와 같은 진단.
- 별도 프로브 `p4.luau`: 제네릭 팩 `Args...`, 안쪽 `<E>` 그림자, 중첩 `<U>(f: <V>(U,V)->(U,V))` 모두 왕복 후 올바르게 적용(그림자 E 는 안쪽 값, 바깥 `E` 는 가려지지 않은 칸에서 유지).
- 런타임: 라이브러리 로드와 테스트 1~11 절 통과. `tests/spec.contracts`·`traitrebuild` 는 옛 `Default(mode, …)` 시그니처를 써서 12절에서 멈춤(제 변경 때문, 테스트 미수정).

## 3. v2 에서 놓쳤다는 `<U>` 재정의
이번 실측에선 **놓치지 않음**: 69 의 `negFoldLen`(Fold 자리에 Len, 65줄), 70 의 ② ③ ④ 모두 에러. 정의 함수 전체 타입을 넘겨 `f:generics()` 를 되넘겼기 때문으로 보임(추측). 놓칠 법한 경로는 *제네릭을 소거한 표(`typeof(listDef(x))`)를 넘기는 모양*이라 v2 의 정확한 모양은 확인 못 함 [미확인].

## 4. 잃는 것 (실측)
- **표시**: 별칭이 풀림 — `AnyToken` → `{ read name: string }`, `ItemIndexRead<E,I>` → 객체 리터럴로 전개 (`shown.luau`). 에러가 길어지고 `Object<…>` 가 더 장황. D3 는 별칭 이름이 남음.
- **정의자 실수 메시지**: 칸에 `Fn` 을 안 쓰거나 부르지 않거나 팩토리가 표가 아니면 에러는 나지만 문구가 `'RebuildFactory' type function errored at runtime: RebuildFactory:84: type.readproperty: expected self to be either a table, but got function instead` 이고 **같은 줄에 2~6번 중복** (`71-definer.luau`). 위치는 `Trait.Trait(...)` 호출 줄이라 쓸 만함. 타입 함수에서 `error("…")` 로 직접 문구를 주면 개선 가능(미시험).
- `Default` 가 함수가 아닌 것을 돌려줘도(`F = number`) 안 막음 — D3 도 같음.
- 제네릭 기본값·바운드는 직렬화 필드가 없어 지어진 타입에서 사라질 수 있음 [소스]. 현재 정의엔 없어서 영향 0.

## 5. 부수 발견: `...any` 꼬리
`f:parameters().tail` 이 정의 함수에서 `any` 로 읽힘. 그것을 그대로 넘기면(repoB) 지은 `Of` 에도 `...any` 가 붙어 호출 인자 수 검사가 사라짐 — D3 의 `Of` 도 똑같이 사라져 있음(`List.Of(d, 1, 2)` 0건; `arity.luau`). **꼬리를 빼면(repoC) 오히려 더 엄격**(`Argument count mismatch`)하고 나머지 결과는 동일. 진짜 가변인자 팩토리가 생기면 꼬리를 살려야 하니 `tail` 을 `any` 일 때만 버리는 식이 안전 [추측].

## 6. 판단
- **쓸 수 있습니다.** 안전성 면에서 D3 와 동등(NEG 전부 동일 줄, POS 0건), 정의자 모드 실수 부류를 구조적으로 제거. 비용은 표시 가독성·정의자 에러 문구, 그리고 types 라이브러리라는 미성숙한 표면에 대한 의존(사용자가 기록한 "시스템이 계속 바뀔 수 있음"과 같은 결).
- 조건: ① 타입 함수 입력은 **제네릭 함수 타입 자체**, ② 지은 함수에 `f:generics()` 를 반드시 되넘김(빠뜨리면 `not in a scope` 에러), ③ 정의 함수가 선언한 제네릭만 본문에 등장(바깥 로컬 제네릭 참조 불가 — 소스 811), ④ 꼬리 처리(5절), ⑤ 정의자 에러 문구 개선은 선택.
- 갈아탈 때 손볼 곳: `Trait.Default` 시그니처(모드 인자 삭제), `TraitFn`, `spec.contracts`/`spec.traitrebuild` 의 `T.Default(T.FULL, …)` 호출, 스파이크 55·69 의 정의 부분과 `spike-expectations.tsv` 줄 번호.
- 이 보고서가 확인 못 한 것: 실제 `src` 를 갈아끼운 뒤의 전체 `check.sh`(스파이크 25개는 비교했으나 tsv 게이트 자체는 안 돌림), 성능(타입 검사 시간은 같은 수준), 상류 RFC 원문.

## 파일
모두 `/tmp/claude-0/-code-Projects-stl-luau/1cb06079-132e-4d95-8fed-df0aa2d5e80d/scratchpad/udtf/sonnet/`
- `run.sh` — 에러 줄 번호 목록·시간
- `p1.luau`~`p4.luau` — 독립 프로브(p2: 기본 왕복, p3: 꼬리/스코프, p4: 팩·그림자·중첩)
- `repo/` (D3 복사), `repoB/` (레코드 안, 꼬리 유지), `repoC/` (꼬리 뺌) — 각 `spikes/70-udtf-extra.luau`, `71-definer.luau`(repoC), `arity.luau`, `shown.luau`
- 변경 핵심: `repoB/src/Trait/init.luau` 의 `RebuildFactory`

# stl-luau 트레이트 시스템 변경분 리뷰 보고서 (2026-10-16)

- **작성자**: agy (Gemini 3.8 Flash)
- **작업 환경**: `/code/Projects/stl-luau-agy/rv-runtime` (worktree `agy/rv-runtime`)
- **기준 커밋**: `3578e457c4591ccea9dc409e654686e9a06ca270` (`git rev-parse HEAD` 로 직접 확인, [실측])
- **리뷰 범위**: `git diff b1ec1e6..HEAD -- src tests scripts .claude/audit`
- **전체 검사**: `./scripts/check.sh` -> exit code 0 통과 ([실측], 테스트 및 스파이크 전량 통과)

---

## 1. 개요 및 총평

본 리뷰는 질문 BA(칸별 읽기/쓰기 분리 `Fn`/`FnMut`/`Default`/`DefaultMut`, `X.Of`/`X.OfMut`, 타입 함수 `Entries`, 트레이트 연관 타입 레코드 `__traits`, 변환자 `Trait.Converter`, `Deque` 기반 `Stack`/`Queue` 뭉텅이 어댑터) 및 질문 BB(종류 = 닫힌 트레이트 `Trait.Struct`/`Kind.Seal`, 종류 자리에 모듈 인스턴스 허용, `Arr`의 읽기 전용 칸/`n` 및 `Arr.Set`, 함수 몸통 `Raw<T>` 캐스트, `CircularDeque`의 물리 칸/`head`/`cap` 은닉, 생성자들의 `{ read [number]: T }` 수용)의 변경분을 대상으로 **런타임 정확성과 구멍(Runtime Correctness and Holes)**을 집중 점검하였습니다.

### 주요 요약
1. **런타임 정확성 및 이전 버전(`b1ec1e6`)과의 정합성**:
   - `Arr` 및 `CircularDeque`의 모든 수정 경로(`Arr.Set`, `Map`/`Filter`/`Flatmap`/`Slice`의 `to` 인자, 제자리 변경 `*Inplace`, `writeBack`, `reverseRange` 등)에 대해 이전 판 소스를 사본으로 추출하여 **10,000회의 무작위 연산 차분 대조(differential testing)**를 수행한 결과, **불일치 0건**으로 완벽하게 동작이 일치함을 확인하였습니다 ([실측]).
   - 모듈 로드 순서(`Stack`만 require, `CircularDeque`만 require, `Deque`만 require 등) 변경에 따른 순환 require나 뭉텅이 구현 누락 없이 안정적으로 작동함을 확인하였습니다 ([실측]).
   - `nil` 구멍 및 NaN이 새로운 진입점(`FromList`, `Set`, `Converter`)에 유입되었을 때, 기존 라이브러리 정책(구멍 보존 또는 `Common.denseList` 건너뜀, NaN 거절)과 일치함을 확인하였습니다 ([실측]).
2. **발견된 결함 및 개선 대상**:
   - **[결함 1] `X.Of(kind)` 및 `X.OfMut(kind)`의 봉인된 종류(모듈) 거절**: Question BB의 핵심 방향은 "종류 자리에 모듈 전달(`Stack.ImplFor(stl.Arr, ...)`)"이지만, `X.Of`와 `X.OfMut`에서는 `asToken(x)` 변환이 누락되어 `List.Of(stl.Arr)` 호출 시 `"List: Of needs a List (got table without a type token)"` 에러가 발생합니다 ([실측]).
   - **[결함 2] `Trait.Converter`의 직렬화 복사본(미 Restore 값) 진단 메시지 결함**: 역직렬화된 컨테이너가 `Converter`에 들어왔을 때, `Errors.entryMiss`와 달리 `Registry.isToken` 검증을 거치지 않아 `"Stack: the converter for Stl.CircularDeque got Stl.CircularDeque"`라는 오해를 부르는 문구가 출력됩니다 ([실측]).
   - **[테스트 공백 1] `CompleteArray.IsHeap`의 `{ T }` 시그니처 잔존**: 읽기 전용 검사 함수임에도 여전히 `{ T }`(읽고 쓰는 테이블)로 타입이 선언되어 있어, `Arr<T>`를 직접 전달하면 타입 에러가 발생합니다 ([실측]).
   - **[참고 1] `Kind.Seal(module)`의 모듈 불변 동결(`table.freeze`) 미수행**: 봉인된 모듈 테이블이 동결되지 않아 런타임에 네임스페이스 및 `records[module].impls`가 외부에서 오염될 수 있습니다 ([실측]).

---

## 2. 결함 및 개선 사항 상세

### [결함 1] `X.Of(kind)` 및 `X.OfMut(kind)`에서 봉인된 종류(`stl.Arr` 등)를 전달하면 거절됨

- **종류**: 결함 (API 비일관성 및 런타임 거절)
- **한 줄 요약**: `Trait.ImplOf(List, stl.Arr)`이나 `List.ImplFor(stl.Arr, ...)`는 봉인된 종류를 받지만, `List.Of(stl.Arr)` 및 `List.OfMut(stl.Arr)`는 `asToken(x)` 변환이 없어 `"got table without a type token"` 에러를 던집니다.
- **재현**:
  - 프로브 파일: [`.agy-probes/probe_defect_of_kind.luau`](file:///code/Projects/stl-luau-agy/rv-runtime/.agy-probes/probe_defect_of_kind.luau)
  - 실행 명령:
    ```bash
    ( ulimit -v 1048576; timeout 60 luau .agy-probes/probe_defect_of_kind.luau )
    ```
  - 실행 출력 ([실측]):
    ```
    === 1. List.Of(stl.Arr) 호출 시도 ===
    성공 여부:	false
    에러 메시지:	./.agy-probes/probe_defect_of_kind.luau:8: List: Of needs a List (got table without a type token)

    === 2. List.OfMut(stl.Arr) 호출 시도 ===
    성공 여부:	false
    에러 메시지:	./.agy-probes/probe_defect_of_kind.luau:15: List: Of needs a List (got table without a type token)

    === 3. 대조: Trait.ImplOf(List, stl.Arr) ===
    성공 여부:	true	결과가 nil이 아닌가:	true

    === 4. 대조: List.Of(Trait.TokenOf(stl.Arr)) ===
    성공 여부:	true	결과가 nil이 아닌가:	true
    ```
- **왜 그런지**:
  - 파일: [`src/Trait/init.luau:622-627`](file:///code/Projects/stl-luau-agy/rv-runtime/src/Trait/init.luau#L622-L627)
    ```lua
    trait.Of = function(x: any): any
        const full = if isToken[x] then impls[x] elseif type(x) == "table" then impls[rawget(x, TYPE_KEY)] else nil
        if full == nil then
            return if isToken[x] then Errors.notImplemented(name, x) else Errors.entryMiss(name, "Of", x)
        end
        return full
    end
    trait.OfMut = trait.Of
    ```
  - Question BB에 따라 컨테이너들은 `Kind.Seal(module)`로 봉인되었고, 모듈 자체(`stl.Arr`)는 raw 토큰이 아니며 `rawget(stl.Arr, "__type")`은 `nil`입니다(토큰은 `Registry.kindToken[module]`에 맵핑됨).
  - `implFor`, `Converter`, `TokenOf`, `ImplOf`, `Implements` 등 모든 신규 API는 모듈 표를 받았을 때 토큰으로 매핑(`asToken(kind)` 또는 `TokenOf(value)`)하도록 갱신되었습니다.
  - 그러나 `trait.Of` 및 `trait.OfMut`에서는 `isToken[x]`와 `rawget(x, "__type")`만 직접 확인하므로, 사용자가 `List.Of(stl.Arr)`처럼 종류 모듈을 넘겨 완성 표를 꺼내려 할 때 `x`를 토큰 없는 임의의 일반 테이블로 취급하여 `Errors.entryMiss`를 발생시킵니다.
  - 사용자는 `List.Of(stl.Trait.TokenOf(stl.Arr))`와 같이 토큰을 수동으로 꺼내 넘겨야만 합니다.
- **제안**:
  - `trait.Of`에서 인자 `x`에 대해 `asToken(x)`를 먼저 적용하거나, `isToken[x]` 외에 `kindToken[x]`를 확인하도록 개선:
    ```lua
    trait.Of = function(x: any): any
        const tok = asToken(x)
        const full = if isToken[tok] then impls[tok] elseif type(x) == "table" then impls[rawget(x, TYPE_KEY)] else nil
        if full == nil then
            return if isToken[tok] then Errors.notImplemented(name, tok) else Errors.entryMiss(name, "Of", x)
        end
        return full
    end
    ```

---

### [결함 2] `Trait.Converter`에서 역직렬화된 복사본(미 Restore 값) 전달 시 `"converter for X got X"` 출력

- **종류**: 결함 (에러 규약 불일치 및 사용자 진단 혼란)
- **한 줄 요약**: 역직렬화되어 토큰 정체성을 잃은 테이블을 `Trait.Converter`에 넘겼을 때, `Errors.entryMiss`와 달리 `Trait.Restore` 안내를 하지 않고 `"Stack: the converter for Stl.CircularDeque got Stl.CircularDeque"`라는 모순된 에러를 냅니다.
- **재현**:
  - 프로브 파일: [`.agy-probes/probe_defect_converter_msg.luau`](file:///code/Projects/stl-luau-agy/rv-runtime/.agy-probes/probe_defect_converter_msg.luau)
  - 실행 명령:
    ```bash
    ( ulimit -v 1048576; timeout 60 luau .agy-probes/probe_defect_converter_msg.luau )
    ```
  - 실행 출력 ([실측]):
    ```
    === 1. Converter(Stack, stl.CircularDeque) 에 되읽은 값 전달 ===
    성공 여부:	false
    에러 메시지:	./.agy-probes/probe_defect_converter_msg.luau:17: Stack: the converter for Stl.CircularDeque got Stl.CircularDeque

    === 2. Converter(Stack) (또는 Deque.AsStack) 에 되읽은 값 전달 ===
    성공 여부:	false
    에러 메시지:	./.agy-probes/probe_defect_converter_msg.luau:24: Stack: the converter needs a Stack — got Stl.CircularDeque

    === 3. 대조: 일반 진입점(Errors.entryMiss)의 에러 메시지 ===
    성공 여부:	false
    에러 메시지:	./.agy-probes/probe_defect_converter_msg.luau:31: Stack: Peek needs a Stack — got a Stl.CircularDeque this library does not know (deserialized? Trait.Restore it — or from another copy of the library)
    ```
- **왜 그런지**:
  - 파일: [`src/Trait/Errors.luau:131-139`](file:///code/Projects/stl-luau-agy/rv-runtime/src/Trait/Errors.luau#L131-L139)
    ```lua
    function Errors.convertMismatch(trait: string, kind: string?, value: any): never
        const raw: any = if type(value) == "table" then rawget(value, "__type") else nil
        const name: any = if type(raw) == "table" then rawget(raw, "name") else nil
        const got = if type(name) == "string" then name else typeof(value)
        if kind == nil then
            return raise(`{trait}: the converter needs a {trait} — got {got}`)
        end
        return raise(`{trait}: the converter for {kind} got {got}`)
    end
    ```
  - 일반 진입점에서 불리는 `Errors.entryMiss`([`src/Trait/Errors.luau:115-126`](file:///code/Projects/stl-luau-agy/rv-runtime/src/Trait/Errors.luau#L115-L126))는 `rawget(value, "__type")`가 테이블이고 `name`이 문자열일 때, `Registry.isToken[raw]`를 검사하여 이 사본의 유효한 토큰이 아니면 `got a {rawName} this library does not know (deserialized? Trait.Restore it — or from another copy of the library)`로 명확하게 원인을 짚어 줍니다.
  - 하지만 `convertMismatch`는 단순히 `raw.name` 문자열을 읽어 `got`으로 삼기 때문에, 직렬화 후 되읽은 값(`raw.name == "Stl.CircularDeque"`이지만 `raw ~= token`)이 들어오면 `kind`와 `got`이 동일하여 `"the converter for Stl.CircularDeque got Stl.CircularDeque"`라는 당혹스러운 메시지가 출력됩니다.
  - 토큰이 생략된 변환자(`toStackAny` 또는 `Deque.AsStack`)의 경우에도 CircularDeque는 정상적인 경우 당연히 Stack을 구현하는데, `"needs a Stack — got Stl.CircularDeque"`라고만 출력되어 사용자는 무엇이 잘못되었는지 알 수 없습니다.
- **제안**:
  - `convertMismatch`에서도 `entryMiss`와 마찬가지로 `raw`가 테이블이고 `not Registry.isToken[raw]`인 경우, `Trait.Restore`를 제안하는 안내 문구를 부가하도록 수정:
    ```lua
    function Errors.convertMismatch(trait: string, kind: string?, value: any): never
        const raw: any = if type(value) == "table" then rawget(value, "__type") else nil
        const name: any = if type(raw) == "table" then rawget(raw, "name") else nil
        if type(name) == "string" and not Registry.isToken[raw] then
            return raise(
                `{trait}: the converter got a {name} this library does not know (deserialized? Trait.Restore it — or from another copy of the library)`
            )
        end
        const got = if type(name) == "string" then name else typeof(value)
        if kind == nil then
            return raise(`{trait}: the converter needs a {trait} — got {got}`)
        end
        return raise(`{trait}: the converter for {kind} got {got}`)
    end
    ```

---

### [테스트 공백 1] `CompleteArray.IsHeap` 시그니처가 `{ read [number]: T }`가 아닌 `{ T }`로 남아 `Arr<T>` 거절

- **종류**: 테스트 공백 / 타입 시그니처 갱신 누락
- **한 줄 요약**: `CompleteArray.IsHeap`은 내부를 읽기만 하는 검사 함수이지만, 매개변수 타입이 `{ T }`로 남아 있어 `Arr`의 읽기 전용 인덱서(`read [number]: T`)를 거절합니다.
- **재현**:
  - 프로브 파일: [`.agy-probes/probe_gap_isheap.luau`](file:///code/Projects/stl-luau-agy/rv-runtime/.agy-probes/probe_gap_isheap.luau)
  - 실행 명령:
    ```bash
    ( ulimit -v 2097152; timeout 120 luau-analyze .agy-probes/probe_gap_isheap.luau )
    ```
  - 실행 출력 ([실측]):
    ```
    ./.agy-probes/probe_gap_isheap.luau(7,38): TypeError: Expected this to be '{number}', but got 'ArrData<number>'; 
    the indexer is read-only in the latter type, but the former type requires a read-write indexer
    ```
- **왜 그런지**:
  - 파일: [`src/Trees/CompleteArray.luau:113`](file:///code/Projects/stl-luau-agy/rv-runtime/src/Trees/CompleteArray.luau#L113)
    ```lua
    const function IsHeap<T>(list: { T }, count: number, less: LessThan<T>): boolean
    ```
  - Question BB에 따라 리스트를 읽기만 하는 모든 진입점(`FromList`, `FromRecords`, `Arr.FromTable`, `Fut.All`, `Common.denseList`)은 `{ read [number]: T }`로 변경되었습니다.
  - `CompleteArray.SiftUp`, `SiftDown`, `Heapify`는 실제로 배열을 제자리에서 수정하므로 `{ T }`가 맞지만, `IsHeap`은 `list[idx]`를 조회하여 힙 불변식을 검증만 하는 읽기 전용 함수입니다.
  - 시그니처가 `{ T }`로 유지되었기 때문에 공개 타입의 칸이 `read [number]: T`가 된 `Arr`를 `CompleteArray.IsHeap(arr, arr.n, less)`로 직접 검사하려는 코드가 타입 거절을 당합니다.
- **제안**:
  - `src/Trees/CompleteArray.luau:113`의 `list: { T }`를 `list: { read [number]: T }`로 변경.

---

### [참고 1] `Kind.Seal(module)`의 모듈 네임스페이스 동결(`table.freeze`) 미수행

- **종류**: 참고 (설계 일관성 및 잠재적 오염 방지)
- **한 줄 요약**: `Kind.Seal(module)`은 모듈 테이블을 `table.freeze`로 얼리지 않으며, 라이브러리 컨테이너 모듈들도 얼리지 않아 런타임에 모듈 및 트레이트 구현 표가 변조될 수 있습니다.
- **분석 및 실측**:
  - 파일: [`src/Trait/init.luau:507-531`](file:///code/Projects/stl-luau-agy/rv-runtime/src/Trait/init.luau#L507-L531)
  - `NewToken`은 `table.freeze({ name = name })`로 얼리고, `Trait.Trait`은 팩토리 반환 표를 `table.freeze`하도록 강제합니다.
  - 하지만 `Kind.Seal`은 `records[module] = { ... impls = { [token] = module } ... }`와 같이 `module` 테이블 자체를 `impls` 표의 완성 표로 직접 등록하면서도, `module`을 동결하지 않습니다.
  - 프로브 [`.agy-probes/probe_frozen.luau`](file:///code/Projects/stl-luau-agy/rv-runtime/.agy-probes/probe_frozen.luau) 실행 결과 ([실측]):
    ```
    Arr frozen?	false
    CircularDeque frozen?	false
    HashMap frozen?	false
    HashSet frozen?	false
    Fut frozen?	false
    ```
  - 만약 사용자가 실수로 `stl.Arr.At = nil` 또는 `stl.Arr.NewMethod = fn` 등으로 모듈을 수정하면, `stl.Arr` 뿐만 아니라 `Trait.ImplOf(stl.Arr, arr)`가 반환하는 표까지 전역으로 수정됩니다.
- **제안**:
  - `Kind.Seal`의 끝에서 `return table.freeze(module)`을 수행하거나, 각 컨테이너 파일의 모듈 선언부를 `table.freeze`하도록 통일하는 것을 고려해 볼 수 있습니다 (단, 사용자가 모듈 네임스페이스에 사용자 함수를 몽키패칭하는 확장 유즈케이스가 있는지 정책적 판단 필요).

---

## 3. 6개 관점별 종합 실측 검증 보고

사용자 요청에 명시된 6가지 핵심 관점에 대한 전수 검증 결과입니다.

### 1) `Trait.Struct`·`Kind.Seal` 과 등록부(`Registry`/`Build`)의 만남
- **프로브**: [`.agy-probes/probe_1_struct_registry.luau`](file:///code/Projects/stl-luau-agy/rv-runtime/.agy-probes/probe_1_struct_registry.luau) ([실측])
- **실측 결과 요약**:
  1. **닫힌 트레이트의 뭉텅이 의존(`ImplWhere({ stl.Arr }, ...)` )**: `records[stl.Arr]`가 정상 존재하므로 의존성으로 등록되며, `Arr.Token`에 대해 뭉텅이 구현이 정상적으로 빌드 및 캐싱됩니다. 다른 컨테이너(`CircularDeque`)에는 전파되지 않습니다.
  2. **명시 구현으로 오버라이드**: `T1.ImplFor(stl.Arr, ...)` 호출 시 기존 뭉텅이 구현을 정상적으로 덮어쓰고 최신 함수로 갱신됩니다.
  3. **조회 API(`ImplOf`, `Implements`, `Impls`, `ExpectImpl`, `Restore`)**:
     - `Trait.ImplOf(stl.Arr, arr)` -> `stl.Arr` 반환 ([실측])
     - `Trait.Implements(stl.Arr, arr)` -> `true`, 다른 컨테이너는 `false` ([실측])
     - `Trait.ExpectImpl(stl.Arr, arr, "who")` -> `stl.Arr` 반환 ([실측])
     - `Trait.Impls(stl.Arr)` -> `[Arr.Token] = stl.Arr` 반환 ([실측])
     - `Trait.Restore(stl.Arr)` -> 모듈 자체는 손상 없이 유지 ([실측])
  4. **봉인 전후 및 2회 봉인**:
     - 봉인 전에는 `kindToken[mod]`가 없어 `TokenOf(mod)`가 `nil`을 반환하며, `ImplFor`나 `Converter`에 넘기면 `notToken`으로 즉시 거절됩니다.
     - 동일 `Kind`에 대해 2회 봉인 시 `Errors.structSealed` ("is already sealed")가 정확히 발생합니다.
     - 이미 다른 `Kind`로 봉인된 테이블을 재봉인하려 할 때 `Errors.structBad` ("needs a module table that is not already a trait or a kind")가 발생합니다.
  5. **미봉인 표 전달**:
     - 봉인되지 않은 일반 테이블을 `ImplFor`의 kind 자리에 전달 시 `Errors.notToken` ("needs a type token")으로 거절됩니다.
  6. **외부 사용자의 `Trait.Struct` 정의**:
     - 프로브 [`.agy-probes/probe_external_struct.luau`](file:///code/Projects/stl-luau-agy/rv-runtime/.agy-probes/probe_external_struct.luau) 실행 결과, 외부 모듈이 자체 `Struct`를 정의하고 봉인한 뒤 `Stack.ImplFor` 등록, `Trait.Converter` 변환까지 완벽하게 동작함을 확인하였습니다 ([실측]).

### 2) `Trait.Converter` 동작
- **프로브**: [`.agy-probes/probe_2_converter.luau`](file:///code/Projects/stl-luau-agy/rv-runtime/.agy-probes/probe_2_converter.luau) ([실측])
- **실측 결과 요약**:
  1. **토큰 지정 유무**:
     - `Trait.Converter(Stack, CircularDeque)`: 생성 시점에 해당 종류의 구현 여부를 1회 검증하며, 호출 시마다 `rawget(v, "__type") == token`을 검증합니다 (13~20ns 빠른 경로).
     - `Trait.Converter(Stack)`: 호출 시마다 `impls[rawget(v, "__type")]`를 동적으로 검증하여, Stack을 구현한 종류면 무엇이든 통과시킵니다.
  2. **뭉텅이 구현 자동 반영**: `CircularDeque`는 `Deque`를 통해 `Stack`을 뭉텅이 구현으로 얻는데, `Converter`가 이를 완벽히 인식하고 통과시킵니다.
  3. **등록 전 생성 시점 차이**:
     - 토큰 지정 시: 아직 구현이 등록되지 않은 토큰/종류를 넘기면 생성 즉시 `Errors.notImplemented`로 거절됩니다 (문서대로 "등록 뒤에 만드세요").
     - 토큰 미지정 시: 생성 시점에는 검증하지 않고 호출 시점에 동적 조회하므로, 생성 후 등록된 종류도 정상 처리됩니다.
  4. **비테이블 및 프리미티브 방어**: `nil`, `123`, `"string"`, `true` 전달 시 `convertMismatch`를 통해 사용자 줄 에러로 안전하게 거절됩니다.
  5. **역직렬화 및 Restore 전후**: `Restore` 전에는 불일치 에러가 발생하고, `Restore` 후에는 실제 토큰 정체성이 복원되어 즉시 정상 통과합니다. (단, 에러 메시지 서식 결함은 상기 [결함 2] 참조).

### 3) 모듈 로드 순서 및 순환 의존
- **프로브**: [`.agy-probes/probe_3_load_order.luau`](file:///code/Projects/stl-luau-agy/rv-runtime/.agy-probes/probe_3_load_order.luau) ([실측])
- **실측 결과 요약**:
  - `Stack`과 `Queue`의 뭉텅이 구현 코드가 `src/Traits/Deque.luau`로 이동함에 따라, `Traits/Stack`과 `Traits/Queue`는 더 이상 `Deque`를 require하지 않습니다.
  - `Deque.luau`가 `Stack`과 `Queue`를 require하는 단방향 의존성 구조를 갖추어, **순환 require가 원천적으로 제거**되었습니다 ([추정/실측]).
  - `require("Traits/Stack")`만 먼저 호출된 후, 나중에 `require("Collections/CircularDeque")`가 호출되더라도 `CircularDeque`가 `Deque`를 로드하면서 `Stack.ImplWhere`가 등록되고, `CircularDeque`가 스택으로 자동 승격되어 `Stack.OfMut(cd)` 및 `Stack.Pop(cd)`가 완벽히 동작함을 확인하였습니다 ([실측]).

### 4) `Arr` 쓰기 경로 및 10,000회 무작위 차분 대조
- **프로브**: [`.agy-probes/probe_4_arr_set.luau`](file:///code/Projects/stl-luau-agy/rv-runtime/.agy-probes/probe_4_arr_set.luau), [`.agy-probes/diff_test_arr.luau`](file:///code/Projects/stl-luau-agy/rv-runtime/.agy-probes/diff_test_arr.luau) ([실측])
- **`Arr.Set` 실측 결과**:
  - 정상 인덱스(1, 2, 3): 정상 수정 및 길이 `n` 불변.
  - 음수 인덱스(-1: 끝, -3: 처음): `At`과 동일하게 뒤에서부터 정확히 계산하여 수정.
  - 소수 인덱스(1.9 -> 1, -1.9 -> -1): 0 쪽으로 내림/올림 절삭하여 정확히 수정.
  - 범위 밖 및 NaN: 0, 4, -4, `math.huge`, `-math.huge`는 out of range 에러, NaN은 Set index is NaN 에러 발생 및 원본 불변.
  - 빈 배열(`len = 0`): `out of range [1, 0]` 에러 발생.
  - `nil` 원소: `Set(arr, 2, nil)` 호출 시 구멍이 생성되며 `n`은 줄어들지 않고 유지됨.
  - 타입 안전성: `ArrRead`를 넘기면 타입 검사 거절, 밀집 배열(`Arr<number>`)에 `nil`을 넣으면 타입 검사 거절, `Arr<number?>`에서는 `nil` 허용.
- **`b1ec1e6` 대비 10,000회 무작위 차분 대조**:
  - `PushBack`, `PushFront`, `PopBack`, `PopFront`, `SwapRemove`, `ReverseInplace`, `RotateInplace`, `Insert`, `Slice` (to 누적), `Map` (to 누적), `Filter` (to 누적), `Flatmap` (to 누적), `SortInplace`, `DedupInplace`, `Retain`, `SliceInplace`, `EraseInplace`, `ConcatInplace` 등 18개 연산을 10,000회 무작위 연속 수행한 결과:
  - **불일치 0건 (10000 operations passed with 0 mismatches)**으로 완벽히 통과하였습니다 ([실측]).

### 5) `CircularDeque` 함수 몸통 변경 및 10,000회 무작위 차분 대조
- **프로브**: [`.agy-probes/diff_test_cd.luau`](file:///code/Projects/stl-luau-agy/rv-runtime/.agy-probes/diff_test_cd.luau) ([실측])
- **실측 결과 요약**:
  - `deque` 매개변수 도입 및 함수 진입 시 `const self = deque :: Raw<T>` 캐스트가 모든 공개 함수에 누락 없이 일관되게 적용되었음을 확인하였습니다 ([실측]).
  - `b1ec1e6` 판과의 10,000회 무작위 차분 대조(`PushBack`, `PushFront`, `PopBack`, `PopFront`, `At`, `Clone`, `Clear`, `ToArr`, `Len`, `Front`, `Back`, `Empty`) 결과:
  - **불일치 0건 (10000 operations passed with 0 mismatches)**으로 완벽히 통과하였습니다 ([실측]).

### 6) `nil` 구멍 및 NaN 처리
- **프로브**: [`.agy-probes/probe_6_nil_holes.luau`](file:///code/Projects/stl-luau-agy/rv-runtime/.agy-probes/probe_6_nil_holes.luau) ([실측])
- **실측 결과 요약**:
  - **구멍 든 배열(`Arr.Of(10, nil, 30)`) 유입 시**:
    - `CircularDeque.FromList`: 구멍을 `nil` 원소 그대로 보존하여 `len = 3`, `At(2) == nil` 유지 ([실측]).
    - `LinkedDeque.FromList`: 구멍을 `nil` 노드로 보존하여 양끝 연결 유지 ([실측]).
    - `HashSet.FromList`, `FlatSet.FromList`, `TreeSet.FromList`, `Heap.FromList`: `Common.denseList`를 거치므로 구멍을 안전하게 건너뛰고 유효 원소만 담아 크기 2로 생성 ([실측]).
  - **NaN 원소 유입 시**:
    - `HashSet.FromList`: 원시 Lua 해시 인덱싱 에러 `table index is NaN` 발생 (질문 AN 결정 규약 일치) ([실측]).
    - `FlatSet.FromList`, `TreeSet.FromList`: `Common.raise`를 통해 `FlatSet: NaN item`, `TreeSet: NaN item` 사용자 줄 에러 발생 ([실측]).
    - `CircularDeque`, `LinkedDeque`, `Heap`: NaN 값을 원소로 허용하여 정상 생성 ([실측]).
  - **`Fut.All`**:
    - `count = Common.listLength(futs)` 후 1..count 루프에서 `isFutRaw(futs[idx])` 검사를 수행하므로, 구멍이 있으면 즉시 `"Fut: All expects a Fut at index {idx}"`로 `Rejected` 상태로 전환됨을 확인하였습니다 ([추정/코드분석]).

---

## 4. 제안 요약 테이블

| 번호 | 구분 | 위치 | 내용 요약 | 상태 / 제안 |
|---|---|---|---|---|
| 1 | 결함 | `src/Trait/init.luau:623` | `X.Of(kind)`/`X.OfMut(kind)` 호출 시 `asToken(x)` 부재로 인한 거절 | `trait.Of`에서 `asToken(x)` 적용하여 `List.Of(stl.Arr)` 지원 |
| 2 | 결함 | `src/Trait/Errors.luau:131` | `Trait.Converter`에서 역직렬화된 객체에 대해 `"converter for X got X"` 출력 | `Registry.isToken[raw]` 확인 후 `Trait.Restore` 안내 문구 출력 |
| 3 | 테스트 공백 | `src/Trees/CompleteArray.luau:113` | `IsHeap`의 파라미터가 `{ T }`로 남아 `Arr<T>` 거절됨 | `list: { read [number]: T }`로 시그니처 갱신 |
| 4 | 참고 | `src/Trait/init.luau:507` | `Kind.Seal(module)`에서 `table.freeze(module)` 미수행 | 모듈 불변 동결 정책 검토 |
| 5 | 참고 | `src/init.luau:66` | `ListReadFull` 타입 export 누락 (List는 읽기 전용이므로 Full과 동일) | 일관성을 위한 타입 export 추가 고려 |

---

## 5. 생성된 프로브 파일 목록

모든 프로브는 `.agy-probes/` 디렉터리에 실행 가능한 독립 파일로 보존되어 있습니다:
- `.agy-probes/probe_defect_of_kind.luau`: [결함 1] `X.Of(kind)` 거절 재현
- `.agy-probes/probe_defect_converter_msg.luau`: [결함 2] `Converter` 직렬화 복사본 에러 메시지 재현
- `.agy-probes/probe_gap_isheap.luau`: [공백 1] `CompleteArray.IsHeap` 타입 거절 재현
- `.agy-probes/probe_1_struct_registry.luau`: 관점 1 (Struct/Seal/Registry 상호작용)
- `.agy-probes/probe_2_converter.luau`: 관점 2 (Converter 엣지 케이스)
- `.agy-probes/probe_3_load_order.luau`: 관점 3 (모듈 로드 순서 및 순환 require)
- `.agy-probes/probe_4_arr_set.luau`: 관점 4 (`Arr.Set` 경계 및 구멍)
- `.agy-probes/diff_test_arr.luau`: 관점 4 (이전 판 대비 Arr 10,000회 차분 대조)
- `.agy-probes/diff_test_cd.luau`: 관점 5 (이전 판 대비 CircularDeque 10,000회 차분 대조)
- `.agy-probes/probe_6_nil_holes.luau`: 관점 6 (nil 구멍 및 NaN 전수 검증)

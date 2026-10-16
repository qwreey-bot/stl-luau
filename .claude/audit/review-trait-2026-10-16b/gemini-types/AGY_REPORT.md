# stl-luau 트레이트 시스템 변경분 리뷰 보고서 (2026-10-16)

- **작성자**: Gemini (agy / rv-types 워크트리)
- **기준 커밋**: `3578e457c4591ccea9dc409e654686e9a06ca270` (`git rev-parse HEAD` 실측)
- **리뷰 범위**: `git diff b1ec1e6..HEAD -- src tests scripts .claude/audit` (질문 BA 및 질문 BB 변경분)
- **검증 환경**: Luau 0.742 (new solver, `--!strict`), Linux x86_64

---

## 1. 개요 및 총평

이번 변경(질문 BA, BB)은 트레이트 시스템과 컨테이너 타입을 근본적으로 재편했습니다:
1. **질문 BA**: 읽기/쓰기를 칸(`Fn`/`FnMut`/`Default`/`DefaultMut`)으로 이동, `X.Of`(읽기 보기)와 `X.OfMut`(완성 표)의 분리, 타입 함수 `Trait.Entries` 를 통한 진입점 자동 서명 생성, 트레이트 연관 타입 레코드(`__traits`), 중간자 `Trait.Converter`, `Stack`/`Queue` 분리.
2. **질문 BB**: 종류 = 닫힌 트레이트(`Trait.Struct`/`Kind.Seal`), `Arr` 의 공개 인덱서 및 `n` 의 읽기 전용화(`read [number]: T`, `read n`), `CircularDeque` 내부 물리 구조 은닉.

검토 결과, 이전 시스템의 심각했던 구멍(`stl.Collection.Of(arrRead).Clear(arrRead)`)과 과잉 거절(`stl.Deque.Of(circularDequeRead)` 불가)은 깔끔하게 해결되었습니다. 음성 대조군 `spikes/71`, `72`, `73` 도 의도한 성질을 정확히 검증하고 있습니다.

그러나 **타입 함수의 인덱서 재구축 한계**, **위치 인자의 공변성 누락**, **Arr 읽기 전용화에 따른 라이브러리 내 기존 함수 서명의 미갱신** 등 새로운 시스템의 틈새에서 실측된 결함들이 발견되었습니다.

---

## 2. 발견 사항 요약표

| 번호 | 분류 | 요약 | 상태 / 성격 |
|---|---|---|---|
| **1** | **결함** | `List.AssocRead<E, I>` 의 `Index` 공변성으로 인한 위치 인자 확대 통과 및 런타임 크래시 | 타입 구멍 / 런타임 라이브러리 줄 에러 |
| **2** | **결함** | `Trait.Entries` 의 `subst` 과정에서 인덱서의 `read` 탈락으로 `Map.Iter` 반환 타입이 가변화되어 내부 저장소 직접 오염 | 타입 구멍 / 조용한 내부 상태 손상 |
| **3** | **결함** | 읽기 전용 함수 9곳이 `{ T }` / `{ [K]: V }` 를 요구하여 `stl.Arr<T>` 및 읽기 전용 맵 거절 | 타입 과잉 / 공개 API 호환성 결여 |
| **4** | **테스트 공백** | `LinkedDequeData<T>` 의 필드(`head`, `tail`, `size`)가 여전히 가변으로 노출되어 외부 직접 변조 가능 | 불변식 위반 가능 |
| **5** | **테스트 공백 / API 누락** | `src/init.luau` 배럴에서 탐침 타입(`Trait.A`, `B`, `C`) 및 `MapAssocRead`/`SetAssocRead` 미수출 | 확장 규약 미비 |
| **6** | **참고** | `Map.luau` 및 `Set.luau` 에 `Trait.Entries` 도입 전의 구식 주석 잔존 | 문서-구현 불일치 |
| **7** | **참고** | `Self` 반환 진입점(`Deque.PushBack`, `Stack.Push` 등)의 명시적 제네릭 순서와 솔버 한계 | 언어/솔버 제약 |

---

## 3. 상세 보고

---

### [결함 1] `List.AssocRead<E, I>` 의 `Index` 공변성으로 인한 위치 인자 확대 통과 및 런타임 크래시

- **분류**: 결함 (타입 구멍 / 런타임 라이브러리 줄 에러)
- **한 줄 요약**: `List.AssocRead<E, I>` 에서 `Index` 가 `() -> I`(공변)로 정의되어 있어, 위치를 인자로 받는 읽기 진입점(`List.Get`, `List.NextIndex`, `List.PrevIndex`)에 엉뚱한 타입의 인자를 넘겨도 정적 분석을 0건으로 통과하고 런타임에 크래시가 납니다.

#### 1) 왜 그런가 (파일:줄)
- [src/Traits/List.luau:39-42](file:///code/Projects/stl-luau-agy/rv-types/src/Traits/List.luau#L39-L42):
  ```lua
  export type AssocRead<E, I> = { read Item: () -> E, read Index: () -> I }
  export type Assoc<E, I> = { read Item: () -> E, read Index: () -> I, read Mut: (E, I) -> (E, I) }
  export type ValueRead<E, I> = { read __type: Trait.Token<any>, read __traits: { read List: AssocRead<E, I> } }
  ```
- [src/Traits/List.luau:66-72](file:///code/Projects/stl-luau-agy/rv-types/src/Traits/List.luau#L66-L72):
  ```lua
  const ListBase = Trait.Trait("List", function<Self, E, I>(of: (Self & ValueRead<E, I>) | AnyToken)
      return table.freeze({
          Get = Fn<<(list: Self, idx: I) -> E?>>(),
          ...
          NextIndex = Fn<<(list: Self, idx: I) -> I?>>(),
          PrevIndex = Fn<<(list: Self, idx: I) -> I?>>(),
  ```
- **원인 분석**:
  - `List` 는 읽기만 하는 트레이트이므로 `of` 조건에 `ValueRead<E, I>` 를 사용합니다.
  - 그런데 `AssocRead<E, I>` 에서 원소 `Item` 뿐 아니라 위치 `Index` 까지 `read Index: () -> I` 로 두었습니다.
  - `() -> I` 는 반환 타입이므로 Luau 타입 체커에서 `I` 에 대해 **공변(covariant)** 입니다.
  - `conventions.md` 259~273행에 따르면, 컨테이너에 "입력으로 넘기는 키·위치·값" 은 불변이어야 조용히 넓어지지 않는다고 규정하고 있습니다.
  - 실제로 `MapBase` 는 `of` 조건에 불변 팬텀 `Mut: (K, V) -> (K, V)` 가 포함된 `Value<K, V>` 를 사용하여 키 조회(`Map.Get(tm, 123)`) 시 타입 에러를 정상적으로 잡아냅니다.
  - 반면 `List` 는 `ValueRead<E, I>` 에 `Mut` 이 없고 `Index: () -> I` 가 공변이기 때문에, `List.Get(ld, 123)` 호출 시 `I` 가 `NodeRead<number> | number` 로 유니온 확장됩니다.
  - 그 결과 `luau-analyze` 는 0건의 진단으로 통과하고, 런타임에 `LinkedDeque.luau:91`(`node[1]`)에서 `attempt to index number with number` 로 즉시 크래시합니다. `Arr` 및 `CircularDeque` 도 문자열 인덱스를 넘겼을 때 `idx < size` 비교 시 런타임 크래시가 발생합니다.

#### 2) 재현 (실측)
- **재현 프로브**:
  - `.agy-probes/probe_linked_deque_get.luau`
  - `.agy-probes/probe_linked_deque_next_idx.luau`
  - `.agy-probes/probe_cd_get_crash.luau`
  - `.agy-probes/probe_arr_next_crash.luau`
- **정적 분석 실행**:
  ```bash
  ( ulimit -v 2097152; timeout 120 luau-analyze .agy-probes/probe_linked_deque_get.luau )
  # 출력: exit code 0 (진단 0건!)
  ```
- **런타임 실행**:
  ```bash
  ( ulimit -v 1048576; timeout 60 luau .agy-probes/probe_linked_deque_get.luau )
  # 출력:
  # ./src/Collections/LinkedDeque.luau:91: attempt to index number with number
  # stacktrace:
  # ./src/Collections/LinkedDeque.luau:91 function Get
  # ./src/Trait/Entry.luau:22
  # ./.agy-probes/probe_linked_deque_get.luau:4
  ```
  ```bash
  ( ulimit -v 1048576; timeout 60 luau .agy-probes/probe_cd_get_crash.luau )
  # 출력:
  # ./src/Collections/CircularDeque.luau:153: attempt to compare string < number
  # stacktrace:
  # ./src/Collections/CircularDeque.luau:153 function Get
  # ./src/Trait/Entry.luau:22
  # ./.agy-probes/probe_cd_get_crash.luau:3
  ```
  ```bash
  ( ulimit -v 1048576; timeout 60 luau .agy-probes/probe_arr_next_crash.luau )
  # 출력:
  # ./src/Collections/Arr.luau:289: attempt to compare string < number
  # stacktrace:
  # ./src/Collections/Arr.luau:289 function NextIndex
  # ./src/Trait/Entry.luau:22
  # ./.agy-probes/probe_arr_next_crash.luau:3
  ```

#### 3) 제안
- 컨테이너의 위치(`Index`)는 조회 입력으로 사용되며 컨테이너 종류별로 고정(정수 또는 노드)되어 있으므로 공변으로 넓어질 이유가 전혀 없습니다.
- `src/Traits/List.luau` 의 `AssocRead<E, I>` 에서 `Index` 를 불변으로 정의:
  ```lua
  export type AssocRead<E, I> = { read Item: () -> E, read Index: (I) -> I }
  ```
- **실측 확인** (`.agy-probes/probe_invariant_index_test.luau`):
  `read Index: (I) -> I` 로 변경 시, `read Item: () -> E` 에 의한 원소의 읽기 공변성(`ArrRead<number?>` 에 `Arr<number>` 전달)은 100% 정상 유지되면서, 잘못된 인덱스 전달(`testGet(arr, "wrong")`)은 `TypeError: Expected this to be 'number', but got 'string'` 으로 정확하게 거절됨을 확인했습니다.

---

### [결함 2] `Trait.Entries` 의 `subst` 과정에서 인덱서의 `read` 탈락으로 `Map.Iter` 반환 타입이 가변화되어 내부 저장소 직접 오염

- **분류**: 결함 (타입 구멍 / 조용한 내부 상태 손상)
- **한 줄 요약**: `src/Traits/Map.luau` 의 `Iter` 계약은 `{ read [K]: V } | (() -> (K, V))` 로 읽기 전용 인덱서를 요구하지만, `Trait.Entries` 가 서명을 지을 때 `subst` 를 거치면서 인덱서의 `read` 수식어가 탈락하여 읽기-쓰기 인덱서 `{ [K]: V }` 로 변질됩니다. 이로 인해 `stl.Map.Iter(hm)` 반환 테이블에 직접 쓰기를 해도 타입 진단이 0건이며, `HashMap` 의 내부 테이블이 직접 오염됩니다.

#### 1) 왜 그런가 (파일:줄)
- [src/Traits/Map.luau:54](file:///code/Projects/stl-luau-agy/rv-types/src/Traits/Map.luau#L54):
  ```lua
  Iter = Fn<<(map: Self) -> { read [K]: V } | (() -> (K, V))>>(),
  ```
- [src/Trait/init.luau:256-260](file:///code/Projects/stl-luau-agy/rv-types/src/Trait/init.luau#L256-L260):
  ```lua
  local idx = t:indexer()
  if idx ~= nil then
      out:setindexer(subst(idx.index, map, memo), subst(idx.readresult, map, memo))
  end
  ```
- **원인 분석**:
  - `Trait.Entries` 는 제네릭 타입 변수를 새로 치환하기 위해 `subst` 함수로 함수 타입의 파라미터 및 반환 타입을 재구축합니다.
  - 반환 타입 내의 테이블을 복제할 때 `out:setindexer(idx.index, idx.readresult)` 를 호출합니다.
  - 그런데 Luau 타입 함수 C++ 엔진은 현재 인덱서의 read/write 분리를 지원하지 않습니다 (`type.setreadindexer: luau does not yet support separate read/write types for indexers` — `.agy-probes/probe_test_indexer_fn.luau` 실측).
  - 따라서 `out:setindexer` 는 무조건 **읽기-쓰기 인덱서**를 생성합니다.
  - 그 결과 원래 `{ read [K]: V }` 였던 읽기 전용 인덱서가 `{ [K]: V }`(읽기-쓰기)로 강제 변환되어 진입점 `stl.Map.Iter` 의 서명에 들어갑니다.
  - 사용자가 `stl.Map.Iter(hm)` 을 호출하여 테이블을 얻은 뒤 `iter["evil_key"] = 999` 로 쓰기를 수행해도 체커가 전혀 잡지 못합니다.
  - 런타임에 `HashMap.Iter` 는 내부 테이블 `self.data` 를 그대로 돌려주므로, `hm.size` 는 1인데 내부에 키가 2개 존재하는 조용한 내부 불변식 파괴가 발생합니다.
  - 반면 `stl.Map.Of(hm).Iter(hm)` 는 `Trait.View` 가 `subst` 를 거치지 않고 슬롯 타입을 그대로 사용하므로 `{ read [string]: number }` 가 보존되어 쓰기 시 컴파일 에러를 냅니다.

#### 2) 재현 (실측)
- **재현 프로브**:
  - `.agy-probes/probe_map_iter_readonly.luau` (타입 검사)
  - `.agy-probes/probe_map_iter_corrupt.luau` (런타임 오염)
  - `.agy-probes/probe_map_of_iter.luau` (Of 보기를 통한 대조군)
- **정적 분석 실행**:
  ```bash
  ( ulimit -v 2097152; timeout 120 luau-analyze .agy-probes/probe_map_iter_readonly.luau )
  # 출력: exit code 0 (진단 0건!)
  ```
- **런타임 오염 실행**:
  ```bash
  ( ulimit -v 1048576; timeout 60 luau .agy-probes/probe_map_iter_corrupt.luau )
  # 출력:
  # hm size:	1
  # hm has evil_key?	true
  # hm raw get evil_key:	999
  ```
- **`Map.Of` 대조군 정적 분석**:
  ```bash
  ( ulimit -v 2097152; timeout 120 luau-analyze .agy-probes/probe_map_of_iter.luau )
  # 출력:
  # ./.agy-probes/probe_map_of_iter.luau(7,2): TypeError: Property evil_key of table '{ read [string]: number }' is read-only
  ```

#### 3) 제안
- Luau C++ 상류에서 `setreadindexer` 가 제공될 때까지, 인덱서가 포함된 반환 타입을 갖는 진입점(`Map.Iter`)은 `Trait.Entries` 의 자동 서명 생성 대신 `Map.Keys`/`Values`/`Records` 처럼 `Trait.Expose` 를 통해 직접 손 서명을 지정하거나, `subst` 내부에서 인덱서를 가진 테이블은 타입 재구축 대신 원본 타입을 유지하도록 우회.

---

### [결함 3] 읽기만 수행하는 10개 함수가 `{ T }` / `{ [K]: V }` 를 요구하여 `stl.Arr<T>` 및 읽기 전용 맵 거절

- **분류**: 결함 (타입 과잉 / 공개 API 호환성 결여)
- **한 줄 요약**: 질문 BB 에서 `Arr<T>` 의 인덱서가 `read [number]: T` 로 바뀌어 읽기-쓰기 인덱서 `{ T }` 자리에 들어갈 수 없게 되었으나, 라이브러리 내 다수의 읽기 전용 함수들이 여전히 `{ T }` 또는 `{ [K]: V }` 를 요구하고 있어 `stl.Arr` 및 읽기 전용 테이블이 타입 에러로 거절됩니다.

#### 1) 왜 그런가 (파일:줄)
- [conventions.md:305-308](file:///code/Projects/stl-luau-agy/rv-types/.claude/conventions.md#L305-L308):
  > "대가: 리스트를 읽고 쓰는 타입({ T })을 받는 자리에 Arr 가 안 들어갑니다 — 라이브러리의 생성자 중 리스트를 읽기만 하는 것(FromList·FromRecords·Arr.FromTable·Fut.All·Common.denseList)은 { read [number]: T } 로 받게 바꿨고 … 새 함수가 리스트를 읽기만 하면 { read [number]: T } 로 받으세요."
- 그러나 질문 BB 변경 당시 아래 함수들이 누락되었습니다:
  1. [src/Collections/TreeMap.luau:542-544](file:///code/Projects/stl-luau-agy/rv-types/src/Collections/TreeMap.luau#L542-L544): `FromSorted<K, V>(keys: { K }, values: { V }, ...)`
  2. [src/Trees/RedBlack.luau:466](file:///code/Projects/stl-luau-agy/rv-types/src/Trees/RedBlack.luau#L466): `FromSorted<K, V>(keys: { K }, values: { V }, ...)`
  3. [src/Trees/Avl.luau:275](file:///code/Projects/stl-luau-agy/rv-types/src/Trees/Avl.luau#L275): `FromSorted<K, V>(keys: { K }, values: { V }, ...)`
  4. [src/Algorithms/BSearch.luau:42](file:///code/Projects/stl-luau-agy/rv-types/src/Algorithms/BSearch.luau#L42): `LowerBound<E, K>(list: { E }, ...)`
  5. [src/Algorithms/BSearch.luau:55](file:///code/Projects/stl-luau-agy/rv-types/src/Algorithms/BSearch.luau#L55): `UpperBound<E, K>(list: { E }, ...)`
  6. [src/Algorithms/BSearch.luau:67](file:///code/Projects/stl-luau-agy/rv-types/src/Algorithms/BSearch.luau#L67): `Find<E, K>(list: { E }, ...)`
  7. [src/Algorithms/BSearch.luau:80](file:///code/Projects/stl-luau-agy/rv-types/src/Algorithms/BSearch.luau#L80): `EqualRange<E, K>(list: { E }, ...)`
  8. [src/Algorithms/BSearch.luau:94](file:///code/Projects/stl-luau-agy/rv-types/src/Algorithms/BSearch.luau#L94): `IsSorted<E>(list: { E }, ...)`
  9. [src/Trees/SortedArray.luau:83](file:///code/Projects/stl-luau-agy/rv-types/src/Trees/SortedArray.luau#L83): `Append<E>(list: { E }, count: number, other: { E }, otherCount: number)` (`other` 는 읽기만 함)
  10. [src/Collections/HashMap.luau:365](file:///code/Projects/stl-luau-agy/rv-types/src/Collections/HashMap.luau#L365): `FromTable<K, V>(tbl: { [K]: V })` (`tbl` 은 복사할 뿐 쓰지 않음)
- 이 함수들은 넘겨받은 배열/테이블을 **읽기만** 합니다(수정하지 않음).
- 그러나 타입 표기가 `{ T }` / `{ [K]: V }` 로 되어 있어, 사용자가 `stl.Arr` 이나 읽기 전용 테이블을 넘기면:
  `TypeError: Expected this to be '{number}', but got 'Arr<number>'; the indexer is read-only in the latter type, but the former type requires a read-write indexer`
  에러가 발생합니다.

#### 2) 재현 (실측)
- **재현 프로브**:
  - `.agy-probes/probe_rejected_arr_calls.luau`
  - `.agy-probes/probe_runtime_arr_compat.luau`
  - `.agy-probes/probe_hashmap_fromtable_readonly.luau`
- **정적 분석 실행**:
  ```bash
  ( ulimit -v 2097152; timeout 120 luau-analyze .agy-probes/probe_rejected_arr_calls.luau )
  # 출력:
  # ./.agy-probes/probe_rejected_arr_calls.luau(6,35): TypeError: Expected this to be '{number}', but got 'Arr<number>'; the indexer is read-only in the latter type, but the former type requires a read-write indexer
  # ./.agy-probes/probe_rejected_arr_calls.luau(15,35): TypeError: Expected this to be '{string}', but got 'Arr<string>'; the indexer is read-only in the latter type, but the former type requires a read-write indexer
  # ... (총 11건 에러)
  ```
- **런타임 실행 대조**:
  ```bash
  ( ulimit -v 1048576; timeout 60 luau .agy-probes/probe_runtime_arr_compat.luau )
  # 출력:
  # Runtime success:	2	2	1
  # (Arr 를 넘겨도 런타임에는 완전히 정상 동작함!)
  ```

#### 3) 제안
- 위 10개 함수의 매개변수 타입을 읽기 전용 인덱서로 변경:
  - `BSearch.*`, `TreeMap.FromSorted`, `RedBlack.FromSorted`, `Avl.FromSorted`: `keys: { read [number]: K }`, `values: { read [number]: V }`, `list: { read [number]: E }`
  - `SortedArray.Append`: `other: { read [number]: E }`
  - `HashMap.FromTable`: `tbl: { read [K]: V }`

---

### [테스트 공백 4] `LinkedDequeData<T>` 의 필드(`head`, `tail`, `size`)가 여전히 가변으로 노출

- **분류**: 테스트 공백 / 타입 구멍
- **한 줄 요약**: 질문 BB 에서 `Arr` 의 `n` 과 `CircularDeque` 의 `size` 는 `read` 로 잠그고 내부 구조를 숨겼으나, `LinkedDequeData<T>` 는 `head`, `tail`, `size` 가 여전히 read-write 로 열려 있어 외부에서 직접 대입해 내부 상태를 망가뜨릴 수 있습니다.

#### 1) 왜 그런가 (파일:줄)
- [src/Collections/LinkedDeque.luau:53-64](file:///code/Projects/stl-luau-agy/rv-types/src/Collections/LinkedDeque.luau#L53-L64):
  ```lua
  export type LinkedDequeData<T> = {
      head: Node<T>?,
      tail: Node<T>?,
      size: number,
      read __type: Trait.Token<"Stl.LinkedDeque">,
      read __traits: { ... },
  }
  ```
- 반면 읽기 타입인 [src/Collections/LinkedDeque.luau:69-72](file:///code/Projects/stl-luau-agy/rv-types/src/Collections/LinkedDeque.luau#L69-L72):
  ```lua
  export type LinkedDequeRead<T> = {
      read head: NodeRead<T>?,
      read tail: NodeRead<T>?,
      read size: number,
      ...
  ```
- `ArrData` 가 `read n: number`, `CircularDequeData` 가 `read size: number` 로 바뀐 것과 대조적으로, `LinkedDequeData` 는 필드에 `read` 가 붙어 있지 않아 `ld.size = 0`, `ld.head = nil` 같은 파괴적 직접 대입이 허용됩니다.

#### 2) 재현 (실측)
- **재현 프로브**: `.agy-probes/probe_linkeddeque_fields.luau`
- **정적 분석 실행**:
  ```bash
  ( ulimit -v 2097152; timeout 120 luau-analyze .agy-probes/probe_linkeddeque_fields.luau )
  # 출력: exit code 0 (진단 0건!)
  ```

#### 3) 제안
- `LinkedDequeData<T>` 의 필드를 `read head: Node<T>?`, `read tail: Node<T>?`, `read size: number` 로 변경하고, 모듈 내부는 `Raw<T>` 캐스트로 쓰도록 통일.

---

### [테스트 공백 / API 누락 5] `src/init.luau` 배럴에서 탐침 타입(`Trait.A`, `B`, `C`) 및 `MapAssocRead`/`SetAssocRead` 미수출

- **분류**: 테스트 공백 / API 누락
- **한 줄 요약**: 규약(`conventions.md` 167행)은 트레이트 구현 시 탐침 타입(`Trait.A`, `Trait.B`)을 쓰라고 안내하지만 배럴 `src/init.luau` 에서 이를 re-export 하지 않으며, `MapAssocRead` 와 `SetAssocRead` 도 정의되지 않았습니다.

#### 1) 왜 그런가 (파일:줄)
- [src/init.luau:128-130](file:///code/Projects/stl-luau-agy/rv-types/src/init.luau#L128-L130):
  ```lua
  export type TraitToken<N> = Trait.Token<N>
  export type TraitAnyKind = Trait.AnyKind
  export type TraitObject<R, F, G> = Trait.Object<R, F, G>
  ```
- [src/Trait/init.luau:91-93](file:///code/Projects/stl-luau-agy/rv-types/src/Trait/init.luau#L91-L93)에 정의된 `Trait.A`, `Trait.B`, `Trait.C` 가 배럴에 없습니다.
- 외부 라이브러리 사용자가 `stl` 배럴만 require 해서는 `stl.DequeProvided<MyDeque<stl.TraitA>, stl.TraitA>` 같은 정석적인 구현 표 주석을 달 수 없습니다.
- 또한 [src/init.luau:104-114](file:///code/Projects/stl-luau-agy/rv-types/src/init.luau#L104-L114)에서 `ListAssocRead`, `DequeAssocRead`, `StackAssocRead`, `QueueAssocRead` 는 export 되지만, `MapAssocRead` 와 `SetAssocRead` 는 정의조차 되어 있지 않습니다 (`Map.luau` 와 `Set.luau` 내부에서 익명 테이블로 인라인됨).

#### 2) 재현 (실측)
- **재현 프로브**: `.agy-probes/probe_external_container.luau`
- `Trait.A` 를 `stl.Trait.A` 또는 `stl.TraitA` 로 쓰려 하면 `Unknown type` 에러 발생.

#### 3) 제안
- `src/init.luau` 에 `export type TraitA = Trait.A`, `export type TraitB = Trait.B`, `export type TraitC = Trait.C` 추가.
- `src/Traits/Map.luau` 에 `export type AssocRead<K, V> = { read Key: () -> K, read Value: () -> V }` 명시적 정의 및 `src/init.luau` 에 `export type MapAssocRead<K, V> = Map.AssocRead<K, V>` 추가 (`Set` 도 동일).

---

### [참고 6] `Map.luau` 및 `Set.luau` 의 구식 주석 잔존

- **분류**: 참고 (문서-구현 불일치)
- [src/Traits/Map.luau:129](file:///code/Projects/stl-luau-agy/rv-types/src/Traits/Map.luau#L129):
  `-- 트레이트 함수의 진입점(Map.Get …)은 시스템이 만들지만 서명을 입히지 않습니다(아직 부르는 곳이 없음 — 넣을 땐 Value 로).`
- [src/Traits/Set.luau:32](file:///code/Projects/stl-luau-agy/rv-types/src/Traits/Set.luau#L32):
  `-- 완성 표(= 등록 표 — 기본 구현이 없음). 진입점(Set.Add …)은 시스템이 만들지만 서명을 입히지 않습니다(부르는 곳이 생기면 Value 로).`
- **현실**: 질문 BA 에서 `Trait.Entries` 가 도입되면서 `Trait.Trait` 반환값에 `Entries<F>` 가 자동으로 붙었습니다. 현재 `stl.Map.Get`, `stl.Map.Set`, `stl.Set.Add`, `stl.Set.Has` 등은 정적 서명이 완전히 입혀져 있으며 정상 동작합니다 (`.agy-probes/probe_map_entries.luau`, `probe_set_entries.luau` 실측). 옛 주석을 갱신하거나 정리하는 것을 제안합니다.

---

### [참고 7] `Self` 반환 진입점의 명시적 제네릭 순서와 Luau 솔버 동작

- **분류**: 참고 (언어 및 솔버 제약)
- **내용**:
  `Trait.Entries` 의 `dropSelf` 는 `Self` 가 첫 번째 파라미터에만 쓰일 때만 제네릭에서 제거합니다 (`src/Trait/init.luau:322-371`).
  반환 타입이 `Self` 인 진입점들:
  - `Collection.Clear`: `(collection: Self) -> Self` => 제네릭 `<Self>`
  - `Deque.PushFront`, `PushBack`: `(deque: Self, item: T) -> Self` => 제네릭 `<Self, T>`
  - `Stack.Push`, `Queue.Push`: `(s: Self, item: T) -> Self` => 제네릭 `<Self, T>`
  이 함수들은 첫 번째 제네릭이 `Self` 입니다.
  Luau 새 솔버는 명시적 제네릭 인자 `f<<...>>` 의 부분 지정을 지원하지 않으므로(`Internal error: outstanding free or blocked type in function call`),
  사용자가 원소 타입만 지정하려고 `Deque.PushBack<<number>>(d, 3)` 을 호출하면 `number` 가 `Self` 에 바인딩되어:
  `TypeError: Expected this to be 'number & { ... }' but got 'CircularDeque<number>'; CircularDeque<number> is not a subtype of number`
  에러가 발생합니다 (`.agy-probes/probe_entries_generics.luau` 실측).
  따라서 `Self` 를 반환하는 진입점은 명시적 제네릭 인자를 주지 않고 타입 추론에 맡기거나, 전체를 명시(`PushBack<<typeof(d), number>>(d, 3)`)해야 합니다.
  이는 Luau 솔버의 제네릭 부분 지정 부재에 기인한 것으로, 설계 의도와 일치하므로 규약 문서에 유의 사항으로 남겨두는 것을 권장합니다.

---

## 4. 결론

질문 BA/BB 변경은 트레이트의 읽기/쓰기 분리(`Of`/`OfMut`)와 연관 타입 레코드(`__traits`), 그리고 닫힌 트레이트(`Trait.Struct`) 모델을 통해 기존의 거대한 마커 팬텀들을 획기적으로 줄이고 타입 건전성을 크게 끌어올렸습니다.

그러나 다음 세 가지 핵심 메커니즘은 후속 조치가 필요합니다:
1. **`List.AssocRead` 의 `Index` 불변화**: `read Index: (I) -> I` 로 수정하여 엉뚱한 타입의 인덱스 전달 시 정적 에러로 잡고 런타임 크래시를 방지할 것.
2. **`Map.Iter` 의 인덱서 `read` 복원**: Luau 타입 함수가 `setreadindexer` 를 지원하지 않으므로 `Map.Iter` 서명이 가변으로 풀리는 현상을 우회할 것.
3. **읽기 전용 함수들의 `{ read [number]: T }` 수용**: `BSearch`, `TreeMap.FromSorted`, `RedBlack.FromSorted`, `Avl.FromSorted`, `SortedArray.Append`, `HashMap.FromTable` 이 `stl.Arr` 및 읽기 전용 테이블을 수용하도록 서명을 맞출 것.

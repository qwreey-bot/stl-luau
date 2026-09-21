# 전면 재작성 계획 (2026-09-21 확정)

stl-luau 는 **한 번도 외부에 반출·릴리스된 적이 없어** breaking change 개념이
없습니다(사용자 확인). 공개 API 를 전부 바꾸고 `arr` 을 새로 씁니다.

이 문서는 **확정된 결정과 그 근거**입니다. 실측 전량은
`.claude/audit/arr-type-redesign/`(REPORT + 스파이크 11개)에 있습니다.

---

## 0. 왜 재작성인가

`.claude/audit/arr-type-redesign/REPORT.md` 가 보여주듯 **타입 검사가 죽어
있었습니다**(음성 대조군 0/6). 1차 수정으로 6/6 까지 살렸지만, 그 과정에서
현재 구조의 한계가 드러났습니다:

- 메소드가 `snake_case` 라 quad 생태계와 어긋남
- 생성자가 "호출 가능한 모듈 값"이라 **모듈 오타를 못 잡음**(교집합 구멍)
- `map` 등 타입 변환 메소드가 **타입 인자를 잃음**(`Unifiable<Error>`)

셋 다 타입 선언 구조에서 나오므로, 이름까지 바꾸는 김에 한 번에 갑니다.

---

## 1. 확정된 설계 (전부 실측 근거 있음)

### 1-1. 타입 3층

```lua
export type ArrData<T> = { n: number, [number]: T }        -- 데이터부
export type ArrView<T> = ArrData<T> & { …조회·자기폐쇄 메소드… }  -- 콜백이 받는 뷰
export type Arr<T>     = ArrData<T> & ArrIfce               -- 전체형
```

**교집합(`&`)을 씁니다. `setmetatable<>` 은 쓰지 않습니다.**

| 메소드 수 | `setmetatable<>` | 교집합 `&` |
|---|---|---|
| 10, 20 | 클린 | 클린 |
| **30~63** | `Code is too complex` + `pending-expansion` 1700여 건 | 클린 |

한도 플래그는 **듣지 않습니다** — quad 가 쓰는 3종
(`LuauTarjanChildLimit`/`LuauSubtypingIterationLimit`/`LuauTypeInferIterationLimit`)
에 3종을 더해도 `luau-analyze`/`luau-lsp` 양쪽에서 1590 → 1590. 실패가
`Type function instance setmetatable<…>` 1586건이라 예산이 아니라 **타입
함수가 확장을 못 하는 구조 문제**입니다.

### 1-2. 메소드는 이름 붙은 top-level 함수 + `typeof` 명시 나열 (quad ③)

```lua
local function Map<T, G>(self: Arr<T>, fn: (el: T, idx: number, arr: ArrView<T>) -> G): Arr<G>
	…
end

type ArrIfce = {
	Map: typeof(Map),
	Push: typeof(Push),
	…
}
```

인라인 제네릭으로 쓰면 `Map` 의 반환이 `Unifiable<Error>` 로 샙니다(실측).
`ArrIfce` 자체는 **제네릭이 아닙니다** — 제네릭성은 이름 붙은 함수 쪽에
있고, 이게 재귀 파라미터 충돌을 없앱니다.

### 1-3. 콜백의 컨테이너 인자는 `ArrView<T>`

**규칙: 콜백 타입이 `Arr<T>`(전체형)를 어디에서도 언급하지 않으면 됩니다.**

| 콜백 arr 타입 | 3단 타입변환 체이닝 | 콜백서 메소드 |
|---|---|---|
| `ArrData<T>` | ✅ | ❌ |
| **비재귀 메소드 포함** | **✅** | **✅** |
| **자기폐쇄 재귀(`-> ArrView<T>`)** | **✅** | **✅** |
| 재귀 반환이 `Arr<T>` | ❌ | ✅ |
| 전체 `Arr<T>` | ❌ | ✅ |

그래서 `ArrView<T>` 의 자기폐쇄 메소드는 `Arr<T>` 가 아니라 **`ArrView<T>`**
를 반환합니다. `Map`/`FlatMap`/`Reduce` 처럼 타입을 바꾸는 것만 뷰에서
빠집니다 — 넣으면 바깥 체이닝이 죽습니다. 콜백 안에서 `Map` 이 필요하면
바깥 변수를 쓰면 됩니다.

콜백 안에서 이게 전부 됩니다:
```lua
a:Map(function(el, idx, arr: ArrView<number>)
	return el + arr.n + arr:Len() + #arr:Join(",") + arr:Slice(1, idx):Len()
end)
```

**`self` 파라미터의 극성은 무관합니다**(`Arr<T>` 든 `ArrData<T>` 든 동일 —
실측). quad 가 `Apply` 에서 `self: StateData<T>` 를 쓰는 건 이 문제가 아니라
§8.9 의 유니언 검사 결함 때문이라 우리는 해당 없습니다.

### 1-4. 네임스페이스는 순수 테이블 (`List.of` 선례)

```lua
local a = stl.Arr.Of(1, 2, 3)
local b = stl.Arr.Sized(10, 0)
if stl.isArr(a) then end
```

**콜러블 네임스페이스(`Arr(...)` + `Arr.Sized(...)`)는 쓸 수 없습니다** —
`Arr` 이 제네릭이라 `__call` 경유 호출이 타입 인자를 잃습니다(실측; quad
§1-3 의 "제네릭 생성자엔 필드를 얹지 말 것"과 일치). 순수 테이블이면
**모듈 오타까지 잡힙니다**(`Key 'Off' not found in table 'ArrNs'`).

### 1-5. 네이밍 (quad 2026-09-15 갱신 기준)

기준: **"값을 만들거나 감싸는 함수는 대문자, 판별 술어·엔진 멤버는 소문자."**

| 무엇 | 케이싱 | 예 |
|---|---|---|
| 타입 | PascalCase | `Arr<T>`, `ArrView<T>`, `ArrData<T>` |
| 생성자 | PascalCase | `Arr.Of`, `Arr.Sized`, `Arr.FromTable` |
| 콜론 메소드 | PascalCase | `:Push()`, `:PushMany()`, `:SortInplace()` |
| 술어 | camelCase 최상위 | `stl.isArr(v)` |
| 지역 변수 | camelCase | `arrLen`, `moveLen` |
| `require` 받은 모듈 | PascalCase | `local Common = require("./Common")` |
| 소스 파일 | PascalCase | `src/Arr.luau`, `src/HashSet.luau` |
| 테스트 파일 | 소문자 + dot | `tests/spec.arr.luau` |

### 1-6. 나머지 규약 (사용자 확정)

- **`const` 바인딩을 씁니다.** 재대입 없는 바인딩은 전부 `const`.
- **삼항 `and/or` 금지.** `if-then-else` 표현식만. 단순 2항 `x or y` 는 허용.
- **`--!strict` 를 모든 파일 1행에.** 그 다음 `--[[ Module — 설명 ]]` 블록.
- **탭 들여쓰기.** 주석은 한국어(이 저장소 지배 스타일).
- **에러 메시지는 영어, `Arr: <설명>` 형식.**

### 1-7. selene 폐기 (사용자 확정)

`const` 의 관문이었습니다:

| 도구 | `const` |
|---|---|
| `luau` / `luau-analyze` / `luau-lsp` | ✅ |
| **`selene` 0.31.0**(최신) | ❌ 파스 에러 |
| `pesde` 0.7.3 | ❌ → **0.7.4 로 올려야 함** |

selene 은 갈아탈 상위 버전이 없어 폐기합니다. 잃는 것: `empty_if`,
`empty_loop`, 미사용 변수 탐지 정밀도(21→2). 전면 재작성이라 미사용 변수
대부분은 어차피 사라집니다.

---

## 2. 작업 순서

### 1단계 — 검증 장치부터

재작성 도중 "타입이 죽었는데 진단 0건" 을 놓치지 않기 위해 **먼저** 세웁니다.

- `scripts/check.sh` 에 **음성 대조군 배터리**를 게이트로 편입.
  스파이크별 기대 진단 건수가 `spikes/README.md` 에 표로 있음 — 수치가
  틀리면 실패시킨다.
- `mise.toml`: selene 제거, `pesde = "0.7.4"` 추가(또는 `self-upgrade`).
- `.luaurc` 는 그대로(`strict` + `lint: *`).

### 2단계 — `src/Types.luau` (타입 단일 파일)

quad 의 `quad-types` 방식. 배포 시 ModuleScript 가 덜 들고 LSP 부담이 적습니다.
배치 순서도 quad 를 따릅니다: **마커 → 데이터부/뷰 → 전체형 → 최상위**.

이후 컨테이너 타입도 전부 여기 모읍니다.

### 3단계 — `src/Arr.luau` 재작성 (메소드 54 + 생성자 9)

- 이름 붙은 함수 + `typeof` 나열로 전면 재작성
- `tests/spec.arr.luau` 동시 재작성 (호출부 207군데)
- 각 절마다 **음성 대조군**을 같이 넣는다 — 지금 테스트는 양성만 본다

### 4단계 — 검증 후 나머지 컨테이너

`HashSet` → `TreeSet`(+`BSearch`) → `HashMap` → `TreeMap` → `Heap`.
컨테이너 표현은 사용자 결정(2026-08-22)대로 **래퍼**(`{ data, size }`) —
`hashset<string>` 에서 `add(s, "n")` 이 길이 필드를 덮어쓰는 문제 때문.

---

## 3. 개명표

### 네임스페이스 (`stl.Arr.*`) — 생성자·술어

| 지금 | 재작성 후 |
|---|---|
| `arr(...)` | `Arr.Of(...)` |
| `arr.sized(...)` | `Arr.Sized(...)` |
| `arr.from_table(...)` | `Arr.FromTable(...)` |
| `arr.clone_from_table(...)` | `Arr.CloneFromTable(...)` |
| `arr.from_iter(...)` | `Arr.FromIter(...)` |
| `arr.from_func(...)` | `Arr.FromFunc(...)` |
| `arr.pack(...)` | `Arr.Pack(...)` |
| `arr.merge(...)` | `Arr.Merge(...)` |
| `arr.range(...)` | `Arr.Range(...)` |
| `arr.is_arr(...)` | `stl.isArr(...)` *(술어는 camelCase 최상위)* |

### 인스턴스 콜론 메소드 (54개)

| 지금 | 재작성 후 | ArrView 포함 |
|---|---|---|
| `:clear()` | `:Clear()` | — |
| `:clone()` | `:Clone()` | ✅ 자기폐쇄 |
| `:consume()` | `:Consume()` | — |
| `:count()` | `:Count()` | ✅ 조회 |
| `:each()` | `:Each()` | — |
| `:empty()` | `:Empty()` | ✅ 조회 |
| `:equal()` | `:Equal()` | ✅ 조회 |
| `:erase()` | `:Erase()` | ✅ 자기폐쇄 |
| `:erase_inplace()` | `:EraseInplace()` | — |
| `:every()` | `:Every()` | ✅ 조회 |
| `:fill()` | `:Fill()` | — |
| `:filter()` | `:Filter()` | ✅ 자기폐쇄 |
| `:filter_inplace()` | `:FilterInplace()` | — |
| `:find()` | `:Find()` | ✅ 조회 |
| `:flat()` | `:Flat()` | ✅ 자기폐쇄 |
| `:flat_inplace()` | `:FlatInplace()` | — |
| `:flatmap()` | `:Flatmap()` | ❌ 타입변환 |
| `:flatmap_inplace()` | `:FlatmapInplace()` | ❌ 타입변환 |
| `:insert()` | `:Insert()` | — |
| `:insert_array()` | `:InsertArray()` | — |
| `:insert_many()` | `:InsertMany()` | — |
| `:iter()` | `:Iter()` | ✅ 조회 |
| `:join()` | `:Join()` | ✅ 조회 |
| `:len()` | `:Len()` | ✅ 조회 |
| `:map()` | `:Map()` | ❌ 타입변환 |
| `:map_inplace()` | `:MapInplace()` | ❌ 타입변환 |
| `:max()` | `:Max()` | ✅ 조회 |
| `:merge_inplace()` | `:MergeInplace()` | — |
| `:min()` | `:Min()` | ✅ 조회 |
| `:prod()` | `:Prod()` | ✅ 조회 |
| `:push()` | `:Push()` | — |
| `:push_array()` | `:PushArray()` | — |
| `:push_many()` | `:PushMany()` | — |
| `:rangeflat()` | `:Rangeflat()` | ✅ 자기폐쇄 |
| `:rangeflat_inplace()` | `:RangeflatInplace()` | — |
| `:reduce()` | `:Reduce()` | ❌ 타입변환 |
| `:replace()` | `:Replace()` | — |
| `:replace_inplace()` | `:ReplaceInplace()` | — |
| `:reverse()` | `:Reverse()` | ✅ 자기폐쇄 |
| `:reverse_inplace()` | `:ReverseInplace()` | — |
| `:rotate()` | `:Rotate()` | ✅ 자기폐쇄 |
| `:rotate_inplace()` | `:RotateInplace()` | — |
| `:shuffle()` | `:Shuffle()` | — |
| `:shuffle_inplace()` | `:ShuffleInplace()` | — |
| `:slice()` | `:Slice()` | ✅ 자기폐쇄 |
| `:slice_inplace()` | `:SliceInplace()` | — |
| `:some()` | `:Some()` | ✅ 조회 |
| `:sort_inplace()` | `:SortInplace()` | — |
| `:sorted()` | `:Sorted()` | ✅ 자기폐쇄 |
| `:sum()` | `:Sum()` | ✅ 조회 |
| `:unpack()` | `:Unpack()` | ✅ 조회 |
| `:unshift()` | `:Unshift()` | — |
| `:unshift_array()` | `:UnshiftArray()` | — |
| `:unshift_many()` | `:UnshiftMany()` | — |

**`ArrView` 구성**: 조회 14 + 자기폐쇄 9 = **23개**.
빠지는 것은 타입 변환 5개(`Map`/`MapInplace`/`FlatMap`/`FlatMapInplace`/`Reduce`)
와 변형 계열(`Push`/`Erase`/`Fill` 등 — 뷰는 읽기 관점이므로 의도적 제외).

---

## 4. 보류 / 추적

### 보류 (사용자: "문제가 발생할 때, 아플 때 처리")

- **극성 검사 게이트**(quad 의 `type-surface-check.py`). 입력 자리에 전체형이
  오면 실패시키는 스크립트. 컨테이너가 늘어나면 값질 것.
- **마커 타입**(`{ read __arr__: true, read __arrValue: T }`). quad §8.11 의
  기법으로, **입력 자리를 공변으로** 만듭니다 — `Arr.Merge(a, b)`,
  `:PushArray(source)` 처럼 다른 배열을 받는 자리에서 `Arr<Frame>` 을
  `Arr<Instance>` 자리에 넣을 수 있게 됩니다. 지금은 불변이라 거부됩니다.
  **주의**: 마커에 `& { read Push }` 를 걸어 "쓸 수 있는 값"을 요구하는 건
  안 됩니다(quad §8.25 — 교집합 조각별 대조 실패).

### 추적 — Luau 가 고치면 풀리는 것

- **재귀 제네릭 반환의 명시 바인딩 관례**:
  RFC [`relax-recursive-type-restriction`](https://rfcs.luau.org/relax-recursive-type-restriction.html),
  이슈 [luau-lang/luau#2380](https://github.com/luau-lang/luau/issues/2380).
  RFC 가 드는 예시 `Promise<T>.andThen` 이 우리 `Map` 과 글자 그대로 같은
  모양입니다. **순수 내부 변경이라 지금 코드를 그대로 두면 자동으로 수혜**를
  받습니다 — quad 결론: *"미리 대비할 것 — 없음."*
- **콜백 파라미터 무주석 추론**: RFC/이슈가 **없습니다**. quad 가 20개
  formulation 으로 재시도했지만 못 뚫었고, 원인이 재귀가 아니라
  *"제네릭이 관여하는 함수 호출의 인자로 넘긴 함수 리터럴엔 Luau 가 컨텍스트
  타입을 전파하지 않는다"* 는 더 일반적인 한계로 재규정됐습니다.
  **지금은 콜백 파라미터에 주석을 답니다.** 나중에 고쳐지면 기존 코드는
  그대로 돌고 새 코드만 주석을 생략하면 됩니다(사용자 전략).

### 남은 실측 부채

- `slice` 의 `to_start` 삽입 경로 버그(`todos.md`). 재작성에서 **`to_start`
  의미를 먼저 정하고**(밀어내기 vs 덮어쓰기) 구현할 것 — 현재 `reverse` 는
  덮어쓰기로 테스트가 고정돼 있어 둘이 어긋나 있음.
- `max`/`min`/`sum`/`prod` 의 `nil` 구멍 안전성(`sorted` 만 고쳐짐).

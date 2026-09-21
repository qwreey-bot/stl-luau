# `Arr` 재작성 작업 목록

`.claude/base/rewrite-plan.md` 가 **결정**이고, 이 문서는 **그 결정을 메소드마다
적용한 체크리스트**입니다. 3단계(`src/Arr.luau` 재작성) 착수 시 이걸 따라갑니다.

## 모든 메소드에 공통으로 적용되는 것

1. 이름은 PascalCase 콜론 메소드. 구현은 **이름 붙은 top-level 함수**로 쓰고
   `ArrIfce` 에 `typeof(…)` 로 나열합니다.
2. 콜백을 받는 것은 3번째 인자로 **`ArrView<T>`** 를 넘깁니다(전체형 `Arr<T>`
   를 넘기면 타입 변환 체이닝이 죽음).
3. 범위 규약은 **Lua 관례**: 닫힘 `[start, last]`, 음수 인덱스 지원,
   범위 초과는 clamp, 뒤집힌 범위는 빈 결과/no-op, 빈 것 조회는 `nil`.
4. **경계 케이스를 테스트로 고정**합니다: 빈 것 / 1개 / 뒤집힘 / 초과 / 음수 /
   `nil` 구멍. 그리고 계약을 메소드 주석에 적습니다.
5. 재대입 없는 바인딩은 `const`. 삼항 `and/or` 금지.

## 메소드별

| 지금 | 새 이름 | ArrView | 비고 / 알려진 문제 |
|---|---|---|---|
| `:clear()` | `:Clear()` | — | `table.clear` 가 `__arr__` 태그를 지우므로 다시 심어야 함(2026-08-31 수정) |
| `:clone()` | `:Clone()` | 자기폐쇄 |  |
| `:consume()` | ~~제거~~ | — | FoldUntil 로 통합(each 와 중복이었음) |
| `:count()` | `:Count()` | 조회 |  |
| `:each()` | `:FoldUntil()` | — | → `FoldUntil(init, fn)`. 콜백이 `(acc, done)` 반환, `(acc, 멈춘 인덱스?)` 돌려줌 |
| `:empty()` | `:Empty()` | 조회 |  |
| `:equal()` | `:Equal()` | 조회 |  |
| `:erase()` | `:Erase()` | 자기폐쇄 |  |
| `:erase_inplace()` | `:EraseInplace()` | — | 뒤집힌 구간은 no-op(2026-08-31 수정) |
| `:every()` | `:Every()` | 조회 |  |
| `:fill()` | `:Fill()` | — |  |
| `:filter()` | `:Filter()` | 자기폐쇄 |  |
| `:filter_inplace()` | `:Retain()` | — |  |
| `:find()` | `:Find()` | 조회 |  |
| `:flat()` | `:Flat()` | 자기폐쇄 | `Flat(start?, last?, to?)` 로 구간 인자를 받아 rangeflat 흡수 |
| `:flat_inplace()` | `:FlatInplace()` | — | `FlatInplace(start?, last?)` |
| `:flatmap()` | `:Flatmap()` | — | 타입 변환 |
| `:flatmap_inplace()` | `:FlatmapInplace()` | — | 타입 변환 |
| `:insert()` | `:Insert()` | — |  |
| `:insert_array()` | `:InsertArray()` | — | table.move |
| `:insert_many()` | `:InsertMany()` | — | select 루프 |
| `:iter()` | `:Iter()` | — | `__iter` 는 **보류**. 교집합에서 루프 변수 타입이 죽음. 나중에 추가해도 breaking 아님 |
| `:join()` | `:Join()` | 조회 |  |
| `:len()` | `:Len()` | 조회 |  |
| `:map()` | `:Map()` | — | 타입 변환 — 콜백 인자는 `ArrView<T>`. 반환은 `Arr<G>` |
| `:map_inplace()` | `:MapInplace()` | — | 타입 변환 |
| `:max()` | `:Max()` | 조회 | ⚠️ 1..n 사이 nil 구멍에서 `compareTo(nil, base)` → `nil - base` 로 터짐 |
| `:merge_inplace()` | `:MergeInplace()` | — |  |
| `:min()` | `:Min()` | 조회 | ⚠️ max 와 동일 |
| `:prod()` | `:Prod()` | 조회 | ⚠️ max 와 동일 |
| `:push()` | `:PushBack()` | — | 고정 인자(비용 0). 가변인자로 합치지 않음 — 실측 +8~13% |
| `:push_array()` | `:PushBackArray()` | — | `table.move` |
| `:push_many()` | `:PushBackMany()` | — | `table.pack` 대신 **select 루프**(실측 1.6~2.3배 빠름) |
| `:rangeflat()` | ~~제거~~ | — | Flat 이 구간 인자를 받아 흡수 |
| `:rangeflat_inplace()` | ~~제거~~ | — | FlatInplace 가 흡수 |
| `:reduce()` | `:Fold()` | — | **초기값을 앞으로**. 초기값 없는 판은 `Reduce(fn) -> T?` 로 신설 분리 |
| `:replace()` | `:Replace()` | — |  |
| `:replace_inplace()` | `:ReplaceInplace()` | — |  |
| `:reverse()` | `:Reverse()` | 자기폐쇄 | to_start 는 **덮어쓰기**(테스트로 고정). Slice 와 의미가 다름 — 통일 여부 판단 필요 |
| `:reverse_inplace()` | `:ReverseInplace()` | — |  |
| `:rotate()` | `:Rotate()` | 자기폐쇄 | shift 양수 = 왼쪽 회전(STL std::rotate 방향) |
| `:rotate_inplace()` | `:RotateInplace()` | — |  |
| `:shuffle()` | `:Shuffle()` | — | rng 주입 가능 `(min, max) -> number`, 기본 `math.random` |
| `:shuffle_inplace()` | `:ShuffleInplace()` | — |  |
| `:slice()` | `:Slice()` | 자기폐쇄 | ⚠️ **to_start 삽입 경로가 틀림** — to_len=5, to_start=2, move_len=2 이면 2..5 를 4..7 로 옮겨야 하는데 4..5 만 옮김. `to.n` 도 중간 삽입 미고려. **먼저 to_start 의미를 정할 것**(밀어내기 vs 덮어쓰기) — Reverse 는 덮어쓰기로 테스트 고정됨 |
| `:slice_inplace()` | `:SliceInplace()` | — | 빈 구간이면 Clear 를 호출 |
| `:some()` | `:Some()` | 조회 |  |
| `:sort_inplace()` | `:SortInplace()` | — | Sorted 와 같은 헬퍼 공유 |
| `:sorted()` | `:Sort()` | 자기폐쇄 | nil 구멍을 걸러내고 뒤로 몲(2026-08-31 수정). 비교자 방향은 Max/Min 과 동일 |
| `:sum()` | `:Sum()` | 조회 | ⚠️ max 와 동일 |
| `:unpack()` | `:Unpack()` | 조회 |  |
| `:unshift()` | `:PushFront()` | — |  |
| `:unshift_array()` | `:PushFrontArray()` | — | table.move |
| `:unshift_many()` | `:PushFrontMany()` | — | select 루프 |

### 신설 (2개)

| 이름 | 무엇 | ArrView |
|---|---|---|
| `:FoldRight(init, fn)` | 오른쪽부터 접기 | — |
| `:Reduce(fn)` | 초기값 없음, 첫 원소가 씨앗 → `T?` | — |

## 네임스페이스 `Arr.*` (생성자 10개)

| 지금 | 새 이름 | 비고 |
|---|---|---|
| `arr(...)` | `Arr.Of(...)` | `List.of` 선례 |
| `arr.sized(...)` | `Arr.Sized(...)` | |
| `arr.from_table(...)` | `Arr.FromTable(...)` | |
| `arr.clone_from_table(...)` | `Arr.CloneFromTable(...)` | |
| `arr.from_iter(...)` | `Arr.FromIter(...)` | |
| `arr.from_func(...)` | `Arr.FromFunc(...)` | |
| `arr.pack(...)` | `Arr.Pack(...)` | |
| `arr.merge(...)` | `Arr.Merge(...)` | |
| `arr.range(...)` | `Arr.Range(...)` | |
| `arr.is_arr(v)` | `stl.isArr(v)` | 술어는 camelCase 최상위 |

## 사용자 대응이 필요해 쌓아둔 것

1. **⭐ mlua(Rust) 바인딩이 실제 목표인가?** 루트 `todo` 에만 있던 항목입니다.
   사실이면 공개 API 가 바인딩에서 부르기 쉬운 모양인지 봐야 합니다 —
   콜론 메소드 54개를 러스트에서 노출하는 건 부담이 큽니다.
2. **`slice` 의 `to_start` 의미**: 밀어내고 삽입인가 덮어쓰기인가.
   지금 `Reverse` 는 덮어쓰기로 테스트가 고정돼 있어 둘이 어긋나 있습니다.
3. **`nil` 구멍 정책**: `Sort` 만 고쳐졌고 `Max`/`Min`/`Sum`/`Prod` 는 그대로
   터집니다. 컨테이너 전반에서 한 번에 정할 문제입니다.
4. **위치 저장 UB**: 문서 규약으로 둘지 세대 카운터로 런타임 검출할지.
5. **`__iter` 제공 여부**: 보류 결정됨. 나중에 추가해도 breaking 아님.

## 지금 손대지 않는 이유

`src/` 스캐폴딩(공통 뼈대, 폴더 구조, 무엇을 공통으로 뽑을지)이 먼저입니다.
뼈대 없이 54개를 짜면 뼈대가 잡힐 때 다시 짜야 합니다.


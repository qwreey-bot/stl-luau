# 04. 빠진 표면 — 무엇을 더 구현할까 (2026-09-30)

사용자 요청: *"아직 구현해야할 부분이 많지 않아? stl 은 필요한 요소가 하나가
아니니까. 소트 알고리즘도 여럿 있고(일반 소트가 아닌것도) … 일반적 stl 에서
필요한 요소들이, 우리가 무엇을 빠트렸는지도 보고싶음."*

**어떻게 봤나**: sonnet 리서처 셋이 읽기 전용으로 나눠 봤습니다 — (1) C++
`<algorithm>`/`<numeric>`/`<ranges>`/컨테이너(로컬 MSVC STL), (2) Rust slice·
Iterator·컬렉션 + Java `java.util`(로컬 소스), (3) Luau 생태계(Sift, Llama,
TableUtil, Dash, evaera Promise 의 API 표면 + Luau VM 의 `table`/`buffer`
라이브러리 + `quad-scratch/refs` 의 손으로 짠 자료구조). 보고서의 추측 표시
주장은 제가 소스로 다시 확인했습니다(아래 "확인한 사실"). 정렬 쪽은 직접
실측했습니다(`base/perf-measurements.md` 15절).

**이 문서는 결정이 아니라 판단 재료입니다.** 결정은 `question.md` W 에.

---

## 확인한 사실 (리서처 주장 → 소스 대조)

| 주장 | 확인 |
|---|---|
| `Arr` 에 `PushBack`/`PushFront` 는 있는데 **꺼내는 짝(`Pop*`)이 없다** | ✅ 맞음 |
| `Arr.Merge`/`MergeInplace` 는 `std::merge`(정렬 병합)가 아니라 **이어붙이기** | ✅ 맞음 — 이름이 오해를 부름 |
| `Arr.Replace` 는 `std::replace`(값→값)가 아니라 **구간 치환(splice)** | ✅ 맞음 |
| `Arr.Get` 은 음수 인덱스를 안 받는다(구간 연산만 받음) | ✅ `return self[idx]` — 계약(`ListCore`) 멤버라 원시 조회 |
| `PushFront` 는 O(n) | ✅ `table.move` 로 전체를 한 칸 밈 |
| `Heap` 이 비교자를 받는가 | ✅ `New(less)` — `priority_queue` 는 이미 있음 |
| `HashMap.Records` 가 삽입 순서를 지키는가 | ❌ `pairs` 순서 — 순서 있는 맵은 **없음** |
| `table.freeze` 를 안 쓴다 | 거의 — `Optional.Absent` 하나뿐. 컨테이너 API 로는 없음 |
| 안정 정렬 수요가 있나 | ✅ **내부에 이미 있음** — `TreeMap` 이 원래 위치를 타이브레이커로 써서 흉내 냄 |

---

## 여러 출처가 겹친 것 (= 강한 신호)

세 리서처가 독립적으로 같은 것을 짚은 것만 모았습니다.

| 무엇 | C++ | Rust/Java | Luau 생태계 |
|---|---|---|---|
| **`PopBack`/`PopFront`** | stack/queue pop | `Vec::pop`, `pollFirst` | Sift·Llama `pop`/`shift` |
| **`Zip` / 이항 `Map`** | 2-입력 `transform` | `zip` | **4/4 라이브러리** |
| **중복 제거** | `unique` | `dedup` | Sift `dedupe` |
| **안정 정렬 / 키 정렬 / 부분 정렬** | `stable_sort`/`partial_sort`/`nth_element` | `sort_by_key`/`select_nth_unstable` | (라이브러리엔 `sortBy` 정도) |
| **맵 누적(`없으면 넣기`/`merge`)** | — | `entry().or_insert_with`, `Map.merge`/`computeIfAbsent` | 딕셔너리 `merge` **4/4** |
| **양끝 O(1) 큐(Deque)** | `deque` | `VecDeque`/`ArrayDeque` | `rbvm` 이 스택/큐를 **손으로 짬**(주석에 이유까지) |
| **`Partition`** | `partition` | `Iterator::partition` | — |
| **`Chunks`/`Windows`** | `views::chunk`/`slide` | `chunks`/`windows` | — |
| **누적 배열(Scan / prefix sum)** | `partial_sum`/`inclusive_scan` | `scan` | — |
| **`Fut.Race`/`Timeout`/`Retry`/`AllSettled`** | — | — | evaera Promise |

---

## 제안 — 다섯 파도

같은 파도 안은 서로 독립이라 한꺼번에 갈 수 있고, 파도 사이에는 사용자 확인을
둡니다. 괄호 안은 주 출처.

### 파도 1 — `Arr` 의 빈 조각 (작고 확실함)

| 이름(안) | 무엇 | 비고 |
|---|---|---|
| `PopBack` / `PopFront` | 꺼내며 제거, 값을 돌려줌 | `PopFront` 는 O(n) 이라고 적고 Deque 를 가리킴 |
| `SwapRemove(idx)` | 끝 원소로 메워 O(1) 제거(순서 무시) | Rust. 이 저장소 성능 문화와 맞음 |
| `Contains(v)` / `IndexOf(v)` / `LastIndexOf(v)` | 값 기반 조회 | 지금은 `Some(fn)` 을 매번 손으로 |
| `FindLast(fn)` | 뒤에서부터 찾기 | Sift·Llama |
| `Zip(a, b)` / `ZipWith(a, b, fn)` | 두 배열을 짝지음 | ⚠️ 짝의 **표현**이 질문(아래 W2) |
| `Dedup` / `DedupInplace` | **인접** 중복 제거(정렬 뒤 짝) | C++ `unique`, Rust `dedup` |
| `Unique` | 순서 보존 전체 중복 제거(해시) | 생태계 `uniq` |
| `Partition(fn)` | 한 패스로 두 배열 | `Filter` 두 번보다 1패스 |
| `Chunks(n)` / `Windows(n)` | 고정 크기 조각 / 미끄럼 창 | **즉시 `Arr<Arr<T>>`** — 지연 반복자는 2.9배 느림(9절) |
| `Scan(init, fn)` | 중간값을 모두 남기는 `Fold`(누적합 등) | prefix sum 의 일반형 |
| `MinMax` | 한 패스로 둘 다 | |
| `MaxBy(key)` / `MinBy(key)` | 키 추출 기준 | 비교자 클로저를 매번 짜는 것을 없앰 |
| `TakeWhile` / `DropWhile` | 앞에서 조건이 깨질 때까지 | 정렬된 데이터 자르기 |

### 파도 2 — 정렬 가족 (사용자가 짚은 것)

실측(15절)이 받쳐줍니다.

| 이름(안) | 무엇 | 실측 |
|---|---|---|
| `StableSort` / `StableSortInplace` | 병합 + 삽입정렬 하이브리드 | 무작위 1.43x, **정렬된 입력 0.10x** |
| `SortBy(key)` / `SortByInplace` | 키를 원소당 **한 번만** 계산(decorate-sort-undecorate). 안정으로 두면 자연스러움 | (구현 때 잼) |
| `NthElement(k)` / 또는 `Select(k)` | k 번째를 제자리에, 왼쪽 ≤, 오른쪽 ≥ | **0.15x** (중앙값) |
| `TopK(k, less)` / `PartialSort` | 앞 k 개만 정렬해서 | **0.05~0.14x** |
| `MergeSorted(a, b)` | 두 정렬 배열의 정렬 병합(진짜 `std::merge`) | — |
| `IsSorted` | `BSearch.IsSorted` 를 `Arr` 에서도 | 이미 있음, 노출만 |

**비교 없는 정렬(계수/기수)**: 키 범위가 좁고 알려진 경우만 이득이라 범용
이름으로 두면 "Sort 보다 빠르다" 는 착각을 부릅니다. 넣는다면
`CountingSortBy(key, maxKey)` 처럼 **좁은 이름**으로 두고 실측 뒤에. 지금은 보류 추천.

### 파도 3 — 맵·셋 (누적과 비대칭 메우기)

| 이름(안) | 무엇 | 비고 |
|---|---|---|
| `HashMap.GetOrInsert(k, v)` / `GetOrInsertWith(k, fn)` | 없으면 넣고 값을 돌려줌 | 그룹핑의 핵심. 상수판/클로저판 분리는 `PushBack`/`Many` 와 같은 이유 |
| `HashMap.Upsert(k, v, combine)` 또는 `Merge` | 없으면 `v`, 있으면 `combine(old, v)` | 빈도 맵. ⚠️ 이름(W3) |
| `HashMap.Extend(other)` | 다른 맵을 덮어 합침(딕셔너리 merge) | 생태계 4/4 |
| `Retain(fn)` — HashMap/HashSet/TreeMap/TreeSet | 조건 만족만 남김 | `Arr.Retain` 과 비대칭 해소 |
| `TreeMap.LowerKey`/`HigherKey`, TreeSet 짝 | **경계 제외** 이웃 | `Floor`/`Ceiling` 만 있음 — 같은 값 재비교 버그 소지 |
| `TreeMap.PopFirst`/`PopLast`, TreeSet 짝 | 꺼내며 제거 | `Heap.Pop` 과 비대칭 |
| `Arr.GroupBy(key)` / `CountBy(key)` / `KeyBy(key)` | 배열 → `HashMap` | Java `groupingBy`. 생태계 신호는 약함(Dash 1/4) — 중 |

### 파도 4 — 새 컨테이너

| 무엇 | 추천 | 근거 |
|---|---|---|
| **`Deque`** (링 버퍼, 양끝 O(1)) | **상** | 세 출처 공통. `rbvm` 이 BFS 큐를 손으로 짬. `Arr.PushFront`/`PopFront` 는 O(n) |
| `Counter` (멀티셋) | 중 | `HashMap<T, number>` + `Upsert` 위에 얇게. `MostCommon(k)` 은 파도 2 의 `TopK` 재사용 |
| `OrderedMap` (삽입 순서 맵, LinkedHashMap) | 중 | 지금 없음(확인함). LRU 까지는 하 |
| `BitSet` (`buffer` 기반) | 하~중 | Luau 고유 기회. 메모리 8~64배 조밀. 실측 주제 |
| packed 숫자 배열(`buffer` 기반) | 하 | 성능 문화와 맞지만 수요 불명. 연구로 |
| 연결 리스트 | ✗ | 테이블 배열 + `table.move` 가 이미 우위. 세 출처 모두 비추천 |
| Stack/Queue 어댑터 타입 | ✗ | `Arr` + `Pop*` + `Deque` 면 충분 |

### 파도 5 — `Fut` (부르는 곳 기준으로)

evaera Promise 대비. 수요 순: `Race`, `Timeout`(**타이머가 필요** — provider 에
`delay` 능력을 더해야 함), `Retry`, `AllSettled`, `Finally`, `Any`, `Delay`.
`Cancel` 은 사용자 결정대로 보류(확장 표면). `FromEvent` 는 Roblox 전용이라
얹는 층에서.

---

## 이름 정리가 필요한 것 (새 표면을 얹기 전에)

| 지금 | 문제 | 안 |
|---|---|---|
| `Arr.Merge` / `MergeInplace` | `std::merge`(정렬 병합)를 연상, 실제는 이어붙이기 | **`Concat` / `ConcatInplace`** (JS·생태계 어휘). `Merge` 라는 이름은 비워 둠 |
| `Arr.Replace` / `ReplaceInplace` | C++ `replace` 는 값→값 | 구간 치환은 **`Splice`** 가 생태계 어휘. 백로그의 "splice" 와도 합쳐짐 |
| `Arr.Get` 이 음수를 안 받음 | 구간 규약은 음수를 받아 비일관 | `Get` 은 계약 멤버라 원시 조회로 두고 **`At(idx)`** 를 따로(JS `Array.at`, Sift `at`) |
| `Arr.Count(fn)` | 값 기반이 없음 | `Contains`/`IndexOf` 와 함께 `CountOf(v)`? — 하 |

---

## 하지 않을 것 (근거와 함께)

- `NextPermutation`, `Sample`, `Gcd`/`Lcm`, `CartesianProduct` — 수요 신호 없음.
  `Sample` 은 `Shuffle` + `Slice` 로.
- 배열 위 힙 연산(`MakeHeap` 등) — `Heap.FromList` 가 이미 그 자리.
- 지연 뷰(ranges 식) — 이 저장소는 즉시 실행·절차적 호출이 정식 모양이고
  클로저 반복자가 2.9배 느림(9절).
- `debounce`/`throttle`/`memoize` — 컨테이너가 아니라 함수 유틸. 필요하면 `Fut`
  타이머와 같이 다시.
- `vector` 타입 전용 컨테이너 — Roblox 쪽 최적화라 범용 표면 밖.

## 출처

- 로컬: `refs-ignoreme/ms-stl`, `refs-ignoreme/rust`, `refs-ignoreme/openjdk`,
  `quad-scratch/refs/luau/VM/src/ltablib.cpp`·`lbuflib.cpp`,
  `quad-scratch/refs/rbvm/src/proxy/vtree.luau`(손으로 짠 스택·큐 주석),
  `quad-scratch/refs/charm/packages/charm/src/system.luau`(손으로 짠 이중 연결 리스트)
- 웹: [Sift](https://github.com/cxmeel/sift), [Llama](https://github.com/freddylist/llama),
  [TableUtil](https://sleitnick.github.io/RbxUtil/api/TableUtil/),
  [Roblox/dash](https://github.com/Roblox/dash),
  [evaera Promise](https://eryn.io/roblox-lua-promise/api/Promise/)

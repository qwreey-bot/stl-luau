# 종류 = 닫힌 트레이트(`Trait.Struct`) + 원형 덱의 칸 숨기기 — 시제품 (2026-10-15, 질문 BB)

브랜치 `proto/trait-struct`(main `8a21b9b` 위). 사용자: *"Arr 조차 Trait 이여야 하는거 아닌가 … struct Arr impl Arr {}"*, *"닫힌 경로는 다른 곳에서 impl
될 일 없어 … 한번 구현되고 끝"*, *"read [number]: T 를 공개 해야할 까 … 그냥 팬텀으로 두면 안 돼?"*.

## 들어간 것
- `Trait.Struct(이름)` → `{ Token, Seal }`: 맨 위에서(토큰도 같이), 맨 끝에서 `Kind.Seal(모듈 표)` — 그 표가 곧 종류의 정체이자 닫힌 트레이트
  (`ImplFor`·`ImplWhere` 없음, 다시 짓기에 안 낌). 종류 자리에 모듈을 넘김: `Stack.ImplFor(stl.Arr, …)`, `Trait.Converter(stl.Stack, stl.Arr)`,
  아래로 `Trait.Converter(stl.Arr)`, `Trait.Implements(stl.Arr, v)`, `Trait.TokenOf(stl.Arr)`. 두 번 봉인·트레이트를 봉인은 사용자 줄 에러.
- `Arr`·`CircularDeque` 에 적용(공개 `Token` 필드 뺌 — 시험은 `Trait.TokenOf(모듈)`). 나머지 종류는 아직 `NewToken`.
- `CircularDeque` 의 공개 타입: 칸(`[number]: T` — **물리** 칸이라 `d[1]` 이 첫 원소도 아니었음)·`head`·`cap` 을 숨기고 `size` 는 읽기만. 원소 타입은
  트레이트 레코드(`__traits`)에서 — 읽기 타입(`CircularDequeRead`)과의 차이가 레코드 하나. 함수는 받자마자 `const self = deque :: Raw<T>`(비용 0).
- `spikes/73`(변환자·숨긴 칸·읽기 전용 크기·레코드에서 오는 공변), `spec.traitrebuild` 9절 (d′)(사용자 종류를 `Trait.Struct` 로).

게이트 exit 0(스파이크 55), 편집기(luau-lsp 1.70.1 + Studio FFlag) 같은 줄 54 + 알려진 57.

## 재 본 것
- **읽기 타입을 `Struct` 에서 뽑기**: 별칭에 타입 함수(`ReadOnly<ArrData<T>>`)는 제네릭 함수 안에서 안 줄어듦(상류 한계 그대로). 정의를 제네릭 함수로 받아
  함수 타입 전체에 걸면(`View` 와 같은 길) 섬 — **그러나 인덱서를 읽기 전용으로 못 만듦**: `type.setreadindexer: luau does not yet support separate
  read/write types for indexers`. 그래서 인덱서가 있는 읽기 타입은 손으로. (원형 덱처럼 인덱서를 숨기면 읽기 타입은 레코드만 다름.)
- **직접 인덱싱 대 함수**(`-O2`, 원소 1000 × 5000 × 5 최소, 두 번):

| 읽기 | ns/원소 |
|---|---|
| `Arr` 직접 `a[i]` | 5.5~5.7 |
| `Arr.Get(a, i)`(검사 없는 계약 함수) | 15.1~15.3 |
| `Arr.Fold(a, 0, +)` | 13.6~14.3 |
| `for _, v in Arr.Iter(a)` | 24.5~24.8 |
| `Arr.At(a, i)`(음수·범위 검사) | 29.3~29.4 |
| 원형 덱 물리 칸 직접(안쪽만 가능) | 7.8~8.1 |
| `CircularDeque.At(d, i)` | 37.8~38.8 |
| `for _, v in CircularDeque.Iter(d)` | 29.7~30.0 |

원형 덱은 원래 사용자가 칸을 바로 읽으면 틀렸으니 잃는 것이 없습니다. `Arr` 은 칸을 숨기면 사용자의 원소 읽기가 2.7배(`Get`)~5배(`At`) 느려집니다(캐스트하면 그대로).

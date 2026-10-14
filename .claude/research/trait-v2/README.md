# 트레이트 시스템 v2 — 시제품 (2026-10-14, 사용자와 정한 모양)

`src` 는 그대로. 나중에 `src/Trait/` 가 될 폴더 구조로 지었습니다.

| 파일 | 무엇 |
|---|---|
| `Trait/init.luau` | 공개 API — `Token`·`Fn`·`Default`·`Trait`·`Impl(…):For/Where`·`ImplOf`·`Restore` |
| `Trait/Registry.luau` | 기억하는 것 전부 — **강한 배열**(토큰·트레이트는 정의라 버리지 않음, 버리면 정의되지 않은 동작) |
| `Trait/Build.luau` | 짓기(`assemble`)·놓기(`commit` — 같은 표를 비우고 채움)·**사건 셋**(`onToken`·`onFor`·`onWhere` → `refresh`) |
| `Trait/Entry.luau` | 진입점을 시스템이 만듦(가변인자 + 함수 번호) |
| `Trait/Errors.luau` | 에러 메시지 모음(전부 `Common.raise` — 사용자 줄) |
| `Trait/Fill.luau` | 타입 함수 `FillGenerics` — 시그니처에서 "이 종류에 대한" 등록 모양을 끌어냄 |
| `Traits.luau` | 그 위의 `Deque`·`Stack`·`Queue`·`List`, `src` 컨테이너 등록(`Arr` 를 `For` 로 스택) |
| `check.luau` | 동작 확인(토큰 유일·되찾기, 함수 번호, 필수/기본 구현, 뭉텅이 구현, For 가 덮고 위로 번짐, 겹침 에러) |
| `types.luau` | 타입 확인 — 진입점·등록(음성 대조군 넷) |
| `bench.luau` | 진입점 값 |

실행(저장소 루트 기준 경로):
```
( ulimit -v 1048576; timeout 60 luau .claude/research/trait-v2/check.luau )       # -O2 도
( ulimit -v 2097152; timeout 60 luau-analyze .claude/research/trait-v2/types.luau )
( ulimit -v 1048576; timeout 300 luau -O2 .claude/research/trait-v2/bench.luau )
```
⚠️ 포맷은 저장소 루트에서 `stylua .claude/research/trait-v2` — 이 폴더에서 돌리면 stylua 가 위쪽의 `stylua.toml`(Luau 문법)을
안 찾아 `Fn<<…>>()` 를 못 읽습니다.

## 모양

```lua
-- 연관 타입의 이름(정의 자리 하나)과 시그니처의 표식
type Item = Fill.CreateGeneric<"Item">            -- 라이브러리 어휘는 Fill 이 줌(Item, Index)
const stackFns = {
	Push = Fn<<<Self>(stack: Self, item: UseGeneric<Item>) -> Self>>(),     -- 필수
	Fold = Default<<<Self, U>(list: Self, init: U, fn: (U, UseGeneric<Item>, UseGeneric<Index>, ...any) -> U) -> U>>(),
}
-- Fn 의 출력은 RewriteSig 를 거친 모양: <Self, Item>(Self & { read __generics: { read Item: (Item) -> Item } }, Item) -> Self
export type StackFor<S> = Fill.ImplFor<typeof(stackFns), S>
const Stack = Trait.Trait("Stack", stackFns, defaults?)

-- 종류(자료 타입)는 연관 타입을 **글자 그대로** 적음(타입 함수 금지)
type Arr<T> = { …, read __generics: { read Item: Fill.Inv<T>, read Index: Fill.Inv<number> } }

const arrStack: StackFor<Arr<string>> = { Push = Arr.PushBack, … }      -- 주석이 등록 검사
Trait.Impl(Stack):For(ARR)(arrStack)
Trait.Impl(Stack):Where({ Deque })(function(deps) return { Push = deps[Deque].PushBack, … } end)
```

### 타입 쪽이 이 모양이 된 이유(2026-10-14 사용자와의 실험 — `bench-ignoreme/probe/`)

| 시도 | 결과 |
|---|---|
| 트레이트마다 마커(스택 시그니처가 덱 마커를 요구) | 덱이 아닌 `Arr` 스택이 타입에서 거절 — 바깥 확장도 막음 |
| 두 마커의 합(`Self & (A<T> \| B<T>)`) | 원소 추론이 `unknown` |
| 이름을 매개변수로(`{ [Name]: T }`) | 인덱서가 됨 |
| 받는 쪽에서 타입 함수로 꺼냄(`index<Self, …>`) | 진입점은 되지만 등록 검사(`FillGenerics`)가 그 안을 못 봄 |
| 연관 타입을 공변 필드로 | 넣는 쪽 검사가 빠짐(원소가 넓혀져 받아짐) |
| 연관 타입을 별칭 교집합으로 붙임 | `Self` 반환이 합(`\|`)으로 깨짐 |
| 자료 타입(또는 그 `__generics` 필드)을 타입 함수로 | 그 종류의 제네릭 함수가 `T` 를 못 풂 / 등록 검사가 깨짐 |
| **시그니처는 표식 → `Fn` 출력을 타입 함수로 바꿔 끼움, 자료는 글자 그대로 `Inv<T>`** | **진입점·뭉텅이 기능·바깥 계약·등록 검사가 다 섬** |

## 실험에서 정해진 것

- 함수 번호 = 이름을 정렬한 순서(표의 키 순서는 실행마다 다를 수 있음).
- 필수/기본 구현은 시그니처에서 `Fn`/`Default` 로 표시합니다. 기본 구현을 불러 보고 아는 방식은 런타임만 알아 등록 표의 타입이
  모든 함수를 요구했습니다. 런타임은 기본 구현이 `Default` 로 적은 이름을 정확히 채우는지 확인합니다.
- `FillGenerics` 는 `Self & 마커` 교집합을 채운 타입 하나로 접고, `Default` 꼬리표 칸을 선택 필드로 바꿉니다.
- 등록 표는 **`For<…>` 주석을 단 지역 변수**여야 검사가 섭니다(인자·반환으로 바로 넘기면 솔버가 구현의 제네릭을 안 풂).
- 콜백을 받는 시그니처는 `...any` 꼬리(구현이 인자를 더 넘김 — `Arr.Fold` 는 읽기 뷰). 타입을 적은 콜백 변수도 들어감.

## 열린 것

- ~~타입 마커가 뭉텅이 구현을 모름~~ → 연관 타입(`__generics`) + 표식(`UseGeneric`)으로 풀림: `Arr` 스택이 타입에서도 통과(`types.luau`).
- 읽기 전용으로 빌린 타입(`ArrRead`·`CircularDequeRead`)에는 `__generics` 를 안 넣었습니다(원소에 공변이어야 한다는 결정 —
  질문 AC·AK. 불변 팬텀을 넣으면 깨짐). 새 진입점이 빌린 참조를 어떻게 받을지는 정할 거리.
- 쓰는 진입점과 읽는 진입점의 구분(예전 `MarkerMut` — 빌린 참조는 꺼내기 못 함)도 이 모양에는 아직 없습니다.
- 다시 짓다 겹침이 생기면 그 연쇄 도중의 에러(앞선 표는 이미 바뀜) — `onWhere` 는 먼저 다 보고 바꾸지만 `onFor` 가 위로 번지는
  길은 아님.
- `__index` 로 물려받은 구현(지금 `src` 가 보는 것)은 아직 안 넣음.

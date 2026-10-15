# `Of`/`OfMut` + 트레이트를 타입에 드러내기 — 시제품 (2026-10-15)

> 브랜치 **`proto/trait-ofmut`**(worktree `/code/Projects/stl-luau-proto/trait-ofmut`)에 통째로 있습니다 — 이 폴더는 그 기록.
> ⭐ **2026-10-15 main 에 들임**(사용자: *"가 나 들여보고. 생각하자"* — 질문 BA 의 (가)·(나)). 이름(다)은 임시 그대로.

## 어떻게 여기까지 왔나

1. 사용자: *"MarkerMut Marker 나누는거 너무 애매모호 … Mut/NonMut 을 한 곳에 모아둔게 문제이지 않을까?"* — 실측으로 확인: 읽기·쓰기를
   **두 곳에서 따로** 정하고 있었고(트레이트 통째의 `of` 변성 대 진입점마다의 `Marker`/`MarkerMut`), 둘이 어긋났습니다.
   - **구멍**: `stl.Collection.Of(arrRead).Clear(arrRead)` 진단 0건 — 빌린 읽기 참조가 완성 표를 거쳐 지움(진입점 `Collection.Clear` 는 막혀 있었음,
     질문 AO 의 구멍이 다른 길로 열려 있음). **지금 main 에도 있습니다.**
   - **과잉**: `stl.Deque.Of(circularDequeRead)` 에러 — 읽기 함수(`Front`)만 쓰려 해도 덱 표를 못 얻음.
2. Rust 는 받는 쪽(`&self`/`&mut self`)으로 함수마다 가르는데 Luau 엔 참조의 종류가 없음 → 사용자: *"FnMut … OfMut 이랑 Of 가 있는 느낌"* —
   칸마다 읽기·쓰기를 적기(Rust 의 받는 쪽을 칸에).
3. 사용자: *"결국 `Trait.ItemIndexRead<E, I>` 가 오긴 했네 … 이럴거면 Trait 를 아예 드러내는게 나아보이겠다"* — 공용 연관 타입(`__generics: { Item,
   Index }`)은 전역 어휘라 트레이트끼리 이름에 합의해야 하고 뜻이 부딪힐 수 있음 → **트레이트마다 자기 연관 타입 레코드**, 컨테이너는
   `read __traits: { read Deque: Deque.Assoc<T>, … }` 로 "어느 트레이트를 무슨 인자로 구현하는가" 를 적음(Rust 의 `impl Deque<T> for X`).
4. 사용자(뿌리): *"Impl 자체가 타입을 변경 못 시키기 때문에 생긴다는 큰 제약을 돌고 돌고 돌았을 뿐 … 합의해야만 하는 부분이 생겼어"* —
   런타임은 "등록하면 따라온다" 로 열려 있고 타입은 "적힌 것만 안다" 로 닫혀 있음. 이 시제품은 그 합의를 **트레이트 이름 하나**(타입에
   `__traits.이름` 을 적는 것)로 줄인 것.

## 시제품의 모양

```lua
-- 정의: 칸마다 읽기/쓰기, 매개변수 둘(읽기 조건 · 바꿀 수 있는 조건 — 하나면 둘 다)
const DequeBase = Trait.Trait("Deque", function<Self, T>(of: (Self & Marker<T>) | AnyToken, ofMut: (Self & MarkerMut<T>) | AnyToken)
	return table.freeze({
		PushBack = FnMut<<(deque: Self, item: T) -> Self>>(),
		Front = Fn<<(deque: Self) -> T?>>(),
	})
end)
-- 트레이트가 자기 연관 타입을 가짐
export type AssocRead<T> = { read Item: () -> T }
export type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
export type Marker<T> = { read __type: Trait.Token<any>, read __traits: { read Deque: AssocRead<T> } }
export type MarkerMut<T> = { read __type: Trait.Token<any>, read __traits: { read Deque: Assoc<T> } }
-- 컨테이너는 한 줄(빌린 읽기 타입은 AssocRead 들)
read __traits: { read List: List.Assoc<T, number>, read Deque: Deque.Assoc<T>, read Collection: Collection.Assoc },
```

- `X.Of(v)` = **읽기 보기**(쓰기 칸 없음 — 빌린 참조도), `X.OfMut(v)` = **완성 표**(바꿀 수 있는 참조만). 런타임은 같은 표(비용 0).
- 칸: `Fn`·`FnMut`·`Default`·`DefaultMut`. 타입 레코드에 `mut` 이 붙고 `View` 가 `"read"` 보기를 하나 더 지음.
- ⭐ **진입점 서명을 정의에서 짓습니다**(타입 함수 `Trait.Entries` — 트레이트 객체 타입에 자동으로): 쓰기 칸은 `ofMut` 조건을, 읽기 칸은 `of`
  조건을 첫 인자로. **`Marker`/`MarkerMut` 을 손으로 고를 일이 없어짐**(덱·스택·큐·List·Collection 의 손 서명을 지움). `Self` 가 첫 인자에만
  나오면 빼서 손 서명과 제네릭 순서가 같음(일부만 명시한 타입 인자 `f<<A>>` 는 솔버 내부 에러라 순서가 곧 공개 표면).
- 부르는 쪽 서명이 구현하는 쪽 칸 타입과 다를 때(`List.Some` 의 술어 — 구현은 `(E, I, ...any)` 를 받아야, 부르는 쪽은 꼬리 없는 술어 변수를
  넘길 수 있어야): `Default(build, Trait.Sig<<부르는 쪽 서명>>())`.

## 실측

| 무엇 | 결과 |
|---|---|
| 게이트(`check.sh`, luau 0.742) | **exit 0** — 스파이크 53 전부 일치, 테스트 전부(-O2 포함) |
| 편집기(`editor-check.sh`, luau-lsp 1.70.1 + Studio FFlag 105) | src 0건, 같은 줄 52 + 알려진 차이 57 — main 과 같음 |
| 구멍 `Collection.Of(r).Clear(r)` | **잡힘**(`Key 'Clear' not found in table '{ read Len: … }'`) — `spikes/71` |
| 과잉 `Deque.Of(dr).Front(dr)` | **됨**, `Deque.Of(dr).PushBack` 은 칸 없음, `Deque.OfMut(dr)` 은 에러 |
| 맵 키 | 조건은 불변(`Map.Of(tm).Get(tm, 1)` 잡힘), `Map.Keys` 의 넓혀 읽기는 그대로(`spikes/61` 의 경계 줄 같음) |
| 컨테이너 타입의 팬텀 줄 | **63 → 14**(`__generics`·`__readGenerics`·`__list`·`__listIndex`·`__listMut`·`__dequeItem`·`__dequeMut`·`__collectionMut`·`__mapKey`·`__mapValue`·`__mapMut`·`__setItem`·`__setMut` → `__traits` 하나) |
| `src/Trait/init.luau` | **468 → 700 줄** — 거의 다 타입 함수 `Entries`(+ 제네릭 바꿔 끼우기 `subst`) |
| 트레이트 파일 | 손 서명이 빠져 조금 줄음(List 208 → 182) |
| 런타임 | 바뀐 것 없음(`OfMut` 은 `Of` 와 같은 함수, 진입점은 그대로 시스템이 만듦) |

에러 문구(같은 실수를 main 과 시제품에서):

| 실수 | main | 시제품 |
|---|---|---|
| `Deque.PushBack(빌린덱, 3)` | `CircularDequeRead<number>` is not a subtype of `MarkerMut<number>` | Expected property `__traits.Deque` to be `{ read Item: () -> number, read Mut: (number) -> number }`, but got `AssocRead<number>` |
| `List.IndexOf(hashMap, 1)` | Expected `Marker<number \| string, number>` but got `HashMap<string, number>` | … Expected property `__traits` to be `{ read List: … }`, but got `{ read Collection: Assoc, read Map: Assoc<string, number> }` |
| `Deque.Front(Arr.Of(1))` | Expected `Marker<number>` but got `Arr<number>` | Expected `{ read Deque: { read Item: () -> T } }` but got `{ read Collection: Assoc, read List: Assoc<number, number> }` |

시제품 쪽이 길지만(별칭이 풀림 — 타입 함수가 지은 서명), **그 타입이 무슨 트레이트를 구현하는지**가 메시지에 나옵니다.

## 대가와 경계

- ⚠️ **사용자 타입 함수가 하나 더**(`Entries`, ~230줄): 사용자가 주의하는 것. 그리고 **원인을 다 모르는 우회**가 들어 있습니다 — 진입점마다
  제네릭을 `types.generic` 으로 새로 만들어 바꿔 끼우지 않으면 `List.IndexOf(a, 20)` 이 `Expected this to be 'E', but got 'number'`(끄고 켜서
  확인). 손으로 줄인 모양(`shared-generics-minimal.luau`)으로는 나지 않아 상류에 올릴 최소 재현이 아직 없음.
  - 가벼운 대안: `Entries` 없이 진입점 서명은 손으로 두되 규칙을 기계적으로("`FnMut` 칸이면 `MarkerMut`") — 구멍·과잉은 `Of`/`OfMut` 만으로
    닫히고, 손 서명이 칸과 어긋나는 것은 `spec.contracts` 식 대조가 지켜야 함.
- **정의자 실수 메시지가 같은 줄에 세 번**(보기 셋 — 지금은 둘). `Entries` 는 실수에 조용(빈 표).
- **바깥 컨테이너도 `__traits` 에 한 줄씩**(트레이트마다 `stl.ListAssoc<…>` 등) — 지금 팬텀 여럿을 적던 것의 대신. 테스트의 바깥 타입 여섯
  (`Chain`·`Bag`·`MyMap`·`Sized`·`spec.arr` 의 `Bag`, 스파이크의 흉내 타입들)을 옮겼고 모두 한 줄로 줄었음.
- **바깥에서 뭉텅이(`ImplWhere`)로 만족시킨 트레이트는 타입에 안 붙습니다** — 사용자: *"바깥에서 써큘러 데큐에 뭔가 where 로 만족된걸 못 넣는다
  … 어쩌겠음"*. 쓰는 쪽이 별칭으로 덧붙일 수는 있음(`CircularDeque<T> & { read __traits: { read MyTrait: … } }` — "내 말을 믿어라").
  라이브러리의 `Stack`·`Queue` 는 조건을 `Deque` 레코드로 적어 덱이면 타입으로도 됨(지금과 같음).
- 기본 구현 빌더의 `ops` 는 여전히 `any` — 읽기 기본 구현이 쓰기 형제를 불러도 타입이 못 막음.
- 진입점의 제네릭 순서가 손 서명과 같아야 함(명시적 타입 인자) — `Self` 빼기로 맞췄고 `spikes/60`·`61` 의 `IndexOf<<number?, number>>` 가 지킴.

## 정해 주실 것 → 질문 BA

## 파일

- 시제품 전체: 브랜치 `proto/trait-ofmut`(main 의 `b1ec1e6` 위 커밋 하나).
- `entries-probe.luau` — `Entries` 의 첫 프로브(빌린 참조에 쓰기·원소·다른 종류·칸의 제네릭 `U`·제네릭 몸통 안 호출).
- `shared-generics-minimal.luau` — 상류 후보의 최소화 시도(재현 안 됨).
- `spike-diff.py` — 스파이크의 기대 줄과 실측 줄을 줄마다 견주는 도구(시제품에서 씀).
- 음성 대조군 `spikes/71-trait-ofmut.luau`(읽기·쓰기 보기, 사용자 트레이트), `spikes/72-trait-adapter.luau`(바깥에서 트레이트를 덧붙이는 중간자 —
  사용자: *"<T>(Arr<T>) -> Stack<T> 를 주는 뭔가"*).

## 들인 뒤 같은 날 더 정한 것 (2026-10-15)

| 사용자 | 반영 |
|---|---|
| *"a to b 계약자가 두 점이 확실한지 보게 하는게 나을듯? 런타임 비용이 얼마인지"* | `Trait.Converter(트레이트, 토큰?)` — 등록은 만들 때 한 번, 값의 종류는 부를 때마다(사용자 줄 에러), 같은 테이블을 돌려줌. 호출당 13~20ns(perf 55절), 값 하나에 한 번 |
| *"깔끔하게 다운케스트 … Stack<T> 와 Arr<T> 를 두고 진짜 변환. __traits 가 보이는건 좀 아닌것 같은"*, *"값은 Trait, 타입은 런타임 데이터에 붙이는 표식"* | 트레이트마다 값 타입 `stl.Stack<T>`·`stl.StackRead<T>`(트레이트 파일의 `Value`/`ValueRead` — 예전 `MarkerMut`/`Marker`). 바꾼 값은 그 트레이트로만 보임(`spikes/72`) |
| *"Deque 또한 Stack 으로 가는데 있어서 asStack 모양이 필요 … Stack 은 Deque 가 뭔지 알 필요가 있을까?"* | 스택·큐는 자기 레코드만, 뭉텅이 구현과 변환자 `Deque.AsStack`·`AsQueue`(+ 읽기 판)는 `Traits/Deque` 에. 토큰을 뺀 `Trait.Converter(Stack)` 은 "스택을 구현한 종류면 무엇이든" |

재 본 것: 스택의 조건을 "덱 레코드 **또는** 스택 레코드"(유니온)로 둔 판 — 손으로 쓴 서명에선 추론이 섰지만 `View` 가 다시 지은 보기(`Stack.OfMut(d)`)
에선 원소 타입이 `unknown` 이라 접음(위의 사용자 방향과도 맞음). **상류 결함 후보 하나 더**: 교집합 `A & B` 를 `C & X` 자리에 넘기면 `C` 가 `A | B`
로 풀림(`intersection-generic-repro.luau`) — 그래서 바깥 컨테이너 타입은 트레이트를 `__traits` 필드로 나열합니다(교집합 별칭은 안 됨).

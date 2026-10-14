# 시제품 v5 — 두 보기(`index<>`), 빌린 읽기 참조, 트레이트 객체에서 등록 (2026-10-14)

v4(`../trait-v4/`, 그대로 둠) 옆에 지은 판입니다. 출발은 다시각 2회차 Opus 의 보고(사본에서 짓고 지워서, 메인이 보고의 코드로
다시 지음)이고, 등록 이름은 사용자 제안(`Stack.ImplFor`·`Stack.ImplWhere`)입니다. **이 시제품의 유일한 타입 함수는 내장
`index<>` 입니다** — "타입 함수가 무슨 일을 내나" 를 보려고 지은 판(사용자: *"써도 되긴 한데. 무슨 일을 내나 보고싶음"*).

| 파일 | 무엇 |
|---|---|
| `Trait/` | 시스템. 런타임은 v4 그대로 + `ImplOf`·`ImplFor`·`ImplWhere` 를 트레이트 객체에, `Inherit` 를 걷음, 에러 문구 하나 |
| `Traits.luau` | 트레이트 넷(Deque·Stack·Queue·List)과 등록 — **v4 의 같은 파일과 나란히 보세요** |
| `types.luau` | 타입 시험: `-- NEG` 줄과 canary 만 에러(메인 실측 — 아래), `-- 경계` 줄은 0건 |
| `check.luau` | 런타임 시험(`-O1`·`-O2` PASS) |
| `two-views*.luau` | 맨 처음 메인이 Opus 보고를 확인한 자기완결 프로브 |

## 모양 — v4 와 나란히

**정의하는 자리**

```lua
-- v4
const Stack = Trait.Trait("Stack", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return {
		Push = Fn<<(stack: Self, item: T) -> Self>>(),
		Pop = Fn<<(stack: Self) -> T?>>(),
		Peek = Fn<<(stack: Self) -> T?>>(),
		IsEmpty = Default(function(ops: Stack<Self, T>) … end),
	}
end)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))

-- v5: 한 겹(모드 M) 더, 같은 정의를 두 번 넘김
local function stackDef<M>(mode: M)
	return function<Self, T>(of: (Self & ItemRead<T>) | AnyToken)      -- 읽기 연관 타입으로 받음(빌린 참조도)
		return {
			Push = Fn<<(stack: Mut<Self, T, M>, item: T) -> Self>>(),    -- 쓰는 함수: self 가 Mut
			Pop = Fn<<(stack: Mut<Self, T, M>) -> T?>>(),
			Peek = Fn<<(stack: Self) -> T?>>(),                          -- 읽는 함수: 그대로
			IsEmpty = Default(mode, function(ops: Stack<Self, T>) … end), -- 기본 구현: mode 를 넘김
		}
	end
end
const Stack = Trait.Trait("Stack", stackDef, stackDef)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))         -- 완성 표
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any)) -- 등록 표(기본 구현 칸은 선택)
```

`index<>` 가 나오는 곳은 시스템의 두 줄뿐입니다(정의하는 사람은 `Mut`·`Default(mode, …)` 로만 만남):

```lua
export type Mut<Self, T, M> = index<{ full: Self & Item<T>, impl: Self }, M>
const function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M>
```

**구현하는 자리**

```lua
-- v4: 기본 구현 칸마다 Inherit, 등록은 Trait 모듈의 함수
const cdList: List<CircularDeque<A>, A, number> = {
	Get = …, FirstIndex = …, LastIndex = …, NextIndex = …, PrevIndex = …,
	IndexOf = Trait.Inherit, Contains = Trait.Inherit, Fold = Trait.Inherit,
}
Trait.Impl(List, CD, cdList)
Trait.Blanket(Stack, { Deque }, function(deps) return stackFromDeque(deps[Deque]) end)

-- v5: 기본 구현 칸은 안 적으면 기본 구현(적으면 재정의 — 검사됨), 등록은 트레이트 객체에서
const cdList: ListImpl<CircularDeque<A>, A, number> = {
	Get = …, FirstIndex = …, LastIndex = …, NextIndex = …, PrevIndex = …,
}
List.ImplFor(CD, cdList)
Stack.ImplWhere({ Deque }, function(deps) return stackFromDeque(deps[Deque]) end)
```

**쓰는 자리** — 바뀐 것은 빌린 참조뿐

```lua
local borrowed: CircularDequeRead<number> = d
Stack.Of(borrowed).Peek(borrowed)        -- 됨(v4 는 Of 자체가 안 됐음)
Stack.Of(borrowed).Push(borrowed, 1)     -- 에러: `CircularDequeRead<number>` is not a subtype of `Item<number>`
```

## `index<>` 가 무슨 일을 냈나 (메인 실측, luau 0.742)

| 본 것 | 결과 |
|---|---|
| 겉으로 보이는 타입 | 깨끗이 풀림 — `Stack.Of(d)` 는 `{ Peek: (CircularDeque<number>) -> number?, Pop: (CircularDeque<number> & Item<number>) -> number?, … }`, `ListImpl<…>` 은 그 이름 그대로. **`types.luau` 의 에러 67줄에 `index<` 가 0번** |
| 에러 문구 | v4 와 같은 결(원소를 못박은 등록의 긴 사유 목록은 v4 도 같은 길이 — 옛 마커 팬텀 탓, 23 대 24줄). 빌린 참조로 쓰기는 한 줄 사유 |
| 제네릭 칸 | `index<>` 를 거친 `Fold` 의 `<U>` 를 못박은 재정의, `Fold = Len` 둘 다 잡힘(예전 "타입 함수를 거친 등록 모양은 `<U>` 검사를 잃음" 은 여기선 안 일어남) |
| 종류를 모르는 제네릭 알고리즘 | `pushTwice<C, T>(c: C & Item<T> & ItemRead<T>, x: T)` 정확(`two-views-generic.luau`) |
| 검사 시간 | `types.luau` 최소 0.097s(v4) → 0.105s(v5), 다섯 번 중 최소 |
| 정의자 실수 | 모드 오타(`def<<"ful">>`)·두 모드를 뒤바꿈은 `Trait.Trait` 줄에서 잡힘 — 단 오타는 **쓰는 자리에도** `Property '"ful"' does not exist` 가 번져 시끄러움. 모드를 안 밝히면(`def, def`) **오히려 맞게** 풀려서 그 모양을 표준으로 씀 |
| 터진 것 | 아직 없음. 단 이 판은 작음(트레이트 넷 + 시험) — `src` 규모(트레이트 일곱, 컨테이너 열)로 옮겼을 때는 안 재 봄 |

## 대가

- 정의하는 쪽: 한 겹(`def<M>(mode: M)`), `Default(mode, …)`, 쓰는 함수에 `Mut<Self, T, M>`, `XImpl` 별칭 하나.
- 컨테이너: 팬텀 둘(`__generics` 불변 + `__readGenerics` 공변 — 커밋 b2e0906 에서 `src` 의 셋에 넣음). 바깥 컨테이너도
  `__readGenerics` 를 적어야 `Of(값)` 이 됨.
- `Stack<C, T>` 를 받는 제네릭 알고리즘에서 `st.Pop(c)` 가 `c: C` 로 통과하는 것은 제네릭 몸통 결함(AA 3번)의 관대함 덕 —
  고쳐지면 `c: C & Item<T>` 를 적어야 함(Opus 추론).

## 그대로인 것 (v4 와 같음)

- **편한 진입점(`Stack.Push(d, x)`)은 `any`** — 서명을 한 곳에만 적고는 타입을 못 얻음(Opus). 지금 `src` 는 손으로 쓴 진입점이라
  `stl.Stack.Push(d, "x")` 를 잡음 — v4/v5 는 후퇴.
- 등록 표는 주석 단 지역이어야 함(`bidir-table-arg`). 등록 표의 오타 칸은 타입이 못 잡고 런타임이 등록 줄에서 잡음.
- 타입·런타임 둘 다 못 잡는 배선 실수: `Stack` 표를 `Queue` 에, `Pop = Len` — 사용자: 구현 단 실수는 타입에서 못 잡아도 됨
  (테스트의 배선 전수 표 몫).
- 뭉텅이 몸통의 원소를 못박은 함수는 0건(AA 3번).

## 바뀐 런타임

- `Trait.Impl`·`Trait.Blanket`·`Trait.Inherit` 를 걷고 트레이트 객체에 `ImplFor`·`ImplWhere`·`ImplOf`(= `Of`, 타입 전용). 이 셋과 `Of`·
  `FnTok` 은 트레이트의 함수 이름으로 못 씀(정의 줄에서 에러).
- 진입점이 값을 못 찾았을 때: 진짜 토큰이면 "does not implement", 이름만 같은 사본이면 "is a copy (serialized?): Trait.Restore it" —
  v4 는 늘 둘을 같이 적어 오해를 부름(Opus 지적).

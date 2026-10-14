# 트레이트 시스템 v4 — 다시각 탐색 1회차가 모인 뼈대 (2026-10-14 시제품)

v2(연관 타입 + 타입 함수)·v3(제네릭 트레이트, 받는 쪽이 T 를 밝힘)·1회차 여섯 시선(`../trait-typing-probes/`,
`.claude/audit/agy/2026-10-14-trait-typing-*.md`)이 모인 곳. **타입 함수 0개.** 런타임은 v3(=v2)에 기본 구현 빌더만 더함.

## 세 자리

```lua
-- 정의: 트레이트 = 팩토리 하나. 팩토리가 이름 목록(런타임)·트레이트의 제네릭 타입·`Of` 의 타입을 한꺼번에 줌
const List = Trait.Trait("List", function<Self, E, I>(of: (Self & Trait.ItemIndex<E, I>) | Trait.AnyToken)
	return {
		Get = Trait.Fn<<(list: Self, idx: I) -> E?>>(),
		…
		Contains = Trait.Default(function(ops: List<Self, E, I>)   -- 기본 구현은 빌더(그 종류의 완성 표를 받음)
			const indexOf = ops.IndexOf                            -- 형제를 붙잡아도 됨(재정의됐으면 그것, 순서 무관)
			return function(list: Self, item: E): boolean return indexOf(list, item) ~= nil end
		end),
	}
end)
export type List<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))

-- 구현: 탐침 타입(Trait.A)으로 주석을 단 지역 변수 → 평평한 등록. 기본 구현 칸은 Trait.Inherit
const cdList: List<CircularDeque<A>, A, number> = { Get = CD.Get, …, IndexOf = Trait.Inherit, Contains = Trait.Inherit, Fold = Trait.Inherit }
Trait.Impl(List, CD_TOKEN, cdList)
local function stackFromDeque<C, T>(deque: Deque<C, T>): Stack<C, T> … end      -- 뭉텅이 몸통은 제네릭 함수로(검사됨)
Trait.Blanket(Stack, { Deque }, function(deps) return stackFromDeque(deps[Deque]) end)
const arrIntoStack: <T>(a: Arr<T>) -> Stack<Arr<T>, T> = Stack.Of :: any       -- 중개자 Into(비용 0)

-- 사용: 값으로 꺼내면 Self·원소·위치가 값에서(컨테이너의 `__generics`). 토큰으로는 밝힌 타입이 주장
local s = Stack.Of(d)                       -- d: CircularDeque<number> → s.Pop(d): number?
local t = Stack.Of<<Bag<number>, number>>(BAG_TOKEN)
local function drain<C, T>(st: Stack<C, T>, c: C): { T } … end
Stack.Push(d, x)                            -- 편한 진입점(any)
```

| 파일 | 무엇 |
|---|---|
| `Trait/init.luau` | `Token`·`Fn`·`Default`·`Inherit`·`Trait`(→ `{ read Of: F, … }`)·`Impl`·`Blanket`·`Restore`, 타입 `Item`·`ItemIndex`·`AnyToken`·`A`·`B` |
| `Trait/Build.luau` | v3 + 기본 구현 빌더(형제를 읽으면 그 자리에서 먼저 지음, 고리는 그 빌더 줄의 에러, 짓는 동안만 메타테이블) + `Inherit` |
| `Traits.luau` | `Deque`·`Stack`·`Queue`·`List`, 뭉텅이 둘, 등록 다섯(탐침), `Into` |
| `check.luau` | 동작 확인 일곱 절(토큰·되찾기, 함수 번호, 빌더·`Inherit`·고리, 뭉텅이, 덮고 번지기, 겹침, `Of`) |
| `types.luau` | 타입 확인 — NEG 14 + canary, 경계 셋 |

## 1회차에서 온 것 / 고친 것

- **팩토리가 곧 `Of` 의 타입**(Opus 종합): `Trait<F>(name, factory: F): { read Of: F, … }`. 트레이트마다 `Of` 의 타입을 손으로 적지 않음.
- **탐침 타입 등록 검사**(Opus 런타임만): `List<Arr<A>, A, number>` — 구체 타입(`string`)으로는 원소를 못박은 함수가 샘. 타입
  함수(`Provided`)를 거치지 않으니 `Fold = Arr.Len` 도 잡힘(적대적 검증이 찾은 v2·v3 의 구멍).
- **연관 타입은 컨테이너의 `__generics`**(모든 시선): 값에서 원소를 얻으려면 구조적 훅이 반드시 필요(Gemini 뿌리의 증명).
- ⚠️ 이번에 고친 것: `AnyToken` 을 `{ read name: any }` 로 두었더니 그 필드가 **없는** 값도 만족해, 팩토리 인자의 토큰 갈래가
  아무 값이나 받아 "값으로 밝힌 T 가 어긋남" 이 새었음 → `{ read name: string }`.

## 남은 것

- 등록 표는 주석 단 지역 변수여야 함(제네릭 함수를 구체 함수 타입에 맞추는 것이 그때만 됨 — `bidir-table-arg.luau`, 상류 보고 후보).
- 편한 진입점 `Stack.Push` 는 any. 타입이 필요하면 `Stack.Of(d).Push` 또는 미리 꺼낸 함수.
- 읽기 전용으로 빌린 참조(`ArrRead`)는 `__generics` 가 없어 값으로 못 꺼냄 — 토큰으로 밝혀야 함.
- `Inherit` 는 any — 필수 칸에 넣어도 정적으로 통과(등록 때 런타임 에러). 트레이트에 기본 구현을 더하면 전체 타입으로 적은
  등록 표들이 정적으로 깨짐(런타임은 그대로).
- 이름: `Of`(생성자 `Arr.Of` 와 겹침 — Gemini DX 가 `Ops` 를 제안), `Impl`/`Blanket`/`Fn`/`Default`/`Inherit`.
- 속도는 v3 런타임 그대로라 다시 재지 않음(종합판 측정: 진입점 135ns/쌍, `Of(d).Push` 를 매번 147, 미리 꺼낸 함수 58 = 직접).

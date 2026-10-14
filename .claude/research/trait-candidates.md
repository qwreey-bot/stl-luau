# 트레이트 타입 설계 — 최종 후보 비교 (2026-10-14)

같은 예제(기본 구현이 있는 `List`, 기본 구현이 없는 `Stack`, 덱이면 스택이 따라오는 뭉텅이 구현)를 후보마다 적었습니다.
모든 후보의 **런타임은 같습니다**(토큰·등록부·사건 셋·진입점 — 확정된 런타임). 다른 것은 타입을 얻는 모양뿐입니다.
코드는 각 폴더에 있고 `types.luau`(에러 줄 = `-- NEG` 줄 + canary)와 `check.luau`(`-O1`·`-O2`)가 통과합니다(메인 실측).

| 후보 | 폴더 | 한 줄 |
|---|---|---|
| **A** | `trait-v6/` | v4 의 정의 모양 그대로. 기본 구현 칸은 등록 표에 `Trait.Inherit` |
| **B** | `trait-v8/` | 메인의 최적안: 모드 한 겹(`function<M>(mode: M)`)을 `Trait()` 안에, 내장 `index<>` 로 두 보기 — `Inherit` 없음 |
| **C** | `../audit/agy/2026-10-14-tr3-noindex-probes/probe6_refined_split.luau`, `main-split-names-only.luau` | 타입 함수 없이: 필수 표·기본 구현 표를 따로 적고 교집합 — 프로브 수준(시제품 없음) |
| (참고) | `trait-v4/`, `trait-v5/`, `trait-v7/` | v4 = 출발점, v5 = 두 보기 + 함수마다 `Mut` + 정의를 두 번 넘김, v7 = v5 를 한 번 넘기기로 |

세 후보 공통(v6 에서 들어옴): 빌린 참조는 트레이트가 `of` 한 자리에서 고름(쓰는 트레이트 `Item` → 빌린 참조는 그 트레이트를 못 얻음,
읽기만 하는 `List` 는 `ItemIndexRead`), 등록은 `Stack.ImplFor`·`Stack.ImplWhere`, 뭉텅이 몸통은 탐침 타입(`Deque<A, B> → Stack<A, B>`).

## 1. 정의하는 자리

```lua
-- A (v6)
const List = Trait.Trait("List", function<Self, E, I>(of: (Self & ItemIndexRead<E, I>) | AnyToken)
	return {
		Get = Fn<<(list: Self, idx: I) -> E?>>(),
		…,
		IndexOf = Default(function(ops: List<Self, E, I>) … end),
	}
end)
export type List<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))

-- B (v8): 한 겹 더 — 같은 호출 안
const List = Trait.Trait("List", function<M>(mode: M) return function<Self, E, I>(of: (Self & ItemIndexRead<E, I>) | AnyToken)
	return {
		Get = Fn<<(list: Self, idx: I) -> E?>>(),
		…,
		IndexOf = Default(mode, function(ops: List<Self, E, I>) … end),
	}
	end
end)
export type List<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))
export type ListImpl<Self, E, I> = typeof(List.ImplOf<<Self, E, I>>(nil :: any))
-- 시스템 쪽: Default<F, M>(mode: M, build): index<{ full: F, impl: F? }, M>, Trait(name, def: ((mode: "full") -> F) & ((mode: "impl") -> G))

-- C: 표를 나눠 적음(타입 함수 0)
local function listReq<Self, E, I>() return { Get = Fn<<(list: Self, idx: I) -> E?>>(), … } end
local function listDefaults<Self, E, I>() return { IndexOf = function(list: Self, item: E): I? … end, … } end
export type List<Self, E, I> = typeof(listReq<<Self, E, I>>()) & typeof(listDefaults<<Self, E, I>>())
export type ListImpl<Self, E, I> = typeof(listReq<<Self, E, I>>()) & {
	IndexOf: typeof(listDefaults<<Self, E, I>>().IndexOf)?, … -- 기본 구현 이름을 한 번 더
}
-- (런타임 등록 방식은 시제품으로 짓지 않음 — Trait.Trait 가 두 표를 받는 모양이 될 것)
```

## 2. 구현하는 자리 (바깥 사람의 컨테이너가 `List` 를 구현)

```lua
-- A (v6): 기본 구현 칸마다 Inherit — 빠뜨리면 "missing field", 필수 칸에 Inherit 를 넣어도 타입은 0건(런타임이 등록 줄에서 잡음)
const myList: List<MyList<A>, A, number> = {
	Get = My.Get, FirstIndex = My.First, LastIndex = My.Last, NextIndex = My.Next, PrevIndex = My.Prev,
	IndexOf = Trait.Inherit, Contains = Trait.Inherit, Fold = Trait.Inherit,
}
List.ImplFor(MY, myList)

-- B·C: 기본 구현 칸은 안 적으면 기본 구현, 적으면 재정의(서명 검사됨)
const myList: ListImpl<MyList<A>, A, number> = {
	Get = My.Get, FirstIndex = My.First, LastIndex = My.Last, NextIndex = My.Next, PrevIndex = My.Prev,
}
List.ImplFor(MY, myList)
```

**트레이트가 자라면**(라이브러리 1.1 이 `List` 에 기본 구현 `Count` 를 더함): A 는 바깥 사람의 위 표가 `missing field 'Count'` 로
**타입 에러**(런타임은 정상 — 기본 구현이 채움). B·C 는 아무 일 없음. (라이브러리 안의 컨테이너는 같이 고치면 됨 — 문제는 바깥 구현.)

## 3. 쓰는 자리 — 셋 다 같음

```lua
List.Of(d).IndexOf(d, 2)           -- 정확한 타입(값에서 원소·위치)
List.IndexOf(d, 2)                 -- 편한 진입점: any (셋 다 — 서명을 한 곳에만 적고는 못 얻음, Opus·Gemini 둘 다)
List.Of(borrowed).IndexOf(b, 2)    -- 빌린 참조: 읽기 트레이트는 됨
Stack.Of(borrowed)                 -- 에러: 쓰는 트레이트는 빌린 참조에 없음
```

## 4. 알려진 위험·비용

| | A | B | C |
|---|---|---|---|
| 정의자가 적는 것 | 가장 적음(v4 그대로) | 함수 머리 한 줄 더 + `Default(mode, …)` + `XImpl` 별칭 | 표 둘 + 기본 구현 이름 두 번 + 교집합 별칭 둘 |
| 구현자가 적는 것 | 기본 구현 칸마다 `Inherit` | 필수만 | 필수만 |
| 트레이트가 자랄 때 바깥 구현 | 타입 에러 | 안전 | 안전 |
| 필수 칸에 `Inherit` | 타입 0건(런타임이 잡음) | 해당 없음 | 해당 없음 |
| 타입 함수 | 0 | 내장 `index<>` 둘(시스템 안에만) | 0 |
| 솔버 위험 | 낮음(v4 에서 오래 봄) | `index<>` + 표 리터럴 인자 결함이 상류에 열려 있음(#2608 — 우리는 표 리터럴을 인자로 안 넘김). 같은 파일 안 짧은 프로브에서 기본 구현 칸 반환 검사가 빠지는 모양을 봄(정의와 쓰기가 한 파일일 때 — 실제 구조인 모듈 분리에선 잡힘, 원인 미확정) | 교집합 + 제네릭은 상류에 열린 결함 다수(#2390·#2625·#2621) |
| 에러 문구 | 깔끔 | 대체로 깔끔(모드 오타는 쓰는 자리로 번짐) | 교집합 타입이 문구에 나옴 |
| 기본 구현 몸통 | 팩토리(제네릭) 안 — 몸통 결함 노출 | 같음 | 별도 제네릭 함수 — 같음 |

## 5. 토론 중에 새로 나온 사실 (2026-10-14 밤, 메인 실측·소스 분석)

1. **B 의 같은 모듈 구멍**: 모드를 추론에 맡기는 B(인라인 `Trait.Trait("X", function<M>(mode: M) …)`)는 트레이트를 **정의한 모듈 안에서** 쓰면 기본 구현
   칸 함수의 반환 검사가 사라짐(아무 타입에 넣어도 0건 — 덜 줄어든 `index<>` 가 `never`). 모듈을 나누면 잡힘. 재현
   `../audit/agy/2026-10-14-src-index-probes/main-v8-same-module-hole.luau`. 타입 변호인도 독립적으로 찾음.
2. **모드를 밝혀 적는 B'**(v5 모양: `local function stackDef<M>(mode: M) … end` + `Trait.Trait("Stack", stackDef<<"full">>, stackDef<<"impl">>)`)는 같은 모듈에서도
   전부 잡힘(`main-v8-explicit-mode.luau`). 정의가 `Trait()` 밖으로 나감.
3. ⭐ **"등록 표는 주석 단 지역이어야 한다" 는 결함의 부작용이었음**(`luau-source/README.md` 2절): 받는 타입의 필드가 `read` 면 표 리터럴을 인자로 넘겨도
   검사됨. 정의 팩토리가 **`table.freeze({ … })`** 를 돌려주면 트레이트 타입의 필드가 `read` 가 되고(`luau-source/freeze.luau`), 증인을 먼저 받는 두 단계
   등록이 검사됨(`luau-source/freeze3.luau`):
   ```lua
   Stack.For(Stack.Of<<Arr<A>, A>>)(ARR, { Push = Arr.PushBack, Pop = Arr.PopBack })   -- 한 줄. 원소를 못박은 함수·빠진 칸 잡힘
   ```
   같은 호출에 증인과 표를 같이 넘기는 `ImplFor(토큰, Stack.Of<<…>>, 표)` 는 **안 됨**(R 이 표에서도 추론돼 틀린 표가 0건 — `freeze2.luau`).
   오타 칸(남는 필드)은 어느 모양이든 타입이 못 잡음(런타임 `unknownName` 이 잡음).
4. 제네릭 몸통 결함의 뿌리는 `Subtyping.cpp:830`(상류 TODO "entirely incorrect", CLI-225132) — 탐침 타입 몸통은 원리상 맞는 우회.

# 시제품 v9 — 토론이 모은 모양(D3): 기본 구현이 없으면 한 겹, 있으면 정의 함수를 모드 값으로 두 번 (2026-10-14 밤)

토론(DX 변호인 2라운드의 D3, 타입 변호인 2라운드의 B' 와 같은 갈래)을 메인이 시제품으로 지은 판. 비교는 `../trait-candidates.md`.

```lua
-- 기본 구현 없음(지금 트레이트 일곱 중 여섯): v4·v6 과 같은 한 겹
const Stack = Trait.Trait("Stack", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return { Push = Fn<<(stack: Self, item: T) -> Self>>(), Pop = …, Peek = … }
end)
export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))
export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))   -- 모든 트레이트가 내보냄(첫 기본 구현이 생겨도 등록한 쪽 그대로)

-- 기본 구현 있음(List): 정의 함수 + 모드를 **값**으로
local function listDef<M>(mode: M)
	return function<Self, E, I>(of: (Self & ItemIndexRead<E, I>) | AnyToken)
		return { Get = Fn<<…>>(), …, IndexOf = Default(mode, function(ops: List<Self, E, I>) … end) }
	end
end
const List = Trait.Trait("List", listDef(Trait.FULL), listDef(Trait.IMPL))

-- 등록: 필수만(기본 구현 칸은 안 적으면 기본 구현, 적으면 재정의 — 서명 검사됨)
const cdList: ListImpl<CircularDeque<A>, A, number> = { Get = …, FirstIndex = …, LastIndex = …, NextIndex = …, PrevIndex = … }
List.ImplFor(CD, cdList)
```

`Trait.Trait` 는 하나이고 **인자 수**로 두 모양을 가름(같은 인자 수의 오버로드는 제네릭 앞에서 모호 — 소스 `Subtyping.cpp:830`).

## 왜 모드를 값으로 (토론에서)
- 모드를 추론에 맡기는 v8(인라인)은 **정의와 같은 모듈**에서 기본 구현 칸의 반환 검사가 사라짐(덜 줄어든 `index<>` 가 `never`).
- `def<<"full">>, def<<"impl">>`(B')는 고쳐지지만 `<<…>>` 를 **잊으면 조용히** 다시 열림(DX 변호인 실측).
- 값으로 넘기면 잊을 수 없음 — 정의자의 실수 넷(모드 맞바꿈·글자 리터럴·부르지 않고 넘김·`FULL` 두 번)이 전부 에러(`definer-mistakes.luau`, 마지막은 DX 변호인 실측).

## 시험 (메인 실측)
- `types.luau`: 에러 줄 = `-- NEG` 줄 + canary. 같은 모듈 NEG(`NEG_sameRet` — 이 파일에서 정의한 트레이트의 기본 구현 반환) 포함.
- `definer-mistakes.luau`: 실수 셋마다 에러가 남(조용한 줄 없음).
- `check.luau`: `-O1`·`-O2` PASS.

## 남은 것 (모든 후보 공통이거나 이 모양의 대가)
- 기본 구현이 있는 트레이트는 정의가 `Trait()` 밖의 함수 하나로 나감(지금 일곱 중 `List` 하나).
- 재정의 이름의 오타는 타입이 못 잡음(선택 칸이라 — 런타임이 등록 줄에서 잡음). A(v6)는 잡음.
- `Default("full", …)` 처럼 모드를 박으면 에러가 구현자 줄로 번짐(시끄러움 — 조용하진 않음).
- 편한 진입점 `List.IndexOf(d, x)` 는 any(어느 후보든).
- 내장 `index<>` 하나(`Default` 의 반환 타입) — 시스템 안에만.

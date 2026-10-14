# 트레이트 시스템 v3 — 트레이트가 제네릭 타입을 가짐 (2026-10-14 시제품)

v2(`../trait-v2/` — 연관 타입: 값의 타입에서 원소를 캐냄)와 **런타임은 같고 타입 층만** 다릅니다. 사용자: *"보이는 문제 뿌리는 Trait
자체에 제네릭이 없다는것 같아 … 자바 같은 경우를 보면 List<T> 를 지정해서 받잖아"*. 두 판을 나란히 두고 쓰면서 견주려고
v2 를 지우지 않았습니다.

```lua
local function stackDef<Self, T>()                         -- 정의는 팩토리 한 곳(사용자의 예전 `function<Self>()` 감싸기)
	return { Push = Trait.Fn<<(stack: Self, item: T) -> Self>>(), Pop = Trait.Fn<<(stack: Self) -> T?>>(), … }
end
export type Stack<Self, T> = typeof(stackDef<<Self, T>>())  -- 트레이트의 제네릭 타입
const Stack = Trait.Trait("Stack", stackDef) :: Stack<any, any> & { read Of: <C, T>(C) -> Stack<C, T>, read For: …, read FnTok: … }

const arrStack: Stack<Arr<string>, string> = { … }          -- 등록 검사(구체 타입). 기본 구현이 있으면 Trait.Provided<List<…>>
local function stackFromDeque<C, T>(deque: Deque<C, T>): Stack<C, T> … end   -- 뭉텅이 구현은 제네릭 함수로 검사
Trait.Impl(Stack):Where({ Deque })(function(deps) return stackFromDeque(deps[Deque]) end)

local s = Stack.Of<<CircularDeque<number>, number>>(d)     -- 동적 경로: 받는 쪽이 T 를 밝힘
local function drain<C, T>(s: Stack<C, T>, c: C): { T } … end   -- 자바 식 받기
Stack.Push(d, x)                                            -- 편한 진입점: 원소 검사 없음(any)
```

| 파일 | 무엇 |
|---|---|
| `Trait/` | v2 의 런타임 그대로 + 팩토리 정의, `Of`·`For`, 타입 함수는 `Provided` 하나(등록 표의 선택 필드 — 구체 타입에만) |
| `Traits.luau` | `Deque`·`Stack`·`Queue`·`List` + 등록(`Arr` 를 `For` 로 스택) |
| `check.luau` | v2 의 동작 확인 + `Of`·`For` |
| `types.luau` | 타입 확인 — 음성 대조군 다섯, 알려진 경계 하나(밝힌 T 는 주장) |

## v2 와 견주면

| | v2(연관 타입) | v3(제네릭 트레이트) |
|---|---|---|
| 원소 타입은 | 값의 타입에서 캐냄(`__generics` + 표식 + 바꿔 끼우는 타입 함수) | 받는 쪽이 밝힘(`Stack.Of<<C, T>>`, `s: Stack<C, T>`) |
| 컨테이너 타입에 | `read __generics: { read Item: Inv<T> }` 가 필요 | 아무것도 필요 없음 |
| 타입 함수 | `RewriteSig`·`ImplFor`(+ `CreateGeneric`) | `Provided` 하나 |
| 편한 진입점 `Stack.Push(d, x)` | 원소 검사됨 | 원소 검사 없음(any) |
| 동적으로 꺼낸 표 | 값에 맞게 정확 | 밝힌 T 를 믿음(검사 안 됨 — 자바의 검사 안 된 형변환) |
| 뭉텅이 구현의 검사 | 없음(런타임) | 제네릭 함수로 검사됨 |
| 바깥 사람이 새 계약 정의 | 표식 + 컨테이너가 연관 타입을 적음 | 팩토리 + `typeof` 별칭 한 줄 |

⚠️ 트레이트 객체의 타입을 `[string]: any` 인덱서가 든 타입과 교집합으로 적으면 `Stack.Of` 가 "제네릭 함수 | 에러" 가 되어
`<<…>>` 를 못 붙였습니다 — 그래서 `Stack<any, any> & { Of, For, FnTok }`.

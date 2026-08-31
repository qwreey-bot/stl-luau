# Luau 타입 한계와 이 저장소의 현황

quad 의 같은 이름 문서(`/code/Projects/stl-luau-refs/quad/.claude/base/typing-limits.md`,
513줄)가 **훨씬 방대하고 실측이 잘 돼 있습니다 — 타입 문제로 막히면 거기부터
읽으세요.** 이 문서는 stl-luau 고유의 현황만 기록합니다.

## 원칙 (quad 에서 가져옴)

- **⭐ Luau 한계를 우회하려고 API/타입을 비틀지 마세요.** 한계를 문서화하고,
  그로부터 강제되는 사용 관례를 적고, 나중에 되돌릴 수 있게 RFC/이슈 링크를
  남기는 게 원칙입니다. 반환 타입을 `any` 로 열어버리는 식의 회피는 금지.
  (근거: quad 의 사용자 발언 — *"타입을 비틀어 해당 시도를 하는 건 전혀
  적합하지 않고, 이것은 상위의 Luau의 현 한계다."*)
- **⭐ "진단 0건" 을 신뢰하지 마세요.** 타입이 `any`/`Unifiable<Error>` 로
  조용히 새면 검사가 그냥 통과합니다. 반드시 (a) 실제 추론된 타입을 확인하고
  (b) **음성 대조군**(일부러 틀린 대입)을 넣어 에러가 나는지 봐야 합니다.
- **추론만으로 "된다/안 된다" 를 결론짓지 마세요.** 작은 스파이크 파일을
  만들어 실제로 돌려보세요.

## [2026-08-22 실측] `Arr<T>` 는 new solver 에서 통과하지 못합니다

`luau-lsp analyze --platform=standard --flag:LuauSolverV2=true src/arr.luau`
기준 **TypeError 68건**(2026-08-31 측정, 이전 47건). 런타임 동작은 정상입니다
(`tests/arr.luau` 전부 통과) — 즉 이건 "코드가 틀렸다" 가 아니라 **타입 표현이
solver 를 못 따라간다** 는 문제입니다. 유형별로:

| 건수 | 내용 |
|---|---|
| 46 | `No valid instantiation could be inferred for generic type parameter` — `table.move` 계열 호출에서 제네릭이 안 풀림 |
| 7 | `Cannot add property 'n' / '__arr__' to table '{unknown}'` — `table.pack(...)`/`table.create(n)` 의 결과에 필드를 덧붙이는 패턴 |
| 5 | `Expected this to be 'ArrInterface & {...}' but got '{ @metatable ArrInterface, {unknown} }'` — 메타테이블 + intersection 조합 |
| 2 | `Code is too complex to typecheck!` — `replace_inplace` 부근. intersection 이 `T & T & T & ...` 로 부풀어 solver 가 포기합니다 |
| 나머지 | 위 원인에서 파생된 `Expected type table, got ...` 류 |

**47 → 68 (2026-08-31)**: 빈 함수 10개를 구현하면서 늘었습니다. 새로 생긴
21건은 전부 위 표의 기존 유형과 같은 원인(대부분 `table.move` 제네릭)이고,
새로운 종류의 실패는 `Code is too complex to typecheck!` 2건뿐입니다.
**구현을 더할수록 이 숫자는 계속 늘어납니다** — 재설계 전까지는 개별 함수에
`:: any` 를 덧발라 숫자를 낮추지 마세요(원인을 가릴 뿐입니다).

**[2026-08-22 해소] `Argument count mismatch` 7건**은 `sized(length, fill)` 의
`fill: T` 를 `fill: T?` 로 고쳐 없앴습니다(`arr_sized(0)` 처럼 `fill` 을
생략하는 호출이 내부에 여럿 있는데 시그니처가 필수 인자로 돼 있었음).
54건 → 47건. 이건 타입 회피가 아니라 시그니처 자체가 틀렸던 것입니다.

### 근본 원인 (추정, 미확정)

`Arr<T>` 는 지금 이렇게 정의돼 있습니다(`src/arr.luau` 끝부분):

```lua
export type ArrInterface = typeof(arr_ifce)
export type Arr<T> = { n: number, [number]: T } & ArrInterface
local Arr = (arr_ifce :: unknown) :: (<T>(...T|any) -> (Arr<T>)) & Arr<any>
```

문제가 되는 지점 셋:

1. **`table.pack`/`table.create` 결과에 필드를 덧붙이는 생성 패턴.**
   solver 는 그 결과를 `{unknown}` 으로 보고 `n`/`__arr__` 추가를 거부합니다.
2. **`typeof(arr_ifce)` 로 만든 인터페이스와 데이터부의 intersection.**
   `arr_ifce` 는 자기 자신이 메타테이블이면서 생성자 메타테이블
   (`arr_constructor`)도 얹고 있어, `@metatable` 이 낀 타입과
   `ArrInterface` 가 서로 subtype 이 아니게 됩니다.
3. **메소드가 `Arr<T>` 를 받아 `Arr<U>` 를 돌려주는 자기재귀 제네릭**
   (`map`, `flatmap` 등). 이건 quad 문서 §1 이 다루는 바로 그 케이스입니다
   — RFC [`relax-recursive-type-restriction`](https://rfcs.luau.org/relax-recursive-type-restriction.html),
   이슈 [luau-lang/luau#2380](https://github.com/luau-lang/luau/issues/2380).

### 아직 시도하지 않은 것 (다음 작업)

quad 문서가 제시하는 회피법 중 이 저장소에 적용해볼 만한 것:

- **§1 워크어라운드 ③ — 메소드를 최상위 named function 으로 선언하고
  `typeof(fn)` 으로 타입에 넣기.** 인라인 함수 타입 리터럴 대신:
  ```lua
  local function map<T, U>(self: Arr<T>, fn: (T) -> U): Arr<U> ... end
  type Arr<T> = { map: typeof(map), ... }
  ```
  quad 는 이걸로 체인 깊이 50 까지 반환 타입 안전성을 확보했습니다
  (파라미터 추론은 별개 문제로 남음).
- **§1 워크어라운드 ② — 데이터부/메소드부 타입 분리**(`ArrData<T>` /
  `Arr<T>`). 콜백 파라미터 추론이 필요할 때.
- (`sized` 의 `fill` optional 화는 이미 적용했습니다 — 위 참고.)

**이 재설계는 아직 착수하지 않았습니다.** 착수 전에 quad 의 typing-limits.md
전문을 읽고, 스파이크 파일로 후보안을 먼저 측정하세요(음성 대조군 포함).

## 기타 모듈

- `tuple.luau` 9건, `typeutil.luau` 3건, `treeset.luau` 1건
  (`subtract` 의 미타입 파라미터). 전부 스텁/실험 코드라 우선순위가 낮습니다.

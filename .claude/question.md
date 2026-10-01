# 열린 질문 (우선순위순)

사용자가 답해야 하는 것만. 답이 나오면 `.claude/base/`에 확정 사실로
반영하고 이 파일에서 지우세요.

## ⭐ 지금 답을 기다리는 것 (2026-09-21)

전면 재작성 계획(`base/rewrite-plan.md`)과 스캐폴딩 제안서
(`base/scaffolding-proposal.md`)는 확정됐습니다(A 해소).
**지금 구현을 막는 질문은 없습니다** — 나머지는 구현하며 만나는 순서대로
답하면 됩니다.

### A. 스캐폴딩 제안서 — **[2026-09-22 사용자 승인]**

`base/scaffolding-proposal.md` 를 그대로 채택합니다. 네 항목 전부 확정:

- 컨테이너 하나 = 파일 하나. 폴더 분할은 필요해질 때(실측 완료).
- `Types.luau` 가 공유 계약을 담는 말단 모듈.
- **`Set` 을 `Map` 위에 단방향으로 얹음** — 사용자: *"그래도 돼."*
  셋 전용 연산이 맵을 한 겹 거치는 대가를 받아들입니다. 사용자 증언:
  예전 C++ 과제도 결국 같은 경로를 갔다 — 확인 결과는
  `base/container-design-notes.md`.
- 전략(해시·비교)은 생성 함수 인자로 주입.

### B. `slice` 의 `to_start` — **[2026-09-22] 매개변수를 없애서 해소**

지금 `Reverse` 는 **덮어쓰기**로 테스트가 고정돼 있고 `slice` 는 밀어내기를
의도했는데 **구현이 틀려서 데이터를 잃습니다**(재현:
`audit/known-bugs/repro.luau`). 둘을 통일해야 합니다.

**정한 것**: `to_start` 를 없앴습니다. `to` 는 **"목적지 배열 뒤에
이어붙이기"** 하나만 뜻하고, `Reverse`/`Rotate` 에서는 `to` 자체를 뺐습니다
— 거기가 밀어내기냐 덮어쓰기냐가 갈려 데이터를 잃던 자리입니다. `to` 는
누적이 뜻이 분명한 스트림 계열(`Slice`/`Map`/`Filter`/`Flat`/`Flatmap`)에만
남았습니다.

같이 고친 것(`base/container-design-notes.md` §6 의 교훈): **삽입 위치의
유효 범위는 원소 위치보다 하나 넓습니다**(`1 .. n+1`). 예전 구현은 이걸
놓쳐 조회용 클램프로 삽입까지 처리하다 **끝에 삽입하는 것이 원리적으로
불가능**해졌습니다. 그래서 정규화 함수를 `resolveRange`(조회)와
`resolveInsertPos`(삽입) 둘로 나눴고, 테스트로 고정했습니다.

되살리고 싶으시면 말씀해 주세요.

### C. `nil` 구멍 정책 — **[2026-09-22 사용자 결정] 둘로 가릅니다**

사용자: *"안전한 부분을 내놓고, 위험한 부분은 제어된 환경에서 쓸 수 있도록
`SortUnchecked` 같은 다른 메서드를 unchecked 로 주는게 괜찮아보임. 데이터
안에 들어 있는 요소는 사용자가 확인할 수 있는 부분이지 우리는 모르는
부분이라 … 거의 대부분에서는 checked 를 쓰도록 하고, 최적화가 아주 중요할
때 안전을 포기하고 선택할 수 있는 옵션을 주는게 좋다."*

**구현 완료.** 기본은 전부 checked(구멍을 건너뜀)이고, 옆에 `*Unchecked`
여섯을 뒀습니다 — `SumUnchecked` / `ProdUnchecked` / `MaxUnchecked` /
`MinUnchecked` / `SortUnchecked` / `SortInplaceUnchecked`.

얻는 것(실제 콜론 호출로 실측, `base/perf-measurements.md` 11절):

| 무엇 | 빨라지는 정도 |
|---|---|
| `MaxUnchecked` / `MinUnchecked` | **1.83배** |
| `SortInplaceUnchecked` | 1.18배 |
| `SumUnchecked` / `ProdUnchecked` | 1.08배 |

⚠️ **셋 중 정렬만 조용히 틀립니다.** 집계 계열은 구멍에서 터지지만,
`table.sort` 는 `#` 를 보므로 구멍 뒤쪽이 **에러 없이** 잘립니다. 문서에서
그 줄을 특히 강조했고, "구멍이 있으면 문서대로 망가지는지" 를 테스트로도
고정했습니다 — 안 그러면 나중에 누가 "안전하게" 고쳐서 존재 이유가
사라집니다.

### D. 위치(Index) 저장 — **[2026-09-22 사용자 결정] 문서 규약으로 둡니다**

세대 카운터를 두지 않습니다. 사용자: *"quad에서도 사용자 실수를 잡기 위해
너무 오버엔지니어링을 하지 않기로 했어 … 쉽고 싸게 막히는 부분을, 빈번한
실수가 나는 막을 때 비용 대비 얻는게 충분히 큰 부분만 막기로 했었어."*

판단 기준과 이 저장소의 실제 적용례는
`base/container-design-notes.md` 2절에 표로 정리했습니다.

같이 결정된 것: **문서를 만들 때 quad 의 `docs/` 구조를 그대로 따릅니다**
(Diátaxis 4트랙 + starlight 사이트 + 동기화 스크립트). 계획과 백로그는
`base/docs-plan.md`.

### E. `Record.luau` — **[2026-09-22 해소] `Types.Record` 로 흡수했습니다**

타입 별칭 한 줄뿐이었고 모듈 패턴도 안 따랐습니다. 지금은
`Types.Record<K, V> = { key: K, value: V }` 이고 `HashMap`/`TreeMap` 의
`Records()` 가 그걸 씁니다 — **실제 소비자가 생겼습니다.**
다르게 생각하시면 말씀해 주세요.

### F. `Fut` / `Optional` — **아직 열려 있습니다**

옛 `src/fut.luau` 는 네임스페이스와 메타테이블만 있는 **2줄짜리 뼈대**였고,
재작성하면서 지웠습니다(git 히스토리에 있습니다). 새 `src` 에는 없습니다.

물어볼 것 둘:

1. **`Fut` 이 정말 필요한가.** 이 저장소는 순수 `luau` 로 돌고 스케줄러가
   없습니다. 비동기 프리미티브를 여기서 만들면 실행기를 가정하게 됩니다 —
   Roblox 의 task 스케줄러인지, lute 인지, mlua 호스트인지.
2. **`Optional` 은 `T?` 로 충분해 보입니다.** Luau 에 이미 옵셔널 타입이
   있고, `Get`/`Find`/`Max` 같은 것들이 전부 `T?` 를 돌려주도록 짜여 있어
   일관됩니다. 감싸는 타입을 하나 더 두면 `if x then` 이 `if x:IsSome() then`
   이 되는데, 그만한 값이 있는지 모르겠습니다.

---

## 🌙 2026-09-22 밤 작업에서 **제가 정한 것들**

사용자가 자는 동안 진행하며 막히지 않으려고 정한 것들입니다. **전부 되돌리기
쉬운 것만 골랐고**, 구조를 바꾸는 결정은 건드리지 않았습니다. 아래 중 어느
것이든 한마디면 뒤집습니다.

### I. 정렬·비교의 통화를 3방향에서 **불리언**으로 바꿨습니다

`table.sort` 가 불리언을 받으므로, 3방향 비교자를 쓰면 비교마다 래퍼 클로저가
한 겹 붙어 **1.82배** 느려집니다(실측). 그래서 `Sort`/`Max`/`Min` 은
`LessThan<T>`(`(a, b) -> boolean`)를 받습니다. 3방향이 필요하면
`Common.lessFrom(cmp)` 로 감싸면 되고, 그 비용이 눈에 보입니다.

3방향 `Comparator<T>` 는 **정렬된 구조에서의 탐색**(이분 탐색·트리)용으로
남겨뒀습니다 — 거기서는 "같다" 를 한 번에 알아야 해서 3방향이 오히려 절반입니다.

⚠️ 옛 `Comparator` 는 불리언과 숫자를 **둘 다 받는 유니언**이었습니다. 그건
비교마다 반환 타입을 분기해야 해서 없앴습니다.

### J. `Arr.Pack` 을 없앴습니다

`Arr.Of` 와 **완전히 같은 것**이었습니다(둘 다 `table.pack` 의미). 이름만
둘이면 쓰는 사람이 차이를 찾게 됩니다. 되살릴 이유가 있으면 말씀해 주세요.

### K. `Arr.Range` 의 뜻을 바꿨습니다

옛 `arr.range(len, start, last)` 는 **내부 구간 정규화 헬퍼**가 공개 표면에
샌 것이었습니다. 그건 비공개 `resolveRange` 로 내리고, `Arr.Range(from, to, step?)`
를 **실제 숫자 구간 생성자**로 만들었습니다(`Arr.Range(1, 5)` → `1,2,3,4,5`,
닫힌 구간).

### L. `Flat`/`FlatInplace` 의 **입력** 원소 타입을 열었습니다

자연스러운 `self: Arr<T | Arr<T>>` 은 Luau 가 `T | Arr<T>` 를
`number | Arr<number>` 로 분해하지 못해 *"No valid instantiation"* 이 납니다.
옛 테스트의 21건도 거기서 났습니다. 평탄화는 어차피 원소마다 런타임에 배열인지
보는 동적 연산이라 **결과 타입만 박고 입력은 열었습니다**.

⚠️ 대신 호출자가 결과를 **캐스트로** 적어야 합니다 —
`local flat = nested:Flat() :: Arr<number>`. 선언 주석은 안 됩니다(Luau 가
기대 타입을 제네릭 호출 안으로 전파하지 않음).

### M. `Types.Hasher` 는 타입만 두고 소비자를 두지 않았습니다

Luau 테이블 자체가 해시맵이라 문자열/숫자 키에는 해시 함수가 필요 없습니다.
**테이블을 값으로 비교해 키로 쓰는 기능**(예: `{1,2}` 와 `{1,2}` 를 같은 키로)
을 만들 때만 값집니다. 그 기능을 만들지 말지가 열린 질문이고, 지금은 자리만
남겨뒀습니다.

### N. 문법 함정 하나 — `local const x = 1` 은 조용히 **전역**을 만듭니다

`const` 는 `local` 을 **대체**하는 키워드입니다(`const x = 1`). `local const x = 1`
이라고 쓰면 `const` 라는 지역변수를 만들고 `x = 1` 은 **전역 대입**이 됩니다.
타입 주석이 붙어 있으면 문법 에러로 잡히지만, 없으면 그냥 돕니다.

---

## 🔁 2026-09-26 작업에서 **제가 정한 것들** (되돌리기 쉬움)

### O. `Optional` 은 메소드가 아니라 네임스페이스 함수입니다

`o:UnwrapOr(0)` 이 아니라 `Optional.UnwrapOr(o, 0)`. 태그 유니온에 메소드
교집합을 얹으면 메소드의 `T` 가 `number | nil` 로 잡혀 추론이 무너집니다
(`spikes/45`). 덤으로 메타테이블이 없어 `.value` 읽기에 세금이 없습니다.
**메소드 체인이 꼭 필요하면** 다른 모양을 다시 재야 합니다.

### P. `Optional` 표면에서 `Filter` 를 뺐습니다

페이퍼 초안엔 있었는데 부르는 곳이 없어서입니다. `Present`/`Absent`/`Of`/
`Unwrap`/`UnwrapOr`/`Map`/`ToNil`/`isOptional` 만 있습니다.

### Q. `Arr` 에 구멍 다루기 넷 — `FillHoles`/`Compact`/`CompactInplace`/`ToOptionals`

`Fillholes` 가 아니라 **`FillHoles`** 로 썼습니다(단어마다 대문자, 이 저장소
규약). `ToOptionals` 가 따로 있는 건 `arr:Map(Optional.Of)` 가 타입 에러라서
입니다.

⚠️ 실측으로 정정한 것: 구멍을 한 번 정리하고 unchecked 를 **한 번만** 쓰면
오히려 손해(0.87x)이고 **두 번째 연산부터** 이득입니다.

### ⭐ 2026-09-30 사용자 답 (O~S 와 브리프 넷)

- **Roblox 에서 `Await` 허용** — 동의. *"사용하는 위치에 대해서 준비하는건
  사용자 책임 아닌가 싶어. 하지만 그걸 우리가 준비하는데 문제는 없는것
  같다."* → `Fut.UseProvider({ schedule, canWait, resume })` 로 넓혔습니다.
  기본값은 그대로 두고(환경에 중립), Roblox 한 벌은 모듈 머리말에 **예시로만**
  적었습니다.
- **`AndThen`/`Chain` 분리** — 동의. *"promise 가 다른 promise 로 받은 경우
  교체되는 부분이랑(껍데기 통으로) 펑터/어플리케이팅 되어서 내부 요소를
  갈려진 것은 다르니까."* 겸해서 immutable/mutable 을 물으셨는데, **지금이
  이미 immutable 입니다** — 잇기는 전부 새 `Fut` 을 만들고 원래 것은 안
  바뀝니다. `spec.fut` 9절로 고정했습니다.
- **`Fut` 다음 표면** — 제 의견대로(`All` 먼저), 천천히.
  서브에이전트는 **최대 3개**, sonnet/opus 는 속도·경제성 보고 고름.
- **`Optional` 네임스페이스 함수** — 동의. ⭐ **방향 하나가 같이 왔습니다**:
  *"quad는 DX가 UI 엔진이라 체이닝이 중요했는데 여기는 데이터처리라 라인을
  나눠 깔끔하게, 견고하게 쓰는게 나을수도 있어서 … 선언형에서 체이닝과
  (테이블 안에 들어가는 값이라 expr 임) 우리는 코드 실행 맥락 안에 있기
  때문에 statement 로써 써낼 수 있거든. 절차적이 된다는거야. 그래서
  `.Map()` 이나 `Optional.UnwrapOr()` 모양도 나쁘지 않아."* 그리고 *"나중에
  타입이 멀쩡해질 때 단순 추가로 넘어갈 수 있는 구조"* 면 `:` 를 나중에
  더해도 된다. → `conventions.md` 에 기록.

### R. `Fut` — `AndThen` 과 `Chain` 을 가릅니다

콜백이 값을 돌려주면 `AndThen`, `Fut` 을 돌려주면 `Chain`(펼침). JS `then`
처럼 하나로 합치면 "돌려준 게 Fut 이면 펼친다" 를 Luau 타입으로 표현할 수
없습니다. 이름을 `Chain` 으로 한 게 마음에 안 드시면 바꿉니다
(`AndThenFut`, `FlatMap` 등).

### S. `Fut` 첫 판에서 뺀 것

`All`/`Race`, 재시도(`Retry`/`OnRetry` — 옛 `promise.lua` 에 있던 것), `Finally`,
처리 안 된 실패 경고. 부르는 곳이 생기면 얹습니다.

---

## ❓ 2026-09-30 리뷰에서 나온 정책 질문

### T. 콜백 계열이 구멍을 어떻게 다룰까 — **[2026-09-30 사용자 결정] (b), 같은 날 구현**

사용자: *"네 추천대로 가는게 맞는것 같아. 이건 러스트에 maybe uninit 과도
유사한듯. 우리가 default 가 없어서, 채워주는걸 못 하고, 그럼 선택지가
드러내기가 가장 명시적이야."* → **구멍은 타입에 `T?` 로 드러냅니다.**
**구현한 것**: `Sized(len, fill)` 의 `fill` 필수(구멍은
`Arr.Sized<<number?>>(5, nil)`). 다른 생성자는 점검 결과 이미 정직했습니다 —
`Of(1, nil, 3)` 과 `FromTable({ 1, nil, 3 })` 은 `Arr<number?>`, `FromIter` 는
첫 `nil` 에서 멈춰 구멍을 못 만들고, `FromFunc` 는 콜백 반환 타입을 따릅니다.
`FromTable` 의 `#` 가 구멍 뒤를 **조용히 자를 수 있는 것**은 주석으로
적었습니다. 규약은 `Arr.luau` 머리말과 `conventions.md` 로, 음성 대조군은
`spikes/50`. `Fut.All` 의 결과 버퍼는 fail-fast 라 밖에서 구멍을 볼 일이
없어 `T` 로 단언했습니다. 구현하며 정한 것 하나(U)와 새 질문 하나(V)가
아래에 있습니다.


**지금**: 집계·정렬(`Sum`/`Max`/`Sort`/`Join`)은 구멍을 건너뛰는데, 콜백 계열
(`Map`/`Filter`/`Fold`/`Count`/`Find`/`Some`/`Every`/`Reduce` 등 12개)은
**`nil` 을 콜백에 그대로 넘깁니다.** 그래서 이게 **타입 검사를 통과하고
런타임에 터집니다**:

```lua
local s = Arr.Sized<<number>>(3)          -- 칸이 전부 nil 인데 타입은 Arr<number>
Arr.Map(s, function(x: number) return x * 2 end)   -- 0건 → arithmetic on nil
```

두 길입니다:

| | (a) 콜백 계열도 건너뜀 | (b) 타입을 정직하게 — 구멍은 `T?` 로 드러냄 |
|---|---|---|
| 어떻게 | 구멍이면 콜백을 안 부름. `Map` 은 그 자리를 구멍으로 둠 | 지금처럼 넘기되, 구멍이 생기는 생성자가 `Arr<T?>` 를 돌려주게 |
| 비용 | 원소마다 검사 하나 — `Map` 기준 **5%**(실측) | 0 |
| 잃는 것 | `Arr<number?>` 에서 **`nil` 을 보고 싶을 때 못 봄**(`Map(v or 0)` 이 불가능해짐 — 지금 테스트와 스파이크 46 이 바로 그걸 씀) | `Sized(n)` 처럼 fill 없이 만들던 코드가 `Arr<T?>` 를 받게 됨 |
| 결 | "안전한 쪽이 기본"(질문 C) | **"타입이 진실이고, checked 는 런타임 그물"** |

**제 추천은 (b)** 입니다. 구멍이 있으면 타입이 `Arr<T?>` 이고 콜백도 `T?` 를
받으니 건전합니다. `Sum` 은 이미 `ArrData<number>` 만 받으므로 `Arr<number?>`
에서는 먼저 `Compact` 하라고 타입이 알려줍니다. 구체적으로는 `Sized(len, fill)`
의 `fill` 을 **필수**로 바꾸면 됩니다 — 구멍을 원하면
`Arr.Sized<<number?>>(5, nil)` 로 명시합니다.

(a) 를 고르시면 `Map` 이 구멍 자리를 구멍으로 두는지, `Reduce` 가 첫 **값**을
씨앗으로 잡는지 같은 세부를 같이 정해야 합니다.

### U. `FillHoles` 를 새 배열판으로, 제자리판은 `FillHolesInplace` 로 (제가 정함, 되돌리기 쉬움)

(b) 에서는 구멍이 `Arr<number?>` 로 드러나는데, 예전 `FillHoles` 는 제자리
변형이라 건전성 때문에 `self` 를 불변으로 받아 **채운 뒤에도 `Arr<number?>`**
로 남았습니다 — `?` 를 떼는 길이 `Compact`(길이가 바뀜)뿐이었습니다. 그래서:

| | 무엇 | 타입 | 비용(`Sum` = 1.00) |
|---|---|---|---|
| `FillHoles(v)` | **새 배열**, 원본 불변 | `Arr<number?>` → **`Arr<number>`** | 1.45x |
| `FillHolesInplace(v)` | 제자리(예전 `FillHoles`) | 불변 — `?` 유지 | 1.03x |

이름은 이 저장소의 **`Inplace` 쌍 관례**(`Sort`/`SortInplace`)에 맞춘 것이기도
합니다 — 예전 `FillHoles` 는 이름과 달리 제자리였습니다. 새 배열판은 `v` 가
다른 타입이면 `T` 가 넓어지지만(`number | string`) 원본이 안 바뀌어 건전합니다.

### V. `Arr` 콜백의 셋째 인자(`arr: ArrView<T>`)에서 `T` 를 뺄까 — **[2026-09-30 사용자 결정] (b), 같은 날 적용**

사용자: *"추천대로 가면 될 것 같아."* (U 도 확인하셨습니다.) → 콜백 타입의
셋째 인자는 `ArrView<any>`. `spikes/50` 이 9 → 11건(구멍이던 `T?` 자리와
유니온 자리가 NEG 로), 테스트 한 곳에 콜백 주석을 달았습니다.


`spikes/50` 을 쓰다 나온 체커 구멍입니다. **네임스페이스 호출**에서 콜백 원소를
더 좁게 적으면 안 잡힙니다:

```lua
local holed = Arr.Sized<<number?>>(3, nil)
Arr.Map(holed, function(v: number) return v * 2 end)   -- 0건 → 런타임 arithmetic on nil
holed:Map(function(v: number) return v * 2 end)        -- 잡힘
```

`T?` 만이 아니라 `Arr<number | string>` 에 `(v: number)` 도 같습니다. 원인을
좁혀보니 **콜백 타입의 다른 인자가 `T` 를 품은 테이블**(`arr: ArrView<T>`)이고
람다가 그 인자를 생략할 때입니다(`base/typing-limits.md` 새 절). 절차적 호출이
정식 모양이라 가볍지 않습니다.

| | (a) 그대로 두고 문서화 | (b) 셋째 인자를 `ArrView<any>` 로 |
|---|---|---|
| 이 구멍 | 남음 | **닫힘**(실측, spikes/50 이 10건) |
| 잃는 것 | 없음 | ① 콜백 안 `arr` 의 원소 타입(`arr[1]` 이 `any`) ② **주석 없는 람다 + `to` 인자** 자리에서 새 에러 하나: `Arr.Of(1, 2):Map(function(v) return v end, Arr.Of(0))` — `ArrView<T>` 가 거기서 `T` 를 붙잡아 주고 있었음 |
| 셋째 인자를 쓰는 곳 | — | 저장소 안에 테스트 둘, 스파이크 POS 하나. 적어둔 `arr: ArrView<number>` 주석은 그대로 통과 |

**제 추천은 (b)** 입니다. 셋째 인자는 JS 관례를 따른 덤이고 거의 안 쓰는
반면, 원소 파라미터는 모든 콜백이 씁니다 — 자주 쓰는 쪽의 건전성을 사는
게 맞습니다. ②는 콜백 주석을 달면 사라지고, 콜백 파라미터 주석은 어차피
지금도 요구되는 한계라(`typing-limits` "명시적 타입 인자가 풀어주지 않는
것") 새 부담이 거의 없습니다. 다만 공개 콜백 타입이 바뀌니 여쭙니다.

---

## 2026-09-30 빠진 표면 리서치에서 나온 질문 (`papers/04-surface-gaps.md`)

### W. 무엇을 어떤 순서로 더할까 — **[2026-09-30 사용자 결정]**

| | 결정 |
|---|---|
| `Contains` vs `Has` | **`Arr.Contains` 유지.** 사용자: *"contains 는 value 를 가지냐고 has 는 key 를 가지냐 아닌가. 키를 '가지냐' 는 의미적으로 맞는데, 키를 '포함하냐' 는 애매하지 … array 에서 값을 '포함하냐' 는 또 맞아."* → **`Has` = 키, `Contains` = 값** 이 이 저장소의 어휘 |
| `Splice` | 유지 + "JS `splice` 와 다름" 문서화 |
| 맵 두 이름 | **(가) Luau 생태계 쪽**: `HashMap.Merge(other)`(덮어 합치기), 누적은 **`Accumulate(k, v, combine)`** — `Update` 는 Python `dict.update`(=덮어 합치기)와 겹쳐서 뺐습니다(제가 고름, 되돌리기 쉬움) |
| `TopK` vs `PartialSort` | **`PartialSort`** — *"선례이고 더 명확한"* |
| `Counter` vs `Multiset` | **`Multiset`** — *"파이썬 보다는 java 계보가 더 잘 쓰인것 같아"* |
| 이견 없던 것 | 초안대로. *"검토자도 이견 없다면 택하면 될것 같음."* |
| 순서·범위 | **제게 맡김.** *"시간이 많고 작업 방식일 뿐이라 너가 생각하기에 최적인 방법을 택하면 돼 … 지금은 작게 두고 나오는걸 잡아가다 나중에 넓혀도 좋고"* → 마일스톤은 `todos.md` |

(아래는 물었던 원문)

리서처 셋(C++ / Rust·Java / Luau 생태계)의 결과와 정렬 실측을 합쳐 **다섯
파도**로 나눴습니다: ① `Arr` 빈 조각(`PopBack`/`PopFront`, `SwapRemove`,
`Contains`/`IndexOf`, `FindLast`, `Zip`, `Dedup`/`Unique`, `Partition`,
`Chunks`/`Windows`, `Scan`, `MinMax`, `MaxBy`/`MinBy`, `TakeWhile`/`DropWhile`)
② 정렬 가족(`StableSort`, `SortBy`, `NthElement`, `TopK`, `MergeSorted`)
③ 맵·셋(`GetOrInsert(With)`, 누적, `Extend`, `Retain`, `Lower`/`HigherKey`,
`PopFirst`/`PopLast`, `GroupBy`/`CountBy`) ④ 새 컨테이너(`Deque` 상, `Counter`·
`OrderedMap` 중, `buffer` 기반 `BitSet` 하~중) ⑤ `Fut`(`Race`, `Timeout`, `Retry`,
`AllSettled`, `Finally`). 상세와 근거는 페이퍼.

세부 질문:

- **W1. 순서**: 제 추천은 **이름 정리(W3) → ② 정렬 → ① → ③ → ④ Deque → ⑤**.
  정렬을 앞에 두는 건 사용자가 짚은 것이고 실측이 가장 확실해서입니다
  (top-k 7~20배, 선택 6.7배, 안정 정렬 1.43x). 이름 정리를 맨 앞에 두는 건
  새 표면이 옛 이름 위에 쌓이기 전에 하는 게 싸서입니다.
- **W2. `Zip` 의 짝 표현**: Luau 에는 튜플 테이블 타입이 없습니다. (a) `ZipWith(a,
  b, fn)` 만 둠 — 할당 없음, 타입 정확 (b) `Zip` 이 `Arr<{ first: T, second: U }>`
  를 돌려줌 — 칸마다 테이블 (c) 둘 다. **추천 (c)** — 성능 경로는 `ZipWith`,
  편의는 `Zip`(편의를 기본 경로와 분리하는 관례).
- **W3. 이름 정리**: `Arr.Merge`/`MergeInplace` → **`Concat`/`ConcatInplace`**
  (정렬 병합이 아닌데 `std::merge` 를 연상), `Replace`/`ReplaceInplace` →
  **`Splice`/`SpliceInplace`**(C++ `replace` 는 값→값), 음수를 받는 **`At(idx)`**
  추가(`Get` 은 계약 멤버라 원시 조회로 둠). 맵 누적은 `Merge` 가 Java 어휘지만
  `Arr.Merge` 와 헷갈리니 **`Upsert(k, v, combine)`** 추천.
- **W3 이름 검토 결과(2026-09-30)**: 내부자·외부자 sonnet 둘의 판정을
  `papers/04` 부록에 합쳤습니다. `Concat`/`At`/`NthElement` 등 대부분은 둘이
  같은 판정으로 유지, **`Upsert` 는 둘 다 반대**, 갈린 것은 `Contains`(→`Has`?),
  `Splice`, `Extend`(맵 두 이름을 묶어 고르는 문제), `TopK`/`PartialSort`,
  `Counter`/`Multiset`.
- **W4. 범위**: `buffer` 기반 컨테이너(`BitSet`, packed 숫자 배열)와
  `Freeze`(`table.freeze`) — 이 라이브러리 범위에 넣을까요? 제 생각은
  `BitSet` 은 ④ 뒤에 실측 주제로, `Freeze` 는 메타테이블·`n` 과 얽혀 있어
  수요가 생기면.

---

## 🔁 2026-09-30 M2(정렬 가족)에서 **제가 정한 것들** (되돌리기 쉬움)

### X. 정렬 가족의 모양

- **`NthElement(k)` 는 값을 돌려주고 배열을 안 건드립니다.** C++ 모양(제자리
  재배치)은 `NthElementInplace(k)`. 새 배열이 기본인 관례에서 "재배치된 새
  배열" 은 쓸모가 없어서, 비변형 판은 **답(값)** 을 주게 했습니다.
- **`k` 는 구멍을 뺀 값들 사이의 순위**이고 음수는 뒤에서(`At` 과 같은 규약),
  범위 밖이면 `nil`(Inplace 는 구멍만 치움). `PartialSort` 의 `k ≤ 0` 은 빈 결과.
- (리뷰 뒤) **`k` 가 NaN 이면 에러**(구간 NaN 과 같은 정책), 선택·부분 정렬은
  진입 시 `less(x, x)` 를 한 번 봐서 `<=` 같은 **엄격하지 않은 비교자를 에러로**
  알립니다. `Shuffle` 의 rng 가 정수 `[min, max]` 가 아니면 에러입니다.
- **`PartialSort` 는 안정하지 않습니다**(C++ 와 같음, 힙을 씀). `StableSort`/
  `SortBy`/`MergeSorted` 는 안정입니다.
- **`*Unchecked` 판은 두지 않았습니다.** 순수 Luau 정렬은 어차피 날 버퍼로
  모아 작업하므로 구멍 검사를 빼도 얻는 게 모으기 한 번뿐입니다.
- **`SortBy` 는 키가 쌀 때 손해**(1.53x 대 비교자 안에서 뽑기 1.35x)라는 걸
  주석에 적었습니다 — 이름이 있다고 늘 빠른 게 아닙니다.
- 비교 없는 정렬(계수·기수)은 넣지 않았습니다(페이퍼 04 의 보류 그대로).

---

## 2026-09-30 리뷰(M1·M2·구멍)에서 나온 설계 질문 (2026-10-01 결정됨)

### Y. 타입을 바꾸는 제자리 판 — 원래 변수가 거짓말을 하게 됨 — **[2026-10-01 사용자 결정] (b) 소비 규약**

사용자: *"추천대로. T -> T 만 허용하면 Map 이란 이름에 부합하지 않게 됨."* →
네 함수 주석과 `conventions.md` 의 `Inplace` 항목에 "입력을 소비한다" 를 적었습니다.


리뷰가 재현: `MapInplace`/`FlatmapInplace`/`FlatInplace` 는 **같은 테이블**을
다른 원소 타입으로 돌려주므로, 원래 변수가 `Arr<number>` 인 채로 문자열이나
구멍이 들어갑니다(진단 0건, 런타임에 터짐). `CompactInplace`(`Arr<T?>` →
`Arr<T>`)는 원래 변수(`T?`)로 `nil` 을 다시 쓰면 좁힌 쪽이 거짓이 됩니다.

```lua
local nums: Arr<number> = Arr.Of(10, 20, 30)
Arr.MapInplace(nums, function(v: number): string return tostring(v) end)
Arr.Map(nums, function(v: number) return v * 2 end)   -- 0건 → 런타임 에러
```

| | (a) 막기 | (b) "소비" 규약으로 문서화 |
|---|---|---|
| 어떻게 | `MapInplace`/`FlatmapInplace` 를 **같은 타입**(`T → T`)으로 제한. 타입을 바꾸려면 새 배열판(`Map`). `FlatInplace` 는 본질이 타입 변경이라 없앰 또는 (b) | 타입을 바꾸는 `*Inplace` 는 **입력을 소비**한다 — 결과만 쓰고 원래 변수는 다시 쓰지 않는다(Rust 의 move 와 같은 결). Luau 가 강제하지 못하니 주석·conventions 로 |
| 잃는 것 | 타입을 바꾸는 제자리 변환(할당 한 번 아낌) | 건전성 — 규약을 어기면 타입이 거짓 |
| 선례 | `FillHolesInplace` 를 불변으로 막은 것(질문 U) | — |

**제 추천은 (b)** 입니다. `FillHolesInplace` 는 **아무 실수 없이** `T` 가
조용히 넓어지는 구멍이라 막았지만, 이건 타입 변환이 호출에 **드러나 있고**
돌려받은 값의 타입은 정확합니다 — 문제는 버린 변수를 다시 쓸 때뿐입니다.
막으면 `FlatInplace` 가 통째로 사라집니다. 다만 "타입이 진실" 이라는 방향과는
(a) 가 더 맞습니다.

### Z. 콜백 셋째 인자 `ArrView<any>` 의 `any` 가 결과 타입으로 샘 — **[2026-10-01 사용자 결정] `ArrView<unknown>`**

적용: 콜백 타입 다섯 + `Reduce`. `spikes/50` 에 누수 NEG 둘(`any` 로 되돌리면
이 둘만 사라짐). 셋째 인자에 주석을 달던 세 곳은 `ArrView<unknown>` 으로.


질문 V 에서 `ArrView<T>` → `ArrView<any>` 로 바꾼 대가를 "콜백 안 `arr[i]` 가
`any`" 로 적었는데, 리뷰가 **그 `any` 가 `Map`/`Flatmap` 의 결과까지 나간다**는
걸 재현했습니다:

```lua
local nums: Arr<number> = Arr.Of(1, 2)
local s: Arr<string> = Arr.Map(nums, function(v, i, arr) return arr[i] end)   -- 0건 (V 전엔 에러)
```

셋째 인자를 틀린 원소 타입으로 적는 것(`arr: ArrView<string>`)도 이제 안
잡힙니다. 리뷰어가 **`ArrView<unknown>`** 시안을 사본에서 재봤습니다:
spikes/50 은 11건 그대로(V 의 구멍은 계속 닫힘), 위 누수 전부 잡힘, 테스트 통과.
**대가**: 콜백에 `arr: ArrView<number>` 처럼 **구체 타입을 적으면 에러**가
납니다(`unknown` 을 받는 자리에 좁은 타입 — 저장소 안에 두 곳). 적으려면
`arr: ArrView<unknown>` 로 받고 원소를 캐스트해야 합니다.

**제 추천은 `ArrView<unknown>`** 입니다. V 를 고른 이유("드물게 쓰는 셋째 인자의
편의를 내주고 모든 콜백의 건전성을 산다")를 끝까지 밀면 여기로 옵니다 —
`any` 는 편의를 반쯤 남기려다 건전성 구멍을 새로 낸 셈입니다.

---

## ❓ 2026-10-01 — 뿌리를 판 결과

### AA. Luau 새 솔버의 결함을 업스트림에 보고할까

`arr: ArrView<number>` 를 못 쓰는 뿌리는 **Luau 새 솔버의 결함**이었습니다
(`base/typing-limits.md` "뿌리" 절, `spikes/52`). 최소 재현은 세 줄이고 옛
솔버는 잡습니다. 업스트림 트래커에서 같은 보고를 못 찾았습니다.

보고는 공개 저장소(`luau-lang/luau`)에 글을 올리는 일이라 **사용자 판단**입니다
— 제가 대신 올리지 않습니다. 원하시면 아래 초안을 쓰시면 됩니다.

> **New solver: annotation on a function literal is not checked against an inferred generic when the literal omits a later parameter that mentions the generic**
>
> ```lua
> --!strict
> local function F<T>(x: T, fn: (T, T) -> ()) end
> local text: string = "x"
> F(text, function(v: number) end) -- no error in the new solver; error with --solver=old
> ```
> The upper bound `T <: number` contributed by the annotation is lost when the lambda omits the second parameter (whose type mentions `T` covariantly). Declaring the parameter (`function(v: number, _w)`), using explicit type arguments (`F<<string>>`), or a non-generic signature all report the error. The omitted parameter's shape does not matter (`T`, `{ T }`, `{ read [number]: T }`, `{ get: () -> T }` all reproduce); a contravariant occurrence (`(T) -> ()`) does not. Observed on 0.734.

고쳐지면 `spikes/52` 가 알려주고, 그때 `ArrView<T>` 로 되돌려 구체 주석을
되살릴지 다시 여쭙겠습니다.

**2026-10-02 보강(quad 탐사 B, `papers/05` 4절)** — 판단에 쓰실 새 사실:
- 같은 영역의 **열린 이슈 `luau-lang/luau#2168`**("basic mapping function fails in
  new solver" — 타입 인자 없는 맨 람다가 에러, 2025-12)가 있습니다. 고치려던 커뮤니티
  PR `#2894` 등은 2026-09-08 에 **머지 없이 닫혔습니다**(API 로 확인). 원인으로 짚은
  함수(`tryDispatch(FunctionCheckConstraint)`)가 우리 결함과 같습니다 — 같은 결함이란
  증거는 없습니다.
- quad 도 업스트림 초안을 둘 썼고 **하나도 내지 않았습니다**.
- 우회가 하나 더 확실해졌습니다: **`<<T>>` 를 주면 이 구멍이 막히고 콜백 주석도 필요
  없어집니다**(`spikes/54`). 그래서 이 결함의 실무 비용은 전보다 작습니다.
- 내신다면 초안에 더할 것: Related `#2168`/`#2894`, "그쪽 증상(맨 람다)과 별개 — 주석
  상한 소실" 한 줄, 버전 행렬(analyze 0.734 / luau-lsp 1.69.0).

---

## ❓ 2026-10-01 — 호출 모양을 하나로

### AB. 하나만 제공한다면 콜론인가 네임스페이스인가 — **[2026-10-01 사용자 결정] 네임스페이스만 + 메타테이블 제거, 예외 없음(`Fut` 포함)** — **M0 로 적용**(`1d7ca32`, perf 16-2)

`Fut` 에 대해 사용자: *"이미 루아우에 존재하는 Fut 의 모체인 코루틴도 바깥함수야.
luau 의 강한 경향을 따라가더라도 크게 이질적이지 않은 부분으로 보여."* → M0.


사용자: *"일관성을 유지하고싶어 … 우린 하나만 제공하는게 좋다면, 무엇을
제공해야할까? fast call 이 어차피 안 먹는 유저 라이브러리이니, 편의성으로써 :
를 택할까?"*

| | 네임스페이스만 (+ 메타테이블 제거) | 콜론만 |
|---|---|---|
| **모든 모듈을 덮나** | ✅ — 지금도 전부 됨 | ❌ **`Optional` 은 콜론을 못 가짐**(태그 유니온에 메소드를 얹으면 추론이 무너짐, `spikes/45`) — 일관성이 거기서 깨짐 |
| 원소 접근 속도 | **메타테이블이 없어짐** → 사용자 루프 0.58~0.63x, `Sum` 0.69x, `Max` 0.80x (perf 16절) | 1.59x 세금 유지 |
| 호출 비용 | 콜론보다 18%, `local` 로 받으면 36% 빠름(perf 14절) | 기준 |
| 타입 | `Arr<T>` 가 단순해짐(`ArrIfce` 교집합·재귀 우회·"계약 멤버 재선언 금지" 규칙이 필요 없어짐). 솔버 결함은 남음 → 셋째 인자 `unknown` 유지 | 솔버 결함을 안 밟음 → `ArrView<T>` 로 정밀한 셋째 인자 |
| 쓰는 맛 | 문장으로 나눠 씀(사용자 방향 그대로). 체이닝 없음 | 체이닝 |
| 바꿀 것 | 계약(`ListCore`/`MapCore`/`SetCore`)을 **함수 묶음을 같이 넘기는** 모양으로(Rust 트레이트 vtable 결 — `Algorithm` 은 함수 넷뿐), 테스트·스파이크의 콜론 호출(약 700곳, 기계적) | `Optional` 을 예외로 두거나 다시 설계 |

**제 추천은 네임스페이스만 + 메타테이블 제거** 입니다. 결정적인 건 둘입니다:
(1) **콜론으로는 전 모듈을 일관되게 덮을 수 없습니다** — `Optional` 이 막습니다.
(2) 말씀하신 Luau 의 이유(인덱싱)가 **우리에게도 그대로** 적용됩니다 — fastcall 은
안 먹지만 메타테이블 세금은 먹고, 그게 호출 비용보다 큽니다. 편의(체이닝)는
"데이터 처리는 문장으로" 라는 앞선 방향과 이미 맞바꾼 것이기도 합니다.

정해지면 M3 앞에 **M0 로 넣겠습니다** — M3 가 함수를 스무 개 넘게 더하므로 그
전에 하는 게 쌉니다.

**[2026-10-01 사용자 답 — 조건부 동의]** *"아주 좋은것 같아. 실제로 이러면
recursive 에서 완전히 탈출하고 (함수가 타입 바깥에 있으므로), arr 에 대한 함수
확장이 외부에서 되므로, 라이브러리에 묶여 무언가 더 넣기 어려워지는게 원천적으로
해결되고, 단순 T를 다루는 함수를 추가해나가는 방향으로 확장돼 … quad 는 expr
공간에 놓이는 연산들이라 원라이너가 필요했고, 여기는 속도가 더 생명이라 그냥
statement 안에서 살짝 불편하더라도 이렇게 미는게 더 좋아보여. 예외 없이 모두
바깥에 두는게 나는 좋게 보이고 … luau 는 class 같은게 나오려 하고 있긴 하지만,
타입 상 ecs 형식 구현이 더 나은 곳이라, 우리도 arr 가 엔티티이고, 각 함수가
서비스처럼 되는 구현이 된다면 가장 깔끔해보인다"* — **조건**: 외부자 시선 검토에서
Luau 생태계가 바깥 함수 쪽으로 강하게 기울면 그것으로 간다.

**외부자 검토 결과(sonnet, 2026-10-01)** — 영역별로 갈립니다:

| 영역 | 판정 | 근거 |
|---|---|---|
| **컨테이너·데이터 처리** | **A 강하게 우세** | TableUtil(직접 확인), Sift·Llama·Dash·LuauPolyfill `Array`(기억), 표준 `table` 전부 A. "데이터가 평범한 테이블이고 변환이 목적이면 A" 가 생태계 전반에서 일관됨 |
| 수명·상태 객체 | B 우세 | evaera Promise(`:andThen`), Janitor/Trove, ECS 의 `World` 메소드 — **우리 `Fut` 가 여기 걸림** |
| 전체 | A 약하게 우세 | 객체 영역 반대 증거 + 일부 기억 의존 |

그 밖에: 공식 성능 문서는 `__index` 가 테이블을 직접 가리켜야 덜 느리다고만 하고
"콜론이 공짜" 라고 하지 않음(NAMECALL 절은 reflected userdata 문맥). 메타테이블이
붙은 테이블의 `t[i]` 세금은 문서가 다루지 않음 — 우리 실측과 어긋나지 않음.
class RFC(`syntax-classes`)는 동기가 "`setmetatable` 타입 추론이 어렵다" 로 A 쪽
근거이면서, 구현되면 B 가 좋아질 여지라 양면. 외부자가 든 A 의 약점 "사용자가
메소드를 못 붙임" 은 사용자 관점과 반대 — 바깥 함수는 **누구나 같은 모양으로
더할 수 있어** 오히려 확장이 열립니다.

---

## ❓ 2026-10-02 — quad 탐사에서 나온 질문 (`papers/05`)

### AC. 읽기만 하는 함수의 첫 인자를 읽기 전용(공변)으로 받을까

지금 `Arr` 함수의 첫 인자는 대부분 `ArrData<T>`(읽기·쓰기 인덱서 → **T 에 불변**)
입니다. 그래서 **더 좁은 원소의 배열을 넓은 원소 자리에 못 넘깁니다**:

```lua
local parts = Arr.Of(Instance.new("Frame"), Instance.new("Part"))  -- Arr<Frame | Part>
Arr.Map<<Instance, string>>(parts, function(v) return v.Name end)   -- ❌ 지금
local nums = Arr.Of(1, 2, 3)
Arr.Map<<number?, number>>(nums, function(v) return v or 0 end)     -- ❌ 지금
```

읽기만 하는 함수(`Map`/`Filter`/`Fold`/`Find`/`Some`/`Every`/`Count`/`Sort`(새 배열)/
`Slice`/`Join`/`At`/`Reduce`/`SortBy`/`IndexOf` … 약 40개)는 첫 인자를 이미
`FillHoles`/`Compact` 가 쓰는 `ArrRead<T>`(`read` 인덱서 → **공변**)로 받아도 건전합니다
— 쓰지 않으니까요. quad 의 규칙 *"입력 자리는 `read` 마커, 출력과 self 는 전체형"*
(그쪽 typing-limits 8.11)과 같습니다.

**실측**(사본에서 13개를 바꿔 봄): 위 두 줄이 통과하고, **스파이크 37개가 줄까지 그대로
일치, 테스트 통과**, NEG(결과 타입 불일치, 원소 타입이 아예 다름)는 그대로 잡힘. 내부
에러 둘은 `Clone` 도 같이 바꾸면 사라짐. 런타임·성능은 무관(타입만).

| | (a) 그대로 | (b) 읽기만 하는 함수는 `ArrRead<T>` |
|---|---|---|
| 좁은 배열 → 넓은 자리 | 캐스트 필요 | **됨** |
| 변형 함수(`Push*`/`Insert`/`Fill`/`*Inplace`) | 불변 | **불변 유지**(넓어지면 건전하지 않음) |
| `Concat(nums, holed)` | 에러 | 여전히 에러(`T` 가 첫 인자에서 굳음 — `<<number?>>` 로) |
| `spikes/46` 캐비엇(계약에 유니온 원소) | 남음 | 남음(원인이 다름) |
| 위험(추측) | — | `T` 가 넓은 쪽으로 조용히 정해져 오타가 늦게 잡힐 수 있음 — 측정한 범위에선 안 보임 |
| `ArrRead` 공개 | 아니오 | `export` — 사용자 함수도 같은 규칙을 쓸 수 있게 |

**제 추천은 (b)** 입니다 — M3 에서 함수를 스무 개 넘게 더하기 **전에** 규칙("읽기만 하면
`ArrRead`, 쓰면 `ArrData`")을 정하면 새 함수가 처음부터 맞게 들어갑니다. 적용은 공변
NEG/POS 스파이크를 같이 만들고, 맵·셋(`HashMap` 의 읽기 함수)도 같은 결로 볼지 그때
재서 여쭙겠습니다.

### AD. 콜백이 던지면 무엇을 약속할까 — 예외 안전성의 "계약 대 관측"

`MapInplace` 콜백이 중간에 던지면 배열은 반쯤 바뀐 채입니다. `Sort` 의 비교자가 던지면,
`Fold` 가 던지면, `Fut` 리스너가 던지면 — **지금 어디에도 약속이 적혀 있지 않습니다**
(`src`·`conventions` grep 0건). quad 는 *"던진 뒤의 상태에 대해 약속하는 것은 명시된
것뿐이고 나머지는 **관측 — 계약 아님**, 바뀌어도 BREAKING 아님"* 으로 정하고 문서에
그 표기를 씁니다(`architecture.md` 예외 안전성 절).

**제 추천**: 같은 틀을 씁니다.
- **계약(약속)**: ① 새 배열판(`Map`/`Filter`/`Sort` …)은 콜백이 던져도 **입력(`self`)을
  바꾸지 않음**(지금도 그렇고 비용 0). 단 목적지 `to` 를 넘겼다면 `to` 는 반쯤 쓰인 채일
  수 있음(관측). ② `Fut` 는 리스너가 던져도 **다른 리스너가
  다 돎**(지금 구현, 2026-09-30 리뷰). ③ 라이브러리 자신의 에러는 사용자 줄을 가리킴.
- **관측(약속 안 함)**: `*Inplace` 가 던진 뒤의 내용(반쯤 바뀜), 맵·셋 변형 중 던진 뒤의
  `size` 정합. 복구하려면 비용이 드는 자리라 약속하지 않습니다 — 필요하면 새 배열판을
  쓰라고 안내.

M3 에 들어가기 전에 `conventions.md` 에 한 문단으로 두고, ①은 테스트로 고정하겠습니다.

---

### G. mlua 바인딩 — **보류 확정**

사용자: *"얹혀지는 구조여도 좋아 … 여기에 얽메일 필요는 없어."*
이 프로젝트가 실제 mlua 바인딩 프로젝트에서 Luau 자료형이 미흡해 갈라져
나왔다는 맥락만 기록해둡니다.

### H. `__iter` — **[2026-09-22 해소] 필요 없어졌습니다**

교집합에서 for-in 루프 변수 타입이 죽는 것은 for-in 이 **컨테이너의 인덱서**를
볼 때뿐입니다. **`Iter()` 메소드가 이터레이터 삼중항을 돌려주면** for-in 이
그 함수의 반환 타입을 보므로 타입이 완전히 삽니다(실측: `spikes/37`).

```lua
for i, v in arr:Iter() do … end   -- i: number, v: T — 교집합인데도 정확
```

속도는 `__iter` 와 같은 2.89배인데 한쪽만 타입을 잃으므로, `__iter` 를 달
이유가 없습니다. `Iter()` 로 갑니다.

## [해소됨, 2026-08-22] 패키지 매니저 / 엔트리포인트 / 저장소 구조 / 런타임 / 테스트 방식

**사용자 결정(2026-08-22)**, 전부 `.claude/base/architecture.md` 에 반영됨:

- pesde 도입, 엔트리포인트 `src/init.luau`, 단일 패키지 유지.
- **런타임은 순수 luau — lune 제거.** 나중에 갈아탈 대상은 lute.
- **테스트는 quad 식 `assert` + `print`, 프레임워크 없음.**
- 타입 체크/린트 툴체인(luau-lsp + selene)을 `mise.toml` 로 도입.
- `const` 문법은 쓰지 않음(quad 가 툴링 문제로 이미 버린 문법).

require 경로 규칙은 lune 시절과 **정반대**로 바뀌었으니
`base/architecture.md` 의 "require 경로 규칙" 절 표를 보세요.

## 1. `type function` — **[2026-09-22 사용자 결정] 안 밉니다**

*"quad에서도 이를 사용해보려 했지만 부작용이 너무 많았고 결국 대부분
폐기했어. 타입 함수는 문제가 너무 많기 때문에, 가급적 사용을 피할거야."*

`Tuple.luau` / `TypeUtil.luau` 를 `src/` 에서 내렸습니다 —
*"지금은 지우고, 나중에 보기 위한 리서치 자료로 어딘가에 보관만 하자."*
→ `.claude/research/type-function-experiment/`

**그래서 `src/` 전체가 `--!strict` 가 됐습니다.** 그 둘이 저장소에서
유일하게 검사에서 빠져 있던 코드였습니다.

`conventions.md` 의 "실험적 기능 사용 시 주의" 절을 **"쓰지 않습니다"** 로
바꿔 올렸습니다. 튜플이 정말 필요해지는 구체적인 호출부가 생기면
`papers/03-tuple.md` 를 다시 엽니다.

## [해소됨, 2026-08-22] hash/tree 컨테이너 표현

**사용자 결정**: 크기는 **래퍼 구조로 분리**(`{ data = {...}, size = n }`).
인스턴스에 `n` 을 직접 두면 `hashset<string>` 에서 `add(s, "n")` 이 길이
필드를 덮어쓰기 때문. 그리고 지금 `treeset.luau` 내용은 사실 해시셋이므로
`hashset.luau` 로 옮기고, `treeset` 은 정렬 구조로 새로 작성합니다.
실제 작업은 `.claude/todos.md` 2번 항목.

## [낡음 — 아래 2026-09-21 결정이 뒤집었습니다] tbox 코드 스타일(`const`)

**이식하지 않습니다.** `local` 을 씁니다. 사용자 확인: *"그거 quad 에서는
툴링때문에 버린 문법이야 local 씀"* — quad 가 이미 툴링 문제로 폐기한
문법이고, 실측으로도 lune 0.8.9 가 파싱하지 못했습니다.

## [해소됨, 2026-09-21] `arr(1, 2, 3)` 호출 형태

**사용자 결정**: 순수 네임스페이스(`Arr.Of(1, 2, 3)`)로 갑니다 — *"java 에서
List.of() 형태로 이미 외부에 선례 사례가 존재함"*. 이걸로 모듈 오타 검출까지
같이 얻습니다. 근거와 실측은 `.claude/base/rewrite-plan.md` 1-4 절.

## [해소됨, 2026-09-21] const / selene

**사용자 결정**: `const` 를 채택하고 **selene 을 폐기**합니다. selene 0.31.0
(최신)이 `const` 를 파싱하지 못하고 갈아탈 상위 버전이 없습니다. `pesde` 는
0.7.4 로 올려야 합니다. 예전 기록("quad 가 툴링때문에 버린 문법")은 낡았습니다
— quad 는 2026-09-10 에 `const` 를 채택했습니다.

## 3. 라이선스 — **[2026-09-22 사용자 결정] MIT.** README 는 아직

사용자: *"라이선스는 그냥 MIT로 택하면 돼."*

`LICENSE` 를 넣었습니다(`Copyright (c) 2026 qwreey` — quad 과 같은 표기).
`pesde.toml` 에 `license = "MIT"` 를 달고 `includes` 에 `LICENSE` 를
넣었습니다.

**README 는 아직 안 썼습니다.** `base/docs-plan.md` 에 따라 문서 착수를
API 가 굳은 뒤로 미뤘는데, README 는 그중 가장 먼저 낡는 문서입니다.
지금 쓰면 `Fut`/`Optional` 이 들어올 때 다시 씁니다.

**→ 그래도 지금 원하시면 말씀해 주세요.** 컨테이너 일곱의 공개 표면과
구간 규약, 순회 안내표는 이미 전부 문서화돼 있어 옮기면 됩니다.

**[2026-09-23 사용자 답 → 완료] README 는 지금 간단하게** 썼습니다(루트 `README.md`, 예제는 실제로 돌려 출력 확인) — *"어차피 엄청
바뀌고 문서도 생기고 하면 달라질 게 많아서, 간단하게 쓰는게 맞아보임."*

**`version` 은 안 올립니다.** *"애초에 퍼블리시 되지도 않았고 레지스트리에
없음. … 올려보는게 필요하다 싶어질 때 까지 버전 안 올라도 상관 없음."*
구조가 멀쩡히 잡힐 때까지 `0.1.0` 그대로 둡니다.

## 4. stylua — **[2026-09-22] 도입했습니다**

사용자: *"stylua 는 들여와도 상관 없어. 프로젝트의 mise toml 는 바꿔도 돼."*

- `mise.toml` 에 `stylua = "2.5.2"` 고정
- `stylua.toml` — tbox/quad 와 같은 설정(`Luau`, 120자, 탭 4)
- `scripts/check.sh` 가 `--check` 로 게이트. **바이너리가 없으면 건너뛰고
  알려만 줍니다** — 테스트만 돌려보려는 사람을 막지 않기 위함입니다.

**디스패치 테이블(`Ifce = { … }`)만 `-- stylua: ignore` 로 뺐습니다.**
stylua 는 한 줄에 여럿 있는 테이블 항목을 하나씩 펼치는데, 그러면 `Arr` 의
것이 27줄에서 68줄이 되고 범주별 그룹 주석과의 대응이 흩어집니다.

⚠️ 확인하고 넘어간 것: stylua 가 `;(Ifce :: any).__index = Ifce` 의 **앞
세미콜론을 지웁니다.** 그게 문장 분리용이라 위험해 보였는데, 앞이
`} :: any`(테이블 생성자에 붙은 타입 단언)라 호출의 앞부분이 될 수 없어
모호하지 않습니다. 포맷 후 테스트와 타입 검사 둘 다 통과하는 것으로
확인했습니다.

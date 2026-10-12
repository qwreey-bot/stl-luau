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

⚠️ **셋 중 정렬만 조용히 틀립니다.**(2026-10-02 꼬리표: **M0 6라운드 이후 사실 아님** —
`#` ≠ `n` 이면 checked 로 넘어가고, 같으면 비교 에러로 터집니다. 아래는 결정 당시 기록.) 집계 계열은 구멍에서 터지지만,
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
첫 `nil` 에서 멈춰 구멍을 못 만들고(2026-10-02 꼬리표: **사실 아님** — 그때도 `(키, nil)` 순회자에서
키를 값으로 담는 결함이었고, 고친 뒤로는 구멍을 만듭니다. 문서 블록이 `<<T?>>` 를 안내), `FromFunc` 는 콜백 반환 타입을 따릅니다.
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

**2026-10-06 보강(AC 리뷰)** — 같은 영역의 **세 번째 증상**: 타입 인자도 주석도 없는 맨 람다가
파라미터를 제약하지 않으면(`function(p) return p.name end`) 진단 0건으로 결과가 **자유 타입**이
되어 아무 타입에나 들어갑니다. 라이브러리 없이 재현(`local function Map2<T, G>(xs: { T }, f: (T) -> G):
{ G }` + `Map2({ 1, 2 }, function(v) return v end)` 를 `{ string }` 에), 옛 솔버는 잡음. `spikes/57`.
업스트림에 낸다면 이쪽이 실해가 가장 큽니다(흔한 코드 모양에서 타입이 거짓말).

**2026-10-12 보강(AM 리뷰 — 범위 밖 발견, `spikes/62`)** — 라이브러리 없이 재현되는 조용한 구멍 둘:
(1) **제네릭 함수의 몸통이 타입 변수로 검사되지 않음** — `local function h<V>(v: V): number return v end` 가
0건이고 `h("str")` 은 `"str"`(제네릭이 아니면 잡힘). (2) **문자열 키 리터럴을 인덱서 파라미터에** —
`plain({ x = "bad" })`(`t: { [string]: number }`)가 0건(배열 리터럴은 잡힘). 우리 쪽 영향: 불변 마커는 호출
자리만 지키고(제네릭 안에서 다시 부르는 것은 0건), `HashMap.FromTable<<string, number>>({ x = "bad" })` 도 0건.
**옛 솔버(`--solver=old`)는 둘 다 잡습니다**(직접 대조) — 새 솔버의 회귀입니다.

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

### AC. 읽기만 하는 함수의 첫 인자를 읽기 전용(공변)으로 받을까 — **[2026-10-04 사용자 결정] (b)**

> 사용자: *"아 공변성 문제구나. 그거 괜찮은것 같아. luau 가 const number 같은거라던가 타입 자체에
> 뭔가 정할 수 있는게 없어서 T 자리가 out/in 가능한지 out 만인지 모르기에 ArrRead 를 넣는거 필요한
> 지점은 맞아보여."* — 읽기만 하면 `ArrRead<T>`, 쓰면 `ArrData<T>`. `CompactInplace` 는 같은 모양의
> 다른 이름(`ArrConsumed`)으로. M3 전에 적용.
>
> **적용(2026-10-06)**: 읽기 함수 46개 + 내부 헬퍼 넷을 `ArrRead`. 하나 빗나감 — `Concat`·
> `MergeSorted`(배열 둘 이상을 같은 `T` 로 합침)까지 바꾸니 솔버가 `T = number & string` 을 골라
> 결과가 건전하지 않았습니다(`Arr.Concat(nums, strs)[1]` 이 `number` 에도 `string` 에도 들어감,
> 진단 0건). 이 둘은 `ArrData` 로 되돌렸습니다. 그리고 `ArrConsumed` 를 `ArrRead` 와 같은 타입으로
> 두었더니 읽기 전용으로 빌린 참조가 `CompactInplace` 로 쓰기 가능한 배열을 얻는 구멍(리뷰) — `n` 을
> 읽기·쓰기로 갈라 막음. `spikes/56`(POS 여덟 + NEG 아홉).


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

**2026-10-02 Gemini(agy) 의 바깥 의견**(`audit/agy/2026-10-02-roots.md`): 조건부 찬성, 그리고
제가 놓친 것 하나 — **`CompactInplace` 가 지금 `ArrRead<T?>` 를 받으면서 원본을 고칩니다**
(`?` 를 떼려고 공변 인덱서를 빌린 것). `ArrRead` 를 "읽기 전용" 이라는 이름으로 공개하면 이
자리가 거짓말이 됩니다. 그래서 (b) 를 고르시면 `CompactInplace` 만 **같은 모양의 다른 이름**
(예: 내부 `ArrConsumed<T>` — 입력을 소비한다는 질문 Y 의 뜻)으로 받겠습니다. 모양이 같아 동작·
추론은 그대로이고 이름만 정직해집니다. (Gemini 가 든 "여러 인자에서 `T` 가 첫 인자로 굳는다" 는
위 표의 `Concat` 줄과 같은 것입니다.)

### AD. 콜백이 던지면 무엇을 약속할까 — 예외 안전성의 "계약 대 관측" — **[2026-10-04 사용자 결정] 약속 없음(관측)**

> 사용자: *"콜백이 던지는건 복사가 비용이 드는거라 약속 없고 만일 복사가 필요한 곳이라면 있어도
> 될것 같긴 해. 강하게 보장해야할 이유는 모르겠고 디버깅이 쉬워서."* — 던진 뒤의 상태는 **약속하지
> 않습니다**(quad 와 같은 "관측 — 계약 아님"). 이미 복사가 필요한 구조(새 배열판, 버퍼 정렬 판)가
> 원본을 그대로 두는 것은 **관측**으로 적어 둡니다(디버깅에 도움). 그것을 지키려고 비용을 더하지는
> 않습니다. **불변식(`n`·`size`)도 관측**(2026-10-06 사용자: *"관측으로 두는편이 좋긴 하겠음.
> 안 그럼 나중에 Breaking changes 가 되어버리거든. 그래서 quad 는 계약정본은 따로 있고 온
> 부수효과는 관측으로 두는 편이야"*). → `conventions.md` "예외 안전성" 절.


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

**2026-10-02 Gemini(agy) 의 바깥 의견 — 반대, 그리고 제 추천을 고칩니다.** 요지: "관측" 에
**데이터가 반쯤 바뀌는 것**과 **컨테이너 불변식이 깨지는 것**(`n`·`size`·정렬 순서)을 한데
넣었다 — 뒤의 것은 관측이 아니라 망가진 객체이고, 예외 안전성의 최소선(기본 보장)이다.
옳다고 봅니다. 제가 재 본 것:
- 지금 함수들에서는 **불변식이 이미 지켜집니다** — `TreeMap.Set`/`Remove` 에서 비교자가 던져도
  `Len` 과 실제 키 수가 같음(비교가 변경 전에 끝남), `FilterInplace`·`MapInplace` 도 `n` 이 그대로
  (재현). 그러니 약속하는 비용은 지금은 테스트뿐이고, **M4 의 `Accumulate`/`GetOrInsertWith`
  (콜백이 변경 도중에 불림)를 설계할 때 제약**이 됩니다.
- 예외 하나: `Map(self, fn, to)` 처럼 **목적지 `to`** 에 쌓다가 던지면 `to.n` 밖 칸에 값이 쓰인
  채 남습니다(재현) — "원소는 1..n 만" 위반. 지키려면 `to.n` 을 원소마다 갱신(쓰기 한 번)하거나
  던질 때 지워야(pcall — 비쌈) 합니다.
- Gemini 가 찾은 덤: **버퍼에서 정렬하고 마지막에 되쓰는 판**(`StableSortInplace`/
  `SortByInplace`/`PartialSortInplace`)은 비교자가 던져도 **원본이 그대로**입니다(재현) — 이미
  있는 강한 보장을 저희가 적지 않았습니다.

**고친 추천**:
- **계약 — 기본 보장(전부)**: 콜백·비교자가 던져도 컨테이너의 **불변식**(`n`, `size`, 원소는
  1..n 만, 정렬된 구조의 순서, `Fut` 상태가 셋 중 하나)은 지켜짐. `to` 는 원소마다 `n` 을 갱신해
  지킴(비용은 재서 perf 에).
- **계약 — 강한 보장(일부, 이름으로)**: 새 배열판은 입력을 안 바꿈. 버퍼 정렬 판의 Inplace 는
  던지면 원본 그대로.
- **관측(약속 안 함)**: 그 밖 `*Inplace` 가 던진 뒤의 **내용**(반쯤 바뀐 값들).
- 그대로: `Fut` 리스너 격리, 라이브러리 에러는 사용자 줄.

---

### AE. `Count` 가 두 뜻 — `Arr.Count(a, pred)` 와 `Algorithm.Count(ops, list)` — **[2026-10-06 사용자 결정] 둘 다 `Count`, 술어 옵셔널**

> 사용자가 `Len` 이 트리·셋을 포용하지 못할 수 있다고 짚었고, 제가 "`Len` = 알고 있는 크기 O(1), `Count` = 세어서 구함(술어 옵셔널)" 로 정리하자 *"AE 확인 완료"*. 시제품(`proto/trait`)에 들어 있음.


Gemini 사냥이 짚었습니다(`audit/agy/2026-10-02-hunt.md` 5-1). `Arr.Count` 는 **술어가 참인
원소 수**(C++ `count_if`)이고 `Algorithm.Count` 는 **원소 전체 수**(위치를 끝까지 세기)입니다.
같은 이름이 두 뜻이고, `Arr.Count(a)`(술어 빠뜨림)는 nil 호출 에러입니다.

| | 안 |
|---|---|
| (a) | `Algorithm.Count` → **`Algorithm.Len`** — `Arr.Len`/`HashMap.Len` 과 같은 어휘. `Count` 는 "술어로 센다" 한 뜻만 |
| (b) | 그대로 두고 문서로 |
| (c) | `Arr.Count` 의 술어를 옵셔널로(없으면 전체) — 기본 경로에 분기가 붙음 |

**제 추천은 (a)** 입니다. W 의 어휘(`Has` = 키, `Contains` = 값)처럼 한 단어 한 뜻이고, 공개
사용자가 없어 지금이 쌉니다.

### AF. 술어는 얼마나 깊이 볼까 — 그리고 함수 묶음 계약의 무게 — **[2026-10-06] 트레이트로 합침 → AG**

> 사용자: quad 식 Brand 의 원래 의도는 인터페이스 구현 여부와 비테이블 값에도 안전한 판별이었고, 위조 방지는 신경 쓰지 말자. → 타입 단위 트레이트로 시제품(`papers/06`, 질문 AG). 아래는 그 전 판단 재료.


Gemini 뿌리 분석 1·5(`audit/agy/2026-10-02-roots.md`). 둘 다 "규약이 늘어나는 패턴" 에 대한
바깥 의견이라 함께 올립니다. **지금 바꾸자는 추천은 아닙니다** — 바깥 시선이 이렇게 본다는
것을 판단 재료로.

**1. 술어의 깊이.** 지금 술어(`isArr` 등)는 태그 + 최상위 필드 전부의 타입을 봅니다(M0 4라운드에
제가 그은 경계 — 리뷰마다 한 겹 깊은 위조가 나와서). Gemini 의 의견: C++/Rust STL 은 메모리를
조작한 위조를 방어하지 않는다(UB). 술어는 "사용자의 단순 실수(nil, 숫자, 다른 컨테이너)" 를
가르는 용도여야 하고, 예약어 태그를 붙인 위조는 UB 로 선언하면 **술어를
`rawget(v, TAG) == true` 하나로** 줄일 수 있다 — 그래야 Deque·Multiset 마다 위조 방어가
복제되지 않는다.
- 비용 쪽 실측(quad 탐사 A, perf 18절 근처): 태그 + 모양 379ms vs 태그만 215ms(1000만 호출) —
  술어 적중이 약 1.8배 빠름.
- 잃는 것: `{ __fut__ = true }` 같은 위조를 `Fut.Chain` 이 입양해 `AwaitSafe` 가 던졌던 종류를
  "계약 밖" 으로 돌림(지금은 `isFut` 가 막음).

**2. 함수 묶음 계약(`Types.ListOps`/`MapOps`/`SetOps`).** 지금 이것을 쓰는 것은
`Algorithm` 의 넷(`IndexOf`/`Count`/`Keys`/`Values`)뿐이고, 맵·셋 계약은 타입 인자를 셋 다
명시해야 합니다. Gemini 의 의견: Luau 에는 비용 0 추상화가 없어 간접 호출 세금이 붙고 추론도
약하니, 계약을 축소하고 컨테이너별 함수로 가는 편이 실용적이다. 제 관찰: 계약은 M0 에서 "바깥
에서 확장" 근거의 일부였고, M4~M6(Deque·OrderedMap)이 들어오면 쓰는 곳이 늘 수 있습니다 —
**M5 에서 Deque 가 계약을 실제로 쓰는지 보고 다시 여쭙는 것**을 제안합니다.

---

## ❓ 2026-10-06 — 트레이트 시제품 (`papers/06-traits.md`)

### AG. 트레이트 시제품을 들일까 — **[2026-10-06 사용자 결정] 들임, 키는 `__type`**

> 사용자: *"1. 들이자. 비용이 감당 가능한 정도이고 효과가 좋아. 2. … 어차피 어디선가 콜리전이
> 난다면 그냥 `__type` 으로 알아보기 좋은걸 써도 되는거 아닐까 … 3. 동의. 4. 동의. 오히려 호환
> 안 되고, 소스 구현은 하나가 되도록 유도하는게 이로워보임"* — 재 보니 `__t`/`__type` 은
> 컨테이너 여섯 모양에서 ±5% 엇갈려(어느 쪽도 고르게 낫지 않음) `__type` 으로. 본 저장소에
> 들임(`596436a`, `c1f54d4`).

AF 대화에서 정한 방향("값에는 타입 토큰, 구현은 트레이트가 — 위조는 막지 않음")을 브랜치
`proto/trait` 에 만들었습니다. `check.sh` 통과, 생성 비용 같음, 술어 적중 0.62~0.66배, 공용
알고리즘은 호출당 ~36ns 더(긴 리스트에선 같음). 자세한 것은 페이퍼 06.

정하실 것:
1. **들일까** — 제 추천은 예. M3 가 함수를 더하기 전에(태그 체계 전체를 바꾸는 일이라).
2. **타입 키 이름 `__t`** — 해시 배치 실측으로 고른 이름입니다(`__type` 은 3~7% 느림). 짧아서
   읽기엔 덜 친절합니다. 괜찮으신지.
3. **트레이트 마커는 타입에만 있는 필드**(런타임엔 없음) — quad `StateMarker` 와 같은 결정입니다.
   사용자 컨테이너는 생성 함수에서 한 번 캐스트가 필요합니다.
4. **의미 변화 둘**: 라이브러리 사본이 둘이면 서로의 값을 그 종류로 안 봄(예전엔 문자열 태그라
   호환), 직렬화했다 되읽은 테이블은 그 종류가 아님(예전엔 태그가 살아 있으면 받음).

AD 의 남은 확인(불변식 — `n`·`size` — 도 관측으로 둘지)도 같이 답해 주시면 M3 전에 정리합니다.

---

### AH. 트레이트 API 이름 — 다른 계열의 눈으로 (2026-10-06, `audit/agy/2026-10-06-trait-review.md`) — **[2026-10-06 사용자 결정] `TokenOf` 로, 나머지 그대로**

> 사용자: *"TokenOf 동의. quad 도 type** 를 포기했고 Brand 로 이름을 지을 수 밖에 없었던 이유기도
> 해.(type 함수도 있으니까) Impl 은 그대로 둬도 될 것 같아. Trait 아래 두고 문서로 설명도 괜찮게
> 보여."* — `Trait.TypeOf` → `Trait.TokenOf`. `Impl`, `Trait.NewType`/`Trait.Types` 는 그대로.
> 교훈: Lua 내장(`type`/`typeof`)과 겹치는 `type…` 이름은 피합니다.

Gemini 가 이름을 셋 짚었습니다(이 레포의 이름은 Claude 계열이 지었습니다). 지금 쓰는 곳이 적어
바꾸기 쌉니다.

| 지금 | 지적 | 제 의견 |
|---|---|---|
| `Trait.TypeOf(v)` | 문자열이 아니라 **토큰**을 돌려주는데 Lua 내장 `type`/`typeof` 와 헷갈림 | **`TokenOf`** 로 — 동의합니다 |
| `Trait.Impl(trait, token, impl)` | Rust 예약어 축약을 함수 이름으로, 인자도 `impl` | `Impl` 은 짧고 Rust/Luau 사용자에게 익숙해 그대로도 괜찮다고 봅니다. 바꾼다면 **`Implement`** |
| `Trait.NewType` / `Trait.Types` | 토큰은 트레이트를 구현하지 않는 `Heap`/`Fut` 도 쓰는 바탕인데 `Trait` 밑에 있음 | 모듈을 둘로 쪼개면(`Token.New`, `Trait.New`) 깔끔하지만 require 가 하나 늘어납니다. **그대로 두고 문서로** 쪽을 추천 |

## ❓ 2026-10-07 — M3(Arr 빈 조각)

### AI. M3 의 의미 넷 — **[2026-10-07 사용자 결정] 전부 추천안**

| 질문 | 결정 | 근거 |
|---|---|---|
| `Scan(a, init, fn)` 의 길이 | **n — `init` 미포함**: `Scan({1,2,3}, 0, +) = {1,3,6}` | C++ `inclusive_scan`. 누적합 직관, 입력과 위치가 맞음 |
| `Zip`/`ZipWith` 길이가 다르면 | **짧은 쪽** | Rust·Python. 결과 원소에 구멍이 안 생김 |
| 빈 `PopBack`/`PopFront`, 범위 밖 `SwapRemove` | **`nil`, 아무것도 안 바꿈** | `At` 의 "단일 조회 범위 밖은 nil", `table.remove` |
| `Inplace` 쌍 | **원소 타입이 그대로인 거르기만**: `Dedup`·`Unique`·`TakeWhile`·`DropWhile` | 타입이 바뀌는 `Scan`·`Zip`·`Chunks`·`Windows` 와 둘을 돌려주는 `Partition` 은 새 배열만 |

### 🔁 M3 에서 **제가 정한 것들** (되돌리기 쉬움)

- **`Zip` 의 짝은 `Pair<T, U> = { first, second }`**(질문 W2 초안 — "이견 없던 것은 초안대로").
  공개 타입 `stl.Pair`.
- **`Unique` 의 같음 = 테이블 키의 같음**(테이블은 정체성, `__eq` 안 봄, `0 == -0`). 테이블 키가
  될 수 없는 둘: **`nil` 은 하나로**(첫 구멍만 남음), **NaN 은 서로 다름**(모두 남음 — `Dedup` 의
  `==` 와 같은 결). `key` 는 구멍에도 부릅니다(콜백 계열 규약 — 구멍은 `nil` 그대로).
- **`Dedup` 의 `eq(kept, item)`** 은 **마지막으로 남긴 원소**와 비교(Rust `dedup_by`, C++ `unique`).
  이웃끼리 비교하면 `near` 같은 비추이적 `eq` 에서 사슬이 통째로 하나가 됩니다.
- **`MaxBy`/`MinBy`·`MinMax` 는 구멍을 건너뜀**(집계 — `Max`/`Min` 처럼, 구멍에 `key` 를 안 부름).
  같은 값·키는 처음 것. 반환은 원소만(위치는 안 줌 — `Max` 와 같게).
- **`IndexOf`/`LastIndexOf`/`Contains` 는 구간 인자 없음**(`Find` 처럼). 구간이 필요하면
  `Some(a, fn, start, last)`. 비교는 `==`(NaN 못 찾음, `nil` 은 첫 구멍).
- **`Chunks`/`Windows` 의 크기**: 0 쪽으로 자르고 1 미만·NaN 은 에러(Rust 는 0 에서 패닉), 무한대는
  "전부 한 조각"/"빈 결과". 조각·창은 사본(지연 뷰 없음 — papers/04).
- **`SwapRemove(idx)`** 는 `At` 규약(음수, 소수 0 쪽, NaN 에러). 순서를 지키는 한 칸 제거는 따로
  두지 않았습니다 — `EraseInplace(a, i, i)`.
- `ZipWith` 의 콜백은 `(a, b, index)` — 배열 뷰는 안 넘깁니다(두 배열 중 어느 것인지 애매).

## 🔁 2026-10-07 — M4(맵·셋)에서 **제가 정한 것들** (되돌리기 쉬움 — 사용자 주무시는 동안)

### AJ. M4 의 모양 — 아침에 확인 부탁

| 무엇 | 정한 것 | 다른 길 |
|---|---|---|
| `HashMap.Merge` | **새 맵** + `MergeInplace`(제자리) 쌍 — `Inplace` 관례. 같은 키는 `other` 가 이김 | W 표는 "`Merge(other)` 덮어 합치기" 만 정함. 제자리 하나만 둘 수도 |
| `Merge` 의 범위 | **`HashMap` 끼리만**(불변 — 같은 `K, V`) | `TreeMap.Merge`, 트레이트(`Trait.Map`)로 아무 맵이나 받기 — 부르는 곳이 보이면 |
| 맵 변형의 반환 | ~~`Retain`·`MergeInplace` 는 `()`~~ → **[2026-10-12] 자기 자신**(`Clear` 를 자기 자신으로 통일한 AM 의 흐름 — `Arr.Retain` 과 같은 이름이 다른 반환이던 것을 맞춤). `Set` 만 `MapOps` 계약대로 `()` | — |
| `Accumulate(m, k, v, combine)` | 없으면 `v`, 있으면 `combine(old, v)`. **바뀐 값을 `V?` 로** 돌려주고 `nil` 이면 지움(Java `Map.merge`) | 반환 없음 |
| `GetOrInsert(m, k, default)` | 있으면 그 값(안 바꿈). `default` 가 `nil` 이면 아무것도 안 넣음 | `nil` 이면 에러 |
| `GetOrInsertWith(m, k, make)` | `make(key)` 를 **없을 때만**. `make` 가 같은 키를 넣었으면(재귀 메모이즈) 크기를 다시 셈 — 결과는 `make` 의 반환이 이김, `make` 가 `nil` 이면 그때 맵에 있는 값 | — |
| `Retain` 콜백 | 맵 `(key, value)`, 셋 `(item)`. TreeMap/TreeSet 은 정렬 순서로 부름. 콜백 안에서 같은 컨테이너를 바꾸는 것은 ~~Hash 는 지우기 안전, Tree 는 크기를 바꾸면 에러~~ → **[2026-10-12 사용자 결정, AL 1] UB — 검사 없음**(Hash 쪽 지우기의 크기가 맞는 것은 관측) | — |
| `LowerKey`/`HigherKey` | **엄격**(같은 키는 안 줌) — `FloorKey`/`CeilingKey` 의 짝. 셋은 `LowerItem`/`HigherItem`(셋의 `FloorItem` 어휘) | Java `lowerKey`/`higherKey` 와 같음 |
| `PopFirst`/`PopLast` | 맵은 **`Record<K, V>?`**(꺼낸 레코드를 그대로 — 이미 빠졌으니 복사 안 함), 셋은 `T?`. `PopFirst` 는 정렬 배열이라 O(n) | `(K?, V?)` 두 값으로 돌려주기 |
| `Arr.GroupBy`/`CountBy`/`KeyBy` | **`HashMap` 을 돌려줌**(`HashMap<K, Arr<T>>`·`<K, number>`·`<K, T>`) → **`Arr` 가 `HashMap` 을 require**(한 방향, 순환 없음) | 평범한 테이블 `{ [K]: … }` 을 돌려주면 의존이 없음 |
| 묶기의 키 | `(element) -> K`(`SortBy` 모양), 원소당 한 번. `GroupBy`·`CountBy` 는 구멍에도 부름(`KeyBy` 는 구멍을 건너뜀 — 아래). **키가 `nil`·NaN 이면 에러** | 그 원소를 건너뛰기 |
| `KeyBy` 의 같은 키 | **나중 것이 이김**(lodash·Kotlin). **구멍은 건너뜀**(`key` 도 안 부름 — 처음엔 그 키를 지웠는데 결과가 구멍 위치에 좌우돼 리뷰 1라운드 의견으로 바꿈) | 처음 것 |

## 🔁 2026-10-07 — M5(`Deque`)에서 **제가 정한 것들** (되돌리기 쉬움 — 확인 부탁)

### AK. `Deque` 의 모양

| 무엇 | 정한 것 | 다른 길 |
|---|---|---|
| ⭐ **리스트 진입점이 Deque 를 받을까**(todos M5 메모) | **안 받음 — 지금 그대로**. `Arr.FromTable`·`Deque.FromList`·`Fut.All` 등 `Common.listLength` 진입점은 `__type` 이 `Arr` 가 아니면 에러. 넘기려면 `Deque.ToArr(d)`. Deque 는 `Trait.List` 를 구현하니 **`Algorithm`(트레이트를 보는 쪽)은 받음** | 진입점이 `Trait.List` 구현이면 `FirstIndex`/`NextIndex`/`Get` 으로 읽기 — 일반적이지만 진입점마다 느린 갈래가 생김 |
| 표현 | **링 버퍼**(perf 24절 — 길이 유지 큐에서 두 인덱스보다 3배 빠름). 길이 필드는 `n` 이 아니라 **`size`**(물리 칸이 감겨 있어 `{n, [1..n]}` 로 읽히면 틀림) | — |
| 이름 | `PushBack`/`PushFront`/`PopBack`/`PopFront`(Arr 와 같음), 엿보기 **`Front`/`Back`**(Rust·C++), `At`(Arr 규약), `ToArr` | Java `peekFirst`/`peekLast` |
| 반환 | 넣기·`Clear` 는 자기 자신(`Arr` 처럼), 꺼내기는 `T?`(비면 `nil` — 질문 AI) | — |
| 읽기 함수의 공변(`ArrRead` 같은 `DequeRead`) | **안 둠** — 전부 `DequeData`(불변). 맵·셋과 같음 | 질문 AC 를 Deque 에도 넓히기. ⚠️ **리뷰어 의견(1라운드): 넓히자** — `Deque<number>` 를 `Deque<number?>` 받는 함수에 못 넘김(재현). AC 의 근거(읽기는 원소에 공변)가 맵·셋보다 같은 리스트인 Deque 에 더 직접 들어맞고, 사용자 코드가 없는 지금이 가장 쌈. 저도 동의 쪽입니다 — 정해 주시면 적용(`At`/`Front`/`Back`/`Len`/`Empty`/`Iter`/`ToArr`/`Clone`/계약 함수) |
| 칸 수 | `New(capacity?)`(최소 4, `Arr` 길이 정책), 두 배로 늘리고 **줄이지 않음**(Rust 와 같음 — `Clone` 이 원소 수에 맞춤) | `ShrinkToFit` |
| 안 넣은 것 | 위치에 쓰기(`SetAt`), `Insert`/`Remove`(가운데), `Rotate`, 스트림(`Map` 등) — 부르는 곳이 보이면 | — |

## ❓ 2026-10-07 아침 — 밤 작업 전체를 가로지른 리뷰(`43b65a9..96e3a68`)에서 나온 일관성

재현된 결함은 0. 문서 표류는 고쳤고(conventions 에 Deque `size`·콜백 중 변경·의존 방향, architecture 표, README·GEMINI
숫자), Deque 를 리스트 진입점에 넣을 때 에러가 `ToArr` 를 안내하게 했습니다. 남은 것은 모양 선택이라 여쭙니다.

### AL. 모듈 사이 어긋남 — 맞출까

> **[2026-10-12 사용자 답]** 1: *"이런 종류의 재진입이나 검사는 없는걸로. UB로 둔다."* 2: 동의. 3: *"의미 달라서
> 그게 맞고."* 4: *"백로깅 상 두고 필요해지면 꺼내 넣어보자."* 5: Clear 트레이트 + 자기 자신 반환을 더 파 보기로 →
> 아래 **AM**. 1 의 적용(Tree `Retain` 의 크기 검사 걷기)도 같은 날 확인받아 넣음(`0576bfe`).

| # | 어긋남 | 제 추천 |
|---|---|---|
| 1 | **콜백이 같은 컨테이너를 바꿀 때**: Tree 는 에러, Hash 는 지우기만 안전, **`Arr`(Retain·`*Inplace`·Map …)은 아무 말 없이 틀릴 수 있음**(`Retain` 콜백이 `PopBack` 하면 `Arr<number>` 에 구멍, 리뷰 재현) | **문서로 "약속 없음"**(conventions 에 지금 적어 둠). 검사를 넣으면 원소마다 `n` 읽기 — 핫 루프라 안 넣음 |
| 2 | **키 콜백이 `nil` 을 돌려줄 때**: `GroupBy`/`CountBy`/`KeyBy` 는 사용자 줄 에러, `SortBy`/`MaxBy`/`MinBy` 는 라이브러리 줄의 원시 비교 에러, `Unique` 는 `nil` 을 값으로 묶음 | **그대로 + 문서 한 줄**. 비교 계열의 원시 에러는 `Sort`(섞인 타입)와 같은 결이고 검사는 원소마다 비용. 묶기는 맵 키라서, `Unique` 는 값 비교라서 각각 맞음 |
| 3 | **양끝 엿보기 이름이 넷**: `Arr.At(1)`/`At(-1)`, `Deque.Front`/`Back`, `TreeMap.First`/`Last`, `Heap.Peek` | 정렬 구조의 `First`/`Last`(Java `TreeMap`)와 덱의 `Front`/`Back`(Rust·C++)은 뜻이 달라 **그대로**. 갈아 끼우기를 원하시면 `Deque` 를 `First`/`Last` 로 |
| 4 | `TreeMap` 에 `GetOrInsert(With)`·`Accumulate` 가 없음(HashMap 만) | **부르는 곳이 보이면**(정렬 맵에서 넣기는 O(n) 이라 쓰임이 다름) |
| 5 | `Clear` 반환: `Arr`·`Deque` 는 자기 자신, 맵·셋·`Heap` 은 `()`(Heap 은 `Push` 는 자기 자신인데 `Clear` 는 `()` — 원래 있던 것) | 리스트 계열 = 자기 자신, 맵·셋 = `()` 로 **그대로**. `Heap.Clear` 만 자기 자신으로 맞출지는 취향 |

### AM. `Clear` 를 트레이트로, 자기 자신을 돌려주게 — 시제품 결과 (2026-10-12, AL 5 에서) — **[2026-10-12 사용자 결정] 추천대로**

> 사용자: *"확인 … clear 같은 경우도 확인. 흐름 그대로 따라가면 될 것 같아. al 검사 빼는것도 다 봤어. 전부 동의해"*
> — **(가) 적용**(`Clear` + 같은 흐름으로 맵·셋 `Retain`·`MergeInplace` 도 자기 자신), **(나) 적용**(불변 마커
> `MapMarkerMut`/`SetMarkerMut`/`ListMarkerMut`, `spikes/61`), **(다) M6 때 같이**(`Trait.Collection`, 넓은 맵
> 계약 — 사용자가 *"hash 인지 tree 인지 몰라도 만질 수 있게 하는 Map trait"* 을 물음: `Trait.Map` 은 있지만
> `Get`/`Set`/`Records` 뿐이라 얇음). AL 1 도 적용(Tree `Retain` 검사 걷음, UB).

사본에서 시제품을 만들어 쟀습니다(저장소는 그대로). 사용자 생각: *"Clear trait 을 두고 … tree map 이든 hash map
이든 clear 이후 재빌딩 하는게 가능해지는 느낌 … 타입도 공짜고(바깥에서 타이핑을 하니까) self 돌려줘도 되지 않나"*.

**1. 자기 자신 반환은 공짜입니다.** 맵·셋·힙의 `Clear` 를 `(): ()` 에서 자기 자신으로 바꿔도 `src`·`tests` 타입 에러
0건, 테스트 통과, 속도 같음(HashMap `Set`×2 + `Clear` 30만 번: 21.2ms → 21.1ms). 다른 타입으로 받으면 에러.

**2. 트레이트로 올리는 것도 섭니다.** `Trait.Collection = { Len, Clear }`(Java `Collection` 결)를 일곱 컨테이너가
구현하게 하고 `Algorithm.Clear(c)`·`Algorithm.Len(c)` 를 두었습니다. 타입은 세 모양을 비교:

| 모양 | 같은 타입을 돌려줌 | 컨테이너 아닌 것을 막음 |
|---|---|---|
| **`<C>(c: C & CollectionMarker): C`** | ✅ `HashMap<string, number>` 그대로 | ✅ 리터럴·숫자 (Fut 처럼 토큰은 있고 구현이 없는 것은 런타임 에러) |
| `<C>(c: C): C` | ✅ | ❌ 아무거나 통과 |
| `(c: CollectionMarker): ()` | — | ✅ |

비용: 트레이트 경유는 호출당 ~40ns(작은 맵에서 직접 호출의 1.6배 — perf 21절의 `IndexOf` 36ns 와 같은 크기).
`todos` M6 메모("`MapOps` 엔 `Len`/`Has` 가 없음")도 이 트레이트가 받습니다.

**3. ⚠️ 그런데 "비우고 다시 채우기" 를 쓰다가 기존 구멍을 찾았습니다 — 마커를 받아 *쓰는* 제네릭은 건전하지 않습니다.**
트레이트 마커가 `read`(공변)라, 마커를 받아 `Set`/`Add` 하는 사용자 제네릭 함수에서 값 타입이 조용히 넓어집니다.
**지금 저장소에서 재현**(10-06 트레이트 설계부터 — conventions 가 권하는 바로 그 모양):

```lua
local function put<K, V>(m: stl.MapMarker<K, V>, k: K, v: V)
	const ops = Trait.ImplOf(Trait.Map, m)
	if ops then ops.Set(m, k, v) end
end
put(hm, "x", "bad")              -- hm: HashMap<string, number> — 진단 0건
local n: number? = HashMap.Get(hm, "x")   -- 런타임엔 "bad"
```

`HashSet<number>` 에 문자열을 넣는 `add<T>(s: SetMarker<T>, item: T)` 도 같습니다. AC 에서 본 것(공변으로 빌린
참조가 쓰기를 얻음)과 같은 메커니즘이고, 라이브러리 자신의 `Algorithm` 은 읽기만 해서 지금은 사용자 코드에서만 납니다.

**[2026-10-12 넣은 뒤 리뷰 두 라운드(결함 1 → 0)]** ① `ListMarkerMut` 의 팬텀이 `(E) -> E` 뿐이라 **위치**는
공변이었음 → `(E, I) -> (E, I)`. ② 규칙을 "쓰는 제네릭" 에서 **"타입 변수로 받은 키·위치·값을 컨테이너에
넘기는 제네릭"** 으로 — 키를 넘기는 조회도 읽기 마커면 `TreeMap<string, …>` 에 숫자 키가 0건으로 넘어감.
`==` 비교만 하는 값(`IndexOf`)과 위치가 타입 변수가 아닌 조회는 읽기 마커로 건전. ③ 범위 밖: 새 솔버 구멍 둘
(제네릭 몸통 미검사, 문자열 키 리터럴 → 인덱서 — `spikes/62`, 질문 AA 보강). 불변 마커는 그래서 **호출
자리만** 지킵니다(제네릭 안에서 다시 부르는 잘못된 쓰기는 0건).

**막는 법(시제품으로 확인)**: 쓰는 알고리즘용 **불변 마커**를 따로 둡니다 — 데이터 타입에 함수 타입 팬텀을 하나 더
(`read __mapMut: (K, V) -> (K, V)` — 인자·반환 양쪽에 나와 불변, tbox 식), `MapMarkerMut<K, V>`/`SetMarkerMut<T>`
가 그것을 요구. 넣으니 위 넷(`put` 값·키, `add`, `Refill` 을 감싼 사용자 제네릭)이 전부 에러, 읽는 알고리즘의
공변(`Algorithm.Keys<<string | number, number>>(hm)`)은 그대로. (팬텀을 읽기·쓰기로 선언하는 길도 막긴 하는데
사용자가 팬텀 필드에 쓰는 것이 통과해 버려 함수 타입 쪽이 낫습니다.)

**제 추천**
- (가) 일곱 컨테이너의 `Clear` 를 **자기 자신 반환으로 통일** — 공짜이고 AL 5 의 어긋남이 사라집니다.
- (나) **불변 마커는 Clear 와 무관하게 넣기** — 지금도 있는 구멍이고, 쓰는 공용 알고리즘을 하나라도 두려면 먼저 필요.
- (다) `Trait.Collection`(`Len`·`Clear`) + `Algorithm.Clear`/`Len`/`Refill` 은 **부르는 곳이 보이면** — 타입은 서지만
  지금 부르는 코드가 없고, 넣으면 일곱 모듈이 트레이트 둘씩 등록합니다. 다만 M6(`Multiset`·`OrderedMap`)가 이
  트레이트를 쓰게 될 가능성이 커서 "M6 때 같이" 가 자연스럽습니다.

### AN. 맵·셋의 `nil`·NaN 키 (2026-10-12, 백로그 점검) — ❓ 해시 쪽은 여쭙니다

전수로 넣어 봤습니다(`HashMap`·`HashSet`·`TreeMap`·`TreeSet` 의 키를 받는 함수 전부 × `nil`·NaN).

**🔁 트리 쪽 — 제가 정해서 넣었습니다(되돌리기 쉬움)**: ⚠️ **빈 `TreeMap` 에 `nil` 키가 조용히 들어갔습니다**
(비교가 한 번도 안 일어나서). 그 뒤 `Get`·`Set`·`Remove` 전부가 비교자 안(`Common.luau` 줄)에서
`attempt to compare nil < number` 로 죽었고, `TreeSet.Add(s, nil)`·`TreeMap.FromRecords({ { value = 1 } })` 도 같았습니다.
타입으로는 못 넣지만 타입 없는 데이터(`t.id` 가 런타임에 `nil`)로는 들어옵니다. 이미 있던 NaN 정책과 같게 했습니다:

| | `nil`·NaN 을 넣기 | `nil`·NaN 으로 조회·삭제 |
|---|---|---|
| `TreeMap.Set`·`FromRecords` | 에러 `TreeMap: nil key` / `NaN key`(사용자 줄) | — |
| `TreeSet.Add` | 에러 `TreeSet: nil item` / `NaN item`(예전엔 `TreeMap: NaN key` — 부른 적 없는 모듈 이름) | — |
| `Get`·`Has`·`Remove`·`Floor`·`Ceiling`·`Lower`·`Higher`·`Range…` | — | "없음"(비교자를 부르지 않음) — `HashMap.Get(m, nil)` 과 같음 |
| `TreeSet.FromList` 의 `nil` | 구멍이라 건너뜀(리스트 진입점 규약 — 그대로) | — |

잃는 것: `nil` 을 아는 비교자를 주고 `TreeMap<K?, V>` 에 `nil` 키를 담는 쓰임(전엔 우연히 됐음). `FirstKey`·
`FloorKey` 의 `K?` 가 "없음" 과 구분되지 않고 `HashMap` 도 못 담아 막는 쪽으로 정했습니다. 비용은 잡음 안(perf 26절).
`Heap` 은 그대로 둡니다 — 비교자가 사용자 것이라 에러가 사용자 코드에서 나고, `Deque` 처럼 `nil` 을 아는 `less` 로
`Heap<T?>` 를 쓸 수 있습니다.

**❓ 해시 쪽 — 검사를 넣을까요**: `HashMap.Set`·`GetOrInsert(With)`·`Accumulate`·`FromRecords`, `HashSet.Add`·
`FromList`(NaN)·`Of`(NaN) 는 Lua 의 원시 에러(`table index is nil` / `is NaN`)가 **라이브러리 줄**을 가리킵니다(에러
규약 밖). 상태는 안 망가집니다(먼저 쓰고 세므로). 조회·삭제는 지금도 "없음".

| 안 | 내용 | 비용 |
|---|---|---|
| **(a) 그대로 — 제 추천** | 원시 에러를 둠. conventions 에 "해시 계열의 `nil`·NaN 키는 Lua 의 에러 그대로(규약의 예외)" 로 적음 | 0 |
| (b) 검사 | `Common.raise("HashMap: nil key")` — 사용자 줄 | `Set` 이 조밀한 숫자 키에서 **1.09~1.10배**, 해시 경로에선 0~7%(perf 26절) |

(a) 를 추천하는 이유: 가장 뜨거운 함수에 원소마다 비용이 붙고(AL 1 에서 "검사 없음" 으로 정하신 것과 같은 결), 메시지
자체는 이미 분명하며(`table index is nil`), 타입이 `nil` 을 막고, 스택 추적에는 사용자 줄이 같이 나옵니다. 트리와
다른 점은 **조용히 망가지지 않는다**는 것입니다 — 트리는 넣는 순간엔 아무 일 없다가 나중에 다른 곳에서 터졌습니다.

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

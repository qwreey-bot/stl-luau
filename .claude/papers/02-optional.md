# 페이퍼 — `Optional` (`nil` 구멍을 값으로 만들기)

**상태: 미결. 구현하지 않았습니다.**

> 사용자(2026-09-22): *"`Optional` 은 **nil hole** 이 이유야. sort 나 여러
> 처리가 필요한 부분에서 nil 이 문제가 되는 부분이 있다면 그 부분을 처리를
> 돕는 유틸이였어. 테이블 또는 특정 자료형으로써 **자리를 차지하면서**
> 옵셔널한 구조임을 밝히는 도구야. … 루아우에서도
> `{ isSome: true } | { isSome: false }` 에 대한 타입 분기 처리가 잘 될거야."*

---

## 1. 이게 푸는 문제 — `T?` 가 못 하는 것

Luau 에 `T?` 가 이미 있는데 왜 또 두는가. **`T?` 는 테이블 안에서 자리를
차지하지 못합니다.**

```lua
local a = Arr.Sized(3)
a[1], a[3] = 1, 3        -- a[2] 는 구멍
a:Sum()                  -- 구멍을 건너뛰어야 함 (13% 비용)
a:SortUnchecked()        -- ⚠️ 조용히 잘림
```

`nil` 은 **"없음" 과 "자리 자체가 없음" 을 구분하지 못합니다.** 그래서 이
저장소의 모든 집계·정렬이 원소마다 구멍 검사를 달고 있고, `*Unchecked` 를
따로 둬야 했습니다(`question.md` C).

**`Optional<T>` 는 그 자리를 값으로 채웁니다.** `a[2] = Optional.None` 이면
구멍이 아니라 **"없음이라는 값"** 이 들어가고, `n` 과 `#` 가 어긋나지 않으며,
`table.sort` 가 조용히 잘리지 않습니다.

## 2. 모양 — 사용자가 이미 정해준 것

```lua
export type Optional<T> = { isSome: true, value: T } | { isSome: false }
```

**태그된 유니온입니다.** Luau 의 타입 좁히기가 이 모양에 잘 듭니다:

```lua
if opt.isSome then
    print(opt.value)   -- 여기서 value 가 보임
end
```

⚠️ **실측이 필요합니다.** 이 저장소의 교집합 타입들과 섞였을 때
(`Arr<Optional<number>>` 의 `Map` 체이닝 등) 좁히기가 살아 있는지는
**아직 안 쟀습니다.** 유니온은 quad 의 §8.9(유니언 검사 결함)에서 문제를
냈던 자리이기도 합니다.

### 사용자의 `Result` 는 다른 모양이었습니다 (실물 확인)

사용자가 레퍼런스로 든 `qwreey-js` 의 `Result` 를 받아서 봤습니다
(`packages/ts-util/src/result.ts` + `docs/result.md`). **불리언 태그가
아니라 "한쪽이 비어 있음" 으로 좁힙니다:**

```typescript
export type Result<T, U> =
  | { result: undefined; error: U }
  | { result: T; error: undefined };
```

문서가 밝히는 이유: *"두 값 중 하나가 반드시 `undefined` 이므로, 단순한
truthiness 검사만으로 타입스크립트의 제어 흐름 분석이 완벽하게 좁혀낸다."*
쓰는 쪽은 `if (parseResult.error) { … }` 한 줄입니다.

**Luau 로 옮기면** `nil` 이 거짓이라 같은 모양이 됩니다:

```lua
export type Result<T, E> = { result: nil, error: E } | { result: T, error: nil }
```

**그래서 `Optional` 도 두 모양이 후보입니다:**

**사용자가 그 뒤 `Result` 를 고쳤다고 해서 클론해 확인했습니다** —
지금은 **태그가 붙어 있고 양쪽 슬롯이 항상 존재**합니다:

```typescript
export type Result<T, U> =
  | { result: undefined; error: U;         ok: false }
  | { result: T;         error: undefined; ok: true  };
```

두 갈래 모두 **세 필드를 다 갖는 것**이 요점입니다 — 객체 모양이 균일해서
좁히기와 접근이 모두 단순해집니다. 짧은 별칭 `Ok`/`Err` 도 같이 export
합니다.

그래서 `Optional` 도 **태그형**으로 갑니다:

```lua
export type Optional<T> = { isSome: true, value: T } | { isSome: false, value: nil }
```

빈칸형(`{ value: T } | { value: nil }`)은 필드가 하나 적지만, **`T` 자체가
`nil` 일 수 있는 일반형에서 "값이 nil 인 Some" 과 `None` 을 구분하지
못합니다.** 이 저장소에서는 `T` 가 `nil` 인 경우가 바로 문제의 원인이라
그 구분이 필요합니다.

**→ 착수 전 첫 일: 스파이크로 두 모양의 좁히기를 재고, 교집합 컨테이너와
섞였을 때(`Arr<Optional<number>>:Map(…)`) 체이닝이 사는지 같이 재기.**

## 3. 갈림길 — 테이블인가 싱글턴인가

`None` 을 어떻게 표현하느냐가 비용을 가릅니다.

| 안 | `Some(x)` | `None` | 대가 |
|---|---|---|---|
| **A. 둘 다 테이블** | `{ isSome = true, value = x }` | `{ isSome = false }` (싱글턴 공유) | `Some` 마다 테이블 하나. 96바이트(실측 1절 기준) |
| **B. 값을 그대로, None 만 센티넬** | `x` 그대로 | 공유 센티넬 테이블 | 할당 0. 다만 `T` 가 그 센티넬일 수 없고, 타입이 `T \| Sentinel` 이라 좁히기가 A 만 못함 |
| **C. 둘 다 싱글턴 + 값 분리** | — | — | 자리를 못 차지하므로 탈락 |

**A 가 사용자가 말한 "자리를 차지하면서 옵셔널함을 밝히는" 것에 맞습니다.**
B 는 싸지만 `isSome` 필드가 없어 좁히기가 약합니다.

**→ [2026-09-22 사용자 결정] 태그형(A)으로 갑니다.**
*"빈칸은 T자체가 무엇이냐를 몰라서, 태그형을 밀어."*

## 4. 표면 초안

Rust 의 `Option` 과 사용자의 `Result` 어휘를 섞되, 이 저장소 규약을 따릅니다.

| 이름 | 무엇 |
|---|---|
| `Optional.Some(v)` / `Optional.None` | 생성. `None` 은 **싱글턴** |
| `Optional.Of(v)` | `v` 가 `nil` 이면 `None`, 아니면 `Some(v)` — `T?` 에서 건너오는 문 |
| `:Unwrap()` | 값. 없으면 **에러** |
| `:UnwrapOr(fallback)` | 값 또는 기본값 |
| `:Map(fn)` | `Optional<G>` — `None` 이면 그대로 |
| `:Filter(pred)` | 조건에 안 맞으면 `None` |
| `:ToNil()` | `T?` 로 내보내는 문 |
| `stl.isOptional(v)` | 술어 |

### ⭐ 컨테이너와 어떻게 이어지는가 — 여기가 본론

`Optional` 을 왜 **이 저장소에** 두는지의 답입니다.

| 후보 | 무엇 |
|---|---|
| `Arr:Compact()` | `Optional`/구멍을 걸러내고 조밀하게 |
| `Arr:Fillholes()` | 구멍을 `None` 으로 메워 **`n` 과 `#` 를 맞춤** → 그 뒤로는 `*Unchecked` 를 안전하게 쓸 수 있음 |
| `Arr:GetOptional(i)` | `Get` 이 `T?` 를 주는 것과 달리 자리 유무를 구분 |
| `HashMap:GetOptional(k)` | 같은 이유 |

**`Fillholes` 가 특히 값집니다.** 구멍을 한 번 메우고 나면 `*Unchecked` 의
전제("구멍이 없다")가 **보증되고**, 그 뒤로는 1.83배 빠른 경로를 안심하고
쓸 수 있습니다. 즉 `Optional` 은 checked/unchecked 갈림의 **세 번째 답**입니다.

**→ [2026-09-22 사용자 결정] 이 방향으로 갑니다.** *"될것 같음."*
그래서 `Optional` 은 단독 유틸이 아니라 **컨테이너 성능 경로의 일부**입니다.

## 6. ⭐ 남은 것 — 이름

`Some`/`None` 인가 `Just`/`Nothing` 인가, 아니면 다른 것인가.
**Luau 생태계에서 무엇이 관용인지 아직 모릅니다.**

⚠️ **`None` 은 quad 과 겹칩니다.** quad 은 `q.None` 을 **센티넬**로 쓰고
(`export type None = { read __quadNone: true }`), 코드베이스에서 **1105회**
나옵니다. 뜻이 다릅니다 — quad 의 것은 *"이 프로퍼티를 건드리지 말라"* 는
표시이고 우리 것은 *"값이 없다는 값"* 입니다. 두 라이브러리를 같이 쓰면
`q.None` 과 `stl.None` 이 나란히 서는데 뜻이 달라 헷갈립니다.

후보들:

| 짝 | 출처 | 걸리는 점 |
|---|---|---|
| `Some` / `None` | Rust, OCaml, F# | **quad 충돌** |
| `Just` / `Nothing` | Haskell, Elm | Luau 사용자에게 덜 익숙할 수 있음 |
| `Some` / `Empty` | — | `Empty()` 메소드와 겹침(이 저장소에 이미 있음) |
| `Present` / `Absent` | — | 길고 관용이 아님 |
| `Value` / `Void` | — | `Void` 는 다른 뜻으로 읽힘 |

### 조사 결과 (2026-09-22, 외부자 시선)

**Luau/Roblox 생태계에 확립된 선례가 없습니다.** 로컬 레퍼런스
(fusion, vide, charm, tbox, rbvm) 전체를 뒤져도 값을 감싸는 Optional 류가
**전무**합니다. tbox 의 `Optional` 은 스키마 검증 규칙이지 값 래퍼가
아닙니다.

**웹에서 찾은 유일한 실물**: `util.luau`(lukadev-0) — `Option.Some(...)`,
`Option.None`, `:isSome()` / `:unwrap()` / `:unwrapOr()` / `:match{}`.
**Rust API 를 거의 그대로 옮긴 것**입니다.

**Lua 쪽에는 대상 자체가 없습니다.** Lua 표준 라이브러리에 Optional 개념이
없고 `nil` + 다중 반환(`ok, err`)이 관용구입니다. 그래서 이 저장소의
*"호스트 언어 관례를 우선한다"* 원칙이 **적용될 자리가 아닙니다** — 닫힌
구간처럼 이미 있는 관용을 따르는 게 아니라, **빈 자리를 새로 채우는
상황**입니다.

### `None` 충돌 실측

- **문법 충돌은 없습니다.** `q.None` 과 `stl.None` 은 서로 다른 테이블
  필드입니다.
- **뜻이 충돌합니다.** quad 의 것은 `table.freeze` 된 **신원 센티넬**로
  *"이 프로퍼티에 손대지 마라"* 는 **명령**이고(부수효과가 있음), 우리
  것은 *"이 칸엔 값이 없다"* 는 **순수 데이터 태그**입니다. 같은 저자의 두
  라이브러리에서 `None` 이 다른 종류의 "없음" 을 뜻하게 됩니다.
- 사용 빈도(quad 1105회, 먼저 자리잡음)를 보면 **이름의 소유권은 이미
  quad 에 있다**고 보는 게 맞습니다.
- ⚠️ `Void` 도 이미 quad 에서 다른 뜻(no-op 리트랙터, 9회)으로 쓰입니다.
  `Value`/`Void` 짝도 같은 문제입니다.
- `Present`/`Absent` 는 quad 에 **0건** — 충돌 없음.

### 후보 재평가

| 짝 | 충돌 | 선례 | 걸리는 점 |
|---|---|---|---|
| `Some` / `None` | quad 와 **뜻** 충돌 | `util.luau` 하나 | 사실상 Rust 직역 |
| `Present` / `Absent` | **없음** | 없음 | 길고 낯섦. `Optional.Present(x)` 가 무겁습니다 |
| `Some` / `Empty` | ⚠️ **우리 자신과 충돌** | 절반 | `arr:Empty()` 가 이미 "비었는가" 술어입니다 |
| `Just` / `Nothing` | 없음 | 없음 | Haskell 잔향이 더 강함 |
| `Value` / `Void` | quad 와 충돌 | 없음 | — |

조사자 추천은 **`Present`/`Absent`**(1순위), `Some`/`Empty`(2순위)이고
태그 필드도 `isPresent` 로 맞추자는 것입니다. `ok`(저자의 `Result`)에
맞출 필요는 없다는 판단 — *"`ok` 는 성공/실패 의미론이고 Optional 은
있음/없음 의미론이라 도메인이 다르다"*.

### 제 읽기는 조금 다릅니다

조사자가 `Some`/`Empty` 를 2순위로 뒀는데, **`Empty` 는 우리 자신과
겹칩니다** — 모든 컨테이너에 `:Empty()` 술어가 이미 있습니다. 남의 것보다
자기 것과 겹치는 쪽이 나쁩니다. **2순위에서 빼야 합니다.**

그리고 *"선례가 없다"* 는 결론은 **`util.luau` 가 `Some`/`None` 을 쓴다**는
사실과 같이 읽어야 합니다. 생태계에 하나뿐인 실물이 그걸 쓰고 있다면,
그게 가장 가까운 관용입니다.

**→ 남은 선택은 사실상 둘입니다:**

| | `Some` / `None` | `Present` / `Absent` |
|---|---|---|
| 익숙함 | ✅ 하나뿐인 Luau 선례와 같음 | ❌ 새로 만드는 이름 |
| quad 과 | ⚠️ 뜻이 겹침(네임스페이스는 갈림) | ✅ 깨끗함 |
| 길이 | ✅ 짧음 | ❌ `Optional.Present(x)` |
| *"Rust 를 베끼지 않는다"* | ❌ | ✅ |

**→ 미결: 둘 중 어느 쪽인가요?**

## 5. 안 하는 것

- **`Result<T, E>` 는 지금 안 만듭니다.** 사용자가 레퍼런스로 든 것이지
  요구한 것이 아닙니다. 에러 처리는 `Fut` 의 `Catch` 와 겹치므로, 만든다면
  `Fut` 과 같이 보는 게 맞습니다.
- **`Optional` 을 반환 타입의 기본으로 쓰지 않습니다.** `Get`/`Find`/`Max`
  는 지금대로 `T?` 를 돌려줍니다 — Luau 관례이고, 감싸면 `if x then` 이
  `if x.isSome then` 이 됩니다. `Optional` 은 **구멍이 문제가 되는
  자리에서만** 씁니다.

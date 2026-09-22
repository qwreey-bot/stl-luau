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

| 모양 | 좁히기 | 자리 차지 |
|---|---|---|
| **태그형** `{ isSome: true, value: T } \| { isSome: false }` | `if opt.isSome then` | ✅ 둘 다 테이블 |
| **빈칸형** `{ value: T } \| { value: nil }` | `if opt.value ~= nil then` | ✅ 둘 다 테이블 |

빈칸형은 `Result` 와 어휘가 통일되고 필드가 하나 적습니다. **다만 `T` 자체가
`nil` 일 수 있는 일반형에서는 "값이 nil 인 Some" 과 `None` 이 구분되지
않습니다** — 태그형은 그 구분이 됩니다. 이 저장소에서는 `T` 가 `nil` 인
경우가 바로 문제의 원인이므로, **태그형이 맞아 보입니다.**

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

**→ 질문 1: A 로 갈까요? `Some` 마다 테이블 하나를 치르는 것이 받아들여지나요?**

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

**→ 질문 2: 이 방향이 맞나요?** 맞다면 `Optional` 의 우선순위가 올라갑니다
(단독 유틸이 아니라 컨테이너 성능 경로의 일부가 되므로).

## 5. 안 하는 것

- **`Result<T, E>` 는 지금 안 만듭니다.** 사용자가 레퍼런스로 든 것이지
  요구한 것이 아닙니다. 에러 처리는 `Fut` 의 `Catch` 와 겹치므로, 만든다면
  `Fut` 과 같이 보는 게 맞습니다.
- **`Optional` 을 반환 타입의 기본으로 쓰지 않습니다.** `Get`/`Find`/`Max`
  는 지금대로 `T?` 를 돌려줍니다 — Luau 관례이고, 감싸면 `if x then` 이
  `if x.isSome then` 이 됩니다. `Optional` 은 **구멍이 문제가 되는
  자리에서만** 씁니다.

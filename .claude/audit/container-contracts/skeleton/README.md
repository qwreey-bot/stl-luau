# 스캐폴딩 골격 — 동작하는 최소 구현

```bash
luau-analyze .claude/audit/container-contracts/skeleton/check.luau   # 정확히 6건
luau          .claude/audit/container-contracts/skeleton/check.luau   # 4줄 출력, 에러 없음
```

4개 파일로 된 **실제로 도는** 골격입니다. `src/` 재작성이 이 모양을 따릅니다.

```
Types.luau        계약만. 말단 모듈 — 아무것도 require 하지 않음
Algorithm.luau    계약만 아는 공용 알고리즘. Types 만 require
Arr/init.luau     구현. Types 를 require, 계약을 만족
check.luau        검증
```

## 확인된 것

| | 결과 |
|---|---|
| 공용 알고리즘이 구현을 모른 채 동작 | ✅ `IndexOf`/`Count` 가 `Arr` 을 모름 |
| 계약을 별도 모듈에서 require → 선언 순서 누수 사라짐 | ✅ |
| 타입 변환 체이닝 (`Map` 2단) | ✅ |
| 음성 대조군 5종 | ✅ 전부 검출 |
| 규모 증상 | **0건** |
| 런타임 | ✅ 실제로 돔 |

## ⭐ 설계 규칙 두 개 (실측으로 얻음)

### 1. 계약이 주는 멤버를 구현 인터페이스에서 **다시 선언하지 말 것**

```lua
-- ❌ 이러면 메소드 타입이 통째로 죽습니다
type ArrIfce = { Get: typeof(Get), FirstIndex: typeof(FirstIndex), … }
export type Arr<T> = ArrData<T> & ArrIfce & Types.ListCore<T, number>
```

`ArrIfce.Get` 의 `self` 는 `Arr<T>` 이고 `ListCore.Get` 의 `self` 는
`ListCore<T, number>` 라 교집합이 충돌합니다. 실측 증상: `a:NoSuchMethod()`
조차 안 잡히는데 **진단은 0건**입니다(인덱싱 `a[1]` 은 멀쩡해서 더 헷갈립니다).

```lua
-- ✅ 계약이 주는 것은 빼고 고유 메소드만
type ArrIfce = { PushBack: typeof(PushBack), Map: typeof(Map), Len: typeof(Len) }
export type Arr<T> = ArrData<T> & ArrIfce & Types.ListCore<T, number>
```

런타임 테이블에는 당연히 `Get` 등이 들어 있어야 합니다 — **타입 선언에서만**
빼는 것입니다.

### 2. Luau 의 폴더 모듈 require 규칙 (실측)

`Foo/init.luau` 안에서:

| 쓰려는 것 | 올바른 경로 | 틀린 경로 |
|---|---|---|
| 폴더 **안** 형제 (`Foo/Bar.luau`) | **`@self/Bar`** (또는 `./Foo/Bar`) | — |
| 폴더 **밖** 형제 (`Types.luau`) | **`./Types`** | `../Types` ❌ 실패 |

`init.luau` 가 곧 디렉터리 자신이라 `.` 이 **부모**를 가리킵니다. 직관과
반대입니다. `../` 는 한 단계 더 올라가 버려서 실패합니다.
기존 `src/init.luau` 가 이미 `@self/arr` 을 쓰고 있었습니다.

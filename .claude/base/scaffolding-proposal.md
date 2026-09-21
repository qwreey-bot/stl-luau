# `src/` 스캐폴딩 제안서

**상태: 제안 — 사용자 검토 대기.** 결정되면 `rewrite-plan.md` 로 흡수하고
이 파일은 지웁니다.

근거: `.claude/audit/container-contracts/`(계약·골격·모듈분할 실측),
`.claude/audit/arr-type-redesign/`(타입 설계), `.claude/base/container-design-notes.md`
(Java/Rust/C++ 와 예전 과제에서 얻은 것).

---

## 0. 요약

```
src/
  init.luau              공개 표면 재수출 (배럴)
  Types.luau             ⭐ 공유 계약만. 말단 모듈 — 아무것도 require 안 함
  Common.luau            비교/해시 기본 구현, compareTo 등 런타임 헬퍼
  Algorithm.luau         계약만 아는 공용 알고리즘 (IndexOf/Count/Keys …)
  BSearch.luau           컨테이너를 모르는 순수 알고리즘

  Arr.luau               배열 — ListCore<T, number> 를 만족
  HashMap.luau           해시 맵 — MapCore<K, V>, Hasher<K> 주입
  HashSet.luau           HashMap 위에 얹음 (단방향)
  TreeMap.luau           정렬 맵 — MapCore<K, V>, Comparator<K> 주입
  TreeSet.luau           TreeMap 위에 얹음 (단방향)
  Heap.luau              Comparator<T> 주입
  Tuple.luau             (실험) 현행 유지
```

**컨테이너 하나 = 파일 하나**입니다. 폴더로 쪼개는 건 **필요해질 때** 하고,
그 방법은 이미 실측해뒀습니다(6절).

---

## 1. 왜 이 모양인가 — 실측이 강제한 것

### 1-1. 계약은 말단 모듈에

`Types.luau` 는 **다른 컨테이너를 require 하지 않습니다.** 그래서:

- 순환 require 가 원천적으로 불가능합니다.
- **선언 순서 의존 누수가 사라집니다.** 같은 코드인데 선언 순서만 바꾸면
  제네릭이 `{K & string}` 으로 새는 걸 확인했습니다(진단 0건). 다른 모듈에서
  이미 풀린 타입으로 들어오면 이 문제가 안 생깁니다.
  (`audit/container-contracts/REPORT.md` 3절, quad §8.21 과 같은 계열)

### 1-2. 계약이 주는 멤버를 구현 인터페이스에서 다시 선언하지 않는다

```lua
-- ❌ ArrIfce 에 Get/FirstIndex 를 넣고 ListCore 도 교집합하면
--    self 타입이 달라 충돌 → 메소드 타입이 통째로 죽음 (진단 0건!)
-- ✅ 계약이 주는 건 빼고 고유 메소드만
type ArrIfce = { PushBack: typeof(PushBack), Map: typeof(Map), … }
export type Arr<T> = ArrData<T> & ArrIfce & Types.ListCore<T, number>
```

런타임 테이블에는 당연히 `Get` 등이 들어갑니다 — 타입 선언에서만 뺍니다.

### 1-3. 교집합 필수 (`setmetatable<>` 아님)

메소드 30개에서 `setmetatable<>` 은 `pending-expansion` 1700여 건으로
무너집니다. 한도 플래그 6종 전부 무효. 교집합은 63개까지 클린합니다.

**대가**: 교집합 타입은 `for-in` 루프 변수의 타입을 잃습니다. 그래서 `__iter`
는 보류이고, 순회는 `for i = 1, arr.n`(가장 빠르고 타입도 삶) 또는 콜백
계열을 안내합니다.

### 1-4. 메소드는 이름 붙은 함수 + `typeof` 나열

인라인 제네릭으로 쓰면 `Map` 의 반환이 `Unifiable<Error>` 로 샙니다.

---

## 2. 각 파일이 무엇을 담는가

### `Types.luau` — 공유 계약 (말단)

```lua
export type Comparator<T> = (a: T, b: T) -> number
export type Hasher<T> = (value: T, maxHash: number) -> number
export type Record<K, V> = { key: K, value: V }

-- 위치 타입을 파라미터로 뺀 순차 컨테이너.
-- 배열은 I = number, 연결은 I = 노드 → 같은 알고리즘을 공유하고,
-- "연결 리스트에서 인덱스로 접근" 이 애초에 표현 불가능해집니다.
export type ListCore<E, I> = { Get, FirstIndex, LastIndex, NextIndex, PrevIndex }

export type MapCore<K, V> = { Get, Set, Records }
export type SetCore<T> = { Add, Has, Remove, Items }
```

**레코드 타입을 계약에 포함**합니다. 예전 과제에서 이걸 안 했다가 구현마다
`iter()` / `orderedIter()` 로 이름이 갈라졌고, 다음 판에서 타입 파라미터로
통일한 전례가 있습니다.

### `Algorithm.luau` — 계약만 아는 공용 알고리즘

`IndexOf` / `Count` / `Keys` / `Values` 같이 **계약만으로 쓸 수 있는** 것.
소스에 한 번만 존재하고 모든 구현이 공짜로 씁니다.

### `Common.luau` — 런타임 헬퍼

`compareTo` 어댑터, 기본 해시 함수(정수/문자열), 기본 비교자.
**얇은 어댑터**로 둡니다 — 컨테이너 본체에서 타입별 분기를 없애기 위함입니다.

### 컨테이너 파일들

각각 자기 `XxxData<T>` / `XxxView<T>` / `XxxIfce` / `Xxx<T>` 를 선언하고
공개 네임스페이스 테이블을 반환합니다(`Arr.Of`, `Arr.Sized` …).

---

## 3. Set 을 Map 위에 얹는다 (단방향)

Rust 와 Java 가 실제로 하는 것입니다(`Set = Map + 더미값`). C++ 는 공통 엔진의
두 인스턴스화인데, Luau 에는 템플릿 트레이트가 없어 부자연스럽습니다.

`HashSet → HashMap`, `TreeSet → TreeMap` **단방향**이라 순환이 없습니다.

**이름도 가릅니다**(예전 과제 관례): 셋은 `Add`/`Has`/`Remove`,
맵은 `Set`/`Get`.

---

## 4. 순회를 어떻게 제공하는가

예전 과제의 진화가 답을 줍니다: 콜백 기반 순회를 트리 인터페이스에 default
메소드로 박았다가 인터페이스가 비대해졌고, 다음 판에서 **스택 기반 반복자**로
빼면서 트리 인터페이스는 `isLeaf`/`getHeight` 만 남겼습니다.

우리 계획:

| 층 | 무엇 |
|---|---|
| 계약 | `ListCore` 의 `FirstIndex`/`NextIndex` — 이것만으로 순회가 됨 |
| 공용 | `Algorithm` 의 `IndexOf`/`Count` 등이 그 위에 |
| 컨테이너 | `Fold`/`FoldRight`/`Reduce`/`FoldUntil` 콜백 계열 |
| 사용자 | `for i = 1, arr.n` — 가장 빠르고 타입도 삶 |

`__iter` 는 **보류**(교집합에서 타입이 죽음). 나중에 추가해도 breaking 아님.

---

## 5. 전략 주입

해시·비교를 **생성 함수의 인자로** 받습니다.

```lua
local m = HashMap.New(Common.hashString)
local t = TreeMap.New(Common.compareNumber)
```

예전 과제에서 해셔가 2-메소드 인터페이스의 5줄짜리 어댑터였고, 그 덕에 맵
본체가 키 타입을 몰라도 됐습니다. **상호교체가 실제로 되는지 테스트로 고정**할
것 — 예전 과제에서 인덱스 하나만 해시맵→트리맵으로 바꿨는데 호출부가 타입
선언 한 줄 말고는 그대로였던 게 계약이 제대로 섰다는 증거였습니다.

---

## 6. 파일이 커지면 어떻게 쪼개는가 (실측해둠)

**컨테이너 타입을 반환하는 메소드는 그 타입이 선언된 곳과 같은 모듈에서
보여야 합니다.** 순진하게 쪼개면 체이닝이 **타입과 런타임 양쪽에서** 깨집니다
(`Key 'Map' not found`, `attempt to call missing method`).

쪼개야 한다면 **quad 방식**: `Types` 에 시그니처만 있는 스텁 함수를 두고
`typeof` 로 인터페이스를 만들면, 구현 파일이 컨테이너 타입을 반환할 수
있습니다. 실측으로 체이닝·런타임 모두 정상. **비용은 시그니처 중복.**

지금은 쪼개지 않습니다 — `Arr` 이 새 설계로 1200줄 안팎일 텐데, 비교 대상
표준 라이브러리들의 같은 파일이 1800~4000줄입니다.

### require 경로 (직관과 다름, 실측)

| 어디서 | 폴더 **안** 형제 | 폴더 **밖** 형제 |
|---|---|---|
| `Foo/init.luau` | `@self/Bar` | `./Types` (`../Types` ❌) |
| `Foo/Bar.luau` | `./Baz` | `../Types` (`./Types` ❌) |

---

## 7. 마이그레이션 순서

1. `src/` → `src-old/`(gitignore 대상 아님, 커밋해서 대조용으로 남김)
2. `Types.luau` / `Common.luau` / `Algorithm.luau` 세우고 골격 검증 통과
3. `Arr.luau` 재작성 + `tests/spec.arr.luau`
   — `.claude/arr-worklist.md` 체크리스트를 따라감
   — `.claude/audit/known-bugs/repro.luau` 가 **0 실패**가 되어야 함
4. `HashMap` → `HashSet` → `TreeMap`(+`BSearch`) → `TreeSet` → `Heap`
5. `src-old/` 삭제

---

## 8. 이 제안이 **안 다루는 것**

- `Fut`/`Optional` — 별도 판단 필요
- `Record.luau` — 지금 타입 별칭 한 줄. `Types.Record` 로 흡수하면 파일이
  없어집니다. 그래도 되는지 확인 필요
- `Tuple`/`TypeUtil` — 실험적 `type function`. 현행 유지(`--!nocheck`)
- mlua 바인딩 — 얹는 구조로 나중에

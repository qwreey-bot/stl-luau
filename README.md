# stl-luau

Roblox 엔진 언어 **Luau**용 표준 라이브러리 스타일 유틸리티 모음입니다.
`Arr`/`HashMap`/`HashSet`/`TreeMap`/`TreeSet`/`Heap` 같은 컨테이너와 그
위에서 쓰는 알고리즘을, Luau 문법과 성능 특성(`table.move` 기반 벌크 연산,
메타테이블 없는 평범한 테이블 등)에 맞춰 다시 짠 것입니다.

> **상태: 초기 단계, 미출시.** 막 전면 재작성을 마쳤고 공개 API 는 아직
> 계속 바뀝니다. pesde 레지스트리에 게시돼 있지 않습니다 — 지금은 이
> 저장소를 직접 서브모듈/복사해서 쓰는 것만 가능합니다. 이 문서도
> 나중에 제대로 된 문서 사이트가 생기면 다시 씁니다.

## 컨테이너

| 모듈 | 무엇 |
|---|---|
| `Arr<T>` | 배열. 함수 76개 — map/filter/slice, 안정·부분·키 정렬과 선택 등 |
| `HashMap<K, V>` | 해시 맵. Luau 테이블을 그대로 쓰되 크기를 따로 추적 |
| `HashSet<T>` | `HashMap` 위에 얹은 셋 (`Add`/`Has`/`Remove`) |
| `TreeMap<K, V>` | 정렬을 유지하는 맵. 정렬 배열 + 이분 탐색으로 구현 |
| `TreeSet<T>` | `TreeMap` 위에 얹은 정렬 셋 |
| `Heap<T>` | 이진 힙. 기본은 최소 힙, 비교자를 뒤집으면 최대 힙 |
| `Optional<T>` | `nil` 구멍을 값으로 — `Optional.Present(v)` / `Optional.Absent` |
| `Fut<T...>` | 코루틴 래퍼(프로미스). 스케줄러 주입, 다중 반환 |
| `BSearch` | 정렬된 일반 배열 위의 이분 탐색 (컨테이너를 모름) |
| `Common` | 비교자 어댑터 (`LessThan` ↔ `Comparator` 변환) |
| `Algorithm` | 계약(`Types.ListOps` 등 함수 묶음)만 아는 공용 알고리즘 |

## 사용 예시

```lua
local stl = require(path.to.stl_luau)
local Arr = stl.Arr

local numbers = Arr.Of(5, 2, 8, 3, 6)

-- 짝수만 골라 10배 하고, 큰 것부터 정렬합니다
local evens = Arr.Filter(numbers, function(v: number): boolean
	return v % 2 == 0
end)
local scaled = Arr.Map(evens, function(v: number): number
	return v * 10
end)
local result = Arr.Sort(scaled, function(a: number, b: number): boolean
	return a > b
end)

print(stl.isArr(result), result.n) -- true  3
print(Arr.Join(result, ", "))      -- 80, 60, 20
print(Arr.Join(numbers, ", "))     -- 5, 2, 8, 3, 6   (원본은 그대로)

-- 인자로 타입을 알 수 없는 생성자는 명시적 타입 인자로
local ages = stl.HashMap.New<<string, number>>()
stl.HashMap.Set(ages, "철수", 20)
print(stl.HashMap.Get(ages, "철수")) -- 20
```

**모든 연산은 네임스페이스 함수입니다(`Arr.Map(a, fn)`).** 콜론 메소드
(`a:Map(fn)`)는 없습니다 — 컨테이너는 메타테이블 없는 평범한 테이블이고,
Luau 표준 라이브러리(`table`/`buffer`/`coroutine`)와 같은 모양입니다. 그래서
원소 접근에 메타테이블 세금이 없고(배열 루프 0.57~0.70배), 누구나 같은
모양으로 함수를 더할 수 있습니다. 뜨거운 루프에서는 `local Map = Arr.Map`
으로 받아 쓰면 가장 빠릅니다.

콜백 파라미터에는 타입을 적어 주세요(`function(v: number)`). 지금 Luau 는
제네릭 호출에 넘긴 함수 리터럴의 파라미터 타입을 추론해주지 않습니다.

## 알아두면 좋은 것들

- **구간은 닫힌 구간 `[start, last]`**이고 음수 인덱스(`-1` = 마지막)를
  지원합니다. 범위를 넘으면 clamp, 뒤집힌 구간은 조용히 빈 결과 —
  `string.sub`와 같은 규약입니다.
- **길이는 `n` 필드가 진실**입니다. Lua 기본 `#`는 안 씁니다 — 희소 배열과
  꼬리 `nil`을 피하기 위함입니다.
- **`nil` 구멍은 타입에 드러납니다.** 구멍이 있을 수 있는 배열은
  `Arr<number?>` 이고(`Arr.Of(1, nil, 3)`, `Arr.Sized<<number?>>(5, nil)` —
  `Sized` 의 채울 값은 필수), 콜백도 `number?` 를 받습니다. 합계·정렬처럼
  구멍 없는 배열을 요구하는 연산 앞에서는 `Compact()` 나 `FillHoles(v)` 로
  `?` 를 뗍니다.
- 그래도 집계·정렬(`Sum`/`Max`/`Sort` 등)의 기본은 구멍을 건너뛰는 **checked**
  판입니다(캐스트나 `a[i] = nil` 로 타입이 어긋날 때의 그물). 구멍이 없음을
  보장할 수 있으면 더 빠른 `*Unchecked` 판(`SumUnchecked`, `MaxUnchecked`,
  `SortInplaceUnchecked` …)을 씁니다.
- 제네릭을 추론할 단서가 없는 자리(인자 없는 생성자 등)는 명시적 타입 인자
  `f<<T>>(...)` 를 씁니다 — 예: `stl.HashMap.New<<string, number>>()`.
- 벌크 연산은 손 루프 대신 `table.move`/`table.create`를 씁니다.

## 개발

타입 체크 + 테스트 + 음성 대조군 배터리를 한 번에 돌리려면:

```sh
./scripts/check.sh
```

`luau`/`luau-analyze` 0.734가 필요합니다 (`mise install`로 `mise.toml`에
고정된 버전을 받을 수 있습니다). 순수 `luau` CLI로만 돌아가고, 테스트는
`luau tests/run.luau`로 직접 실행할 수도 있습니다.

## 라이선스

[MIT](./LICENSE)

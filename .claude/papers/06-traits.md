# 06. 트레이트 — 값에는 타입 토큰, 구현은 트레이트가 (2026-10-06 시제품)

사용자(AF 대화): *"quad 식 Brand … 내가 저걸 바깥에 값을 두고자 했던건 interface 의 사용 가능
유무를 보거나(대상이 impl 되는지) 숫자나 userdata 등에서 필드를 읽고 쓸 수 없더라도 문제가
없다는점 … 단순 테그로 두면 두개 이상의 impl 을 처리하기 힘들어져."* → *"유저가 막 의도적으로
배껴간다는 솔찍히 막을 이유 모르겠음. 위조 방지는 생각하지 말자."* → *"TraitImplsMap = { [entity]
-> TraitImpls } … 식이 된다던가 해야할까?"*

**시제품**: 브랜치 `proto/trait`(worktree `/code/Projects/stl-luau-proto`, 커밋 `8e8885f`).
`check.sh` exit 0(스파이크 38개 — 55 새로).

## 1. 모양

```lua
-- 값(엔티티)에는 타입 토큰 하나 — 예전 문자열 태그 자리, 생성 비용 같음
local a = Arr.Of(1, 2)          -- a.__t == Trait.Types.Arr (얼린 공유 테이블)

-- 트레이트 = 공유 테이블 하나가 [토큰] = 구현(모듈 테이블)을 듦 — quad Brand 의 [값] = true 자리
Trait.Impl(Trait.List, Trait.Types.Arr, Arr)        -- 모듈을 불러올 때 한 번
Trait.Impl(Trait.Map, Trait.Types.HashMap, HashMap)

-- 공용 알고리즘은 구현을 손으로 받지 않음 — 토큰으로 찾음
Algorithm.IndexOf(a, 2)      -- 예전: Algorithm.IndexOf(Arr, a, 2)
Algorithm.Keys(m)            -- 예전: Algorithm.Keys<<HashMap<string, number>, string, number>>(HashMap, m)

-- 바깥에서: 자기 트레이트를 우리 종류에, 자기 종류를 우리 트레이트에
local Show = Trait.New<<{ read Show: (any) -> string }>>("Show")
Trait.Impl(Show, Trait.Types.Arr, { Show = function(a) return `Arr({a.n})` end })
Trait.ImplOf(Show, a).Show(a)                       -- 구현 타입이 그대로 돌아옴
local MyType = Trait.NewType("MyMap")
Trait.Impl(Trait.Map, MyType, myOps)                -- 이제 Algorithm.Keys(mine) 가 됨
```

말씀하신 `TraitImplsMap[entity][TraitName]` 과 **방향만 뒤집었습니다** — 트레이트가 `[토큰] =
구현` 을 듭니다. 그래야 바깥 사람이 우리 토큰을 고치지 않고(얼려 둠) 자기 트레이트를 붙이고,
트레이트를 이름(문자열)이 아니라 정체성(테이블)으로 구분해 충돌이 없습니다. 열쇠는 값이 아니라
**타입 토큰** — 구현은 타입의 성질이라 값마다 등록할 필요가 없고(quad 방식의 생성 1.66~1.9배를
안 냄, perf 18절), 값에는 필드 하나뿐입니다.

## 2. 타입 쪽 — 트레이트 마커

런타임은 토큰으로 찾지만 정적 타입은 못 따라가니, 트레이트마다 **타입에만 있는 필드**를 둡니다
(quad `StateMarker` 와 같은 결):

```lua
export type ArrData<T> = { n: number, read __t: Token<"Arr">, read __list: T, read __listIndex: number, [number]: T }
function Algorithm.IndexOf<E, I>(list: ListMarker<E, I>, item: E): I?   -- E 를 마커에서 추론
```

`spikes/55`(8건): 타입 인자 없이 `Keys(m): { string }`, 사용자 리스트, 사용자 트레이트의
`ImplOf` 가 구현 타입을 돌려줌 — 그리고 NEG: 맵을 리스트 자리에(·반대), 키·값 타입 틀림, 리터럴
`{ n = 3 }` 을 `Arr` 자리에(토큰 없음), `ImplOf` 결과 타입 틀림.

**한계**: `IndexOf(nums, "x")`(원소 타입이 다른 값)는 안 잡힘 — `E` 가 둘의 합으로 넓어짐.
건전하고(그냥 nil) **예전 판도 같았습니다**(실측). 사용자 컨테이너는 마커가 런타임에 없으니
값을 만들 때 캐스트가 필요합니다(`{ __t = MyType, … } :: any` — 생성 함수 안에 한 번).

## 3. 의미가 바뀌는 것

| | 예전(문자열 태그 + 모양) | 시제품(토큰) |
|---|---|---|
| 술어 | 태그 + 최상위 필드 타입 | **토큰 비교 하나** |
| 손으로 쓴 위조 | 거절(경계 안까지) | 토큰을 베끼면 **받아들임**(사용자 결정) |
| 옛 태그 `{ __arr__ = true }`, 모양만 같은 테이블 | 거절 | 거절 |
| 직렬화했다 되읽은 테이블 | 태그가 살아 있으면 받아들임 | **거절**(토큰의 정체성 잃음) — 우연은 더 잘 막힘 |
| 라이브러리 사본 둘(다른 버전) | 서로 호환 | **호환 안 됨**(토큰이 다름) |
| 구현이 둘 이상 | 하드코딩 | 트레이트마다 등록 |
| 숫자·nil·userdata 에 묻기 | `type` 검사 후 | 같음(`impls[nil]` 읽기도 안전) |

## 4. 실측 (`-O2`, 옛·새를 번갈아 세 번, 최소값 — 스크립트는 스크래치 `trait/bench-run.luau`)

| | 옛 | 새 | 배수 |
|---|---|---|---|
| `Arr.Of(1..4)` ×100만 | 97.8 | 98.1ms | 1.00 |
| `Arr.Clone(n=8)` ×100만 | 175.0 | 173.4ms | 0.99 |
| `Arr.Map(n=8)` ×50만 | 209.4 | 215.5ms | 1.03 |
| `HashMap.New` ×100만 | 83.6 | 86.2ms | 1.03 |
| `Fut.Resolved` ×30만 | 69.2 | 73.0ms | 1.05 |
| `isArr` 적중 ×500만 | 183.9 | 114.6ms | **0.62** |
| `isArr` 빗나감(평범한 표) | 98.7 | 111.8ms | 1.13 |
| `isHashMap` 적중 | 183.8 | 120.5ms | **0.66** |
| `Algorithm.IndexOf(n=10)` ×50만 | 161.3 | 179.8ms | 1.11(호출당 조회 ~36ns) |
| `Algorithm.IndexOf(n=1000)` ×5000 | 153.8 | 153.9ms | 1.00 |
| `Algorithm.Keys(10)` ×20만 | 123.6 | 130.8ms | 1.06 |

두 번 헛디뎠다 고친 것:
- 타입 키를 `Trait.TYPE_KEY` 로 받아 쓰면 **상수 접기가 안 돼** 생성이 7~11% 느렸음 → 모듈마다
  리터럴로.
- 키 이름 `__type` 은 해시 칸이 `n`(Arr)·`data`/`size`(HashMap)와 부딪혀 3~7% 느렸음(같은
  모양에 키 이름만 바꿔 잼 — 값이 `true`/테이블/문자열/숫자인지는 무관) → **`__t`**(옛 태그와 같음).

## 5. 여쭐 것 — 질문 AG

`question.md` AG 를 보세요 — 들일지, 키 이름 `__t`, 마커가 타입에만 있는 것, 의미 변화 둘.

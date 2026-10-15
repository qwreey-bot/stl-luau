# 트레이트 시스템 교체(2026-10-15) 리뷰 1라운드 — Opus 보고 + 메인 검증

> 하네스가 서브에이전트의 파일 쓰기를 막아서, 보고서 본문은 메인이 받은 메시지를 옮겼습니다. 프로브는 리뷰어가 이 폴더에 남겼습니다.

## 메인 검증 (2026-10-15)

| # | 리뷰어 주장 | 메인 검증 |
|---|---|---|
| 1 | 문자열 `__type` 이 트레이트 객체의 필드 이름과 겹치면 라이브러리 줄 에러, `Of` 가 함수를 돌려줌 | **재현**(p01 다시 돌림 — 출력 같음) |
| 2 | 뭉텅이 구현이 서로/자기를 의존으로 두면 명시 등록에서 stack overflow, 반쯤 반영 | **재현**(p03 `Build.luau:91`, p10 `Build.luau:157`) |
| 3 | 같은 모듈에서 정의·등록하면 제네릭 칸(`<U>`)의 등록 검사가 0건 | **재현 + 원인 확정 + D3 와 대조**: D3(이전 커밋 사본)는 같은 프로브의 8건을 같은 모듈에서도 전부 잡음 → **레코드 안이 만든 회귀**. 원인: 역직렬화기가 다시 지은 이름 있는 제네릭에 타입 함수를 줄인 자리의 스코프를 줌(`TypeFunctionRuntimeBuilder.cpp:1022`), 서브타이핑은 스코프가 지금 검사를 감싸는 제네릭을 never/unknown 처럼 다룸(`Subtyping.cpp:830-835`, 상류 "entirely incorrect"). 완성 보기도 같음(`../main/m01-show.luau`). 정의를 `do` 블록·즉시 호출 함수에 넣으면 같은 모듈에서도 8건 전부 잡힘(`../main/m02`·`m03`). `types.generic` 은 이름이 필수라 `View` 안에서 피할 길 없음(`TypeFunctionRuntime.cpp:593`) |
| 4 | `Restore` 재귀로 5만 개 LinkedDeque 에서 stack overflow | **재현**(p04) |
| 5·6 | 테스트 공백(런타임 7, 배터리 6) | 고치며 돌연변이로 확인(아래 수정 커밋) |

---

## 리뷰어 보고 원문

시작 상태: `check.sh`(luau 0.742) exit 0, `editor-check.sh`(luau-lsp 1.70.1 + Studio FFlag 105개) src 0건·배터리 51 같은 줄(57 알려진 차이).

### 요약
| # | 종류 | 무엇 | 프로브 |
|---|---|---|---|
| 1 | **결함** | 문자열 `__type` 이 트레이트 객체의 필드 이름과 같으면 라이브러리 줄 에러, `Of` 는 함수를 돌려줌 | p01 |
| 2 | **결함** | 뭉텅이 구현이 서로(또는 자기)를 의존으로 두면 명시 등록에서 stack overflow, 상태는 반쯤 반영 | p03, p10 |
| 3 | **결함(타입 구멍)** | 정의한 모듈 안에서 등록하면 제네릭 칸(`<U>`)의 등록 검사가 0건(0.742·lsp 둘 다) | t07–t10 |
| 4 | 결함(낮음) | `Restore` 가 재귀라 긴 LinkedDeque(5만 개)에서 stack overflow | p04 |
| 5 | 테스트 공백 | 런타임 돌연변이 40개 중 실질 생존 7 | p08, mut-rt.log |
| 6 | 테스트 공백(배터리) | 타입 돌연변이 30개 중 생존 6 | t04, mut-ty.log |
| 7–12 | 참고 | — | — |

### 1. 문자열 `__type` 이 트레이트 객체의 필드 이름과 겹침
완성 표가 이제 트레이트 객체 자신에 `[토큰] = 표` 로 들어가는데(옛 시스템은 따로 둔 `impls` 표), 진입점(`Entry.luau:19`)·`Of`(`init.luau:271`)·
`ExpectImpl`(`:358`)·`Map.Keys/Values/Records`(`Map.luau:97·109·123`)가 `trait[rawget(v,"__type")]` 로 찾음. 재현 장면: `__type = "Set"` 인 자기 셋
클래스를 `Map.Keys` 나 `Arr.GroupBy(…, into)` 에 실수로 넘김.
```
Map.Keys	false	../../../../src/Traits/Map.luau:101: attempt to index function with 'Iter'
Map.Of	true	function
Map.Get(entry)	false	../../../../src/Trait/Entry.luau:21: attempt to index function with number
Arr.GroupBy into	false	../../../../src/Collections/Arr.luau:2364: attempt to index function with 'Get'
Stack.Push(__type=Push) / Collection.Len(__type=Len) — 같은 Entry.luau:21
Map.Keys(__type=FnTok)	false	…Map.luau:101: attempt to call a number value
Map.Keys(__type=Bag)	false	./p01…:21: Map: Keys needs a Map (got table without a type token)   ← 대조
```
`Implements`·`ImplOf` 는 `TokenOf` 를 거쳐 안전. 제안: 완성 표를 따로 둔 `impls` 표로(b01 실측 비용 차이 없음: `-O1` 36.63→36.54ns, `-O2` 38.84→38.73ns)
또는 `type(t)=="table"` 확인(+0.9~3.2ns).

### 2. 고리가 있는 뭉텅이 구현
p03: `LibB.ImplWhere({LibA})`, `LibA.ImplWhere({LibB})` 둘 다 통과 → `LibA.ImplFor(T, …)` 가 `Build.luau:91: stack overflow`. 그 뒤 `B.Count` 동작(A 가
놓인 채 — 같은 등록을 다시 하면 "already"). p10: `X.ImplWhere({X})` 통과, 이후 X 의 모든 명시 등록이 `Build.luau:157: stack overflow`. 명시 구현이
뭉텅이를 덮으니 commit→refresh 가 끝없이 돎. 제안: `implWhere` 에서 의존 그래프의 고리를 등록 줄 에러로, 또는 위로 번짐에 "이미 다시 지은" 집합.

### 3. 같은 모듈에서 정의·등록하면 제네릭 칸 검사 없음
t09(같은 모듈)·t09b(정의만 `t09mod/F.luau`) 같은 NEG:

| NEG | 같은 모듈 | 다른 모듈 |
|---|---|---|
| 기본 구현 `Fold<U>` 의 U 못박기 | **0건** | 잡힘 |
| `Fold<U>` 반환 틀림 | **0건** | 잡힘 |
| `Fold` 인자 수 | **0건** | 잡힘 |
| 필수 칸 `Map<U>` 의 U 못박기 | **0건** | 잡힘 |
| 원소 틀림 / `Fold = 5` / 비제네릭 기본 구현 반환 / 쓰는 쪽 반환 | 잡힘 | 잡힘 |

luau-lsp 1.70.1 도 같음. 대조(t10): 같은 모듈이라도 손으로 적은 별칭이나 View 없이 `typeof(def<<…>>(nil))` 로 꺼낸 표는 잡힘.

### 4. `Restore` 재귀
되읽은 LinkedDeque 1000·10000 통과, 50000·200000 은 `init.luau:203: stack overflow`. 제안: 명시적 스택.

### 5. 런타임 돌연변이 40(`mutations_rt.py`) — 31 잡힘, M07 동등, 생존 7(`p08-gap-tests.luau` 가 각각을 잡음)
M04 `sourceOf` 겹침 검사 삭제(뭉텅이 둘을 건 뒤 생기는 겹침이 조용히 하나를 고름), M05 `onWhere` 선검사 삭제, M38 선검사가 명시 구현 있는
종류도 셈(메시지가 권하는 해결이 막힘), M16 명시 구현을 사본 대신 넘긴 표로 기억(다시 지을 때 물려받은 함수 빠짐), M23 `Restore` 의 얼린 표
조건 삭제, M37 칸이 맨 표인 정의가 통과, M34 문자열 `__type` 의 `Implements`(결함 1).

### 6. 타입 돌연변이 30(전체 `check.sh`) — 생존 6(t04 의 해당 NEG 한 줄씩)
TM11 `Queue.Of(빌린 참조)`, TM16 `Queue.Push(d, "x")`, TM19 `Stack.Pop(빌린 참조)`, TM21 반환 없는 `Deque.PushBack` 등록, TM22 반환 없는
`Collection.Clear` 등록, TM25 위치가 string 인 `List.Get` 등록.

### 참고
7. `ImplWhere({ 오타 })` 는 `{}` 와 같음(strict 타입은 잡음 t03, nonstrict 0건 t03b) — "모든 종류" 를 따로 적는 표식 + 빈 목록 에러 권함.
8. `Trait.Fn()` 에 타입 인자를 잊으면 칸이 unknown 이라 `{Len=5}` 등록이 타입을 통과(런타임이 잡음). t01 의 나머지 12 정의 모양은 NEG 또는 View 에러.
9. `X.Of(토큰)` 의 타입: Self 가 토큰 타입으로 잡혀 맞는 종류에 써도 에러(t06) — `Of<<…>>` 로.
10. 에러 줄(p05): raise 39곳 × -O0/-O1/-O2 중 38곳 사용자 줄, `defaultCycle` 은 빌더(사용자 정의) 줄.
11. 뭉텅이 builder 가 모르는 이름을 돌려줄 때 메시지가 "Stl.HashMap gave Extra …" — 준 쪽은 뭉텅이 구현.
12. `Restore` 는 테이블 키를 걷지 않음(p11).

### 깨끗했던 것
p07 무작위 모델 대조 시드 400, 46,766걸음, 검사 1,641,511회 불일치 0. p06 순서 장면 전부 통과. t02 `Provided` 의 반환 계약. `Of` 인자 수.
내장 덱의 `Push`·`Clear` 가 자기 자신. editor-check 깨끗.

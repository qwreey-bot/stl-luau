# 트레이트 BA·BB 변경분 리뷰 1라운드 (2026-10-16) — Gemini 둘 → Sonnet 검증 → Opus 깊은 리뷰, 메인 판정

범위 `git diff b1ec1e6..HEAD`(HEAD `3578e45`) — 질문 BA(`Of`/`OfMut`·`FnMut`·`Entries`·`__traits`·`Converter`·스택은 덱을 모름)와 BB(`Trait.Struct`·
`Arr` 의 읽기 전용 칸·`Arr.Set`·원형 덱의 칸 숨김). 사용자 방식: *"gemini 를 먼저 띄우는 이유는 얕은 문제를 일단 잡아서, opus가 깊은 문제에 집중"*.

| 단계 | 누가 | 결과 | 원문 |
|---|---|---|---|
| 1 | Gemini 3.8 flash 둘(격리 worktree, uid 61001) | 런타임: 결함 2·공백 1·참고 2 / 타입: 결함 3·공백 2·참고 2 | `gemini-runtime/`, `gemini-types/` |
| 2 | Sonnet(검증 — 사본에서 다시 재현, 옛 판과 갈라 "이번 변경 탓" 판정) | 반박 1(R5), 부분 3, 나머지 확인. "옛 판과 1만 회 대조" 는 옛 소스가 반쯤 새 판이었음 → 진짜 옛 판으로 다시 대조해 불일치 0(대조는 배열 길이가 짧아 약함). T1 의 Gemini 처방은 그대로면 라이브러리가 깨짐(`Assoc` 도 같이) | `sonnet-verify/`(프로브), 보고는 아래 |
| 3 | Opus(깊은 리뷰 — 확인된 것은 재보고 금지, 돌연변이 58) | 결함 3(F1~F3, 전부 사용자 트레이트에서 나는 `Entries` 의 타입 결함), 테스트 공백 2(F5·F6 — 돌연변이 4 생존), 참고 5. 런타임 결함 0, 지난 라운드에 고친 성질(묶음 되돌리기·고리·Any 규칙·사용자 줄) 유지 | `opus/`(프로브·돌연변이 하네스·결과) |

## 메인 판정(메인이 직접 다시 돌린 것에 ✔)

| # | 무엇 | 판정 | 이번 변경 탓 |
|---|---|---|---|
| T1 ✔ | `List.AssocRead`·`Assoc` 의 `Index` 가 공변 → `List.Get(ld, 123)`·`NextIndex(arr, "x")` 가 0건, 라이브러리 줄 에러(`LinkedDeque.luau:91`) | 결함 | 예(BA — 예전엔 그 진입점에 서명이 없었음) |
| T2 ✔ | `Entries` 가 다시 지으며 인덱서의 `read` 를 잃음 → `stl.Map.Iter(hm)` 결과에 쓰기 0건, 맵 안쪽 오염(`size` 1 인데 `Has` 참) | 결함 | 예(BA) |
| F3 ✔ | 같은 뿌리: 사용자 칸 인자가 `{ read [number]: T }` 면 진입점이 `Arr` 를 거절 | 결함 | 예(BA × BB) |
| F1 ✔ | `Entries` 의 `occurs` 가 인덱서를 안 봄 → 칸에 `{ Self }`·`{ [k]: Self }` 가 있으면 그 트레이트의 진입점 타입이 **전부** 사라짐 | 결함 | 예(BA) |
| F2 ✔ | 칸 자신의 제네릭 이름이 정의 제네릭과 같으면 `Duplicate type parameter` → 진입점 전부 사라짐 | 결함 | 예(BA) |
| T3·R3 ✔ | 읽기만 하는 함수 열한 곳이 `{ T }` 라 `Arr` 거절(BSearch 다섯, Tree/RedBlack/Avl.FromSorted, SortedArray.Append·Locate, HashMap.FromTable, CompleteArray.IsHeap) | 결함(맞는 코드 거절) | 예(BB) |
| R1 | `List.Of(stl.Arr)` 가 종류 모듈을 안 받음(`ImplFor`·`Converter` 는 받음) | 결함(비일관성) | BB 뒤 |
| R2 | 되읽은 값에 대한 변환자 메시지가 "for X got X" — `Restore` 안내 없음 | 결함(진단) | 예(BA) |
| F5 ✔ | `spikes/71` 55·90줄 NEG 가 돌연변이(`Map.Set` → `Fn`, `DefaultMut` 의 `mut` 뒤집기) 아래에서 "값을 0개 돌려줌" 으로 같은 줄에 에러 → 게이트 통과 | 테스트 공백 | 예 |
| F6 | `Deque.AsStack`·`AsQueue` 가 빌린 참조를 받게, `AsStackRead` 가 쓰기 스택을 돌려주게 바꿔도 통과 | 테스트 공백 | 예 |
| T5 | 배럴에 탐침 타입(`TraitA`…)·`MapAssocRead`/`SetAssocRead` 없음 — 바깥 구현자가 배럴만으로 등록 표 주석을 못 씀 | 결함(표면) | 예 |
| T4 | `LinkedDequeData` 의 head·tail·size 쓰기 가능 | 참고(예전부터, BB 원칙이 아직 안 닿음) | 아니오 |
| F7 | `Trait.Struct("X").Token` 이 `Token<string>`(`NewToken` 은 리터럴) | 참고 | 예 |
| F8 | `Seal` 이 토큰·다른 종류의 값도 받아 `TokenOf` 가 엉뚱해짐 | 참고 | 예 |
| F4·F9·F10·T6·T7·R4 | 겹침 칸은 `Sig` 없으면 진입점이 빠짐, 메타테이블 반환을 잃음, 닫힌 트레이트를 뭉텅이 의존으로 받음, 낡은 주석, `Self` 반환 진입점의 타입 인자 순서, `Seal` 이 안 얼림 | 참고 | — |
| R5 | `ListReadFull` 누락 | 반박(`List` 엔 `ReadFull` 이 없음) | — |

## 메인이 더 잰 것 — T2·F3 의 뿌리
- 타입 함수 API 는 **읽기 전용 인덱서를 만들지 못하고**(`setreadindexer` 미지원, `writeresult = never` 도 무시 — `ro.luau`), **읽기 전용인지 보지도 못합니다**
  (`{ read [string]: number }` 와 `{ [string]: number }` 의 `indexer()`·`readindexer()`·`writeindexer()` 가 같음 — `ix.luau`). 그러나 손대지 않고 돌려준 타입은
  읽기 전용이 살아 있음(`View`).
- 그래서 처방은 **인덱서가 든 칸은 다시 짓지 않기**(정의의 제네릭을 그대로 — 그 칸 하나만이라 "나눠 쓰면 안 묶임" 이 안 남): 사본에서 `Map.Iter` 결과에 쓰기가 잡히고,
  다른 맵 진입점의 키·값 검사는 그대로, 게이트 exit 0(`/tmp/tmp.ezDSA5MX0g`).

# trait-defaults — 시제품 (papers/07)

기본 구현과 의존을 가진 트레이트, 바깥으로 뺀 노드. `src/` 와 무관한 실험 코드입니다(게이트 밖).

| 파일 | 무엇 |
|---|---|
| `Trait2.luau` | 트레이트: 필수 함수 + 기본 구현 + 의존 + 저절로 따라오는 구현 |
| `Traits.luau` | `List`·`Build`·`Seq`(List + Build 를 요구)·`Tree` |
| `Node.luau` | 리스트 노드·트리 노드(평범한 테이블 + 잇기·끊기) |
| `Containers.luau` | `LinkedList`·`LinkedTree`+`Bst`·`ArrayTree`, 그리고 지금의 `Arr`·`Deque` 를 같은 트레이트에 등록 |
| `Algo.luau` | 타입 있는 진입점(`Fold`·`Find`·`Contains`·`Filter`·`MapInto`) |
| `demo.luau` | 동작 확인 — `luau .claude/research/trait-defaults/demo.luau` |
| `types.luau` | 타입 대조 — `luau-analyze` 가 NEG 여섯 줄에서만 에러를 내야 함 |
| `bench.luau` | 속도 — `luau -O2 .claude/research/trait-defaults/bench.luau` |

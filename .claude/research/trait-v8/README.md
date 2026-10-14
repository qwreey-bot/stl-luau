# 시제품 v8 — 메인의 최적안: v7(두 보기, 정의 한 번) + v6(빌린 참조는 `of` 에서, 탐침 몸통) (2026-10-14)

비교 문서: `../trait-candidates.md`(후보 B). 정의는 `Trait.Trait(이름, function<M>(mode: M) return function<Self, T>(of: …) … end end)`,
`M` 은 기본 구현 칸 `Default(mode, 빌더)` 에만 쓰임(함수마다 `Mut` 없음). 등록 표는 `XImpl<…>` — 기본 구현 칸은 안 적으면 기본 구현.
`types.luau`: 에러 줄 = NEG 줄 + canary(메인 실측). `check.luau`: `-O1`·`-O2` PASS.

# 부분 크기 칸 시제품 (2026-10-13)

`Trees/RedBlack` 에 일곱째 칸(부분 트리의 노드 수)을 더한 판 둘 — 넣을 때 아래에서 위로 올리는 `RedBlackSizedUp`, 내려가며
올리는 `RedBlackSizedDown`. `src/Trees/RedBlack.luau` 를 글자 치환으로 만든 사본이라 원본이 바뀌면 낡습니다(시제품).
`check.luau` 가 크기 칸을 무작위로 검증하고 `bench.luau` 가 지금 판과 견줍니다. 결과와 판단은
`.claude/base/perf-measurements.md` 45절. 실행: `( ulimit -v 2097152; timeout 400 luau -O2 .claude/research/tree-size/bench.luau )`.
`FromSorted`·`Clone` 은 크기 칸을 채우지 않습니다(재는 데 안 씀).

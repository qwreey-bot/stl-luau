# 지금 할 일

우선순위순. 가장 자주 바뀌는 문서입니다. 완료하면 지우고, 방향이 바뀌면
바로 갱신하세요.

## 막힌 것 (사용자 결정 필요)

패키지 매니저/엔트리포인트/저장소 구조는 2026-08-22에 결정되어 해소됨
(`.claude/question.md` 참고). 남은 질문(type function 실험 방향, hash/tree
컨테이너 표현, tbox 코드 스타일 이식 여부)은 각 항목에서 개별적으로 막힘 —
전체를 막고 있진 않음.

## 진행 중 / 다음 작업 후보

1. ~~**`treeset.luau` 버그 수정**~~ **[2026-08-22 완료]** `has`/`add`의
   `self` vs 모듈 테이블 버그를 고치고 타입을 `TreeSet<T>`로 정리했습니다.
   **남은 일**: 생성자/메타테이블 배선이 없어 아직 실제로 인스턴스를 만들
   수 없고, `intersect`/`union`/`subtract`/`exclusive`/`is_subset_of`/`size`는
   여전히 빈 함수 — 이건 `.claude/question.md` #2(hash/tree 컨테이너 표현)
   결정 이후에 이어서 할 것.
2. **`arr` 미구현 함수 채우기** — `shuffle`/`reverse(_inplace)`/`rotate(_inplace)`/
   `sorted`/`replace(_inplace)`/`erase`가 빈 본문입니다
   (`.claude/project-context.md` 모듈 현황 표).
3. **`arr` 테스트 커버리지 확대** — `tests/arr.luau`는 `slice_inplace` 6케이스뿐,
   나머지 30여 개 함수(특히 `push`/`insert`/`unshift` 계열, `map`/`filter`/
   `flatmap`, `flat`, `merge`)는 무테스트. 회귀 없이 나머지 함수를 채우려면
   먼저 이게 필요.
4. **`hashmap`/`hashset`/`treemap`/`bsearch`/`heap` 설계 및 착수** — 전부 빈
   파일. `arr`가 정한 컨테이너 표현 규약(길이 필드+태그)이 hash/tree 구조에도
   맞는지부터 결정(`.claude/question.md`).
5. **`tuple`/`typeutil` 완성 여부 판단** — 지금은 `return {}` placeholder.
   type function 기반 설계를 계속 밀지, 더 단순한 런타임 전용 구현으로
   대체할지 결정 필요(`.claude/question.md`).
6. **`record.luau` 재설계** — 현재 모듈 패턴을 전혀 안 따르는 타입 별칭
   한 줄. 실제로 뭘 할 모듈인지부터 정의.
7. **README/LICENSE 추가** — 저장소에 둘 다 없음. `tbox`/`quad` 둘 다 MIT +
   README를 갖춤.
8. **stylua 도입 여부** — 인덴트가 탭/스페이스로 혼재.

## 완료된 작업 (2026-08-22 세션)

- 오랫동안 미커밋 상태였던 변경을 7개 커밋으로 정리(rename, arr 확장,
  packed.luau 제거, set→hash/tree 분리, tuple/typeutil 실험, fut/record
  스캐폴딩, 스크래치 노트).
- `qwreey/quad` 클론(`/code/Projects/stl-luau-refs/quad`), `qwreey/tbox`
  (`/code/Projects/tbox`) 분석.
- `CLAUDE.md`/`.claude/` 문서 체계 최초 구축.

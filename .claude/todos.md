# 지금 할 일

우선순위순. 가장 자주 바뀌는 문서입니다. 완료하면 지우고, 방향이 바뀌면
바로 갱신하세요.

## 막힌 것 (사용자 결정 필요)

`.claude/question.md`의 질문들이 아래 여러 항목을 막고 있습니다 — 특히
패키지 매니저 도입 여부와 저장소 구조는 이후 모든 스캐폴딩 작업의 전제라
먼저 답이 필요합니다.

## 다음 작업 후보

1. **`treeset.luau` 버그 수정** — `set.has`/`set.add`가 `self` 대신 모듈
   테이블을 읽고 씁니다(`.claude/base/architecture.md`가 아니라
   `.claude/project-context.md`의 "모듈 현황" 표 참고). 지금은 그냥
   구 `set.luau`를 옮겨놓기만 한 상태.
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

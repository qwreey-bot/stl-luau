# 지금 할 일

우선순위순. 가장 자주 바뀌는 문서입니다. 완료하면 지우고, 방향이 바뀌면
바로 갱신하세요.

## 막힌 것 (사용자 결정 필요)

`.claude/question.md` 참고. 남은 질문은 3개(type function 실험 방향,
hash/tree 컨테이너 표현, 라이선스/README)이며, 아래 1~2번 작업을 막고
있진 않습니다.

## 다음 작업 후보

1. **⭐ `Arr<T>` 타입 재설계 — strict TypeError 47건.**
   런타임은 정상이지만 타입이 new solver 를 못 따라갑니다. 이게 이 저장소의
   가장 큰 미해결 문제이고, "luau 로 가는 이유" 그 자체이기도 합니다.
   착수 전에 **반드시** `.claude/base/typing-limits.md` 와 그 문서가 가리키는
   quad 의 `typing-limits.md` 전문을 읽으세요 — 이미 실측된 회피법
   (메소드를 named function + `typeof(fn)` 으로 선언, 데이터부/메소드부 분리)이
   정리돼 있습니다. 스파이크 파일로 후보안을 먼저 측정하고, **음성 대조군**을
   반드시 포함하세요.
2. **`hashset` 구현 + `treeset` 재작성.** 사용자 결정(2026-08-22):
   - 지금 `treeset.luau` 에 든 내용은 사실 정렬이 없는 **해시셋**이므로
     `hashset.luau` 로 옮길 것.
   - `treeset` 은 정렬을 유지하는 진짜 트리/정렬배열 구조로 새로 작성
     (빈 `bsearch.luau` 를 정렬배열 백엔드로 활용).
   - **크기(size)는 래퍼 구조로 분리**할 것 — `{ data = {...}, size = n }`.
     인스턴스에 `n` 을 직접 두면 `hashset<string>` 에서 `add(s, "n")` 이
     길이 필드를 덮어씁니다.
3. **`arr` 미구현 함수 채우기** — `shuffle`/`reverse(_inplace)`/`rotate(_inplace)`/
   `sorted`/`replace(_inplace)`/`erase` 가 빈 본문. 1번 재설계 이후가 나을 수
   있습니다(시그니처가 바뀔 수 있으므로).
4. **`hashmap`/`treemap`/`heap` 착수** — 전부 빈 파일. 2번의 컨테이너 표현
   결정을 따라갑니다.
5. **`tuple`/`typeutil` 방향 결정** (`.claude/question.md` #1).
6. **`record.luau` 재설계** — 모듈 패턴을 안 따르는 타입 별칭 한 줄.
7. **`libs/test-luau` 서브모듈 정리** — 더 이상 쓰지 않습니다. 다만 그 안에
   **push 안 된 로컬 커밋**이 있으니 먼저 push 한 뒤 제거하세요
   (`.claude/project-context.md` 참고).
8. **README/LICENSE 추가** — 둘 다 없음. `tbox`/`quad` 는 MIT.
9. **stylua 도입 여부** — 인덴트가 탭/스페이스로 혼재
   (`src/arr.luau` 는 탭, `src/tuple.luau`/`typeutil.luau` 는 스페이스 4칸).
10. **selene 잔여 경고 정리** — 현재 error 2건(`empty_if` — `arr` 의
    fast-path 관용구), warning 46건(대부분 스텁 함수의 미사용 파라미터).
    스텁을 실제로 구현하면 대부분 자연히 사라집니다.

## 완료된 작업 (2026-08-22 세션)

- 오랫동안 미커밋 상태였던 변경을 7개 커밋으로 정리.
- `CLAUDE.md`/`.claude/` 문서 체계 구축 (quad/tbox 관례 참고).
- pesde 도입, 엔트리포인트를 `src/init.luau` 로 이동.
- **lune 제거 → 순수 luau 전환.** 테스트를 quad 식 `assert` + `print` 로
  재작성(`tests/run.luau` + `tests/arr.luau`).
- **타입 체크/린트 툴체인 도입**(`mise.toml`: luau-lsp + selene, `.luaurc`
  strict, `.vscode` new solver, `selene.toml`).
- **`arr` 버그 6건 수정 + 회귀 테스트**: `sized` 공유 테이블 오염,
  `filter_inplace` 전면 오동작, `flat` 오동작, `flat_inplace` 크래시,
  `max`/`min` 반전, `clone_from_table` 무반환. 그리고 `sized` 시그니처
  수정으로 TypeError 7건 해소.
- `treeset` 의 `self` vs 모듈 테이블 버그 수정.

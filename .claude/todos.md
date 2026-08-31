# 지금 할 일

우선순위순. 가장 자주 바뀌는 문서입니다. 완료하면 지우고, 방향이 바뀌면
바로 갱신하세요.

## 막힌 것 (사용자 결정 필요)

`.claude/question.md` 참고. 남은 질문은 3개(type function 실험 방향,
hash/tree 컨테이너 표현, 라이선스/README)이며, 아래 1~2번 작업을 막고
있진 않습니다.

## 다음 작업 후보

1. **⭐ `Arr<T>` 타입 재설계 — strict TypeError 68건(`src/arr.luau` 기준).**
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
3. ~~**`arr` 미구현 함수 채우기**~~ — 2026-08-31 완료. 아래 "완료된 작업" 참고.
4. **`hashmap`/`treemap`/`heap` 착수** — 전부 빈 파일. 2번의 컨테이너 표현
   결정을 따라갑니다.
5. **`tuple`/`typeutil` 방향 결정** (`.claude/question.md` #1).
6. **`record.luau` 재설계** — 모듈 패턴을 안 따르는 타입 별칭 한 줄.
7. **README/LICENSE 추가** — 둘 다 없음. `tbox`/`quad` 는 MIT
   (`.claude/question.md` #2).
8. **stylua 도입 여부** — 인덴트가 탭/스페이스로 혼재
   (`src/arr.luau` 는 탭, `src/tuple.luau`/`typeutil.luau` 는 스페이스 4칸).
9. **`slice` 의 `to_start` 삽입 경로가 틀렸습니다.** `arr_ifce.slice` 에서
   `to` 와 `to_start` 를 둘 다 주면 기존 원소를 밀어내려고
   `table.move(to, to_len - to_start + 1, to_len, to_start + move_len)` 을
   부르는데, 소스 구간이 잘못됐습니다. `to_len = 3, to_start = 2` 처럼
   `to_len - to_start + 1 == to_start` 인 경우에만 우연히 맞고,
   **`to_len = 5, to_start = 2, move_len = 2` 면 2..5 를 4..7 로 옮겨야 하는데
   4..5 만 옮깁니다**. `to.n = to_len + move_len` 도 중간 삽입을 고려하지
   않습니다. 고치려면 먼저 **`to_start` 가 "밀어내고 삽입"인지 "덮어쓰기"인지
   정해야 합니다** — 2026-08-31 에 추가한 `reverse` 는 같은 시그니처지만
   **덮어쓰기**로 구현돼 있어(테스트로 고정됨) 지금 둘이 어긋나 있습니다.
   `rotate` 는 `to_start` 를 생략해 이어붙이기 경로만 타므로 영향 없습니다.
10. **selene 잔여 경고 정리** — 현재 error 2건(`empty_if` — `arr` 의
   fast-path 관용구), warning 21건(2026-08-31 기준. `arr` 스텁을 구현하며
   46건에서 줄었고, 남은 건 대부분 다른 모듈 스텁의 미사용 파라미터입니다).

## 완료된 작업 (2026-08-31 세션)

- **`arr` 의 빈 함수 10개 구현**: `shuffle`/`shuffle_inplace`,
  `reverse`/`reverse_inplace`, `rotate`/`rotate_inplace`,
  `sorted`/`sort_inplace`, `replace`/`replace_inplace`, `erase`.
  결정된 규약: **rotate 의 shift 는 양수 = 왼쪽 회전**(STL `std::rotate` 방향),
  **shuffle 은 rng 주입 가능**(`(min, max) -> number`, 기본 `math.random`),
  **정렬 비교자 방향은 `max`/`min` 과 동일**(`compareTo(a, b) > 0` 이면 a 가 큼).
  `sorted` 는 `table.sort` 가 `#` 를 쓰기 때문에 `1..n` 을 조밀한 테이블로
  옮겨 정렬합니다. `tests/arr.luau` 11~16절 추가.
- **`arr` 버그 2건 수정 + 회귀 테스트(17절)**: `clear` 가 `table.clear` 로
  `__arr__` 태그까지 지워 비운 배열이 `is_arr` 를 통과하지 못했음
  (`slice_inplace` 의 빈 구간 경로도 같은 문제), `erase_inplace` 가 뒤집힌
  구간(`start > last`)에서 배열을 오히려 늘렸음.
- 이 작업으로 `src/arr.luau` 의 TypeError 는 47 → 68 로 늘었습니다. 전부
  기존과 같은 원인이며 1번 재설계 대상입니다(`.claude/base/typing-limits.md`).

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
- `libs/test-luau` 서브모듈 제거(로컬 커밋 push 후). 이 저장소와
  test-luau 저장소 둘 다 GitHub 에 push 완료.

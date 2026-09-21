# 지금 할 일

우선순위순. 가장 자주 바뀌는 문서입니다. 완료하면 지우고, 방향이 바뀌면
바로 갱신하세요.

## 막힌 것 (사용자 결정 필요)

`.claude/question.md` 참고. 남은 질문은 3개(type function 실험 방향,
**`arr(1, 2, 3)` 호출 형태 vs `arr.오타` 검출**, 라이선스/README)이며,
아래 작업들을 막고 있진 않습니다.

## ⭐ 지금 하는 것 — 전면 재작성

**계획서: `.claude/base/rewrite-plan.md`** (2026-09-21 확정). 공개 API 를 전부
바꿉니다 — stl-luau 는 한 번도 반출된 적이 없어 breaking change 가 아닙니다.

1. **1단계 검증 장치** — `check.sh` 에 음성 대조군 배터리 게이트, selene 제거,
   pesde 0.7.4.
2. **2단계 `src/Types.luau`** — 타입 단일 파일(quad-types 방식).
3. **3단계 `src/Arr.luau` 재작성** — 메소드 54 + 생성자 9, 테스트 동시 재작성.
4. **4단계 나머지 컨테이너** — HashSet → TreeSet(+BSearch) → HashMap →
   TreeMap → Heap.

아래 "다음 작업 후보" 의 항목 중 재작성에 흡수되는 것은 그때 정리합니다.

## 루트 `todo` 에서 건진 것 (2026-09-21, 파일은 삭제됨)

예전 스크래치 파일에만 있던 항목들입니다. **재작성 계획에 흡수되지 않는
독립 항목**이라 여기 옮겨둡니다.

- **⭐ mlua(Rust) 바인딩** — 이 저장소 어느 문서에도 없던 프로젝트 목표입니다.
  Rust 의 mlua 에서 이 라이브러리를 쓸 수 있게 하는 게이트:
  `LuaValue.is_arr`, `LuaArr.erase(...)`, `LuaArr.push()` 같은 호출이 되도록
  러스트 바인딩을 만든다. **이게 사실이라면 공개 API 설계에 영향을 줍니다** —
  바인딩에서 부르기 쉬운 모양인지 확인이 필요합니다(사용자 확인 필요).
- **미구현 API 아이디어**: `rangefilter`, `rangefind`, `rangemap`, `splice`.
  `rangeflat` 이 `Flat(start?, last?)` 로 흡수된 것과 같은 방식으로
  `Filter`/`Find`/`Map` 이 구간 인자를 받게 하면 별도 이름이 필요 없습니다.
- **`treeset subset`** — 부분집합 판정. `treeset` 재작성 때 같이.
- **`Fut`, `Optional`** — `src/fut.luau` 가 뼈대만 있는 것과 연결됩니다.
  `Optional` 은 지금 `T?` 로 충분한지 판단 필요.

## 다음 작업 후보

1. ~~**⭐ `Arr<T>` 타입 재설계**~~ — **2026-08-31 완료.**
   음성 대조군 0/6 → 6/6. TypeError 는 재설계 몫이 301 → 126, 테스트 헬퍼에
   타입을 달아 → 41. 전문은
   `.claude/audit/arr-type-redesign/REPORT.md`, 결론은
   `.claude/base/typing-limits.md` 의 "재설계" 절.
   **후속으로 남은 것**은 아래 10번(`src` 20건)과 11번(`tests` 21건).
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
9. **재설계 이후 남은 타입 진단 정리** — `src/arr.luau` 20건은 생성자
   본문(`table.create(n)` 결과에 `n`/`__arr__` 를 덧붙이는 패턴) 6건,
   `slice` 의 `to_start`(아래 12번과 같은 자리) 3건, 파일 끝 `Arr` 캐스트
   등입니다. `tests/arr.luau` 21건은 이종 중첩 배열(`arr(1, arr(2), 3):flat()`)
   에서 `T` 가 안 풀리는 것과 무주석 콜백 파라미터입니다. **이제는 하나씩
   볼 만한 진단이니** 숫자를 줄이려 하지 말고 원인별로 보세요.
10. **`max`/`min` 은 아직 `nil` 구멍에 안전하지 않습니다.** `1..n` 사이에
   구멍이 있으면 `compareTo(nil, base)` 가 `nil - base` 로 터집니다.
   `sorted` 는 2026-08-31 에 구멍을 걸러내도록 고쳤지만(정렬 대상에서 빼고
   뒤로 몰기 — JS `Array.prototype.sort` 와 같은 동작) `max`/`min`/`sum`/`prod`
   는 그대로입니다. 컨테이너 전반에서 구멍을 어떻게 다룰지 한 번에 정하는 게
   나아 보입니다.
11. **`slice` 의 `to_start` 삽입 경로가 틀렸습니다.** `arr_ifce.slice` 에서
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
12. **selene 잔여 경고 정리** — 현재 error 2건(`empty_if` — `arr` 의
   fast-path 관용구), warning 21건(2026-08-31 기준. `arr` 스텁을 구현하며
   46건에서 줄었고, 남은 건 대부분 다른 모듈 스텁의 미사용 파라미터입니다).

## 완료된 작업 (2026-08-31 세션)

- **⭐ `Arr<T>` 재설계 — 타입 검사가 죽어 있던 걸 살렸습니다.**
  음성 대조군 6/6 검출, TypeError 301 → 126(재설계) → 41(테스트 헬퍼 주석),
  런타임 무변경. **`arr.오타` 를 못 잡는 구멍이 하나 남았습니다** — 없애려면
  `arr(1, 2, 3)` 을 포기해야 해서 `question.md` 2번으로 올렸습니다.
  `.claude/audit/arr-type-redesign/`(REPORT + 스파이크).
- **타입 체크 방식을 quad 식으로 전환**: 체커 `luau-analyze`,
  전 모듈 `--!strict`, `scripts/check.sh`, `mise.toml` 에 luau 고정.

- **`arr` 의 빈 함수 10개 구현**: `shuffle`/`shuffle_inplace`,
  `reverse`/`reverse_inplace`, `rotate`/`rotate_inplace`,
  `sorted`/`sort_inplace`, `replace`/`replace_inplace`, `erase`.
  결정된 규약: **rotate 의 shift 는 양수 = 왼쪽 회전**(STL `std::rotate` 방향),
  **shuffle 은 rng 주입 가능**(`(min, max) -> number`, 기본 `math.random`),
  **정렬 비교자 방향은 `max`/`min` 과 동일**(`compareTo(a, b) > 0` 이면 a 가 큼).
  `sorted`/`sort_inplace` 는 `1..n` 중 **`nil` 이 아닌 것만** 조밀하게 모아
  정렬합니다 — `table.sort` 가 `#` 를 쓰는 문제와, 구멍이 있으면 비교가
  터지는 문제(`attempt to compare nil`) 둘 다를 피하기 위함입니다. 구멍은
  결과 뒤쪽으로 몰리고 `n` 은 보존됩니다(JS `Array.prototype.sort` 와 같은
  동작). 사용자 비교자에도 `nil` 이 넘어가지 않습니다. `tests/arr.luau`
  11~17절 추가.
- **`arr` 버그 2건 수정 + 회귀 테스트(17절)**: `clear` 가 `table.clear` 로
  `__arr__` 태그까지 지워 비운 배열이 `is_arr` 를 통과하지 못했음
  (`slice_inplace` 의 빈 구간 경로도 같은 문제), `erase_inplace` 가 뒤집힌
  구간(`start > last`)에서 배열을 오히려 늘렸음.
- 이 작업으로 `src/arr.luau` 의 TypeError 가 늘었습니다. 전부 기존과 같은
  원인이며 1번 재설계 대상입니다(`.claude/base/typing-limits.md`).
- **타입 체크 방식을 quad 식으로 전환**: 체커를 `luau-lsp analyze` →
  **`luau-analyze`** 로(luau-lsp 가 진단을 빠뜨리는 걸 실측), 모든 모듈에
  `--!strict`(실험 파일 2개는 `--!nocheck`), `scripts/check.sh` 추가,
  `mise.toml` 에 `luau = "0.734"` 고정. 근거와 수치는 전부
  `.claude/base/typing-limits.md` 의 새 두 절.

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

# 관례와 작업 방식

`CLAUDE.md`가 `@import`하므로 매 세션 로드됩니다 — 세션마다 필요하진 않은
상세는 `.claude/base/`나 개별 문서로.

## 언어 관례

- 사용자는 한국 유저입니다. 사용자가 보는 것(대화, plan, `.claude/` 문서,
  커밋 메시지 요약 등)은 한국어로. 코드 안 주석은 기존 파일들처럼 한국어로
  쓰는 게 이 저장소의 지배적인 스타일입니다(`src/arr.luau` 참고) — 다만
  강제는 아니고, 기존 파일을 고칠 땐 그 파일의 기존 언어를 따르세요.
- 에러 메시지 문자열, 함수/변수 식별자는 영어.

## 코드 스타일

- **모듈 패턴**: `local X = {}` 네임스페이스 테이블 + `X.__index = X` +
  생성자용 별도 `X_constructor` 메타테이블(`__call`로 팩토리화). `src/arr.luau`,
  `src/tuple.luau`가 정석 예시입니다. 새 컨테이너 모듈은 이 패턴을 따르세요.
  `src/record.luau`(타입 별칭 하나뿐, 모듈 테이블 없음)처럼 패턴을 벗어난 채로
  방치하지 마세요 — 실제로 구현할 때 이 패턴으로 맞추거나, 그 전까진 다른
  모듈이 참조하지 않게 두세요.
- **네이밍**: 공개 인터페이스 함수/필드는 snake_case (`push_many`, `is_arr`).
  내부 로컬 변수도 snake_case. 타입 이름(`Arr<T>`, `ArrInterface`)만 PascalCase.
- **배열 표현**: 컨테이너는 `{ n: number, [number]: T }` 형태 + 태그 필드
  (`__arr__` 등)로 `is_arr` 같은 런타임 판별을 지원합니다. Lua 기본 `#`
  연산자 대신 `self.n`을 신뢰합니다 — 희소 배열/trailing nil 문제를 피하기
  위함으로 보입니다(`arr_ifce.erase_inplace`가 꼬리를 `nil`로 지우고 `n`을
  갱신하는 패턴 참고). 새 컨테이너도 이 규약을 따르세요.
- **`table.move`/`table.create`로 벌크 연산을 최적화**하는 게 이 저장소
  스타일입니다(단건일 때 분기해서 `select`/직접 대입으로 처理) — `arr_ifce.push_many`,
  `merge`, `slice` 참고. 새 함수를 짤 때도 "1개/여러개/0개"를 나눠 처리하는
  패턴을 유지하세요.
- **`_inplace` 접미사 쌍**: 대부분의 변환 함수는 새 컨테이너를 만드는 버전과
  `_inplace`로 자기 자신을 변형하는 버전을 쌍으로 둡니다(`map`/`map_inplace`,
  `filter`/`filter_inplace`, `flat`/`flat_inplace` 등). 새 스트림 API를 추가할
  땐 이 쌍을 같이 고려하세요(둘 다 필요하지 않다면 왜 아닌지 명확히 할 것).
- `Comparator<T>`는 `(a, b) -> boolean` 과 `(a, b) -> number` 둘 다 허용하는
  유니온입니다(`src/common.luau`의 `compareTo`가 그 어댑터). 정렬/비교가
  필요한 새 함수는 이 타입을 재사용하세요.
- stylua 설정 파일이 아직 없습니다 — `tbox`/`quad`의 `stylua.toml`
  (`syntax = "Luau"`, `column_width = 120`, 스페이스 4칸)을 참고해 도입할지는
  `.claude/question.md` 참고. 기존 파일은 탭 들여쓰기를 씁니다(`src/arr.luau`)
  — `src/tuple.luau`/`src/typeutil.luau`만 스페이스 4칸이라 이미 혼재돼
  있습니다.

## 실험적 Luau 기능 사용 시 주의

`src/tuple.luau`, `src/typeutil.luau`는 Luau의 **실험적** `type function`
기능(타입 수준 메타프로그래밍)을 씁니다. 로컬 `luau`/`lune` 바이너리에서
문법 자체는 파싱/실행되는 것을 확인했지만, 이 기능은 upstream에서도 아직
실험 단계입니다 — Luau 버전을 올릴 때 깨질 수 있음을 감안하세요. 이 두
파일은 `lib.luau`에서 아직 export되지 않은 순수 탐색 코드입니다(`return {}`
placeholder). 정식 API로 승격하기 전엔 다른 모듈이 이 둘에 의존하지 않게
하세요.

## 테스트

- 테스트 프레임워크는 `libs/test-luau` 서브모듈(자체 저장소,
  `github.com/qwreey/test-luau`)입니다. `test("name")(...)` 형태로 케이스를
  쌓고 `:solve()`로 출력합니다. 이 프레임워크 자체도 초기 단계입니다
  (`lib.luau` 안 "TODO: syntax highlighting" 주석 참고) — stl-luau 세션에서
  이 프레임워크의 버그를 고치게 되면 `libs/test-luau` 안에서 커밋하고,
  부모 저장소에서 서브모듈 포인터를 별도 커밋으로 올리세요(같은 커밋에
  섞지 말 것 — 서로 다른 두 저장소의 히스토리입니다).
- 새 모듈/함수를 구현하면 `tests/<module>.luau`에 대응 테스트를 추가하고
  `lib.luau`의 `run_test()`가 모으는 목록에도 반영하세요. 지금은
  `tests/arr.luau` 하나뿐이고 그마저 `slice_inplace`만 덮습니다 —
  `src/arr.luau`의 나머지 30여 개 함수는 테스트가 없습니다
  (`.claude/todos.md` 참고).
- 실행: `lune run run_test.luau` (저장소 루트에서).

## 커밋

- 서로 다른 관심사(리네임, 기능 추가, 삭제, 실험적 스캐폴딩, 스크래치
  노트)는 별도 커밋으로 나누세요 — 2026-08-22 세션이 그동안 쌓인 미커밋
  변경을 정리할 때 이 기준으로 7개 커밋으로 쪼갰습니다(`git log` 참고).
- 서브모듈(`libs/test-luau`) 안에서 변경했다면 서브모듈 커밋을 먼저 만들고,
  그다음 부모 저장소에서 서브모듈 포인터 bump를 포함한 커밋을 만드세요.
- 원격에 `git push`하지 마세요 — 사용자가 명시적으로 요청하기 전까지는
  로컬 커밋까지만 합니다(`origin`이 `github.com/qwreey/stl-luau`로 이미
  설정돼 있어 실수로 push하면 바로 공개 레포에 반영됩니다).

# stl-luau — 다른 모델 계열(agy/Gemini)을 위한 진입점

이 레포의 주 작업자는 Claude(Anthropic) 세션입니다. 너(Gemini, `agy`)는 **다른 모델 계열의 시선**으로
불려 왔습니다. 같은 베이스에서 증류된 Claude 계열(opus·sonnet)은 리뷰를 여러 번 돌려도 어휘·선택
편향을 공유해, 같은 틀 안에서만 문제를 찾습니다. 너에게 바라는 것은 그 틀 **밖**입니다 — 근본
원인을 위에서 찾기, 따로 올라온 문제들이 같은 메커니즘인지 묶기, 지금 설계가 놓친 것을 짚기.
틀릴 수 있다는 것은 괜찮습니다. 메인 세션이 모든 주장을 다시 확인합니다. 대신 **근거(파일:줄,
실행 출력)를 붙이고, 실행해 본 것은 "실측", 읽고 추론한 것은 "추정"으로** 갈라 주세요.

규칙 문서의 소스는 `CLAUDE.md` 와 그것이 import 하는 `.claude/conventions.md`,
`.claude/project-context.md`, `.claude/todos.md` 입니다. 이 파일은 그 요약이고, 어긋나면 그쪽이
맞습니다.

## 무엇인가

Roblox 엔진 언어 **Luau** 용 표준 라이브러리 스타일 컨테이너·알고리즘 모음. `src/` 에
`Arr`(배열, 연산 76 + 생성자 8), `HashMap`/`HashSet`, `TreeMap`/`TreeSet`(정렬 배열 + 이분 탐색),
`Heap`, `Optional`, `Fut`(코루틴 프로미스), `Algorithm`(계약만 아는 공용 알고리즘), `Common`.
1인 프로젝트, 아직 게시 전. **성능이 1급 관심사**이고 모든 성능 주장은 실측입니다
(`.claude/base/perf-measurements.md`).

## 확정된 결정 (사용자가 내림 — 제안은 해도 되지만 결정으로 다루지 말 것)

- **데이터는 엔티티, 함수는 서비스**(질문 AB): 컨테이너는 메타테이블 없는 평범한 테이블,
  연산은 전부 모듈 네임스페이스 함수(`Arr.Map(a, fn)`). 콜론 메소드 없음. 근거: 메타테이블이
  있으면 `t[i]` 가 1.6~2배 느려짐(실측), `Optional` 은 메소드를 못 가짐, 바깥에서 확장 가능.
- **판별은 태그 세 겹**: 런타임 태그 필드(`__arr__ = true`), 술어(`stl.isArr` — 태그 + 최상위
  필드 전부의 타입), 타입의 팬텀 태그(`read __arr__: true`). 그보다 깊은 위조는 **계약 밖**.
- **구멍은 타입에 `T?` 로 드러냄**(질문 T): `Arr` 은 `{ n, [number]: T }` 이고 1..n 사이에
  `nil` 이 있을 수 있음. 콜백은 `nil` 을 그대로 받음, 집계·정렬은 런타임 그물로 건너뜀,
  `?` 를 떼는 길은 `Compact`/`FillHoles`.
- **숫자 인자 정책**: NaN 은 에러(사용자 줄), 소수는 0 쪽, 구간은 clamp, 길이는 `[0, 2^26]`.
- **에러 규약**: 새 에러는 `Common.raise(msg)`(스택을 걸어 라이브러리가 아닌 첫 프레임을
  가리킴 — `-O2` 인라인 때문), 되던지기는 `Common.rethrow`(Fut 에서만).
- **타입을 바꾸는 `*Inplace` 는 입력을 소비**(질문 Y). `type function` 은 쓰지 않음.
- 콜백 셋째 인자는 `ArrView<unknown>` — Luau 새 솔버 결함 때문(`spikes/52`).

## 어디에 무엇이

| 무엇 | 어디 |
|---|---|
| 관례 전부(코드 스타일, 에러, 숫자, 구멍, 테스트, 리뷰 방식) | `.claude/conventions.md` |
| 지금 할 일·마일스톤(M3 Arr 빈 조각 → M4 맵·셋 → M5 Deque → M6 Multiset/OrderedMap → M7 Fut) | `.claude/todos.md` |
| **열린 질문**(사용자 답을 기다림)과 결정 이력 | `.claude/question.md` |
| 설계 페이퍼(빠진 표면 04, quad 탐사 05 등) | `.claude/papers/` |
| Luau 타입 한계와 우회 | `.claude/base/typing-limits.md` |
| 성능 실측 전량 | `.claude/base/perf-measurements.md` |
| 음성 대조군 스파이크(일부러 타입 에러가 나야 하는 파일) | `.claude/audit/arr-type-redesign/spikes/` + `scripts/spike-expectations.tsv` |
| 테스트 | `tests/spec.*.luau`, 엔트리 `tests/run.luau` |

## 검사

- `./scripts/check.sh` — 타입 에러 0, 음성 대조군(건수·줄 고정), require, 에러 규약, stylua,
  테스트(`-O1` 과 `-O2`). 판정은 exit code.
- 타입만: `luau-analyze <파일>`. 실행: `luau <파일>`. 순수 `luau` 런타임(lune 아님).

## 함정

- `const` 는 `local` 을 대체하는 키워드(`const x = 1`). `local const x = 1` 은 전역 대입이 됨.
- `(` 로 시작하는 문장 금지(stylua 2.5.2 가 앞의 `;` 를 지워 파싱 에러).
- 명시적 타입 인자 `f<<T>>(…)` 를 씀 — 콜백 파라미터 주석도 없애 줌(`spikes/54`).
- 이 레포의 리뷰는 "소진될 때까지" 돕니다. 지난 리뷰들은 같은 틀에서 라운드마다 비슷한 크기의
  결함을 냈습니다(게이트·테스트 공백). 너는 개별 결함보다 **그 반복의 뿌리**를 볼 수 있습니다.

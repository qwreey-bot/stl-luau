# 트레이트 타입 실험 모음 (2026-10-14, luau 0.742 `luau-analyze`)

사용자와 함께 "종류를 모르는 경로(트레이트)에서 원소 타입을 어떻게 흘리나" 를 판 실험들. 각 파일 끝의 `-- NEG` 줄이 잡혀야
하는 음성 대조군이고, 실행은 `luau-analyze <파일>`(저장소 루트에서 `( ulimit -v 2097152; timeout 60 luau-analyze … )`).
정리된 결론은 `../trait-v2/README.md`(연관 타입판)·`../trait-v3/README.md`(제네릭 트레이트판). 문제 설명은 `BRIEF-*.md`.

| 파일 | 무엇을 봤나 | 결과 |
|---|---|---|
| `union.luau` | 시그니처가 "덱 마커 **또는** 스택 마커" 를 받음 | 원소 추론이 `unknown` |
| `assocnames.luau` | `{ [Name]: T }` / 글자 그대로 `["Test"]` / 이름 박은 별칭의 교집합 / 타입 함수로 만든 속성 | 인덱서가 됨 / 속성 됨 / 합으로 섞임 / 역추론 안 됨 |
| `assocfields.luau` | 연관 타입을 테이블 안의 **공변** 필드로 | 두 번째 호출부터 합이 섞임 |
| `associnv.luau` | 연관 타입을 테이블 안의 **불변 팬텀**(`(T) -> T`)으로 | 정확 |
| `assocdx.luau` | 연관 타입 별칭을 컨테이너에 교집합으로 붙임 / 토큰 필드 안에 | 추출은 되나 `Self` 반환이 합으로 깨짐 / 됨 |
| `assoctoken.luau` | 토큰 타입이 연관 타입을 듦(`Token<"My.Bag", T>`) | 정확 |
| `assockit.luau`·`assoc3.luau`·`assoc3both.luau` | 불변 팬텀을 별칭(`Inv<T>`·`Assoc<A>`)으로 감쌈 / 양쪽 글자 그대로 | 다른 필드 타입·`unknown` / 정확 |
| `genericof.luau` | 받는 쪽이 `index<index<Self,"__generics">, Name>` 로 **앞으로 계산** | 진입점·바깥 계약 됨(등록 검사는 타입 함수가 그 안을 못 봄) |
| `implof.luau` | `ImplOf(trait, value)` 가 값의 타입으로 채운 함수 표를 줌 | 됨 |
| `deftag.luau` | `Default<<sig>>()` 꼬리표 → 등록 표에서 선택 필드 | 됨 |
| `fill3.luau`·`api3.luau` | 타입 함수 `FillGenerics` 로 등록 모양을 끌어냄 / API 모양(인자·반환으로 넘김 대 주석 단 지역) | 교집합을 접어야 됨 / 주석 단 지역만 됨 |
| `rewrite.luau`·`rewrite4/5/6.luau` | 시그니처엔 표식, `Fn` 출력을 타입 함수로 바꿔 끼움 / 자료 쪽 타입 함수·글자 그대로·`Inv` 별칭·공변 | 자료 타입이 타입 함수면 깨짐, 글자 그대로·`Inv` 는 됨, 공변은 넣는 쪽 검사가 빠짐 |
| `tags.luau` | `CreateGeneric`·`UseGeneric`·필드 단위 `ApplyGeneric` | 등록 검사가 깨짐 |
| `generictrait.luau` | 트레이트를 제네릭 타입으로(`typeof(stackDef<<Self, T>>())`) | 됨 — v3 |
| `anyre.luau` | 재대입한 `any` 지역의 최소 재현(0.742 의 레드블랙 진단) | 재현 안 됨 |

검사기 결함(별도): luau 0.734 의 `luau-analyze` 병렬 검사 힙 깨짐 — 상류 #3020, 0.742 에서 고쳐짐.

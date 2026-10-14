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
| `intotyped.luau` | 중개자가 찾기 함수(`Stack.Of`)에 정확한 제네릭 타입만 다시 붙임(`<T>(Arr<T>) -> Stack<Arr<T>, T>`) | 됨 — 런타임 비용 0, 주장은 구현자 한 번 |
| `dictionary.luau` | 구현 표 자체를 사전 값으로 넘김 | 안 됨 — 변수에 담은 제네릭 함수 표는 구체 타입에 안 맞춰짐 |
| `probetype.luau` | 등록 검사를 탐침 타입(`Stack<Arr<A>, A>`)으로 | 됨 — 구체 타입(`string`)으론 원소를 못박은 함수가 샘(지금 `src` 에도 있는 구멍) |
| `factoryof.luau` | `Trait<F>(name, factory: F): { read Of: F }` — 팩토리가 곧 `Of` 의 타입 | 됨 — 값에서 Self·T, 밝힌 T 가 값과 어긋나면 잡힘(Opus 종합) |
| `bidir-table-arg.luau` | 제네릭 함수를 구체 함수 타입 자리에: 주석 단 지역 / 인자 자리 표 리터럴 / 함수 하나를 인자로 | ~~지역만 됨~~ → **2026-10-14 소스 분석으로 정정**: 인자·`return`·대입 자리의 표 리터럴은 받는 타입의 필드가 읽기·쓰기(불변)라 반대 방향 비교가 실패하고, 그 실패가 **서브타입 캐시를 오염**시켜 뒤따르는 리터럴용 검사와 **같은 모듈의 뒷줄까지** 실패(결함 — 상류에 흔적 없음, DRAFTS 6번). **받는 타입의 필드를 `read` 로 적으면 인자 자리에서도 되고 검사도 됨**(메인 확인 — 앞줄의 실패에 오염되지 않게 따로 둘 때). "함수 하나를 인자로" 는 혼자 두면 됨(이 파일에선 앞줄에 오염됨). `../luau-source/README.md` |
| `anyre.luau` | 재대입한 `any` 지역의 최소 재현(0.742 의 레드블랙 진단) | 재현 안 됨 |

검사기 결함(별도): luau 0.734 의 `luau-analyze` 병렬 검사 힙 깨짐 — 상류 #3020, 0.742 에서 고쳐짐.

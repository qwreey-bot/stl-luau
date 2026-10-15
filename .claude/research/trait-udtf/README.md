# 레코드 매핑 안 — 사용자 `type function`(types 라이브러리)으로 정의를 한 번만 넘기기 (2026-10-15, 사용자 제안)

사용자: *"`{ required: true|false, fn: ... }` 식으로 Trait.Fn Trait.Default 가 나오게 하고, 내부적으로 입력 받자 마자 두 테이블 만들어 두면 안 돼? …
필드를 훑는건 … types 라이브러리로 될텐데 … 제네릭 재 구성은 어떤 영향을 미치는지 봐야할 필요가 있겠다"*. Sonnet 과 Gemini 가 독립적으로 봄.

> ⭐ **들임(2026-10-15 낮, 사용자: *"확인. 해보자"*)** — Sonnet 모양을 `src/Trait/init.luau` 의 `View` 로(이름만 바꿈 — `RebuildFactory` →
> `View`), 더한 것: 가변 꼬리 떼기(`Of` 인자 수), 정의자 실수 메시지, `any` 정의는 `any` 보기. 들이기 전 조건 — 편집기(luau-lsp 1.70.1 +
> Studio FFlag)에서 같은 결과, 구현자·쓰는 사람의 에러 문구가 D3 와 같음 — 은 `question.md` AY 머리. 아래 `sonnet/repoB-spikes` 의 69·70·72 는
> require 경로가 `../src`(시제품의 자리)라 이 폴더에선 돌지 않습니다 — 들인 판은 `spikes/69`·`70`.

## 메인 검증 — 결론: **거는 자리에 따라 갈림**

| 모양 | 결과 |
|---|---|
| **Sonnet**: 타입 함수 `RebuildFactory<F, mode>` 를 **정의 함수의 함수 타입 전체**에 걸고(정의할 때 바로 줄어듦), 반환 표의 필드를 훑어 `{ required, fn }` → `fn` / `fn?`, 매개변수와 **원래 제네릭 목록(`f:generics()`)을 되넘김**. `Trait.Trait(name, factory)` 의 타입이 `Object<RebuildFactory<F, "full">, RebuildFactory<F, "impl">>` | **됨**(메인 재실행): 스파이크 69(같은 모듈 기본 구현 반환 포함)·70(`Fold<U>` 못박기·원소 못박기·반환 틀림·`Find = Len`·제네릭 알고리즘) NEG 전부 같은 줄, 맞는 쓰임 0건. 메인이 더한 72(`drain<C, T>(st: StackFull<C, T>)` + **인라인** 등록의 `Fold<U>` 못박기·`Fold = Len`)도 전부 잡힘 — `sonnet/repoB-*` |
| **Gemini**: 타입 함수를 **바깥 제네릭이 든 표 별칭**에 걸음(`type Stack<C, T> = FullOf<StackDef<C, T>>`) | 안 됨(보고대로 — 상류가 `outer_generics_irreducible` 로 고정한 동작): 바깥 제네릭이 정해지지 않은 자리에선 줄어들지 않아 제네릭 알고리즘에서 `does not have key 'Pop'`, 인라인 등록의 제네릭 칸 검사가 빠짐 |

**Sonnet 모양 대 D3**(지금 src): 얻는 것 — 정의를 한 번(모드·`def(FULL), def(IMPL)` 없음), 내장 `index<>` 와 그 `never` 함정 없음, 정의자의 모드 실수가 구조적으로 사라짐. 잃는 것 — 사용자 타입 함수에 기댐(사용자의 주의 대상 — 타입을 직렬화했다 다시 지음: 다시 지은 제네릭의 스코프는 적용한 자리, 기본값·바운드는 사라짐, 지금 정의엔 없음), 에러·툴팁에서 별칭이 풀려 길어짐, 정의자 실수가 "type function errored at runtime" 꼴로 같은 줄에 여러 번. 부수: 정의 함수의 꼬리가 `any` 로 읽혀 `Of` 의 인자 수 검사가 빠짐 — D3 도 같음(`List.Of(d, 1, 2)` 0건), 꼬리를 빼면 둘 다 고쳐짐.

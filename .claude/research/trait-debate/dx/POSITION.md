# DX 변호인 입장문 — 트레이트 타입 설계 A·B·C

프로브는 전부 `dx/m/a/b/`(시제품 사본 + `src` 사본, luau 0.742, `ulimit`+`timeout`). 아래 `pN` 은 그 폴더의 파일.

## 순위: **B > A > C** (B 위에 선택적인 다듬기 D)

| 자리 | A (v6) | B (v8) | C |
|---|---|---|---|
| 정의(트레이트당 한 번) | 가장 짧음 | 한 겹 + `mode` + 별칭 한 줄 | 표 둘 + 이름 두 번 + **기본 구현 몸통이 타입을 잃음** |
| 등록(종류 × 트레이트 — 지금 21자리, 바깥 사람의 자리) | 기본 구현 칸마다 `Inherit`, 트레이트가 자라면 타입 에러 | **필수만** — 오늘 `List.Provided` 와 같은 모양 | 필수만, 문구에서 별칭 이름이 사라짐 |
| 쓰기 | 같음 | 같음(툴팁 같음, `p8`) | 같음 |

## 핵심 논거 셋

**1. 비용은 가장 많은 사람이 서는 자리(등록)에서 재야 하고, 거기서 A 는 지금보다 퇴행합니다.**
지금 저장소의 등록 표는 이미 B 의 모양입니다. `CircularDeque.luau` 의 `listImpl: List.Provided<…> = { Get, FirstIndex, LastIndex, NextIndex, PrevIndex }`,
`Provided` 는 기본 구현 칸이 `?` 입니다. A 로 가면 기본 구현을 받는 종류마다 `IndexOf = Trait.Inherit` 같은 줄이 진짜 `List` 의 기본 구현 수만큼(7줄)
붙습니다. 게다가 **그 줄은 런타임에 필요 없습니다.** A 의 런타임은 칸을 빼도 기본 구현을 채웁니다
(`p7_runtime.luau`: `A omit defaults (runtime) true`, `Contains` 가 기본 구현으로 `true`). 결국 `Inherit` 은 "타입이 선택 칸을 못 적어서 사람이
대신 적는 줄"입니다. 처음 보는 사람이 그 줄을 빼먹으면 이런 문구를 봅니다(`p1_impl_A.luau`).

```
Table type '{ FirstIndex: …, Get: …, … }' not compatible with type 'List<MyList<A>, A, number>'
because the former is missing fields 'IndexOf', 'Contains', and 'Fold'
```

이 문구는 `Inherit` 을 알려 주지 않습니다. 대신 **세 함수를 직접 짜라고** 읽힙니다. 기본 구현은 원래 그 수고를 덜려고 있는 기능인데,
문구가 거꾸로 이끕니다.

**2. A 는 이 저장소가 정한 성장 정책과 정면으로 부딪힙니다.**
conventions 에 이렇게 적혀 있습니다. *"알고리즘은 작게 시작해 점점 늘립니다(사용자 결정)"*, *"기본 구현은 바깥에서 그 트레이트를 구현하는 쪽을
위한 것"*. A 에서는 `List` 에 기본 구현을 하나 더할 때마다, 기본 구현을 받으려던 **바로 그 바깥 사람**의 등록 표가 `missing field 'Count'` 로
깨집니다. "타입만 깨지고 런타임은 정상"이라는 말은 위로가 안 됩니다. `--!strict` 프로젝트에서 TypeError 는 CI 실패이고, 이 저장소의
`check.sh` 도 TypeError 0건을 게이트로 겁니다. B·C 에서는 아무 일도 없습니다(`trait-v8/types.luau` 의 `oldProbeImpl`).
배울 이름 수는 A 와 B 가 같습니다. A 는 `List` + `Trait.Inherit`, B 는 `List` + `ListImpl` 입니다. B 는 "칸마다 표식을 적는 규칙"을
"주석의 별칭 하나"로 바꾼 것뿐입니다.

**3. B 는 사용자가 v5 에서 걸린 두 가지를 다 없앴고, 정의자가 더 내는 값은 작고 한 번뿐입니다. C 는 정의자 자리에서 실제로 깨집니다.**
v5 에서 걸린 것은 *"Trait() 밖까지 나가버림"* 과 *"Mut"* 였습니다. B 는 정의가 `Trait.Trait(…)` 호출 **안**에 있고 `Mut` 이 없습니다.
stylua 로 맞춘 모양(`dx/v8-Traits-fmt.luau`)은 A 보다 들여쓰기 한 단과 줄 둘(`function<M>(mode: M)`, `end`)이 더 있을 뿐입니다.
여기에 기본 구현마다 `mode, ` 를 적고 별칭 `XImpl` 을 한 줄 더 씁니다. 이 값은 트레이트당 한 번 내고, A 의 값은 등록 자리마다 계속 냅니다.
C 는 후보 문서의 조각에 `ops` 가 없습니다. 진짜 기본 구현은 형제 함수를 받아야 하는데, 그 모양으로 적으면 깨집니다.
`p6_C_builders.luau` 에서는 `ops: List<Self, E, I>` 가 순환해 기본 구현 칸이 `Self`·`E` 에 묶인 채 풀리지 않았고, 정상 호출
`full.IndexOf(m, 1)` 이 `Expected 'Self', got 'MyList<number>'` 로 거절됐습니다. 몸통에도 `I & ~nil` 거짓 에러가 났습니다.
돌아가게 하려면 `ops: any` 로 적어야 합니다(`p6c`). 그러면 기본 구현 몸통의 형제 검사(`ops.Nope` 가 잡히는 것)를 잃습니다.
또 C 의 등록 에러 문구에는 별칭 `StackImpl<…>` 대신 펼친 구조 타입이 통째로 나옵니다. B 는 `'StackImpl<Arr<A>, A>'` 로 나옵니다
(`main-split-names-only.luau` 와 `trait-v8/types.luau:84` 를 견줘 보세요).

## 예상 반론에 대한 답

- **"B 의 `index<>` 는 type function 금지에 어긋난다."** — 금지의 근거는 세 가지 함정입니다. 바깥 로컬 참조, `error` 진단,
  self 체이닝 붕괴이고, 내장 `index<>` 에는 셋 다 해당하지 않습니다. 체이닝도 이제 없습니다. 쓰는 자리의 툴팁은 A 와 글자까지 같습니다
  (`p8_hover_v6/v8` 의 `--annotate`: `l: {Contains: (list: CircularDeque<number>, item: number) -> boolean, …}`).
  `index` 는 정의자의 함수 안에서만 보입니다.
- **"B 의 정의자 실수 문구가 나쁘다."** — **맞습니다. 실측으로 인정합니다**(`p3_def_B.luau`). `Default` 에 `mode` 를 빼면
  `Property '(any) -> (Self) -> boolean' does not exist on type '{ full: unknown, impl: unknown? }'` 가 여섯 줄 나옵니다.
  `Default("full", …)` 이나 `function(mode)`(`<M>` 누락)로 적으면 에러가 **등록하는 사람의 줄로 번집니다**.
  그래도 이 비용은 정의자 한정이고, `mode` 를 숨기는 길은 막혀 있습니다. 바깥 겹이 `Default` 자체를 받게 해 보았는데
  `M` 추론이 실패해 쓰는 자리까지 `Cannot call a value of type index<…, unknown>` 이 됐습니다(`p4_D1_default_param_FAILS.luau`).
  그러니 `mode` 한 단어는 이 길의 최소 비용입니다. 대책은 템플릿 한 벌을 주는 것과, 시제품 머리 주석을 고치는 것입니다.
  `trait-v8/Trait/init.luau` 의 머리와 `Trait` 위 주석은 아직 v5 의 `Trait.Trait("Stack", stackDef, stackDef)`·`Mut` 을 설명합니다.
- **"B 는 같은 파일에서 기본 구현의 반환을 못 잡는다(A 는 잡음)."** — **재현했습니다**(`p10_B_samefile` 0건, `p10_A_samefile` 잡음).
  하지만 모듈을 나누면 잡힙니다(`p11_useB.luau`: `Expected 'string', got 'boolean'`). 이 라이브러리의 구조는 트레이트마다 `Traits/<이름>.luau` 이고
  쓰는 쪽은 늘 다른 모듈이라 해당하지 않습니다. 바깥 정의자에게는 "트레이트는 자기 모듈에" 한 줄로 충분합니다.
- **"B 는 재정의 이름의 오타(`IndexOff`)를 타입이 못 잡는다."** — 맞습니다. 대신 등록 줄에서 바로 런타임 에러가 납니다
  (`p7`: `p7_runtime.luau:16: Trait: My.ListB1 gave IndexOff to List, which List does not have`). A 는 이 오타를 `missing field 'IndexOf'` 로
  간접적으로 잡습니다. 문구는 B 쪽이 더 정확합니다.
- **"A 의 `Inherit` 은 `any` 라 필수 칸에 넣어도 0건."** — 런타임이 등록 줄에서 잡고(`p7`: `gave Trait.Inherit as FirstIndex … has no
  default implementation`), B 에는 이 구멍이 아예 없습니다.

## 선택적 다듬기 D (B 그대로 + 기본 구현 없는 트레이트는 한 겹)

진짜 트레이트 일곱 중 기본 구현이 있는 것은 `List` 하나뿐입니다. 나머지 여섯은 B 에서 쓰지도 않는 `mode` 겹을 달고 있습니다
(린트 경고는 없음 — `p0`). `Trait.Trait`(A 모양 한 겹, `Object<F, F>`)와 `Trait.WithDefaults`(B 모양)로 나누면 여섯은 A 와 글자까지 같아집니다.
v8 런타임은 고치지 않아도 됩니다(`TraitE2.luau`, 실행 `p9_run.luau` 에서 `D runtime pop: 5`). `StackImpl` 의 NEG 도 그대로 잡힙니다(`p9_D_two_names.luau`).
한 이름에 오버로드로 둘을 다 받게 하는 것은 안 됩니다. 두 겹 정의가 두 오버로드에 다 맞아 `ambiguous` 가 났습니다(`p5_overload_AMBIGUOUS.luau`).
대가는 이름 하나가 느는 것과, 첫 기본 구현을 더할 때 정의를 한 번 감싸야 하는 것입니다(정의자만 내고, `XImpl` 로 등록한 쪽은 그대로).
필수는 아니고, B 를 고른 뒤 사용자가 보실 선택지입니다.

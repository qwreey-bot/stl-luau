# 반박 (2라운드) — 타입 안전·견고함 변호인

프로브: `x/y/trait-v8p/`(B' 시제품 사본 — `Trait` 의 둘째·셋째 인자를 `def: (mode:"full")->F, implDef: ((mode:"impl")->G)?` 로 바꾼 것), `q1.luau`(같은 파일), `m1.luau`·`m2.luau`(모드), `scale20.luau`(규모).

## 인정한 것
1. **등록 자리의 퇴행은 사실입니다.** 지금 `listImpl: List.Provided<…>` 는 이미 필수만 적는 모양이고, A 는 기본 구현 받는 종류마다 `Inherit` 줄을 되살립니다.
   나는 "시끄러운 타입 전용 실패"를 장점으로 말했지만, 바깥 구현자에게는 *기본 구현을 받으려다 CI 가 깨지는* 정책 충돌입니다
   ("작게 시작해 점점 늘림"). 이 항목은 내가 졌습니다. 에러 문구가 `Inherit` 를 안내하지 않는다는 지적도 맞습니다.
2. **C 는 접습니다.** `ops` 를 받는 진짜 기본 구현에서 깨진다는 상대 프로브(`p6`)는 내 `c3`(몸통 한 줄로 인스턴스화 풀림)와 같은 계통의 결과입니다.
3. **같은 파일 구멍은 B 의 결함이 맞지만 B' 가 푼다 — 내 반대의 가장 큰 축이 사라졌습니다.** `trait-v8p/q1.luau`:
   모드를 `stackDef<<"full">>`·`<<"impl">>` 로 밝히면 같은 파일에서 `local r2: string = x.Contains(…)`, `r3 + 1`, 틀린 재정의 서명, 필수 칸 누락이 **전부 잡힘**
   (NEG 5줄 = 에러 5줄, `types.luau` 규칙). 이전 `q1/q2` 에서 0건이던 것과 같은 몸통입니다. 소스 분석(미해결 `index<>` → 서브타입 검사에서 `never`)과 일치합니다.
4. "이 저장소 구조(`Traits/<이름>.luau`)에선 해당 없음" — B 에서는 일부 맞지만, 사용자 트레이트와 라이브러리 내부 사용이 있어 B' 로 닫는 편이 낫습니다.
5. 툴팁이 A·B 글자까지 같다, 정의자 비용은 한 번뿐이라는 점도 인정합니다.

## 반박/남은 우려 (B' 에 대해)
- **실패의 모양이 위험합니다.** 미해결 `index<>` 가 `never` 로 떨어지면 서브타입 검사가 **참**이 됩니다 = 진단 0건. 모드를 밝히면 안 생기지만,
  이 보증은 "소스 한 곳의 현재 동작"에 기댑니다. 완화는 상류 신뢰가 아니라 **우리 쪽 그물**입니다: 트레이트마다 기본 구현 칸 하나의 반환 NEG 를
  `spikes`·`spike-expectations.tsv` 에 고정(이 저장소의 음성 대조군 규율 그대로 — 진단 0건은 경보). 이것이 B' 채택의 조건입니다.
- **재정의 오타는 여전히 타입이 못 잡습니다**(B' 에서도 `Contans = …` 는 0건, `q1.luau` 26행). A 는 잡았습니다. 런타임 `unknownName` 이 등록 줄에서 잡으므로
  무게는 작지만, 타입 층의 실제 손실입니다. 인정하고 "런타임 그물 + `spec.contracts` 배선 전수"로 덮는 것에 동의합니다(저장소가 이미 하는 일).
- **모드 오기는 시끄럽지만 거칠다.** 모드 오타(`<<"ful">>`)·`full`/`impl` 바꿔치기는 `Trait.Trait` 호출 줄에서 명확히 잡힘(`m1.luau` 11·12행).
  `Default("full", …)` 하드코딩이나 `<M>` 누락은 정의자 쪽에서 여러 줄 `Property 'string' does not exist…` — 상대가 인정한 대로 정의자 한정.
  `implDef` 를 **선택 인자로 두면** 생략 시 `ImplOf` 가 `Cannot instantiate type parameters…` 로 별칭 줄에서 터집니다(`m2.luau`, 시끄러움) — 필수 인자로 바꿀 것.
- **규모는 문제 없음:** `scale20.luau`(20 트레이트 × 기본 구현 6 × 등록 8) 0.20s, 틀린 재정의 서명 1건 정확히 잡힘.

## D("두 이름": 기본 구현 없으면 `Trait.Trait`, 있으면 `Trait.WithDefaults`)에 대해
**반대.** 트레이트가 기본 구현을 처음 얻는 순간 이름이 바뀌고 `XImpl` 별칭이 생겨 *그 트레이트의 모든 바깥 구현이 모양을 바꿉니다* — 성장 정책을 다시 해칩니다.
B' 의 `Trait.Trait` 는 기본 구현이 0개여도 같은 모양으로 동작하므로(정의에 `mode` 한 겹만 비용) 이름 하나로 충분합니다. 하나의 규칙이 둘보다 견고합니다.

## 수정된 최종 순위와 추천 모양
**B' > A > C** (이전: A > B > C — 근거 둘이 무너짐: 같은 파일 구멍은 B' 가 해결, 등록 퇴행/성장 충돌은 A 의 실제 비용).

추천 하나:
```lua
local function stackDef<M>(mode: M) return function<Self, T>(of: …) return { Push = Fn<<…>>(), IsEmpty = Default(mode, function(ops: Stack<Self,T>) … end) } end end
const Stack = Trait.Trait("Stack", stackDef<<"full">>, stackDef<<"impl">>)   -- 둘 다 필수 인자
export type Stack<Self,T>     = typeof(Stack.Of<<Self,T>>(nil :: any))
export type StackImpl<Self,T> = typeof(Stack.ImplOf<<Self,T>>(nil :: any))
```
채택 조건 셋: (1) 트레이트마다 기본 구현 반환 NEG 를 음성 대조군 배터리에 고정(`never` 폴스루 경보), (2) `implDef` 필수 + 정의자 템플릿/주석에 "`mode` 는 `Default` 에 그대로, 호출은 `<<"full">>`·`<<"impl">>`",
(3) 재정의 오타는 런타임 `unknownName`·`spec.contracts` 가 책임(타입 한계로 문서화). 가능하면 `freeze` 한 줄 등록도 같은 배터리 안에서 시험하되 확정은 이후.

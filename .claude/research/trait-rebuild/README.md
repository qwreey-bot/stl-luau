# 다시 만들 수 있는 트레이트 구현 — 시제품 (2026-10-14)

사용자 제안(질문 AW): 트레이트가 (다시) 구현될 때 **그것을 의존으로 쓰는 쪽을 다시 실행**해서, 기본 구현이 의존의 함수를
인덱싱 없이 미리 꺼내 두거나 **함수 자체를 돌려줘도** 낡지 않게. `src/Trait.luau` 는 건드리지 않았습니다.

| 파일 | 무엇 |
|---|---|
| `Trait3.luau` | 시스템. `src/Trait.luau` 와 다른 것: 의존 트레이트에 박힌 표식(`dependents`), 출처 기억(`sources`), 다시 만들기의 연쇄(`commit` → `rebuild`), 만드는 함수로 등록(`Impl(trait, token, function(deps) … end)`), 함수별 표(`FnTable`) |
| `Traits.luau` | 그 위의 `Deque`·`Stack`·`Queue`·`List` — 기본 구현이 만들 때 붙잡음. 진입점 세 모양(`Entry`·`Inline`·`ByFn`). `src` 의 `CircularDeque`·`LinkedDeque` 를 그 토큰으로 등록 |
| `check.luau` | 동작 확인 여덟 절(저절로 따라오기, "먼저 구현하라", 연쇄, 만드는 함수, 마름모, 같은 트레이트 안의 재정의, 던질 때, `src` 와 무작위 대조) |
| `bench.luau` | `src` 와 나란히 잼 |

실행:

```
( ulimit -v 1048576; timeout 60 luau -O2 .claude/research/trait-rebuild/check.luau )
( ulimit -v 1048576; timeout 300 luau -O2 .claude/research/trait-rebuild/bench.luau )
```

결과와 판단은 `.claude/base/perf-measurements.md` 50절, 정할 것은 `.claude/question.md` AW.

## 어떻게 도는가

1. `Trait3.New("Stack", { dependencies = { Deque }, … })` 가 `Deque.dependents[Stack] = true` 를 박습니다(약한 키).
2. 표를 만들 땐 늘 **새 표를 따로 짓고**(`assemble` — 의존 표를 모으고, 넘긴 표나 만드는 함수의 결과를 옮기고, 기본 구현으로
   채움) 그다음에 자리에 놓습니다(`commit`). 처음이면 그 표가 곧 완성 표, 아니면 **같은 테이블을 비우고 다시 채웁니다**.
3. `commit` 이 처음이 아니면(= 이미 있던 표가 바뀌었으면) `dependents` 를 돌며 그 종류의 표가 있는 트레이트를 `rebuild`.
   그것이 다시 `commit` 이라 위로 이어집니다.
4. 의존을 못 갖춘 종류에 등록하면 `K must implement Deque first to implement Stack`.

표가 바뀌는 길은 지금 규칙에서 **하나뿐**입니다 — 저절로 따라온 표 위에 명시 등록이 얹힐 때(명시 등록의 재등록은 에러).

## 시제품에서 드러난 것

- **같은 트레이트 안의 다른 기본 구현도 붙잡을 수 있습니다**: 만드는 함수가 받는 `ops` 에 필수 함수와 재정의가 이미 들어
  있으니 `const indexOf = ops.IndexOf or IndexOf`(AW 에 "붙잡을 수 없다" 고 적었던 것 — 됩니다).
- **함수를 미리 꺼내 둔 쪽은 그 뒤의 등록을 못 봅니다**(표를 쥔 쪽은 봄). `check.luau` 3절이 고정.
- **마름모는 두 번 다시 만듭니다**(A·B 가 D 에 의존, C 가 A·B 에 의존 — D 가 바뀌면 C 가 A 때 한 번, B 때 한 번). 끝 상태는 맞음.
- **다시 만들다 던지면 앞선 것은 이미 바뀐 채**입니다(그 트레이트의 표는 예전 그대로 — 낡은 쪽이 생김). 전부 지어 놓고
  한꺼번에 놓으려면 "아직 안 놓인 표" 를 의존으로 넘겨야 해서 한 겹 더 복잡해집니다.
- 필수만 있는 트레이트도 표를 복사합니다(`src` 는 넘긴 표 그대로) — 등록이 0.3~0.4 μs 느린 이유. 줄일 수 있습니다.

## 시제품이라 뺀 것

에러 규약(`Common.raise`), 토큰·트레이트 인자 검증, `__index` 로 물려받은 구현, `spec` 의 모르는 필드, `Expose`, 타입
(`Core`/`Full`/`Provided`). 넣는다면 `src/Trait.luau` 의 그것들 위에 2·3번을 얹는 일입니다.

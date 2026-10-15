# 시제품 v10 — v9 에서 트레이트 객체 타입의 인덱서를 뺌, 진입점 서명은 교집합으로 (2026-10-15, src 에 들이기 직전)

- `Trait/init.luau` 의 `Object<F, G>` 에서 `read [string]: any` 를 뺐습니다 — 그대로 두면 진입점 서명을 교집합으로 입힐 때
  `X.Of<<…>>` 가 함수가 아니게 됩니다(`T & any` → `T | error`, `../../audit/agy/2026-10-14-src-inst.md`).
- `overlay.luau`: `const Stack = StackBase :: typeof(StackBase) & { read Push: <C, T>(stack: C & Item<T>, item: T) -> C, … }` —
  진입점 호출·`Of`·명시 인스턴스화·등록 검사·같은 모듈의 기본 구현 반환이 전부 잡히고, 인덱서가 없어 없는 이름(`Stack.Nope`)도 잡힘.
  이 모양을 `src/Traits/*` 가 씁니다(진입점 서명은 옛 src 의 손으로 쓴 것 그대로 — 타입 회귀 없음).
- `old-runtime-review2-uncommitted.patch`: 옛 런타임(`src/Trait.luau`)의 커밋하지 않았던 리뷰 2라운드 작업분(약한 테이블을 도는 중의 GC,
  물려받은 재정의와 `ops`, 진입점 비테이블 시험). 새 시스템으로 갈아 끼우며 지운 파일에 있던 것이라 보관 — 새 시스템은 강한 배열이라 첫째는
  원리적으로 없고, 둘째는 등록 때 한 번 읽는 사본 + 빌더가 짓는 표에서 읽기로, 셋째는 `spec.traitrebuild` 7절로 옮겼습니다.

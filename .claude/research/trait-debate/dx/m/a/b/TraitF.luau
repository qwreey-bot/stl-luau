--!strict
--[[ 변형 D2(반박 라운드): v8 런타임 그대로, 이름 하나 `Trait.Trait`, 인자 수로 가름.
     - 기본 구현 없음: `Trait.Trait(이름, 팩토리)` — A 모양 한 겹(index<> 없음)
     - 기본 구현 있음: `Trait.Trait(이름, def<<"full">>, def<<"impl">>)` — B'(모드를 밝혀 적음 → 같은 모듈 구멍 없음)
     런타임: v8 의 Trait 은 둘째 인자만 보고 함수를 두 겹까지 벗김 — 셋째는 타입 전용. ]]
local Trait = require("./trait-v8/Trait")
type Object<F, G> = Trait.Object<F, G>
type TraitFn = (<F>(name: string, factory: F) -> Object<F, F>)
	& (<F, G>(name: string, full: (mode: "full") -> F, impl: (mode: "impl") -> G) -> Object<F, G>)
const Define: TraitFn = Trait.Trait :: any
return { Trait = Define }

--!strict
--[[ 변형 D(실현 가능한 쪽): v8 그대로 + 기본 구현이 없는 트레이트는 A 모양(한 겹)을 받는 오버로드.
     런타임: v8 의 Trait 은 이미 "함수면 벗김" 을 두 번까지 하니 한 겹도 그대로 돔 — 타입만 오버로드. ]]
local Trait = require("./trait-v8/Trait")
type Object<F, G> = Trait.Object<F, G>
type TraitFn = (<F, G>(name: string, def: ((mode: "full") -> F) & ((mode: "impl") -> G)) -> Object<F, G>)
	& (<F>(name: string, factory: F) -> Object<F, F>)
const Define: TraitFn = Trait.Trait :: any
return { Trait = Define }

--!strict
--[[ 변형 D3: 모드를 값으로 — `Trait.Trait("List", listDef(Trait.FULL), listDef(Trait.IMPL))`. 기본 구현 없으면 `Trait.Trait(이름, 팩토리)`.
     타입: 둘째·셋째가 이미 한 겹 벗긴 팩토리. 런타임: v8 Trait 이 둘째 인자를 받아 함수면 벗김(팩토리 → 표) — 그대로 돔. ]]
local Trait = require("./trait-v8/Trait")
type Object<F, G> = Trait.Object<F, G>
type TraitFn = (<F>(name: string, factory: F) -> Object<F, F>) & (<F, G>(name: string, full: F, impl: G) -> Object<F, G>)
const Define: TraitFn = Trait.Trait :: any
const FULL: "full" = "full"
const IMPL: "impl" = "impl"
return { Trait = Define, FULL = FULL, IMPL = IMPL, Default = Trait.Default, Fn = Trait.Fn }

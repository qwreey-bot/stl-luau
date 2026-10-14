--!strict
--[[ 변형 D: v8 런타임 그대로, 이름 둘 — 기본 구현이 없으면 `Trait.Trait`(A 모양 한 겹), 있으면 `Trait.WithDefaults`(B 모양).
     (한 이름에 오버로드로 둘을 받게 하면 두 겹 정의가 두 오버로드에 다 맞아 "ambiguous" — p5_overload_AMBIGUOUS.luau) ]]
local Trait = require("./trait-v8/Trait")
type Object<F, G> = Trait.Object<F, G>
const Plain: <F>(name: string, factory: F) -> Object<F, F> = Trait.Trait :: any -- 런타임은 한 겹도 벗김(v8 init 의 두 번 벗기기)
return { Trait = Plain, WithDefaults = Trait.Trait }

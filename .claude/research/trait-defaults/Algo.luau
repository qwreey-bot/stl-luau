--!strict
--[[
	시제품: 타입 있는 진입점 (papers/07).

	합쳐진 함수 표는 런타임에 만들어져 타입 검사기가 모릅니다. 그래서 **타입은 여기 한 곳에** 적습니다 —
	지금의 `src/Algorithm.luau` 와 같은 자리입니다. 종류를 아는 코드는 `Arr.Fold` 를 직접 부르고,
	종류를 모르는 코드는 `Algo.Fold` 를 부릅니다(트레이트 마커에서 원소 타입을 추론).

	⚠️ Luau 에는 "같은 종류인데 원소 타입만 다른 컨테이너" 를 적을 방법이 없습니다(고차 종류).
	그래서 원소 타입이 **그대로**인 것(`Filter`)은 넣은 타입 그대로 돌려주고, 원소 타입이 **바뀌는**
	것(`Map`)은 결과를 담을 **목적지 인스턴스**를 받습니다(질문 AR 과 같은 모양).
]]
local stl = require("../../../src")
local Trait2 = require("./Trait2")
local Traits = require("./Traits")
require("./Containers")

type ListMarker<E, I> = stl.ListMarker<E, I>
type ListMarkerMut<E, I> = stl.ListMarkerMut<E, I>

local Algo = {}

local function need(trait: any, value: any, who: string): any
	const ops = Trait2.ImplOf(trait, value)
	if ops == nil then
		error(`Algo.{who} needs a {trait.name}`, 3)
	end
	return ops
end

function Algo.Fold<E, I, U>(list: ListMarker<E, I>, init: U, fn: (acc: U, item: E) -> U): U
	return need(Traits.List, list, "Fold").Fold(list, init, fn)
end
function Algo.Find<E, I>(list: ListMarker<E, I>, pred: (item: E) -> boolean): E?
	return need(Traits.List, list, "Find").Find(list, pred)
end
function Algo.Contains<E, I>(list: ListMarker<E, I>, item: E): boolean
	return need(Traits.List, list, "Contains").Contains(list, item)
end
-- 원소 타입이 그대로 — 넣은 타입 그대로 돌려줌
function Algo.Filter<C, E, I>(list: C & ListMarker<E, I>, pred: (item: E) -> boolean): C
	return need(Traits.Seq, list, "Filter").Filter(list, pred)
end
-- 원소 타입이 바뀜 — 목적지 인스턴스에 담고 그 타입 그대로 돌려줌
function Algo.MapInto<E, I, G, J, D>(list: ListMarker<E, I>, fn: (item: E) -> G, into: D & ListMarkerMut<G, J>): D
	const push = need(Traits.Build, into, "MapInto").PushBack
	need(Traits.List, list, "MapInto").Each(list, function(item: E)
		push(into, fn(item))
	end)
	return into
end

return Algo

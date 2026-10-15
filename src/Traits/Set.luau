--!strict
--[[
	Set — 원소의 존재만 다루는 컨테이너의 트레이트. `HashSet`/`TreeSet`/`FlatSet` 이 구현합니다.

	**이름을 맵과 일부러 가릅니다**: 셋은 `Add`/`Has`/`Remove`, 맵은 `Set`/`Get`. 셋이 맵 위에 얹혀
	있어도 바깥 어휘는 완전히 분리합니다.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")

--[[ 마커 — 타입에만 있는 필드(읽으면 nil — 읽는 코드를 쓰지 마세요) ]]

-- 읽기 마커(공변). `T` 는 원소.
export type Marker<T> = { read __type: Trait.Token<any>, read __setItem: T }
-- 원소를 **입력으로 받아 넘기는** 제네릭용 불변 마커(질문 AM — 자세한 것은 `Traits/Map` 의 `MarkerMut`).
export type MarkerMut<T> = { read __type: Trait.Token<any>, read __setItem: T, read __setMut: (T) -> T }

type Item<T> = Trait.Item<T>
type AnyToken = Trait.AnyToken
const Fn = Trait.Fn

--[[ 정의 ]]
-- `Add`·`Remove` 는 바뀌었는가(새로 들어갔나 / 있어서 지웠나), `Items` 는 원소들의 새 배열.
const Set = Trait.Trait("Set", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return table.freeze({
		Add = Fn<<(set: Self, item: T) -> boolean>>(),
		Has = Fn<<(set: Self, item: T) -> boolean>>(),
		Remove = Fn<<(set: Self, item: T) -> boolean>>(),
		Items = Fn<<(set: Self) -> { T }>>(),
	})
end)
-- 완성 표(= 등록 표 — 기본 구현이 없음). 진입점(`Set.Add` …)은 시스템이 만들지만 서명을 입히지 않습니다(부르는 곳이 생기면 `MarkerMut` 로).
export type Full<Self, T> = typeof(Set.Of<<Self, T>>(nil :: any))
export type Provided<Self, T> = typeof(Set.ImplOf<<Self, T>>(nil :: any))

return Set

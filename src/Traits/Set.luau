--!strict
--[[
	Set — 원소의 존재만 다루는 컨테이너의 트레이트. `HashSet`/`TreeSet` 이 구현합니다.

	**이름을 맵과 일부러 가릅니다**: 셋은 `Add`/`Has`/`Remove`, 맵은 `Set`/`Get`. 셋이 맵 위에 얹혀
	있어도 바깥 어휘는 완전히 분리합니다.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")

--[[ 계약 ]]

export type Ops<C, T> = {
	read Add: (set: C, item: T) -> boolean,
	read Has: (set: C, item: T) -> boolean,
	read Remove: (set: C, item: T) -> boolean,
	read Items: (set: C) -> { T },
}

--[[ 마커 — 타입에만 있는 필드(읽으면 nil — 읽는 코드를 쓰지 마세요) ]]

-- 읽기 마커(공변). `T` 는 원소.
export type Marker<T> = { read __type: Trait.Token<any>, read __setItem: T }
-- 원소를 **입력으로 받아 넘기는** 제네릭용 불변 마커(질문 AM — 자세한 것은 `Traits/Map` 의 `MarkerMut`).
export type MarkerMut<T> = { read __type: Trait.Token<any>, read __setItem: T, read __setMut: (T) -> T }

const Set = Trait.New<<Ops<any, any>>>("Set", { required = { "Add", "Has", "Remove", "Items" } })

return Set

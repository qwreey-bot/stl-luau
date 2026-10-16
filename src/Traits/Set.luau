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

-- 연관 타입 레코드(질문 BA): 컨테이너가 `read __traits: { read Set: Set.Assoc<T> }`. 원소는 공변 칸 + 불변 `Mut`(맵과 같음), 조건은 불변.
export type AssocRead<T> = { read Item: () -> T }
export type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
export type ValueRead<T> = { read __type: Trait.Token<any>, read __traits: { read Set: AssocRead<T> } }
export type Value<T> = { read __type: Trait.Token<any>, read __traits: { read Set: Assoc<T> } }

type AnyToken = Trait.AnyToken
const Fn, FnMut = Trait.Fn, Trait.FnMut

--[[ 정의 ]]
-- `Add`·`Remove` 는 바뀌었는가(새로 들어갔나 / 있어서 지웠나), `Items` 는 원소들의 새 배열.
const Set = Trait.Trait("Set", function<Self, T>(of: (Self & Value<T>) | AnyToken)
	return table.freeze({
		Add = FnMut<<(set: Self, item: T) -> boolean>>(),
		Has = Fn<<(set: Self, item: T) -> boolean>>(),
		Remove = FnMut<<(set: Self, item: T) -> boolean>>(),
		Items = Fn<<(set: Self) -> { T }>>(),
	})
end)
-- 완성 표(= 등록 표 — 기본 구현이 없음). 진입점(`Set.Add` …)은 시스템이 만들고 서명은 정의에서 지어집니다(`Trait.Entries`).
export type Full<Self, T> = typeof(Set.OfMut<<Self, T>>(nil :: any))
export type ReadFull<Self, T> = typeof(Set.Of<<Self, T>>(nil :: any))
export type Provided<Self, T> = typeof(Set.ImplOf<<Self, T>>(nil :: any))

return Set

--!strict
--[[
	Collection — 원소를 담는 것이면 무엇이든(2026-10-12, 질문 AM 다 → AO — Java `Collection` 의 결).
	리스트·맵·셋·힙이 전부 구현합니다. 한 종류가 `List` 와 `Collection` 처럼 여러 트레이트를 구현합니다.

	이 파일이 트레이트의 전부입니다: 정의(필수 `Len`·`Clear`), 타입 마커, 종류를 모르는 코드의 진입점 서명
	(`Collection.Len(c)`·`Collection.Clear(c)` — 진입점 자체는 시스템이 만듦).
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")
type AnyToken = Trait.AnyToken
const Fn, FnMut = Trait.Fn, Trait.FnMut

--[[ 마커 — 타입에만 있는 필드 ]]
-- 읽기(크기): 토큰만 — 읽기 전용으로 빌린 참조(`ArrRead`·`CircularDequeRead`)도 받습니다.
export type Marker = { read __type: Trait.Token<any> }
-- 바꾸는 쪽(비우기): 바꿀 수 있는 참조만 적는 레코드 `read __traits: { read Collection: Collection.Assoc }` 를 요구(빌린 읽기 타입은 안 적음) —
-- 토큰만 요구했더니 읽기 전용으로 빌린 참조가 진단 0건으로 지워졌습니다(질문 AO, `spikes/63`).
export type Assoc = { read Mut: true }
export type MarkerMut = { read __type: Trait.Token<any>, read __traits: { read Collection: Assoc } }

--[[ 정의 ]]
-- 원소 타입이 없는 트레이트라 연관 타입 없이 `Self` 만. `Clear` 는 자기 자신을 돌려줌.
-- 읽기 보기 `Of`(`Len`)는 아무 종류(빌린 참조 포함), 완성 표 `OfMut`(`Clear` 까지)은 바꿀 수 있는 참조만 — 예전엔 `Of` 하나라 빌린 참조가
-- 완성 표를 거쳐 `Clear` 를 얻었습니다(질문 BA, `spikes/71`).
const CollectionBase = Trait.Trait(
	"Collection",
	function<Self>(of: (Self & Marker) | AnyToken, ofMut: (Self & MarkerMut) | AnyToken)
		return table.freeze({
			Len = Fn<<(collection: Self) -> number>>(),
			Clear = FnMut<<(collection: Self) -> Self>>(),
		})
	end
)
-- 완성 표(= 등록 표 — 기본 구현이 없음)
export type Full<Self> = typeof(CollectionBase.OfMut<<Self>>(nil :: any))
export type Read<Self> = typeof(CollectionBase.Of<<Self>>(nil :: any))
export type Provided<Self> = typeof(CollectionBase.ImplOf<<Self>>(nil :: any))

--[[ 진입점 서명 — 종류를 모르는 코드가 부릅니다(진입점 자체는 시스템이 만든 것) ]]
const Collection = CollectionBase -- 진입점 서명은 정의에서 지어짐(`Trait.Entries`)

return Collection

--!strict
--[[
	Collection — 원소를 담는 것이면 무엇이든(2026-10-12, 질문 AM 다 → AO — Java `Collection` 의 결).

	리스트·맵·셋·힙이 전부 구현합니다. 한 종류가 `List` 와 `Collection` 처럼 여러 트레이트를 구현합니다.
	이 파일이 트레이트의 전부입니다: 계약(`Ops`), 타입 마커, 종류를 모르는 코드의 진입점
	(`Collection.Len(c)`·`Collection.Clear(c)`).
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")

--[[ 계약 ]]

-- **크기는 알고 있는 값**이어야 합니다(O(1) — 세어서 구하는 것은 `List.Count`).
-- `Clear` 는 자기 자신을 돌려줍니다(질문 AM 가).
export type Ops<C> = {
	read Len: (collection: C) -> number,
	read Clear: (collection: C) -> C,
}

--[[ 마커 — 타입에만 있는 필드(런타임엔 없음) ]]

-- 읽는 쪽(`Len`)은 **타입 토큰만** 요구합니다 — 토큰은 있지만 컬렉션이 아닌 것(`Fut`)은 타입을 지나
-- 런타임에 `Common.raise` 로 걸립니다(읽기 마커 필드를 데이터 타입 일곱과 읽기 타입 셋에 하나씩 더
-- 두는 값을 못 해서).
export type Marker = { read __type: Trait.Token<any> }
-- **바꾸는 쪽**(`Clear`)은 이 팬텀을 요구합니다 — 원소 타입이 흘러들지 않아 불변일 필요는 없지만,
-- **읽기 전용으로 빌린 참조**(`ArrRead`·`DequeRead`)가 `Clear` 를 얻으면 안 됩니다(토큰만 요구하니
-- 진단 0건으로 지워졌습니다 — 시제품에서 재현, AC 의 "빌린 참조가 쓰기를 얻음" 과 같은 결). 팬텀은
-- 데이터 타입(`ArrData`·`DequeData`·맵·셋·`HeapData`)에만 있습니다. 새 컨테이너에도 같이 넣으세요.
export type MarkerMut = { read __type: Trait.Token<any>, read __collectionMut: true }

const Collection = Trait.New<<Ops<any>>>("Collection", { required = { "Len", "Clear" } })
const dispatch = Trait.Dispatch

--[[ 진입점 — 종류를 모르는 코드가 부릅니다 ]]

-- 알고 있는 크기(O(1)). 리스트·맵·셋·힙 어느 것이든. 읽기라 빌린 참조(`ArrRead`·`DequeRead`)도 받습니다.
const function Len(collection: Marker): number
	return dispatch(Collection, collection, "Len").Len(collection)
end

-- 비우고 **같은 컨테이너를 그 타입 그대로** 돌려줍니다(`HashMap<string, number>` 를 넣으면 그 타입).
-- 맵 종류를 모르고 "비우고 다시 채우기" 를 쓸 때. 읽기 전용으로 빌린 참조는 못 넣습니다(`MarkerMut`).
const function Clear<C>(collection: C & MarkerMut): C
	dispatch(Collection, collection, "Clear").Clear(collection)
	return collection
end

-- stylua: ignore
return Trait.Module(Collection, {
	Len = Len, Clear = Clear,
})

--!strict
--[[
	Deque — 양끝에서 넣고 빼는 컨테이너의 트레이트. `CircularDeque`(링 버퍼)와 `LinkedDeque`(노드)가
	구현합니다(2026-10-13 사용자: *"링크드 데큐와 써큘러 데큐를 나눠야하고. 이것도 Trait 으로 몰라도 접근
	가능한 구조여야"*).

	이 파일이 트레이트의 전부입니다: 정의(필수 여섯), 타입 마커, 종류를 모르는 코드의 진입점 서명
	(`Deque.PushBack(d, v)`·`Deque.PopFront(d)` …). 크기와 비우기는 `Collection`, 순회·찾기는 `List` 에
	있습니다 — 두 구현 모두 셋을 다 구현합니다. 덱이면 `Stack`·`Queue` 가 따라옵니다(그 파일의 뭉텅이 구현).

	어느 쪽을 쓸지(perf 35절): 양끝만 쓰면 **원형이 빠릅니다**(노드 할당이 없음). 연결은 **가운데의 위치
	(노드)를 쥐고 O(1) 로 넣고 빼야** 할 때 — LRU 목록, 순회하며 떼어 내기.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")
type Item<T> = Trait.Item<T>
type AnyToken = Trait.AnyToken
const Fn = Trait.Fn

--[[ 마커 — 타입에만 있는 필드 ]]
-- 읽기(공변): 꺼내 보기만 하는 진입점(`Front`·`Back`)용 — 빌린 참조(`CircularDequeRead`)도 받습니다.
export type Marker<T> = { read __type: Trait.Token<any>, read __dequeItem: T }
-- 넣고 빼는 진입점용 불변 마커(질문 AM — 읽기 마커로 받으면 원소 타입이 조용히 넓어짐).
export type MarkerMut<T> = { read __type: Trait.Token<any>, read __dequeItem: T, read __dequeMut: (T) -> T }

--[[ 정의 ]]
-- 쓰는 함수가 있는 트레이트 — `of` 는 불변 연관 타입 `Item<T>`(읽기 전용으로 빌린 참조는 `Deque.Of` 를 못 얻음).
const DequeBase = Trait.Trait("Deque", function<Self, T>(of: (Self & Item<T>) | AnyToken)
	return table.freeze({
		PushFront = Fn<<(deque: Self, item: T) -> Self>>(),
		PushBack = Fn<<(deque: Self, item: T) -> Self>>(),
		PopFront = Fn<<(deque: Self) -> T?>>(),
		PopBack = Fn<<(deque: Self) -> T?>>(),
		Front = Fn<<(deque: Self) -> T?>>(),
		Back = Fn<<(deque: Self) -> T?>>(),
	})
end)
-- 완성 표(= 등록 표 — 기본 구현이 없음)
export type Full<Self, T> = typeof(DequeBase.Of<<Self, T>>(nil :: any))
export type Provided<Self, T> = typeof(DequeBase.ImplOf<<Self, T>>(nil :: any))

--[[ 진입점 서명 ]]
const Deque = DequeBase :: typeof(DequeBase) & {
	-- 앞·뒤에 넣고 넣은 타입 그대로 돌려줍니다.
	read PushFront: <C, T>(deque: C & MarkerMut<T>, item: T) -> C,
	read PushBack: <C, T>(deque: C & MarkerMut<T>, item: T) -> C,
	-- 앞·뒤를 꺼냅니다. 비었으면 nil.
	read PopFront: <T>(deque: MarkerMut<T>) -> T?,
	read PopBack: <T>(deque: MarkerMut<T>) -> T?,
	-- 앞·뒤를 봅니다(꺼내지 않음). 비었으면 nil. 읽기라 빌린 참조도 받습니다.
	read Front: <T>(deque: Marker<T>) -> T?,
	read Back: <T>(deque: Marker<T>) -> T?,
}

return Deque

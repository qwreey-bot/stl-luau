--!strict
--[[
	Deque — 양끝에서 넣고 빼는 컨테이너의 트레이트. `CircularDeque`(링 버퍼)와 `LinkedDeque`(노드)가
	구현합니다(2026-10-13 사용자: *"링크드 데큐와 써큘러 데큐를 나눠야하고. 이것도 Trait 으로 몰라도 접근
	가능한 구조여야"*).

	이 파일이 트레이트의 전부입니다: 계약(`Core`), 타입 마커, 종류를 모르는 코드의 진입점
	(`Deque.PushBack(d, v)`·`Deque.PopFront(d)` …). 크기와 비우기는 `Collection`, 순회·찾기는 `List` 에
	있습니다 — 두 구현 모두 셋을 다 구현합니다.

	어느 쪽을 쓸지(perf 35절): 양끝만 쓰면 **원형이 빠릅니다**(노드 할당이 없음). 연결은 **가운데의 위치
	(노드)를 쥐고 O(1) 로 넣고 빼야** 할 때 — LRU 목록, 순회하며 떼어 내기.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")

--[[ 계약 ]]

-- 여섯 다 O(1)(원형의 넣기는 분할 상환). 넣기는 **자기 자신**을 돌려줍니다(`Arr.PushBack` 과 같음).
-- 꺼내기·보기는 비었으면 `nil` — 구멍(`nil` 원소)을 담은 덱에서는 `Collection.Len` 으로 가르세요.
export type Core<C, T> = {
	read PushFront: (deque: C, item: T) -> C,
	read PushBack: (deque: C, item: T) -> C,
	read PopFront: (deque: C) -> T?,
	read PopBack: (deque: C) -> T?,
	read Front: (deque: C) -> T?,
	read Back: (deque: C) -> T?,
}

--[[ 마커 — 타입에만 있는 필드(읽으면 nil — 읽는 코드를 쓰지 마세요) ]]

-- 읽기 마커(공변). 보기만 하는 진입점(`Front`·`Back`)용 — 빌린 읽기 참조도 받습니다.
export type Marker<T> = { read __type: Trait.Token<any>, read __dequeItem: T }
-- 넣고 빼는 진입점용 불변 마커(질문 AM 과 같은 규칙 — 읽기 마커로 원소를 받아 넣으면 그 타입이 조용히
-- 넓어집니다). 팬텀은 데이터 타입에만 있어 읽기 전용으로 빌린 참조는 꺼내기도 못 합니다.
export type MarkerMut<T> = { read __type: Trait.Token<any>, read __dequeItem: T, read __dequeMut: (T) -> T }

const Deque = Trait.New<<Core<any, any>>>("Deque", {
	required = { "PushFront", "PushBack", "PopFront", "PopBack", "Front", "Back" },
})
const expectImpl = Trait.ExpectImpl

--[[ 진입점 — 종류를 모르는 코드가 부릅니다 ]]
-- 종류를 아는 코드는 그 모듈의 함수를 직접 쓰세요(`CircularDeque.PushBack`) — 구현 찾기가 호출마다 붙습니다.

-- 맨 앞에 넣고 **넣은 타입 그대로** 돌려줍니다.
const function PushFront<C, T>(deque: C & MarkerMut<T>, item: T): C
	expectImpl(Deque, deque, "PushFront").PushFront(deque, item)
	return deque
end

-- 맨 뒤에 넣고 넣은 타입 그대로 돌려줍니다.
const function PushBack<C, T>(deque: C & MarkerMut<T>, item: T): C
	expectImpl(Deque, deque, "PushBack").PushBack(deque, item)
	return deque
end

-- 맨 앞을 꺼냅니다. 비었으면 `nil`.
const function PopFront<T>(deque: MarkerMut<T>): T?
	return expectImpl(Deque, deque, "PopFront").PopFront(deque)
end

-- 맨 뒤를 꺼냅니다. 비었으면 `nil`.
const function PopBack<T>(deque: MarkerMut<T>): T?
	return expectImpl(Deque, deque, "PopBack").PopBack(deque)
end

-- 맨 앞을 봅니다(꺼내지 않음). 비었으면 `nil`.
const function Front<T>(deque: Marker<T>): T?
	return expectImpl(Deque, deque, "Front").Front(deque)
end

-- 맨 뒤를 봅니다. 비었으면 `nil`.
const function Back<T>(deque: Marker<T>): T?
	return expectImpl(Deque, deque, "Back").Back(deque)
end

-- stylua: ignore
return Trait.Expose(Deque, {
	PushFront = PushFront, PushBack = PushBack, PopFront = PopFront, PopBack = PopBack,
	Front = Front, Back = Back,
})

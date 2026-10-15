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
type AnyToken = Trait.AnyToken
const Fn, FnMut = Trait.Fn, Trait.FnMut

--[[ 연관 타입 레코드와 마커 — 타입에만 있는 필드(질문 BA) ]]
-- 컨테이너가 `read __traits: { read Deque: Deque.Assoc<T> }`(빌린 읽기 타입은 `AssocRead<T>`). `Item` 공변, `Mut` 불변 팬텀.
export type AssocRead<T> = { read Item: () -> T }
export type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
-- 조건(정의의 `of`·`ofMut`, 진입점의 첫 인자) — 스택·큐도 이것을 씁니다(덱이면 따라옴).
export type Marker<T> = { read __type: Trait.Token<any>, read __traits: { read Deque: AssocRead<T> } }
export type MarkerMut<T> = { read __type: Trait.Token<any>, read __traits: { read Deque: Assoc<T> } }

--[[ 정의 ]]
-- 칸은 읽기(`Fn` — `Front`·`Back`)와 쓰기(`FnMut` — 넣기·빼기). 읽기 보기 `Deque.Of` 는 공변 `Marker`(빌린 참조도 `Front`·`Back`), 완성 표
-- `Deque.OfMut` 은 불변 `MarkerMut`(질문 BA — 예전엔 빌린 참조가 `Deque.Of` 를 아예 못 얻었음).
const DequeBase = Trait.Trait(
	"Deque",
	function<Self, T>(of: (Self & Marker<T>) | AnyToken, ofMut: (Self & MarkerMut<T>) | AnyToken)
		return table.freeze({
			PushFront = FnMut<<(deque: Self, item: T) -> Self>>(),
			PushBack = FnMut<<(deque: Self, item: T) -> Self>>(),
			PopFront = FnMut<<(deque: Self) -> T?>>(),
			PopBack = FnMut<<(deque: Self) -> T?>>(),
			Front = Fn<<(deque: Self) -> T?>>(),
			Back = Fn<<(deque: Self) -> T?>>(),
		})
	end
)
-- 완성 표(= 등록 표 — 기본 구현이 없음)
export type Full<Self, T> = typeof(DequeBase.OfMut<<Self, T>>(nil :: any))
export type Read<Self, T> = typeof(DequeBase.Of<<Self, T>>(nil :: any))
export type Provided<Self, T> = typeof(DequeBase.ImplOf<<Self, T>>(nil :: any))

--[[ 진입점 서명 — 정의에서 지어짐(`Trait.Entries`): 쓰기 칸은 `MarkerMut`, 읽기 칸은 `Marker` 를 받음 ]]
const Deque = DequeBase

return Deque

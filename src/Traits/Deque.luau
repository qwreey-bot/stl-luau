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
local Stack = require("./Stack")
local Queue = require("./Queue")
type AnyToken = Trait.AnyToken
type A = Trait.A
type B = Trait.B
const Fn, FnMut = Trait.Fn, Trait.FnMut

--[[ 연관 타입 레코드와 마커 — 타입에만 있는 필드(질문 BA) ]]
-- 컨테이너가 `read __traits: { read Deque: Deque.Assoc<T> }`(빌린 읽기 타입은 `AssocRead<T>`). `Item` 공변, `Mut` 불변 팬텀.
export type AssocRead<T> = { read Item: () -> T }
export type Assoc<T> = { read Item: () -> T, read Mut: (T) -> T }
-- 조건(정의의 `of`·`ofMut`, 진입점의 첫 인자) — 스택·큐도 이것을 씁니다(덱이면 따라옴).
export type ValueRead<T> = { read __type: Trait.Token<any>, read __traits: { read Deque: AssocRead<T> } }
export type Value<T> = { read __type: Trait.Token<any>, read __traits: { read Deque: Assoc<T> } }

--[[ 정의 ]]
-- 칸은 읽기(`Fn` — `Front`·`Back`)와 쓰기(`FnMut` — 넣기·빼기). 읽기 보기 `Deque.Of` 는 공변 `ValueRead`(빌린 참조도 `Front`·`Back`), 완성 표
-- `Deque.OfMut` 은 불변 `Value`(질문 BA — 예전엔 빌린 참조가 `Deque.Of` 를 아예 못 얻었음).
const DequeBase = Trait.Trait(
	"Deque",
	function<Self, T>(of: (Self & ValueRead<T>) | AnyToken, ofMut: (Self & Value<T>) | AnyToken)
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
export type ReadFull<Self, T> = typeof(DequeBase.Of<<Self, T>>(nil :: any))
export type Provided<Self, T> = typeof(DequeBase.ImplOf<<Self, T>>(nil :: any))

--[[ 덱이면 스택·큐 — 덱 쪽이 압니다(2026-10-15 사용자: *"Stack 은 Deque 가 뭔지 알 필요가 있을까?"* — 질문 BA) ]]
-- 런타임: 뭉텅이 구현(`ImplWhere`) — 덱을 구현한 모든 종류(나중에 생긴 바깥 덱도)가 스택·큐를 구현합니다. 덱의 함수를 **그대로** 돌려줍니다
-- (감싸지 않음 — 질문 AW): `Stack.OfMut(d).Push` 가 곧 `PushBack`(perf 52절). 몸통은 탐침 타입(A = 종류, B = 원소)으로 — 제네릭 `<C, T>`
-- 몸통은 원소를 못박은 함수가 0건(상류 결함 `Subtyping.cpp:830`).
local function stackFromDeque(deque: Full<A, B>): Stack.Provided<A, B>
	return { Push = deque.PushBack, Pop = deque.PopBack, Peek = deque.Back }
end
local function queueFromDeque(deque: Full<A, B>): Queue.Provided<A, B>
	return { Push = deque.PushBack, Pop = deque.PopFront, Peek = deque.Front }
end
Stack.ImplWhere({ DequeBase }, function(deps)
	return stackFromDeque(deps[DequeBase])
end)
Queue.ImplWhere({ DequeBase }, function(deps)
	return queueFromDeque(deps[DequeBase])
end)

-- 타입: 덱 값을 스택·큐로 보는 변환자(같은 테이블을 돌려줌 — 값 하나에 한 번, 덱을 구현한 종류인지 부를 때마다 봄 — perf 55절).
-- 바꾼 값은 스택·큐로만 보입니다(덱 진입점은 못 받음 — 다시 덱으로 쓰려면 원래 변수를).
const toStack = Trait.Converter(Stack)
const toQueue = Trait.Converter(Queue)
const AsStack: <T>(deque: Value<T>) -> Stack.Value<T> = toStack
const AsQueue: <T>(deque: Value<T>) -> Queue.Value<T> = toQueue
-- 읽기로 빌린 덱은 읽기만 되는 스택·큐로(`Peek`)
const AsStackRead: <T>(deque: ValueRead<T>) -> Stack.ValueRead<T> = toStack
const AsQueueRead: <T>(deque: ValueRead<T>) -> Queue.ValueRead<T> = toQueue

--[[ 진입점 서명 — 정의에서 지어짐(`Trait.Entries`): 쓰기 칸은 `Value`, 읽기 칸은 `ValueRead` 를 받음 ]]
-- stylua: ignore
const Deque = Trait.Expose(DequeBase, {
	AsStack = AsStack, AsQueue = AsQueue, AsStackRead = AsStackRead, AsQueueRead = AsQueueRead,
})

return Deque

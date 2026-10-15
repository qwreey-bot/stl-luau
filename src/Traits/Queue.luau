--!strict
--[[
	Queue — 먼저 넣은 것이 먼저 나오는(FIFO) 컨테이너의 트레이트(2026-10-14 사용자 결정, 질문 AV: *"트레이트로 두는거 동의. stack 으로 무엇을 쓸지,
	queue 로 무엇을 쓸 지는 유저가 선택 가능하다고 봐"*).

	**`Deque` 를 구현한 종류면 따라옵니다**(뭉텅이 구현 — `Queue.ImplWhere({ Deque }, …)`, 페이퍼 07 의 "A 가 되면 이것도 된다").
	`CircularDeque`·`LinkedDeque`, 바깥에서 `Deque` 를 구현한 종류 모두 등록 없이 큐입니다:

	| 여기 | 덱의 무엇 |
	|---|---|
	| `Queue.Push(x, item)` | `Deque.PushBack` |
	| `Queue.Pop(x)` | `Deque.PopFront` |
	| `Queue.Peek(x)` | `Deque.Front` |

	어느 덱을 쓸지는 쓰는 쪽이 고릅니다 — 양끝만 쓰면 원형이 빠르고(perf 38-3절), 가운데 위치를 쥐어야 하면 연결.
	덱이 아닌 종류도 직접 등록해 큐가 될 수 있고(`Queue.ImplFor(토큰, 표)`), 덱인 종류에 직접 등록하면 그것이 뭉텅이 구현을 덮습니다(빠른 판을 얹는 길).

	⚠️ 진입점을 거치면 구현 찾기가 붙습니다(덱 진입점과 같은 값 — 표에 든 것이 덱의 함수 자체, perf 52절). 종류를 아는
	코드는 그 모듈의 함수(`CircularDeque.PushBack`)를 직접 쓰세요.

	진입점 서명은 `Deque` 의 마커 그대로입니다(덱이면 타입으로도 큐) — 새 팬텀 필드가 없습니다.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")
local Deque = require("./Deque")
type AnyToken = Trait.AnyToken
type A = Trait.A
type B = Trait.B
const Fn, FnMut = Trait.Fn, Trait.FnMut

--[[ 마커 — `Deque` 의 것 그대로 ]]

export type Marker<T> = Deque.Marker<T>
export type MarkerMut<T> = Deque.MarkerMut<T>

--[[ 정의 ]]
-- `Push` 는 자기 자신을 돌려주고, `Pop`·`Peek` 은 비었으면 `nil`.
const QueueBase = Trait.Trait(
	"Queue",
	function<Self, T>(of: (Self & Marker<T>) | AnyToken, ofMut: (Self & MarkerMut<T>) | AnyToken)
		return table.freeze({
			Push = FnMut<<(queue: Self, item: T) -> Self>>(),
			Pop = FnMut<<(queue: Self) -> T?>>(),
			Peek = Fn<<(queue: Self) -> T?>>(),
		})
	end
)
-- 완성 표(= 등록 표 — 기본 구현이 없음)
export type Full<Self, T> = typeof(QueueBase.OfMut<<Self, T>>(nil :: any))
export type Read<Self, T> = typeof(QueueBase.Of<<Self, T>>(nil :: any))
export type Provided<Self, T> = typeof(QueueBase.ImplOf<<Self, T>>(nil :: any))

--[[ 뭉텅이 구현 — 덱이면 큐 ]]
-- ⭐ 덱의 함수를 **그대로** 돌려줍니다(감싸지 않음 — 질문 AW): 덱의 표가 다시 지어지면 이것도 다시 불립니다. 그래서
-- `Queue.Of(d).Push` 가 곧 `PushBack` 이고 진입점의 호출이 한 겹 적습니다(perf 52절).
-- 몸통은 탐침 타입(A = 종류, B = 원소)으로 — 제네릭 `<C, T>` 몸통은 원소를 못박은 함수가 0건(상류 결함 `Subtyping.cpp:830`).
local function queueFromDeque(deque: Deque.Full<A, B>): Provided<A, B>
	return { Push = deque.PushBack, Pop = deque.PopFront, Peek = deque.Front }
end
QueueBase.ImplWhere({ Deque }, function(deps)
	return queueFromDeque(deps[Deque])
end)

--[[ 진입점 서명 — 정의에서 지어짐(`Trait.Entries`): 쓰기 칸은 `MarkerMut`, 읽기 칸은 `Marker` 를 받음 ]]
const Queue = QueueBase

return Queue

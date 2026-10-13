--!strict
--[[
	65 — LinkedDeque·Node·Deque 트레이트의 음성 대조군 (2026-10-13).

	지키는 성질: 꺼내기·보기는 옵셔널 / 원소 타입 / 토큰 없는 리터럴은 덱이 아님 / **위치는 노드**(숫자가
	아님)이고 밖으로 나온 노드는 **읽기 전용인 불투명 핸들**(옵셔널 자리에서도 원소 타입·노드 종류를 지킴) / 읽기로 빌린 참조(`LinkedDequeRead`)는 넣기·꺼내기·비우기를
	못 얻음(모듈 함수로도, 트레이트 진입점으로도) / `Deque` 진입점은 원소 타입을 지키고 넣은 타입 그대로
	돌려주며 덱이 아닌 것을 안 받음 / 두 구현은 서로 다른 타입.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 34 줄 + CANARY 1 — 빌린 참조의 `PopFront` 줄은 여러 건)
]]
local stl = require("../../../../src")
local LinkedDeque, CircularDeque, Deque, Arr = stl.LinkedDeque, stl.CircularDeque, stl.Deque, stl.Arr
type LinkedDeque<T> = stl.LinkedDeque<T>
type NodeRead<T> = stl.DoubleNodeRead<T>

local d = LinkedDeque.Of(10, 20, 30)
local ring = CircularDeque.Of(10, 20, 30)

--[[ POS ]]
local front: number? = LinkedDeque.Front(d)
local popped: number? = LinkedDeque.PopBack(d)
local head: NodeRead<number>? = LinkedDeque.FirstIndex(d)
local same: LinkedDeque<number> = LinkedDeque.PushBack(d, 40)
local found: NodeRead<number>? = stl.List.IndexOf(d, 20)
local total: number = stl.List.Fold(d, 0, function(acc: number, v: number, _at: NodeRead<number>): number
	return acc + v
end)
local size: number = stl.Collection.Len(d)
-- 읽기로 빌린 참조는 원소에 공변, 읽는 함수와 읽는 진입점은 받음
local borrowed: stl.LinkedDequeRead<number?> = d
local borrowedFront: number? = LinkedDeque.Front(borrowed)
local viaTrait: number? = Deque.Front(borrowed)
local borrowedLen: number = stl.Collection.Len(borrowed)
-- 진입점은 넣은 타입 그대로
local sameLinked: LinkedDeque<number> = Deque.PushBack(d, 50)
local sameRing: stl.CircularDeque<number> = Deque.PushFront(ring, 5)
local viaPop: number? = Deque.PopFront(ring)

--[[ NEG ]]
-- 꺼내기·보기는 옵셔널
local negPop: number = LinkedDeque.PopFront(d)
local negFront: number = LinkedDeque.Front(d)
-- 원소 타입
LinkedDeque.PushBack(d, "x")
local negRemoved: string = LinkedDeque.Remove(d, head :: NodeRead<number>)
LinkedDeque.InsertAfter(d, head :: NodeRead<number>, "x")
-- 토큰 없는 리터럴은 덱이 아님
local negLiteral: LinkedDeque<number> = { head = nil, tail = nil, size = 0 }
-- 위치는 노드
local negIndex = LinkedDeque.Get(d, 1)
local negFound: number? = stl.List.IndexOf(d, 20)
-- 밖으로 나온 노드는 읽기 전용
if head then
	head.value = 99
	head[2] = nil
end
-- 읽기로 빌린 참조는 바꾸는 것을 못 얻음
LinkedDeque.PushBack(borrowed, 1)
local negBorrowedPop = LinkedDeque.PopFront(borrowed)
LinkedDeque.Clear(borrowed)
stl.Collection.Clear(borrowed)
local negTraitPop = Deque.PopFront(borrowed)
Deque.PushBack(borrowed, 1)
-- Deque 진입점: 원소 타입 / 덱이 아닌 것 / 넣은 타입 그대로 / 꺼내기는 옵셔널
Deque.PushBack(d, "x")
Deque.PushBack(Arr.Of(1), 1)
local negKind: stl.CircularDeque<number> = Deque.PushBack(d, 60)
local negTraitFront: number = Deque.Front(ring)
-- 두 구현은 서로 다른 타입
local negCross: LinkedDeque<number> = ring
-- 대칭 짝의 다른 쪽도(리뷰: 한쪽만 지키고 있었음)
LinkedDeque.PushFront(d, "x")
LinkedDeque.InsertBefore(d, head :: NodeRead<number>, "x")
local negPopBack: number = LinkedDeque.PopBack(d)
Deque.PushFront(d, "x")
local negTraitPopBack = Deque.PopBack(borrowed)
local negTraitBack: number = Deque.Back(ring)
-- 넣기가 돌려준 노드도 읽기 전용 / 다른 원소 타입 덱의 위치(옵셔널이 아닌 자리)
local inserted = LinkedDeque.InsertAfter(d, head :: NodeRead<number>, 7)
inserted.value = 8
local words = LinkedDeque.Of("a", "b")
local negForeign = LinkedDeque.Remove(d, LinkedDeque.FirstIndex(words) :: NodeRead<string>)
-- ⭐ 옵셔널 자리에서도 원소 타입을 지킴(2026-10-13 — 노드를 불투명 핸들로 바꾸며 닫힘. 노드 타입이 재귀 별칭이던
-- 때는 새 솔버 결함(`audit/luau-solver-issues` 5번)으로 이 세 줄이 0건이었고, 다른 덱에 다른 타입의 원소가 들어갔음)
local negOptional: NodeRead<number>? = LinkedDeque.FirstIndex(words)
local negOptionalFound: NodeRead<number>? = stl.List.IndexOf(words, "b")
local function takesOptional(_at: NodeRead<number>?) end
takesOptional(LinkedDeque.LastIndex(words))
-- 다른 종류의 노드(이진)는 덱의 위치가 아님 / 노드의 안쪽은 타입에 드러나지 않음(값은 함수로)
local negKindOfNode = LinkedDeque.Remove(d, stl.Node.Binary.New(1))
local okValue: number = stl.Node.Double.Value(head :: NodeRead<number>)
local negValue: string = stl.Node.Double.Value(head :: NodeRead<number>)

local canary: string = 42

return {
	front,
	popped,
	same,
	found,
	total,
	size,
	borrowedFront,
	viaTrait,
	borrowedLen,
	sameLinked,
	sameRing,
	viaPop,
	negPop,
	negFront,
	negRemoved,
	negLiteral,
	negIndex,
	negFound,
	negBorrowedPop,
	negTraitPop,
	negKind,
	negTraitFront,
	negCross,
	negPopBack,
	negTraitPopBack,
	negTraitBack,
	negForeign,
	negOptional,
	negOptionalFound,
	negKindOfNode,
	okValue,
	negValue,
	canary,
}

--!strict
--[[
	65 — LinkedDeque·Node·Deque 트레이트의 음성 대조군 (2026-10-13).

	지키는 성질: 꺼내기·보기는 옵셔널 / 원소 타입 / 토큰 없는 리터럴은 덱이 아님 / **위치는 노드**(숫자가
	아님)이고 밖으로 나온 노드는 **읽기 전용** / 읽기로 빌린 참조(`LinkedDequeRead`)는 넣기·꺼내기·비우기를
	못 얻음(모듈 함수로도, 트레이트 진입점으로도) / `Deque` 진입점은 원소 타입을 지키고 넣은 타입 그대로
	돌려주며 덱이 아닌 것을 안 받음 / 두 구현은 서로 다른 타입.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 21 줄 · 25건 + CANARY 1 — 60줄은 다섯 건)
]]
local stl = require("../../../../src")
local LinkedDeque, CircularDeque, Deque, Arr = stl.LinkedDeque, stl.CircularDeque, stl.Deque, stl.Arr
type LinkedDeque<T> = stl.LinkedDeque<T>
type NodeRead<T> = stl.NodeRead<T>

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
	canary,
}

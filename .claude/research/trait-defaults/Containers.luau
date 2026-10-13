--!strict
--[[
	시제품: 노드를 조립한 컨테이너 셋 (papers/07).

	- `LinkedList` — 양방향 연결 리스트. 위치(`I`)가 **노드**입니다.
	- `LinkedTree` — 노드로 된 이진 트리 + 그 위의 `Bst`(이진 탐색 트리: 넣기만).
	- `ArrayTree`  — 배열에 담은 완전 이진 트리. 위치가 **인덱스**입니다(같은 `Tree` 기본 구현을 받음).

	각자 **자기가 아는 트레이트의 필수 함수만** 구현해 등록합니다. 그 위의 트레이트(`Seq` 등)는
	등록하지 않아도 따라옵니다.
]]
local stl = require("../../../src")
local Node = require("./Node")
local Trait2 = require("./Trait2")
local Traits = require("./Traits")

type ListNode<T> = Node.ListNode<T>
type TreeNode<T> = Node.TreeNode<T>

--[[ LinkedList ]]
const LinkedListType = stl.Trait.NewType("LinkedList")
export type LinkedList<T> = {
	head: ListNode<T>?,
	tail: ListNode<T>?,
	size: number,
	read __type: stl.TraitToken<string>,
	read __list: T,
	read __listIndex: ListNode<T>,
}
local LinkedList = {}
function LinkedList.New<T>(): LinkedList<T>
	return { head = nil, tail = nil, size = 0, __type = LinkedListType } :: any
end
function LinkedList.PushBack<T>(self: LinkedList<T>, value: T): LinkedList<T>
	const node = Node.List(value)
	const tail = self.tail
	if tail then
		Node.LinkAfter(tail, node)
	else
		self.head = node
	end
	self.tail = node
	self.size += 1
	return self
end
function LinkedList.Remove<T>(self: LinkedList<T>, node: ListNode<T>): T
	if self.head == node then
		self.head = node.next
	end
	if self.tail == node then
		self.tail = node.prev
	end
	Node.Unlink(node)
	self.size -= 1
	return node.value
end
function LinkedList.Get<T>(_self: LinkedList<T>, node: ListNode<T>): T?
	return node.value
end
function LinkedList.FirstIndex<T>(self: LinkedList<T>): ListNode<T>?
	return self.head
end
function LinkedList.LastIndex<T>(self: LinkedList<T>): ListNode<T>?
	return self.tail
end
function LinkedList.NextIndex<T>(_self: LinkedList<T>, node: ListNode<T>): ListNode<T>?
	return node.next
end
function LinkedList.PrevIndex<T>(_self: LinkedList<T>, node: ListNode<T>): ListNode<T>?
	return node.prev
end
-- 크기를 아니까 세지 않습니다 — 기본 구현(`Count`)을 **재정의**
function LinkedList.Count<T>(self: LinkedList<T>): number
	return self.size
end
Trait2.Impl(Traits.List, LinkedListType, LinkedList)
Trait2.Impl(Traits.Build, LinkedListType, LinkedList)
-- `Seq`(Map·Filter)는 등록하지 않습니다 — List 와 Build 를 구현했으니 저절로 따라옵니다.

--[[ LinkedTree + Bst ]]
const LinkedTreeType = stl.Trait.NewType("LinkedTree")
export type LinkedTree<T> = { root: TreeNode<T>?, read __type: stl.TraitToken<string> }
local LinkedTree = {}
function LinkedTree.New<T>(): LinkedTree<T>
	return { root = nil, __type = LinkedTreeType } :: any
end
function LinkedTree.Root<T>(self: LinkedTree<T>): TreeNode<T>?
	return self.root
end
function LinkedTree.Left<T>(_self: LinkedTree<T>, node: TreeNode<T>): TreeNode<T>?
	return node.left
end
function LinkedTree.Right<T>(_self: LinkedTree<T>, node: TreeNode<T>): TreeNode<T>?
	return node.right
end
function LinkedTree.Value<T>(_self: LinkedTree<T>, node: TreeNode<T>): T
	return node.value
end
Trait2.Impl(Traits.Tree, LinkedTreeType, LinkedTree)

-- 이진 탐색 트리: 같은 노드·같은 트리 위에 "넣기" 하나를 얹은 것(순회·높이는 Tree 의 기본 구현).
local Bst = {}
function Bst.Insert<T>(self: LinkedTree<T>, value: T, compare: (T, T) -> number)
	const added = Node.Tree(value)
	local at = self.root
	if at == nil then
		self.root = added
		return
	end
	while true do
		if compare(value, at.value) < 0 then
			const nextNode = at.left
			if nextNode == nil then
				Node.SetLeft(at, added)
				return
			end
			at = nextNode
		else
			const nextNode = at.right
			if nextNode == nil then
				Node.SetRight(at, added)
				return
			end
			at = nextNode
		end
	end
end

--[[ ArrayTree — 완전 이진 트리, 위치는 인덱스 ]]
const ArrayTreeType = stl.Trait.NewType("ArrayTree")
export type ArrayTree<T> = { items: { T }, size: number, read __type: stl.TraitToken<string> }
local ArrayTree = {}
function ArrayTree.FromList<T>(items: { T }): ArrayTree<T>
	return { items = table.clone(items), size = #items, __type = ArrayTreeType } :: any
end
function ArrayTree.Root<T>(self: ArrayTree<T>): number?
	return if self.size > 0 then 1 else nil
end
function ArrayTree.Left<T>(self: ArrayTree<T>, idx: number): number?
	return if idx * 2 <= self.size then idx * 2 else nil
end
function ArrayTree.Right<T>(self: ArrayTree<T>, idx: number): number?
	return if idx * 2 + 1 <= self.size then idx * 2 + 1 else nil
end
function ArrayTree.Value<T>(self: ArrayTree<T>, idx: number): T
	return self.items[idx]
end
-- 완전 이진 트리의 높이는 계산으로 — 기본 구현(재귀)을 **재정의**
function ArrayTree.Height<T>(self: ArrayTree<T>): number
	return if self.size == 0 then 0 else math.floor(math.log(self.size, 2)) + 1
end
Trait2.Impl(Traits.Tree, ArrayTreeType, ArrayTree)

--[[ 이미 있는 Arr·Deque 를 같은 트레이트에 — 필수 함수는 지금 모듈이 그대로 가짐 ]]
const Arr, Deque = stl.Arr, stl.Deque
-- Arr 는 뜨거운 것을 **자기 직접 구현으로 재정의**(Fold·Map·Filter), 나머지는 기본 구현을 받음
Trait2.Impl(Traits.List, stl.Trait.Types.Arr, {
	Get = Arr.Get,
	FirstIndex = Arr.FirstIndex,
	LastIndex = Arr.LastIndex,
	NextIndex = Arr.NextIndex,
	PrevIndex = Arr.PrevIndex,
	Fold = Arr.Fold,
	IndexOf = Arr.IndexOf,
	Count = Arr.Len,
})
Trait2.Impl(Traits.Build, stl.Trait.Types.Arr, {
	New = function()
		return Arr.Of()
	end,
	PushBack = Arr.PushBack,
})
-- (빠른 판이 있는 종류만 따로 등록 — 재정의)
Trait2.Impl(Traits.Seq, stl.Trait.Types.Arr, { Map = Arr.Map, Filter = Arr.Filter })
-- Deque 는 필수 함수만 — Fold·Find·Map·Filter … 를 공짜로 받음
Trait2.Impl(Traits.List, stl.Trait.Types.Deque, {
	Get = Deque.Get,
	FirstIndex = Deque.FirstIndex,
	LastIndex = Deque.LastIndex,
	NextIndex = Deque.NextIndex,
	PrevIndex = Deque.PrevIndex,
	Count = Deque.Len,
})
Trait2.Impl(Traits.Build, stl.Trait.Types.Deque, {
	New = function()
		return Deque.New()
	end,
	PushBack = Deque.PushBack,
})

return { LinkedList = LinkedList, LinkedTree = LinkedTree, Bst = Bst, ArrayTree = ArrayTree }

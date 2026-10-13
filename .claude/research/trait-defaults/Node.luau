--!strict
--[[
	시제품: 노드 — 컨테이너 바깥의 조각 (papers/07).

	예전 과제의 층(`ReadableNode` → `MutableNode` → 트리)을 "데이터는 엔티티, 함수는 서비스" 로
	옮긴 것입니다. 노드는 메타테이블 없는 평범한 테이블이고, 잇고 끊는 일은 여기의 함수가 합니다.
	컨테이너(`LinkedList`, `LinkedTree`)는 이 조각을 **조립**할 뿐 노드의 모양을 다시 정하지 않습니다.
]]
export type ListNode<T> = { value: T, prev: ListNode<T>?, next: ListNode<T>? }
export type TreeNode<T> = { value: T, left: TreeNode<T>?, right: TreeNode<T>?, parent: TreeNode<T>? }

local Node = {}

function Node.List<T>(value: T): ListNode<T>
	return { value = value, prev = nil, next = nil }
end
-- `node` 뒤에 `added` 를 끼웁니다.
function Node.LinkAfter<T>(node: ListNode<T>, added: ListNode<T>)
	const after = node.next
	added.prev, added.next = node, after
	node.next = added
	if after then
		after.prev = added
	end
end
-- 이웃에서 떼어 냅니다.
function Node.Unlink<T>(node: ListNode<T>)
	const before, after = node.prev, node.next
	if before then
		before.next = after
	end
	if after then
		after.prev = before
	end
	node.prev, node.next = nil, nil
end

function Node.Tree<T>(value: T): TreeNode<T>
	return { value = value, left = nil, right = nil, parent = nil }
end
function Node.SetLeft<T>(node: TreeNode<T>, child: TreeNode<T>?)
	node.left = child
	if child then
		child.parent = node
	end
end
function Node.SetRight<T>(node: TreeNode<T>, child: TreeNode<T>?)
	node.right = child
	if child then
		child.parent = node
	end
end

return Node

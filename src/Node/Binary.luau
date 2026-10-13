--!strict
--[[
	Node.Binary — 이진 노드의 도구. 칸 1 = 왼쪽, 2 = 오른쪽, 3 = 부모.

	부모 칸이 있어 **노드만 쥐고** 중위 순서의 다음·이전으로 갈 수 있고(스택 없이), 회전이 위쪽 연결까지
	고칩니다. 균형 방식(`src/Trees/`)이 이것으로 짜입니다. 뿌리가 바뀌었는지는 쓰는 쪽이 봅니다 —
	회전이 돌려준 노드의 부모가 `nil` 이면 그것이 새 뿌리입니다.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Types = require("./Types")

type Node<T> = Types.Node<T>
type NodeRead<T> = Types.NodeRead<T>

const LEFT, RIGHT, PARENT = 1, 2, 3

-- 이 노드를 뿌리로 한 부분 트리에서 중위 순서로 처음(가장 왼쪽) 노드.
const function First<T>(node: NodeRead<T>): NodeRead<T>
	local cursor = node
	local left = cursor[LEFT]
	while left ~= nil do
		cursor = left
		left = cursor[LEFT]
	end
	return cursor
end

-- 중위 순서로 끝(가장 오른쪽) 노드.
const function Last<T>(node: NodeRead<T>): NodeRead<T>
	local cursor = node
	local right = cursor[RIGHT]
	while right ~= nil do
		cursor = right
		right = cursor[RIGHT]
	end
	return cursor
end

-- 중위 순서로 다음 노드. 끝이면 `nil`. 전체를 도는 데 분할 상환 O(1).
const function Next<T>(node: NodeRead<T>): NodeRead<T>?
	const right = node[RIGHT]
	if right ~= nil then
		return First(right)
	end
	local child, parent = node, node[PARENT]
	while parent ~= nil and parent[RIGHT] == child do
		child = parent
		parent = parent[PARENT]
	end
	return parent
end

-- 중위 순서로 이전 노드. 처음이면 `nil`.
const function Prev<T>(node: NodeRead<T>): NodeRead<T>?
	const left = node[LEFT]
	if left ~= nil then
		return Last(left)
	end
	local child, parent = node, node[PARENT]
	while parent ~= nil and parent[LEFT] == child do
		child = parent
		parent = parent[PARENT]
	end
	return parent
end

-- 왼쪽으로 회전: `node` 의 오른쪽 자식이 그 자리로 올라오고 `node` 는 그 왼쪽 자식이 됩니다. 올라온 노드를
-- 돌려줍니다. 부모의 자식 칸과 세 노드의 부모 칸까지 고칩니다. ⚠️ 오른쪽 자식이 있어야 합니다.
const function RotateLeft<T>(node: Node<T>): Node<T>
	const pivot = node[RIGHT] :: Node<T>
	const inner = pivot[LEFT]
	const parent = node[PARENT]
	node[RIGHT] = inner
	if inner ~= nil then
		inner[PARENT] = node
	end
	pivot[LEFT] = node
	node[PARENT] = pivot
	pivot[PARENT] = parent
	if parent ~= nil then
		if parent[LEFT] == node then
			parent[LEFT] = pivot
		else
			parent[RIGHT] = pivot
		end
	end
	return pivot
end

-- 오른쪽으로 회전(위의 거울). ⚠️ 왼쪽 자식이 있어야 합니다.
const function RotateRight<T>(node: Node<T>): Node<T>
	const pivot = node[LEFT] :: Node<T>
	const inner = pivot[RIGHT]
	const parent = node[PARENT]
	node[LEFT] = inner
	if inner ~= nil then
		inner[PARENT] = node
	end
	pivot[RIGHT] = node
	node[PARENT] = pivot
	pivot[PARENT] = parent
	if parent ~= nil then
		if parent[LEFT] == node then
			parent[LEFT] = pivot
		else
			parent[RIGHT] = pivot
		end
	end
	return pivot
end

-- `old` 가 있던 자리에 `fresh`(없어도 됨)를 답니다 — `old` 의 부모의 자식 칸과 `fresh` 의 부모 칸만 고칩니다
-- (`old` 의 자식들은 건드리지 않음 — 옮길지는 쓰는 쪽이 정함). `old` 가 뿌리였으면 `true` 를 돌려줍니다
-- (쓰는 쪽이 뿌리를 `fresh` 로 바꿔야 함).
const function Replace<T>(old: Node<T>, fresh: Node<T>?): boolean
	const parent = old[PARENT]
	if fresh ~= nil then
		fresh[PARENT] = parent
	end
	if parent == nil then
		return true
	end
	if parent[LEFT] == old then
		parent[LEFT] = fresh
	else
		parent[RIGHT] = fresh
	end
	return false
end

-- 중위 순서로 노드를 하나씩: `for node in Node.InOrder(root) do`. `root` 가 `nil` 이면 돌지 않습니다.
-- 다음 노드를 미리 읽어 두지 않습니다 — 도는 동안 트리를 바꾸면 정의되지 않은 동작입니다(회전이 길을 바꿈).
const function InOrder<T>(root: NodeRead<T>?): () -> NodeRead<T>?
	local cursor = if root ~= nil then First(root) else nil
	return function(): NodeRead<T>?
		const node = cursor
		if node ~= nil then
			cursor = Next(node)
		end
		return node
	end
end

-- 부분 트리의 높이(빈 트리는 0). O(n) — 검사·디버깅용.
const function Height<T>(node: NodeRead<T>?): number
	if node == nil then
		return 0
	end
	const left, right = Height(node[LEFT]), Height(node[RIGHT])
	return (if left > right then left else right) + 1
end

-- stylua: ignore
return {
	First = First, Last = Last, Next = Next, Prev = Prev, RotateLeft = RotateLeft, RotateRight = RotateRight, Replace = Replace, InOrder = InOrder, Height = Height,
}

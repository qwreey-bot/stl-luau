--!strict
--[[
	CompleteNode — **노드로 이은 완전 이진 트리**(2층 트리부, 2026-10-13 사용자: *"완전이진 같은 경우는 배열식,
	노드식 둘을 제공하는 방향"*). 배열식은 `Trees/CompleteArray`.

	## 모양 (계약)

	노드는 이진 노드(`Node.Binary` — `1` = 값, `2` = 왼쪽, `3` = 오른쪽, `4` = 부모)이고, 트리는 **뿌리와 개수**
	(`root`, `count`)로 가리킵니다. 자리 번호는 배열식과 같습니다 — 층별로 왼쪽부터 `1..count`(뿌리가 `1`, `idx` 의
	자식은 `2 * idx`·`2 * idx + 1`). 노드에는 번호가 없습니다: **뿌리에서 번호의 비트를 따라** 찾아갑니다
	(가장 높은 비트 아래를 위에서부터 — `0` 은 왼쪽, `1` 은 오른쪽). 그래서 맨 뒤에 붙이기·맨 뒤 떼기가 O(log n) 입니다.

	## 배열식과 무엇이 다른가

	배열식은 원소가 자리를 옮겨 다닙니다 — 원소를 "쥐고" 있을 길이 없습니다. 노드식은 **노드가 곧 위치**입니다:
	순서를 맞출 때 값을 맞바꾸지 않고 **노드를 다시 잇습니다**(`Exchange`). 쥐고 있던 노드는 끝까지 같은 값을
	가리키므로, 가운데 원소의 우선순위를 바꾸거나(값을 고치고 `SiftUp`/`SiftDown`) 가운데 원소를 빼는 일이
	O(log n) 으로 됩니다. 값만 베끼면 쥐고 있던 위치가 다른 값을 가리키게 됩니다(트리부의 지우기와 같은 규칙).
	대가는 속도입니다 — 걸음마다 연결을 열 군데쯤 고칩니다. 양끝만 쓰는 힙이면 배열식(`Heap`)이 맞습니다.

	## 도구는 연결만 고칩니다

	뿌리와 개수는 쓰는 쪽이 듭니다. 뿌리가 바뀔 수 있는 도구는 **새 뿌리를 돌려줍니다**. 개수는 쓰는 쪽이
	올리고 내립니다(`Append` 뒤 `count + 1`, `RemoveLast` 뒤 `count - 1`).

	## ⚠️ 인자를 검사하지 않습니다

	`count` 는 그 트리에 실제로 든 노드 수, 노드는 그 트리의 노드(붙일 노드는 연결이 없는 것)여야 합니다. 조립하는
	쪽이 준 값만 받는 자리입니다(규약의 "계약 함수" 예외, 이 트리의 것이 아닌 노드는 정의되지 않은 동작).
]]
local Types = require("../Types")
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Binary = require("../Node/Binary")

type LessThan<T> = Types.LessThan<T>
type Node<T> = Binary.Node<T>
type NodeRead<T> = Binary.NodeRead<T>
type Kind = { read __links: "binary" }

const VALUE, LEFT, RIGHT, PARENT = 1, 2, 3, 4

-- 자리 `idx` 의 노드. 없으면(`idx` 가 1 보다 작거나 트리에 그 자리가 없으면) `nil`. O(log idx).
const function At<N>(root: (N & Kind)?, idx: number): N?
	if idx < 1 then
		return nil
	end
	-- `idx` 를 넘지 않는 가장 큰 2의 거듭제곱(가장 높은 비트)
	local bit = 1
	while bit * 2 <= idx do
		bit *= 2
	end
	local node: any = root
	bit //= 2
	while bit >= 1 and node ~= nil do
		node = if (idx // bit) % 2 == 1 then node[RIGHT] else node[LEFT]
		bit //= 2
	end
	return node
end

-- 연결이 없는 `node` 를 **맨 뒤 자리**(`count + 1`)에 붙이고 뿌리를 돌려줍니다(빈 트리면 `node` 가 뿌리).
const function Append<T>(root: Node<T>?, count: number, node: Node<T>): Node<T>
	if root == nil then
		return node
	end
	const idx = count + 1
	const parent: any, fresh: any = At(root :: any, idx // 2), node
	if idx % 2 == 0 then
		parent[LEFT] = fresh
	else
		parent[RIGHT] = fresh
	end
	fresh[PARENT] = parent
	return root
end

-- **맨 뒤 자리**(`count`)의 노드를 떼어 `(새 뿌리, 뗀 노드)` 를 돌려줍니다. 하나뿐이었으면 새 뿌리는 `nil`,
-- 빈 트리면 `nil, nil`. 뗀 노드는 연결이 끊깁니다.
const function RemoveLast<T>(root: Node<T>?, count: number): (Node<T>?, Node<T>?)
	if root == nil then
		return nil, nil
	end
	const last: any = At(root :: any, count)
	const parent = last[PARENT]
	if parent == nil then
		return nil, last
	end
	if parent[LEFT] == last then
		parent[LEFT] = nil
	else
		parent[RIGHT] = nil
	end
	last[PARENT] = nil
	return root, last
end

-- 부모 `upper` 와 그 자식 `lower` 의 자리를 맞바꿉니다(연결만).
const function exchangeAdjacent(upper: any, lower: any)
	const grand = upper[PARENT]
	const upperLeft, upperRight = upper[LEFT], upper[RIGHT]
	const lowerLeft, lowerRight = lower[LEFT], lower[RIGHT]
	lower[PARENT] = grand
	if grand ~= nil then
		if grand[LEFT] == upper then
			grand[LEFT] = lower
		else
			grand[RIGHT] = lower
		end
	end
	if upperLeft == lower then
		lower[LEFT] = upper
		lower[RIGHT] = upperRight
		if upperRight ~= nil then
			upperRight[PARENT] = lower
		end
	else
		lower[RIGHT] = upper
		lower[LEFT] = upperLeft
		if upperLeft ~= nil then
			upperLeft[PARENT] = lower
		end
	end
	upper[PARENT] = lower
	upper[LEFT] = lowerLeft
	upper[RIGHT] = lowerRight
	if lowerLeft ~= nil then
		lowerLeft[PARENT] = upper
	end
	if lowerRight ~= nil then
		lowerRight[PARENT] = upper
	end
end

-- 같은 트리의 두 노드 `a`·`b` 의 **자리를 맞바꾸고** 새 뿌리를 돌려줍니다. 값은 옮기지 않습니다 — 노드를 다시
-- 잇습니다(쥐고 있던 노드는 같은 값을 가리킨 채 자리만 바뀜). 같은 노드면 아무 일도 없습니다(바로 돌아옴 —
-- 아래 길을 타도 결과는 같고 쓰기만 듭니다).
const function Exchange<T>(root: Node<T>, a: Node<T>, b: Node<T>): Node<T>
	const first: any, second: any = a, b
	if first == second then
		return root
	end
	if second[PARENT] == first then
		exchangeAdjacent(first, second)
	elseif first[PARENT] == second then
		exchangeAdjacent(second, first)
	else
		const firstParent, firstLeft, firstRight = first[PARENT], first[LEFT], first[RIGHT]
		const secondParent, secondLeft, secondRight = second[PARENT], second[LEFT], second[RIGHT]
		-- 어느 쪽 자식이었는지는 고치기 **전에** 봅니다(둘이 형제면 같은 부모를 두 번 고침).
		const firstWasLeft = firstParent ~= nil and firstParent[LEFT] == first
		const secondWasLeft = secondParent ~= nil and secondParent[LEFT] == second
		if firstParent ~= nil then
			if firstWasLeft then
				firstParent[LEFT] = second
			else
				firstParent[RIGHT] = second
			end
		end
		if secondParent ~= nil then
			if secondWasLeft then
				secondParent[LEFT] = first
			else
				secondParent[RIGHT] = first
			end
		end
		first[PARENT], second[PARENT] = secondParent, firstParent
		first[LEFT], first[RIGHT] = secondLeft, secondRight
		second[LEFT], second[RIGHT] = firstLeft, firstRight
		if firstLeft ~= nil then
			firstLeft[PARENT] = second
		end
		if firstRight ~= nil then
			firstRight[PARENT] = second
		end
		if secondLeft ~= nil then
			secondLeft[PARENT] = first
		end
		if secondRight ~= nil then
			secondRight[PARENT] = first
		end
	end
	if root == a then
		return b
	elseif root == b then
		return a
	end
	return root
end

-- `node` 를 **뿌리 쪽으로** 올립니다 — 부모보다 앞서는 동안(`less(node 의 값, 부모의 값)`). 새 뿌리를 돌려줍니다.
-- 맨 뒤에 붙인 뒤, 또는 쥐고 있던 노드의 값을 더 앞서게 고친 뒤 부르는 자리.
const function SiftUp<T>(root: Node<T>, node: Node<T>, less: LessThan<T>): Node<T>
	const moving: any = node
	const value = moving[VALUE]
	local top: any = root
	while true do
		const parent = moving[PARENT]
		if parent == nil or not less(value, parent[VALUE]) then
			break
		end
		exchangeAdjacent(parent, moving)
		if parent == top then
			top = moving
		end
	end
	return top
end

-- `node` 를 **잎 쪽으로** 내립니다 — 더 앞서는 자식이 있는 동안. 새 뿌리를 돌려줍니다.
-- 뿌리 자리를 갈아 끼운 뒤, 또는 쥐고 있던 노드의 값을 더 뒤서게 고친 뒤 부르는 자리.
const function SiftDown<T>(root: Node<T>, node: Node<T>, less: LessThan<T>): Node<T>
	const moving: any = node
	const value = moving[VALUE]
	local top: any = root
	while true do
		const left = moving[LEFT]
		if left == nil then
			break
		end
		-- 두 자식 중 더 앞서는 쪽을 고릅니다(완전 이진 트리라 오른쪽만 있는 일은 없음).
		local child = left
		const right = moving[RIGHT]
		if right ~= nil and less(right[VALUE], left[VALUE]) then
			child = right
		end
		if not less(child[VALUE], value) then
			break
		end
		exchangeAdjacent(moving, child)
		if moving == top then
			top = child
		end
	end
	return top
end

-- 힙 순서인가(어느 자식도 부모보다 앞서지 않음). 빈 트리는 참. O(n) — 검사·디버깅용.
const function IsHeap<T>(root: NodeRead<T>?, less: LessThan<T>): boolean
	const function check(node: any): boolean
		if node == nil then
			return true
		end
		const parent = node[PARENT]
		if parent ~= nil and less(node[VALUE], parent[VALUE]) then
			return false
		end
		return check(node[LEFT]) and check(node[RIGHT])
	end
	return check(root)
end

-- `root` 가 노드 `count` 개의 **완전 이진 트리**인가: 자리 `1..count` 가 빠짐없이 차 있고, 부모 칸이 전부 맞고,
-- 뿌리의 부모가 없음. 빈 트리는 `count == 0` 일 때 참. O(n) — 검사·디버깅용.
const function IsComplete(root: Kind?, count: number): boolean
	if root == nil then
		return count == 0
	end
	local seen = 0
	-- 자리 번호를 매기며 내려갑니다. 번호가 전부 `count` 이하이고 노드 수가 `count` 면 빈 자리가 없습니다.
	const function visit(node: any, idx: number, parent: any): boolean
		if idx > count or node[PARENT] ~= parent then
			return false
		end
		seen += 1
		const left, right = node[LEFT], node[RIGHT]
		if left ~= nil and not visit(left, idx * 2, node) then
			return false
		end
		if right ~= nil and not visit(right, idx * 2 + 1, node) then
			return false
		end
		return true
	end
	return visit(root, 1, nil) and seen == count
end

-- stylua: ignore
return {
	At = At, Append = Append, RemoveLast = RemoveLast, Exchange = Exchange,
	SiftUp = SiftUp, SiftDown = SiftDown, IsHeap = IsHeap, IsComplete = IsComplete,
}

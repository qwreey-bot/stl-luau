--!strict
--[[
	Avl — AVL 트리의 구조 제어(2층 트리부, 2026-10-13 — `papers/07` 9-4).

	`RedBlack` 과 **같은 표면**입니다(뿌리 노드와 비교자를 받아 고치고 새 뿌리를 돌려줌 — `Find`·`LowerBound`·
	`UpperBound`·`Insert`·`Remove`·`FromSorted`·`Clone`). 제품의 `FlatMap` 은 레드블랙으로 조립하고, 이것은
	구현체로 둡니다(사용자: *"AVL 도 있어도 되긴 해. 버리진 말고 추출해서 Trees 안에 넣어도"*).
	노드는 `Node.Binary` 의 규칙(칸 1 = 왼쪽, 2 = 오른쪽, 3 = 부모)에 키와 높이를 더한 것:

	```lua
	{ key: K, value: V, height: number, [1]: 왼쪽, [2]: 오른쪽, [3]: 부모 }
	```

	## 레드블랙과 견주어 (perf 37절)

	균형이 더 빡빡합니다(높이 ≤ 1.44·log₂ n) — 조회는 같거나 조금 낫고, 넣기·지우기는 높이를 고치며 뿌리
	쪽으로 더 올라가 조금 느립니다. 조회가 압도적으로 많고 넣고 빼기가 드문 쓰임이면 이쪽을 고를 수 있습니다.

	## 불변식 (`tests/spec.trees.luau` 가 연산마다 검사)

	1. 모든 노드에서 두 부분 트리의 높이 차가 1 이하. 2. `height` 가 실제 높이. 3. 중위 순서가 비교자의 순서.
	4. 자식의 부모 칸이 그 부모를 가리키고 뿌리의 부모는 `nil`.

	규칙(비교자, 위치는 노드, 떼어 낸 노드, 순회 중 지우기)은 `RedBlack` 과 같습니다.
]]
local Types = require("../Types")
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Node = require("../Node")
local Search = require("./Search")

type Comparator<T> = Types.Comparator<T>

-- AVL 노드. `Node<V>` 의 모양에 키와 높이(잎 = 1)가 더해진 것.
export type AvlNode<K, V> = { key: K, value: V, height: number, [number]: AvlNode<K, V>? }
-- 읽기만 하는 노드(밖으로 내주는 위치).
export type AvlNodeRead<K, V> = {
	read key: K,
	read value: V,
	read height: number,
	read [number]: AvlNodeRead<K, V>?,
}

-- `Node.Binary` 의 칸 규칙(지역 상수라 접힘).
const LEFT, RIGHT, PARENT = 1, 2, 3
const rotateLeft, rotateRight, replace = Node.Binary.RotateLeft, Node.Binary.RotateRight, Node.Binary.Replace

--#region ----------- 읽기 — 균형 방식과 무관한 공유 조각(`Trees/Search`)을 이 노드 타입으로 -----------

type FindFn = <K, V>(root: AvlNodeRead<K, V>?, key: K, compare: Comparator<K>) -> AvlNodeRead<K, V>?
type CloneFn = <K, V>(root: AvlNodeRead<K, V>?) -> AvlNode<K, V>?
const shared: any = Search
-- 키가 같은 노드 / 키가 `key` 이상인 첫 노드 / 초과인 첫 노드(없으면 `nil`).
const Find: FindFn = shared.Find
const LowerBound: FindFn = shared.LowerBound
const UpperBound: FindFn = shared.UpperBound
-- 구조째 베낍니다(노드는 새로, 키·값·높이는 그대로). O(n).
const Clone: CloneFn = shared.Clone

--#endregion

--#region ----------- 균형 맞추기 -----------

const function heightOf(node: any): number
	return if node ~= nil then node.height else 0
end

-- 자식들의 높이로 이 노드의 높이를 다시 셉니다.
const function refresh(node: any)
	const left, right = heightOf(node[LEFT]), heightOf(node[RIGHT])
	node.height = (if left > right then left else right) + 1
end

-- `node` 에서 뿌리 쪽으로 올라가며 높이를 고치고, 차가 2 가 된 자리를 회전으로 맞춥니다. 새 뿌리를 돌려줍니다.
-- 부분 트리의 높이가 **바뀌지 않은** 자리에서 멈춥니다(그 위는 영향이 없음 — 넣기는 보통 한두 걸음).
const function rebalance(top: any, node: any): any
	while node ~= nil do
		const before: number = node.height
		const left, right = heightOf(node[LEFT]), heightOf(node[RIGHT])
		local raised = node
		if left > right + 1 then
			const heavy = node[LEFT]
			if heightOf(heavy[RIGHT]) > heightOf(heavy[LEFT]) then
				-- 안쪽이 무거움: 먼저 안쪽을 바깥으로 돌림
				refresh(rotateLeft(heavy)[LEFT])
				refresh(node[LEFT])
			end
			raised = rotateRight(node)
			refresh(node)
			refresh(raised)
		elseif right > left + 1 then
			const heavy = node[RIGHT]
			if heightOf(heavy[LEFT]) > heightOf(heavy[RIGHT]) then
				refresh(rotateRight(heavy)[RIGHT])
				refresh(node[RIGHT])
			end
			raised = rotateLeft(node)
			refresh(node)
			refresh(raised)
		else
			node.height = (if left > right then left else right) + 1
		end
		const above = raised[PARENT]
		if above == nil then
			return raised
		end
		if raised.height == before then
			return top
		end
		node = above
	end
	return top
end

--#endregion

--#region ----------- 넣기·지우기 -----------

-- 키-값을 넣고 `(새 뿌리, 그 키의 노드, 새로 만들었나)` 를 돌려줍니다. 키가 이미 있으면 값만 바꿉니다.
const function Insert<K, V>(
	root: AvlNode<K, V>?,
	key: K,
	value: V,
	compare: Comparator<K>
): (AvlNode<K, V>, AvlNode<K, V>, boolean)
	local parent: any, cursor: any = nil, root
	local order = 0
	while cursor ~= nil do
		order = compare(key, cursor.key)
		if order == 0 then
			cursor.value = value
			return root :: any, cursor, false
		end
		parent = cursor
		cursor = if order < 0 then cursor[LEFT] else cursor[RIGHT]
	end
	-- 연결 칸을 생성자에 같이 적습니다(perf 34절)
	const fresh: any = { nil, nil, parent, key = key, value = value, height = 1 }
	if parent == nil then
		return fresh, fresh, true
	end
	if order < 0 then
		parent[LEFT] = fresh
	else
		parent[RIGHT] = fresh
	end
	return rebalance(root, parent), fresh, true
end

-- 이 트리의 노드 `target` 을 떼어 내고 **새 뿌리**(비면 `nil`)를 돌려줍니다. 다른 노드들은 그대로 살아
-- 있습니다(자식이 둘이면 중위 다음 노드를 그 자리로 **옮김** — 값만 베끼지 않음). `target` 은 연결이 끊깁니다.
const function Remove<K, V>(root: AvlNode<K, V>, target: AvlNodeRead<K, V>): AvlNode<K, V>?
	local top: any = root
	const gone: any = target
	const left, right = gone[LEFT], gone[RIGHT]
	-- 높이를 다시 볼 가장 아래 자리
	local start: any
	if left == nil or right == nil then
		const child = if left == nil then right else left
		start = gone[PARENT]
		if replace(gone, child) then
			top = child
		end
	else
		local heir = right
		while heir[LEFT] ~= nil do
			heir = heir[LEFT]
		end
		if heir[PARENT] == gone then
			start = heir
		else
			start = heir[PARENT]
			replace(heir, heir[RIGHT]) -- 올릴 노드는 뿌리가 아님
			heir[RIGHT] = right
			right[PARENT] = heir
		end
		if replace(gone, heir) then
			top = heir
		end
		heir[LEFT] = left
		left[PARENT] = heir
		heir.height = gone.height
	end
	gone[LEFT] = nil
	gone[RIGHT] = nil
	gone[PARENT] = nil
	if start == nil then
		return top
	end
	-- 지우기는 높이가 그대로인 자리에서 멈출 수 없는 경우가 있어(회전 뒤 높이가 줄면 위도 다시 봐야 함)
	-- `rebalance` 의 "높이가 안 바뀌면 멈춤" 이 그대로 맞습니다 — 바뀐 동안은 계속 올라갑니다.
	const fixed = rebalance(top, start)
	return fixed
end

--#endregion

--#region ----------- 한 번에 짓기 -----------

-- **정렬된** 목록에서 O(n) 으로 짓습니다(`keys[i]`·`values[i]`, `1..count` — 키가 오름차순이고 중복이
-- 없어야 함: 검사하지 않습니다).
const function FromSorted<K, V>(keys: { K }, values: { V }, count: number): AvlNode<K, V>?
	const function build(first: number, last: number, parent: any): any
		if first > last then
			return nil
		end
		const mid = (first + last + 1) // 2
		const node: any = { nil, nil, parent, key = keys[mid], value = values[mid], height = 1 }
		node[LEFT] = build(first, mid - 1, node)
		node[RIGHT] = build(mid + 1, last, node)
		refresh(node)
		return node
	end
	return build(1, count, nil)
end

--#endregion

-- stylua: ignore
const AvlModule = {
	Find = Find, LowerBound = LowerBound, UpperBound = UpperBound,
	Insert = Insert, Remove = Remove,
	FromSorted = FromSorted, Clone = Clone,
}

-- 자가 균형의 계약(`Search.Balance`)을 만족하는지 여기서 정적으로 확인합니다 — 트리를 조립하는 쪽이 이
-- 모듈을 그대로 받아 씁니다.
const _balance: Search.Balance = AvlModule

return AvlModule

--!strict
--[[
	Node.Binary — 이진 노드.

	## 칸 배치 (계약)

	`{ [1] = 값, [2] = 왼쪽 자식, [3] = 오른쪽 자식, [4] = 부모 }` — `VALUE = 1`, `LEFT = 2`, `RIGHT = 3`,
	`PARENT = 4`. 그 뒤 칸(`5` …)은 이 노드를 쓰는 쪽의 것입니다 — 트리부는 `5` = 키, `6` = 균형 정보
	(`Trees/Search` 머리).

	부모 칸이 있어 **노드만 쥐고** 중위 순서의 다음·이전으로 갈 수 있고(스택 없이), 회전이 위쪽 연결까지
	고칩니다. 균형 방식(`src/Trees/`)이 이것으로 짜입니다. 뿌리가 바뀌었는지는 쓰는 쪽이 봅니다 — 회전이
	돌려준 노드의 부모가 `nil` 이면 그것이 새 뿌리입니다.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))

-- 읽기 노드(불투명 핸들 — 값에 공변).
export type NodeRead<T> = { read __links: "binary", read __value: T }
-- 고칠 수 있는 노드(불변 팬텀이 더 있음).
export type Node<T> = { read __links: "binary", read __value: T, read __valueMut: (T) -> T }

const VALUE, LEFT, RIGHT, PARENT = 1, 2, 3, 4

-- ⭐ **따라가는 도구는 받은 핸들의 타입 그대로 돌려줍니다**(`<N>(node: N & Kind): N?`): 고칠 수 있는 노드를 따라가면
-- 고칠 수 있는 노드가, 읽기 노드를 따라가면 읽기 노드가 나옵니다. `NodeRead<T>` 로 받아 `NodeRead<T>?` 를 돌려주던
-- 때는 자기가 만든 사슬도 따라간 뒤에는 고칠 수 없었고(`Walk` 로 돌며 떼기가 캐스트 없이는 안 써짐), 타입 인자가
-- 둘인 트리 노드는 값 타입이 `K | V` 로 넓어졌습니다(리뷰).
-- 트리부의 노드(키·균형 칸이 더 있는 것)도 이 종류입니다 — 그 타입 그대로 따라갑니다.
type Kind = { read __links: "binary" }

-- 연결이 없는 새 노드.
const function New<T>(value: T): Node<T>
	return { value, nil, nil, nil } :: any
end

const function Value<T>(node: NodeRead<T>): T
	return (node :: any)[VALUE]
end

const function SetValue<T>(node: Node<T>, value: T)
	(node :: any)[VALUE] = value
end

const function Left<N>(node: N & Kind): N?
	return (node :: any)[LEFT]
end

const function Right<N>(node: N & Kind): N?
	return (node :: any)[RIGHT]
end

const function Parent<N>(node: N & Kind): N?
	return (node :: any)[PARENT]
end

-- `child`(없어도 됨)를 `parent` 의 왼쪽 자식으로 달고 `child` 의 부모 칸도 맞춥니다. 예전 왼쪽 자식의 부모
-- 칸은 건드리지 않습니다(쓰는 쪽이 옮길지 정함).
const function SetLeft<T>(parent: Node<T>, child: Node<T>?)
	(parent :: any)[LEFT] = child
	if child ~= nil then
		(child :: any)[PARENT] = parent
	end
end

-- 오른쪽 자식으로.
const function SetRight<T>(parent: Node<T>, child: Node<T>?)
	(parent :: any)[RIGHT] = child
	if child ~= nil then
		(child :: any)[PARENT] = parent
	end
end

-- 이 노드를 뿌리로 한 부분 트리에서 중위 순서로 처음(가장 왼쪽) 노드.
const function First<N>(node: N & Kind): N
	local cursor: any = node
	local left = cursor[LEFT]
	while left ~= nil do
		cursor = left
		left = cursor[LEFT]
	end
	return cursor
end

-- 중위 순서로 끝(가장 오른쪽) 노드.
const function Last<N>(node: N & Kind): N
	local cursor: any = node
	local right = cursor[RIGHT]
	while right ~= nil do
		cursor = right
		right = cursor[RIGHT]
	end
	return cursor
end

-- 중위 순서로 다음 노드. 끝이면 `nil`. 전체를 도는 데 분할 상환 O(1).
const function Next<N>(node: N & Kind): N?
	local cursor: any = (node :: any)[RIGHT]
	if cursor ~= nil then
		local left = cursor[LEFT]
		while left ~= nil do
			cursor = left
			left = cursor[LEFT]
		end
		return cursor
	end
	local child: any, parent: any = node, (node :: any)[PARENT]
	while parent ~= nil and parent[RIGHT] == child do
		child = parent
		parent = parent[PARENT]
	end
	return parent
end

-- 중위 순서로 이전 노드. 처음이면 `nil`.
const function Prev<N>(node: N & Kind): N?
	local cursor: any = (node :: any)[LEFT]
	if cursor ~= nil then
		local right = cursor[RIGHT]
		while right ~= nil do
			cursor = right
			right = cursor[RIGHT]
		end
		return cursor
	end
	local child: any, parent: any = node, (node :: any)[PARENT]
	while parent ~= nil and parent[LEFT] == child do
		child = parent
		parent = parent[PARENT]
	end
	return parent
end

-- 왼쪽으로 회전: `node` 의 오른쪽 자식이 그 자리로 올라오고 `node` 는 그 왼쪽 자식이 됩니다. 올라온 노드를
-- 돌려줍니다. 부모의 자식 칸과 세 노드의 부모 칸까지 고칩니다. ⚠️ 오른쪽 자식이 있어야 합니다.
const function RotateLeft<T>(node: Node<T>): Node<T>
	const at = node :: any
	const pivot = at[RIGHT]
	const inner = pivot[LEFT]
	const parent = at[PARENT]
	at[RIGHT] = inner
	if inner ~= nil then
		inner[PARENT] = at
	end
	pivot[LEFT] = at
	at[PARENT] = pivot
	pivot[PARENT] = parent
	if parent ~= nil then
		if parent[LEFT] == at then
			parent[LEFT] = pivot
		else
			parent[RIGHT] = pivot
		end
	end
	return pivot
end

-- 오른쪽으로 회전(위의 거울). ⚠️ 왼쪽 자식이 있어야 합니다.
const function RotateRight<T>(node: Node<T>): Node<T>
	const at = node :: any
	const pivot = at[LEFT]
	const inner = pivot[RIGHT]
	const parent = at[PARENT]
	at[LEFT] = inner
	if inner ~= nil then
		inner[PARENT] = at
	end
	pivot[RIGHT] = at
	at[PARENT] = pivot
	pivot[PARENT] = parent
	if parent ~= nil then
		if parent[LEFT] == at then
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
	const parent = (old :: any)[PARENT]
	if fresh ~= nil then
		(fresh :: any)[PARENT] = parent
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

-- (순회자 — 전위·중위·후위·층별 — 는 `Trees/Traverse` 에 있습니다. 여기에는 노드 하나에서 이웃으로 가는 도구만.)

-- 부분 트리의 높이(빈 트리는 0). O(n) — 검사·디버깅용.
const function Height(node: Kind?): number
	if node == nil then
		return 0
	end
	const left, right = Height((node :: any)[LEFT]), Height((node :: any)[RIGHT])
	return (if left > right then left else right) + 1
end

-- stylua: ignore
return {
	-- 칸 배치(계약)
	VALUE = VALUE, LEFT = LEFT, RIGHT = RIGHT, PARENT = PARENT,
	New = New, Value = Value, SetValue = SetValue, Left = Left, Right = Right, Parent = Parent,
	SetLeft = SetLeft, SetRight = SetRight,
	First = First, Last = Last, Next = Next, Prev = Prev,
	RotateLeft = RotateLeft, RotateRight = RotateRight, Replace = Replace,
	Height = Height,
}

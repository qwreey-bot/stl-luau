--!strict
--[[
	Node.Double — 양방향으로 이은 노드.

	## 칸 배치 (계약)

	`{ [1] = 값, [2] = 앞 노드, [3] = 뒤 노드 }` — `VALUE = 1`, `PREV = 2`, `NEXT = 3`.

	노드끼리의 연결만 고칩니다. 머리·꼬리·크기는 그것을 가진 컨테이너가 고칩니다(돌려준 것을 보고).
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))

-- 읽기 노드(불투명 핸들 — 원소에 공변). 컨테이너가 밖으로 내주는 위치.
export type NodeRead<T> = { read __links: "double", read __value: T }
-- 고칠 수 있는 노드(불변 팬텀이 더 있음).
-- (옵셔널로 받는 도구는 `NodeRead<T> | Node<T> | nil` 로 적습니다 — `NodeRead<T>?` 하나로 적으면 `Node<T>` 를
-- 넘길 때 솔버가 `T` 를 못 풀었습니다, 실측.)
export type Node<T> = { read __links: "double", read __value: T, read __valueMut: (T) -> T }

const VALUE, PREV, NEXT = 1, 2, 3

-- 연결이 없는 새 노드.
const function New<T>(value: T): Node<T>
	return { value, nil, nil } :: any
end

const function Value<T>(node: NodeRead<T>): T
	return (node :: any)[VALUE]
end

const function SetValue<T>(node: Node<T>, value: T)
	(node :: any)[VALUE] = value
end

-- 앞 노드. 처음이면 `nil`.
const function Prev<T>(node: NodeRead<T>): NodeRead<T>?
	return (node :: any)[PREV]
end

-- 뒤 노드. 끝이면 `nil`.
const function Next<T>(node: NodeRead<T>): NodeRead<T>?
	return (node :: any)[NEXT]
end

-- `node` 바로 뒤에 `fresh` 를 잇고 `fresh` 를 돌려줍니다. 그 뒤가 없었으면 `fresh` 가 새 꼬리입니다
-- (`Next(fresh) == nil`).
const function InsertNext<T>(node: Node<T>, fresh: Node<T>): Node<T>
	const at, added = node :: any, fresh :: any
	const after = at[NEXT]
	added[PREV] = at
	added[NEXT] = after
	at[NEXT] = added
	if after ~= nil then
		after[PREV] = added
	end
	return fresh
end

-- `node` 바로 앞에 `fresh` 를 잇고 `fresh` 를 돌려줍니다. 그 앞이 없었으면 `fresh` 가 새 머리입니다.
const function InsertPrev<T>(node: Node<T>, fresh: Node<T>): Node<T>
	const at, added = node :: any, fresh :: any
	const before = at[PREV]
	added[PREV] = before
	added[NEXT] = at
	at[PREV] = added
	if before ~= nil then
		before[NEXT] = added
	end
	return fresh
end

-- `node` 를 떼어 냅니다(이웃끼리 잇고 `node` 의 연결을 끊음). 떼기 전의 **앞·뒤 이웃**을 돌려줍니다 —
-- 앞이 `nil` 이면 `node` 가 머리였고(새 머리는 뒤 이웃), 뒤가 `nil` 이면 꼬리였습니다.
const function Unlink<T>(node: Node<T>): (Node<T>?, Node<T>?)
	const at = node :: any
	const before, after = at[PREV], at[NEXT]
	if before ~= nil then
		before[NEXT] = after
	end
	if after ~= nil then
		after[PREV] = before
	end
	at[PREV] = nil
	at[NEXT] = nil
	return before, after
end

-- 앞에서 뒤로 노드를 하나씩: `for node in Node.Double.Walk(head) do`. 다음 노드를 미리 읽어 두므로 도는 동안
-- **지금 노드**를 떼어 내도 이어서 돕니다.
const function Walk<T>(start: NodeRead<T> | Node<T> | nil): () -> NodeRead<T>?
	local cursor: any = start
	return function(): NodeRead<T>?
		const node = cursor
		if node ~= nil then
			cursor = node[NEXT]
		end
		return node
	end
end

-- 뒤에서 앞으로.
const function WalkBack<T>(start: NodeRead<T> | Node<T> | nil): () -> NodeRead<T>?
	local cursor: any = start
	return function(): NodeRead<T>?
		const node = cursor
		if node ~= nil then
			cursor = node[PREV]
		end
		return node
	end
end

-- `start` 부터 뒤쪽 끝까지의 노드 수. `nil` 이면 0. ⚠️ 고리로 이은 사슬에서는 끝나지 않습니다.
const function Count<T>(start: NodeRead<T> | Node<T> | nil): number
	local total, cursor: any = 0, start
	while cursor ~= nil do
		total += 1
		cursor = cursor[NEXT]
	end
	return total
end

-- stylua: ignore
return {
	-- 칸 배치(계약)
	VALUE = VALUE, PREV = PREV, NEXT = NEXT,
	New = New, Value = Value, SetValue = SetValue, Prev = Prev, Next = Next,
	InsertNext = InsertNext, InsertPrev = InsertPrev, Unlink = Unlink,
	Walk = Walk, WalkBack = WalkBack, Count = Count,
}

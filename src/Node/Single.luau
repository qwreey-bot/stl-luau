--!strict
--[[
	Node.Single — 단방향으로 이은 노드.

	## 칸 배치 (계약)

	`{ [1] = 값, [2] = 다음 노드 }` — `VALUE = 1`, `NEXT = 2`.

	앞 노드를 모르니 "내 뒤" 만 O(1) 로 다룹니다. 자기 자신을 떼려면 앞 노드가 필요합니다 — 그건 쓰는 쪽이
	가지고 다닙니다(꼬리를 가진 리스트가 맨 뒤를 지울 때 꼬리를 고치는 것도 그 리스트 안에서 직접 — 사용자:
	*"그냥 그렇게 하는게 맞는것 같아보임. 모듈화 하기엔 별로 이유가 없을듯"*).
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))

-- 읽기 노드(불투명 핸들 — 원소에 공변).
export type NodeRead<T> = { read __links: "single", read __value: T }
-- 고칠 수 있는 노드(불변 팬텀이 더 있음).
-- (옵셔널로 받는 도구는 `NodeRead<T> | Node<T> | nil` 로 적습니다 — `NodeRead<T>?` 하나로 적으면 `Node<T>` 를
-- 넘길 때 솔버가 `T` 를 못 풀었습니다, 실측.)
export type Node<T> = { read __links: "single", read __value: T, read __valueMut: (T) -> T }

const VALUE, NEXT = 1, 2

-- 연결이 없는 새 노드.
const function New<T>(value: T): Node<T>
	return { value, nil } :: any
end

const function Value<T>(node: NodeRead<T>): T
	return (node :: any)[VALUE]
end

const function SetValue<T>(node: Node<T>, value: T)
	(node :: any)[VALUE] = value
end

-- 다음 노드. 끝이면 `nil`.
const function Next<T>(node: NodeRead<T>): NodeRead<T>?
	return (node :: any)[NEXT]
end

-- `node` 바로 뒤에 `fresh` 를 잇고 `fresh` 를 돌려줍니다.
const function InsertNext<T>(node: Node<T>, fresh: Node<T>): Node<T>
	const at, added = node :: any, fresh :: any
	added[NEXT] = at[NEXT]
	at[NEXT] = added
	return fresh
end

-- `node` 바로 뒤의 노드를 떼어 돌려줍니다(없으면 `nil`). 떼어 낸 노드는 연결이 끊깁니다.
const function RemoveNext<T>(node: Node<T>): Node<T>?
	const at = node :: any
	const after = at[NEXT]
	if after ~= nil then
		at[NEXT] = after[NEXT]
		after[NEXT] = nil
	end
	return after
end

-- 노드를 하나씩: `for node in Node.Single.Walk(head) do`. `start` 가 `nil` 이면 돌지 않습니다. 다음 노드를
-- 미리 읽어 두므로 도는 동안 **지금 노드의 연결**을 고쳐도 됩니다.
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

-- `start` 부터 끝까지의 노드 수. `nil` 이면 0. ⚠️ 고리로 이은 사슬에서는 끝나지 않습니다.
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
	VALUE = VALUE, NEXT = NEXT,
	New = New, Value = Value, SetValue = SetValue, Next = Next,
	InsertNext = InsertNext, RemoveNext = RemoveNext, Walk = Walk, Count = Count,
}

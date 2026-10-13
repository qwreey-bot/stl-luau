--!strict
--[[
	Node.Double — 양방향으로 이은 노드의 도구. 칸 1 = 앞, 2 = 뒤.

	노드끼리의 연결만 고칩니다. 머리·꼬리·크기는 그것을 가진 컨테이너가 고칩니다(돌려준 것을 보고).
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Types = require("./Types")

type Node<T> = Types.Node<T>

const PREV, NEXT = 1, 2

-- `node` 바로 뒤에 `fresh` 를 잇고 `fresh` 를 돌려줍니다. `fresh[2] == nil` 이면 `fresh` 가 새 꼬리입니다.
const function InsertNext<T>(node: Node<T>, fresh: Node<T>): Node<T>
	const after = node[NEXT]
	fresh[PREV] = node
	fresh[NEXT] = after
	node[NEXT] = fresh
	if after ~= nil then
		after[PREV] = fresh
	end
	return fresh
end

-- `node` 바로 앞에 `fresh` 를 잇고 `fresh` 를 돌려줍니다. `fresh[1] == nil` 이면 `fresh` 가 새 머리입니다.
const function InsertPrev<T>(node: Node<T>, fresh: Node<T>): Node<T>
	const before = node[PREV]
	fresh[PREV] = before
	fresh[NEXT] = node
	node[PREV] = fresh
	if before ~= nil then
		before[NEXT] = fresh
	end
	return fresh
end

-- `node` 를 떼어 냅니다(이웃끼리 잇고 `node` 의 연결을 끊음). 떼기 전의 **앞·뒤 이웃**을 돌려줍니다 —
-- 앞이 `nil` 이면 `node` 가 머리였고(새 머리는 뒤 이웃), 뒤가 `nil` 이면 꼬리였습니다.
const function Unlink<T>(node: Node<T>): (Node<T>?, Node<T>?)
	const before, after = node[PREV], node[NEXT]
	if before ~= nil then
		before[NEXT] = after
	end
	if after ~= nil then
		after[PREV] = before
	end
	node[PREV] = nil
	node[NEXT] = nil
	return before, after
end

-- stylua: ignore
return {
	InsertNext = InsertNext, InsertPrev = InsertPrev, Unlink = Unlink,
}

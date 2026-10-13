--!strict
--[[
	Node.Single — 단방향으로 이은 노드의 도구. 칸 1 = 다음.

	앞 노드를 모르니 "내 뒤" 만 O(1) 로 다룹니다(자기 자신을 떼려면 앞 노드가 필요 — 그건 쓰는 쪽이 가지고
	다닙니다. 꼬리를 가진 리스트가 맨 뒤를 지울 때 꼬리를 고쳐야 하는 것도 그 리스트 안에서 직접 — 사용자:
	*"그냥 그렇게 하는게 맞는것 같아보임. 모듈화 하기엔 별로 이유가 없을듯"*).
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Types = require("./Types")

type Node<T> = Types.Node<T>

const SINGLE_NEXT = 1

-- `node` 바로 뒤에 `fresh` 를 잇고 `fresh` 를 돌려줍니다.
const function InsertNext<T>(node: Node<T>, fresh: Node<T>): Node<T>
	fresh[SINGLE_NEXT] = node[SINGLE_NEXT]
	node[SINGLE_NEXT] = fresh
	return fresh
end

-- `node` 바로 뒤의 노드를 떼어 돌려줍니다(없으면 `nil`). 떼어 낸 노드는 연결이 끊깁니다.
const function RemoveNext<T>(node: Node<T>): Node<T>?
	const after = node[SINGLE_NEXT]
	if after ~= nil then
		node[SINGLE_NEXT] = after[SINGLE_NEXT]
		after[SINGLE_NEXT] = nil
	end
	return after
end

-- stylua: ignore
return {
	InsertNext = InsertNext, RemoveNext = RemoveNext,
}

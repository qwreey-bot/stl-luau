--!strict
--[[
	Traverse — 이진 트리의 순회자(2층 트리부, 2026-10-13 사용자: *"트리 순회자 그런것도 Trees 폴더에"*).

	`for node in Traverse.PreOrder(root) do` 처럼 씁니다. 넷 다 **노드**를 하나씩 내고(값은 `Node.Binary.Value`,
	트리부 노드의 키는 `Search.Key`), **받은 노드의 타입 그대로** 돌려줍니다(레드블랙 노드를 넣으면 레드블랙 노드).

	| 순회 | 순서 | 쓰임 |
	|---|---|---|
	| `PreOrder` | 자기 → 왼쪽 → 오른쪽 | 구조째 베끼기·직렬화(부모가 자식보다 먼저 나옴) |
	| `InOrder` | 왼쪽 → 자기 → 오른쪽 | 탐색 트리에서는 키 순서 |
	| `PostOrder` | 왼쪽 → 오른쪽 → 자기 | 아래부터 계산·해제(자식이 부모보다 먼저 나옴) |
	| `LevelOrder` | 뿌리부터 층별로, 층 안에서는 왼쪽부터 | 모양 출력, 가까운 것부터 |

	## 약속

	- **`root` 의 부분 트리 안에서만 돕니다.** `root` 에 부모가 있어도(트리의 가운데 노드를 넘겨도) 그 위로
	  나가지 않습니다. `root` 가 `nil` 이면 돌지 않습니다.
	- `PreOrder`·`InOrder`·`PostOrder` 는 **부모 칸을 따라갑니다** — 스택도 큐도 만들지 않습니다(순회자 하나에
	  클로저 하나, 추가 메모리 O(1)). 전체를 도는 데 O(n), 걸음 하나는 분할 상환 O(1).
	- `LevelOrder` 는 층을 담을 배열이 필요합니다 — 추가 메모리는 가장 넓은 층의 노드 수만큼.
	- 다음 노드는 지금 노드를 내기 **전에** 정해 둡니다. 그래도 도는 동안 트리의 연결을 바꾸면(회전이 길을 바꿈)
	  정의되지 않은 동작입니다 — 값만 고치는 것은 됩니다. 지우며 돌려면 `Search.Next` 를 먼저 읽어 두세요.

	칸 배치는 이진 노드의 계약(`Node/Binary` 머리 — `2` = 왼쪽, `3` = 오른쪽, `4` = 부모)이고, 여기서는 그 칸을
	지역 상수로 직접 읽습니다.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))

const LEFT, RIGHT, PARENT = 2, 3, 4

type Kind = { read __links: "binary" }

-- 자기 → 왼쪽 → 오른쪽.
const function PreOrder<N>(root: (N & Kind)?): () -> N?
	const top: any = root
	local cursor: any = root
	return function(): N?
		const node = cursor
		if node == nil then
			return nil
		end
		-- 다음: 왼쪽 자식, 없으면 오른쪽 자식, 그것도 없으면 올라가며 "왼쪽으로 내려왔던 조상의 오른쪽".
		local following = node[LEFT]
		if following == nil then
			following = node[RIGHT]
		end
		if following == nil then
			local child = node
			while child ~= top do
				const parent = child[PARENT]
				const right = parent[RIGHT]
				if right ~= nil and right ~= child then
					following = right
					break
				end
				child = parent
			end
		end
		cursor = following
		return node
	end
end

-- 부분 트리에서 가장 왼쪽 노드.
const function leftmost(node: any): any
	local left = node[LEFT]
	while left ~= nil do
		node = left
		left = node[LEFT]
	end
	return node
end

-- 왼쪽 → 자기 → 오른쪽. 탐색 트리에서는 키 순서입니다.
const function InOrder<N>(root: (N & Kind)?): () -> N?
	const top: any = root
	local cursor: any = if top ~= nil then leftmost(top) else nil
	return function(): N?
		const node = cursor
		if node == nil then
			return nil
		end
		-- 다음: 오른쪽이 있으면 그 가장 왼쪽, 없으면 "왼쪽 자식으로서 올라온" 첫 조상(`top` 을 넘지 않음).
		const right = node[RIGHT]
		local following = nil
		if right ~= nil then
			following = leftmost(right)
		else
			local child = node
			while child ~= top do
				const parent = child[PARENT]
				if parent[LEFT] == child then
					following = parent
					break
				end
				child = parent
			end
		end
		cursor = following
		return node
	end
end

-- 후위 순서에서 부분 트리의 첫 노드: 왼쪽이 있으면 왼쪽으로, 없으면 오른쪽으로, 둘 다 없을 때까지.
const function firstPostOrder(node: any): any
	while true do
		const left = node[LEFT]
		if left ~= nil then
			node = left
		else
			const right = node[RIGHT]
			if right == nil then
				return node
			end
			node = right
		end
	end
end

-- 왼쪽 → 오른쪽 → 자기. 자식이 늘 부모보다 먼저 나옵니다.
const function PostOrder<N>(root: (N & Kind)?): () -> N?
	const top: any = root
	local cursor: any = if top ~= nil then firstPostOrder(top) else nil
	return function(): N?
		const node = cursor
		if node == nil then
			return nil
		end
		-- 다음: 내가 왼쪽 자식이고 오른쪽 형제가 있으면 그 부분 트리의 첫 노드, 아니면 부모. `top` 이면 끝.
		local following = nil
		if node ~= top then
			const parent = node[PARENT]
			const right = parent[RIGHT]
			following = if right ~= nil and right ~= node then firstPostOrder(right) else parent
		end
		cursor = following
		return node
	end
end

-- 뿌리부터 층별로, 층 안에서는 왼쪽부터. **층 두 개를 번갈아** 씁니다(지금 도는 층 / 다음 층) — 추가 메모리는
-- 가장 넓은 층만큼입니다. 바꿔 든 배열은 비우지 않고 덮어씁니다(세어 둔 개수까지만 읽음).
-- (큐 하나에 쌓으며 지나간 칸을 `nil` 로 비우는 판은 1.7배 느렸습니다 — 앞이 빈 배열은 늘어날 때 해시 부분으로
-- 옮겨집니다. 큐를 안 비우는 판은 비슷한 속도지만 순회자가 노드 전부를 끝까지 붙잡습니다. perf 40절.)
const function LevelOrder<N>(root: (N & Kind)?): () -> N?
	local layer: { any }, coming: { any } = { root }, {}
	local at, count, comingCount = 0, if root ~= nil then 1 else 0, 0
	return function(): N?
		if at == count then
			if comingCount == 0 then
				return nil
			end
			layer, coming = coming, layer
			at, count, comingCount = 0, comingCount, 0
		end
		at += 1
		const node = layer[at]
		const left = node[LEFT]
		if left ~= nil then
			comingCount += 1
			coming[comingCount] = left
		end
		const right = node[RIGHT]
		if right ~= nil then
			comingCount += 1
			coming[comingCount] = right
		end
		return node
	end
end

-- stylua: ignore
return {
	PreOrder = PreOrder, InOrder = InOrder, PostOrder = PostOrder, LevelOrder = LevelOrder,
}

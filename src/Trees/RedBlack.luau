--!strict
--[[
	RedBlack — 레드블랙 트리의 구조 제어(2층 트리부, 2026-10-13 — `papers/07` 9-4).

	컨테이너가 **아닙니다**: 뿌리 노드와 비교자를 받아 트리를 고치고 **새 뿌리**를 돌려주는 함수들입니다.
	크기·타입 토큰·키 검사는 이것을 조립하는 쪽(`TreeMap` 등)이 가집니다.

	## 노드의 칸 배치 (계약)

	`{ [1] = 값, [2] = 왼쪽, [3] = 오른쪽, [4] = 부모, [5] = 키, [6] = 빨강인가 }` — 앞의 넷은 `Node.Binary`,
	다섯째는 `Trees/Search`, 여섯째(균형 정보)가 이 방식의 것입니다. 타입은 불투명 핸들(`RbNode`·`RbNodeRead`)
	이라 값·키는 `Search.Value(node)`·`Search.Key(node)` 로, 순서는 `Search.Next`·`Prev` 로 읽습니다.

	## 왜 레드블랙인가

	사용자: *"구현체로 때어 두는건 좋은데 실제 제품에서는 RB 가 들어가긴 해야겠다"*. AVL 보다 균형이 느슨해
	(높이 ≤ 2·log₂(n+1)) 넣기·지우기의 회전이 적습니다 — 넣기는 최대 2번, 지우기는 최대 3번. 넣고 빼기가
	잦은 쓰임에 맞습니다. 실측은 perf 37절.

	## 불변식 (`tests/spec.trees.luau` 가 연산마다 검사)

	1. 뿌리는 검정. 2. 빨강의 자식은 빨강이 아님. 3. 어느 노드에서든 잎까지의 검정 수가 같음.
	4. 중위 순서가 비교자의 순서. 5. 자식의 부모 칸이 그 부모를 가리키고 뿌리의 부모는 `nil`.

	## 규칙

	- 비교자는 3방향(`Comparator`). 비교자가 던지면 트리는 그대로입니다(넣기는 자리를 찾은 뒤에만 고침).
	- 위치는 노드입니다. `Remove` 는 **이 트리의 노드**를 받습니다 — 다른 트리의 노드나 이미 뗀 노드는 정의되지
	  않은 동작입니다(조립하는 쪽이 키로 찾아 넘기는 것이 보통).
	- 떼어 낸 노드는 연결이 끊깁니다(왼쪽·오른쪽·부모 칸이 `nil`). 순회 중에 지우려면 다음 노드를 **먼저** 읽어
	  두세요(`Search.Next`) — 지우기가 회전으로 길을 바꿉니다. 다음 노드 자체는 남아 있습니다.
]]
local Types = require("../Types")
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Node = require("../Node")
local Search = require("./Search")

type Comparator<T> = Types.Comparator<T>

-- 레드블랙 노드(불투명 핸들 — 칸 배치는 머리 주석). 고칠 수 있는 쪽은 불변 팬텀이 더 있습니다.
export type RbNode<K, V> = {
	read __links: "binary",
	read __value: V,
	read __key: K,
	read __balance: "redblack",
	read __keyMut: (K, V) -> (K, V),
}
-- 읽기만 하는 노드(밖으로 내주는 위치). 키·값에 공변.
export type RbNodeRead<K, V> = { read __links: "binary", read __value: V, read __key: K, read __balance: "redblack" }

-- 칸 배치(`Node.Binary` 의 넷 + `Trees/Search` 의 키 + 이 방식의 색). 지역 상수라 접힙니다.
const VALUE, LEFT, RIGHT, PARENT, KEY, RED = 1, 2, 3, 4, 5, 6
-- 노드 도구. 이 모듈 안에서는 노드를 칸으로 직접 다루니 느슨한 타입으로 받습니다(불투명 핸들은 밖을 위한 것).
const binary: any = Node.Binary
const rotateLeft: (any) -> any = binary.RotateLeft
const rotateRight: (any) -> any = binary.RotateRight
const replace: (any, any) -> boolean = binary.Replace

--#region ----------- 읽기 — 균형 방식과 무관한 공유 조각(`Trees/Search`)을 이 노드 타입으로 -----------

-- (옵셔널 자리는 `읽기 | 쓰기 | nil` 로 — `RbNodeRead<K, V>?` 하나로 적으면 `RbNode` 를 넘길 때 `K`·`V` 를 못 풀었습니다)
type FindFn = <K, V>(root: RbNodeRead<K, V> | RbNode<K, V> | nil, key: K, compare: Comparator<K>) -> RbNodeRead<K, V>?
type CloneFn = <K, V>(root: RbNodeRead<K, V> | RbNode<K, V> | nil) -> RbNode<K, V>?
const shared: any = Search
-- 키가 같은 노드 / 키가 `key` 이상인 첫 노드 / 초과인 첫 노드(없으면 `nil`).
const Find: FindFn = shared.Find
const LowerBound: FindFn = shared.LowerBound
const UpperBound: FindFn = shared.UpperBound
-- 구조째 베낍니다(노드는 새로, 키·값·색은 그대로). O(n).
const Clone: CloneFn = shared.Clone

--#endregion

--#region ----------- 넣기 -----------

-- 키-값을 넣고 `(새 뿌리, 그 키의 노드, 새로 만들었나)` 를 돌려줍니다. 키가 이미 있으면 값만 바꿉니다
-- (구조는 그대로, 셋째 반환 `false`). 회전은 최대 2번.
const function Insert<K, V>(
	root: RbNode<K, V>?,
	key: K,
	value: V,
	compare: Comparator<K>
): (RbNode<K, V>, RbNode<K, V>, boolean)
	local parent: any, cursor: any = nil, root
	local order = 0
	while cursor ~= nil do
		order = compare(key, cursor[KEY])
		if order == 0 then
			cursor[VALUE] = value
			return root :: any, cursor, false
		end
		parent = cursor
		cursor = if order < 0 then cursor[LEFT] else cursor[RIGHT]
	end
	-- 연결 칸을 생성자에 같이 적습니다(perf 34절)
	const fresh: any = { value, nil, nil, parent, key, true }
	if parent == nil then
		fresh[RED] = false
		return fresh, fresh, true
	end
	if order < 0 then
		parent[LEFT] = fresh
	else
		parent[RIGHT] = fresh
	end
	-- 빨강-빨강을 위로 밀어 올리며 고칩니다
	local top: any = root
	local node: any = fresh
	while true do
		local above = node[PARENT]
		if above == nil or not above[RED] then
			break
		end
		const grand = above[PARENT] -- 빨강은 뿌리가 아니니 조부모가 있음
		if grand[LEFT] == above then
			const uncle = grand[RIGHT]
			if uncle ~= nil and uncle[RED] then
				above[RED] = false
				uncle[RED] = false
				grand[RED] = true
				node = grand
			else
				if above[RIGHT] == node then
					rotateLeft(above)
					above = node
				end
				above[RED] = false
				grand[RED] = true
				const raised = rotateRight(grand)
				if raised[PARENT] == nil then
					top = raised
				end
				break
			end
		else
			const uncle = grand[LEFT]
			if uncle ~= nil and uncle[RED] then
				above[RED] = false
				uncle[RED] = false
				grand[RED] = true
				node = grand
			else
				if above[LEFT] == node then
					rotateRight(above)
					above = node
				end
				above[RED] = false
				grand[RED] = true
				const raised = rotateLeft(grand)
				if raised[PARENT] == nil then
					top = raised
				end
				break
			end
		end
	end
	top[RED] = false
	return top, fresh, true
end

--#endregion

--#region ----------- 지우기 -----------

-- 검정 하나가 빠진 자리(`node` — `nil` 일 수 있어 부모를 따로 받음)에서 위로 올라가며 검정 수를 맞춥니다.
const function removeFixup(top: any, node: any, parent: any): any
	while node ~= top and (node == nil or not node[RED]) do
		-- `node` 가 `nil` 이어도 어느 쪽인지 갈립니다: 검정이 빠진 쪽의 형제는 반드시 있습니다(검정 수)
		if parent[LEFT] == node then
			local sibling = parent[RIGHT]
			if sibling[RED] then
				sibling[RED] = false
				parent[RED] = true
				const raised = rotateLeft(parent)
				if raised[PARENT] == nil then
					top = raised
				end
				sibling = parent[RIGHT]
			end
			const near, far = sibling[LEFT], sibling[RIGHT]
			if (near == nil or not near[RED]) and (far == nil or not far[RED]) then
				sibling[RED] = true
				node = parent
				parent = node[PARENT]
			else
				if far == nil or not far[RED] then
					near[RED] = false
					sibling[RED] = true
					rotateRight(sibling)
					sibling = parent[RIGHT]
				end
				sibling[RED] = parent[RED]
				parent[RED] = false
				sibling[RIGHT][RED] = false
				const raised = rotateLeft(parent)
				if raised[PARENT] == nil then
					top = raised
				end
				node = top
				break
			end
		else
			local sibling = parent[LEFT]
			if sibling[RED] then
				sibling[RED] = false
				parent[RED] = true
				const raised = rotateRight(parent)
				if raised[PARENT] == nil then
					top = raised
				end
				sibling = parent[LEFT]
			end
			const near, far = sibling[RIGHT], sibling[LEFT]
			if (near == nil or not near[RED]) and (far == nil or not far[RED]) then
				sibling[RED] = true
				node = parent
				parent = node[PARENT]
			else
				if far == nil or not far[RED] then
					near[RED] = false
					sibling[RED] = true
					rotateLeft(sibling)
					sibling = parent[LEFT]
				end
				sibling[RED] = parent[RED]
				parent[RED] = false
				sibling[LEFT][RED] = false
				const raised = rotateRight(parent)
				if raised[PARENT] == nil then
					top = raised
				end
				node = top
				break
			end
		end
	end
	if node ~= nil then
		node[RED] = false
	end
	return top
end

-- 이 트리의 노드 `target` 을 떼어 내고 **새 뿌리**(비면 `nil`)를 돌려줍니다. 회전은 최대 3번.
-- 다른 노드들은 그대로 살아 있습니다(쥐고 있던 다른 위치는 유효) — `target` 만 연결이 끊깁니다.
const function Remove<K, V>(root: RbNode<K, V>, target: RbNodeRead<K, V>): RbNode<K, V>?
	local top: any = root
	const gone: any = target
	local lostRed: boolean = gone[RED]
	local hole: any, holeParent: any
	const left, right = gone[LEFT], gone[RIGHT]
	if left == nil then
		hole, holeParent = right, gone[PARENT]
		if replace(gone, right) then
			top = right
		end
	elseif right == nil then
		hole, holeParent = left, gone[PARENT]
		if replace(gone, left) then
			top = left
		end
	else
		-- 자식이 둘: 중위 다음 노드(오른쪽 부분 트리의 처음)를 그 자리로 올립니다(노드를 옮김 — 값만 베끼면
		-- 쥐고 있던 위치가 다른 키를 가리키게 됨)
		local heir = right
		while heir[LEFT] ~= nil do
			heir = heir[LEFT]
		end
		lostRed = heir[RED]
		hole = heir[RIGHT]
		if heir[PARENT] == gone then
			holeParent = heir
		else
			holeParent = heir[PARENT]
			replace(heir, hole) -- 올릴 노드는 뿌리가 아님
			heir[RIGHT] = right
			right[PARENT] = heir
		end
		if replace(gone, heir) then
			top = heir
		end
		heir[LEFT] = left
		left[PARENT] = heir
		heir[RED] = gone[RED]
	end
	if not lostRed then
		top = removeFixup(top, hole, holeParent)
	end
	gone[LEFT] = nil
	gone[RIGHT] = nil
	gone[PARENT] = nil
	return top
end

--#endregion

--#region ----------- 한 번에 짓기·베끼기 -----------

-- **정렬된** 목록에서 O(n) 으로 짓습니다(`keys[i]`·`values[i]`, `1..count` — 키가 오름차순이고 중복이
-- 없어야 함: 검사하지 않습니다). 완전 이진 모양으로 쌓고 맨 아래 층만 빨강으로 칠합니다.
const function FromSorted<K, V>(keys: { K }, values: { V }, count: number): RbNode<K, V>?
	if count <= 0 then
		return nil
	end
	-- 가득 찬 층의 수: 그보다 깊은(마지막) 층의 노드만 빨강
	local fullLevels = 0
	while 2 ^ (fullLevels + 1) - 1 <= count do
		fullLevels += 1
	end
	const function build(first: number, last: number, depth: number, parent: any): any
		if first > last then
			return nil
		end
		const mid = (first + last + 1) // 2
		const node: any = { values[mid], nil, nil, parent, keys[mid], depth > fullLevels }
		node[LEFT] = build(first, mid - 1, depth + 1, node)
		node[RIGHT] = build(mid + 1, last, depth + 1, node)
		return node
	end
	return build(1, count, 1, nil)
end

--#endregion

-- stylua: ignore
const RedBlackModule = {
	Find = Find, LowerBound = LowerBound, UpperBound = UpperBound,
	Insert = Insert, Remove = Remove,
	FromSorted = FromSorted, Clone = Clone,
}

-- 자가 균형의 계약(`Search.Balance`)을 만족하는지 여기서 정적으로 확인합니다 — 트리를 조립하는 쪽이 이
-- 모듈을 그대로 받아 씁니다.
const _balance: Search.Balance = RedBlackModule

return RedBlackModule

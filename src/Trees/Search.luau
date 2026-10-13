--!strict
--[[
	Search — 이진 탐색 트리의 **균형 방식과 무관한** 조각(2층 트리부의 공유 구현, 2026-10-13).

	키 순서로 놓인 이진 노드를 **읽는** 일은 균형을 어떻게 맞췄든 같습니다 — 찾기, 경계 찾기, 구조째 베끼기.
	`RedBlack`·`Avl` 이 이것을 그대로 내보내고, 자기 것은 넣기·지우기(구조를 고치는 쪽)만 가집니다.
	노드는 `Node.Binary` 의 규칙(칸 1 = 왼쪽, 2 = 오른쪽, 3 = 부모)에 `key`·`value` 필드가 있는 것이면 됩니다.
]]
local Types = require("../Types")
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))

type Comparator<T> = Types.Comparator<T>

-- 키를 가진 이진 노드(읽기). 균형 방식의 노드(`RbNode`·`AvlNode`)는 필드가 더 있을 뿐 이 자리에 들어갑니다.
export type KeyNodeRead<K, V> = { read key: K, read value: V, read [number]: KeyNodeRead<K, V>? }

-- ⭐ **자가 균형의 계약**(2026-10-13 사용자: *"자가균형 같은 경우는 Insert, Remove 를 계약으로 하나의 추상화를 둘 수
-- 있을법 … 트리 쓰는 곳에서 자가균형을 뭘로 할 지 default 가 있고, 직접 선택도 가능한 구조"*). `RedBlack`·`Avl`
-- 모듈이 그대로 이 모양입니다 — 트리를 조립하는 쪽은 이것 하나를 받아 쓰고(기본은 레드블랙), 바깥에서 만든 균형
-- 방식도 같은 모양이면 들어갑니다. 노드 타입은 방식마다 달라(색·높이 …) 여기서는 `any` 입니다 — 조립하는
-- 쪽이 뿌리를 "그 방식의 노드" 로만 다루면 됩니다(읽을 때는 `KeyNodeRead`).
-- - `Insert(root, key, value, compare)` → `(새 뿌리, 그 키의 노드, 새로 만들었나)`. 있던 키면 값만 바꿈.
-- - `Remove(root, node)` → 새 뿌리(비면 `nil`). `node` 는 그 트리의 노드, 떼어 낸 뒤 연결이 끊김.
-- - `FromSorted(keys, values, count)` → 정렬된 목록에서 O(n) 으로 지은 뿌리. `Clone(root)` → 구조째 베낀 뿌리.
export type Balance = {
	read Insert: (root: any, key: any, value: any, compare: Comparator<any>) -> (any, any, boolean),
	read Remove: (root: any, node: any) -> any,
	read FromSorted: (keys: { any }, values: { any }, count: number) -> any,
	read Clone: (root: any) -> any,
}

const LEFT, RIGHT, PARENT = 1, 2, 3

-- 키가 같은 노드. 없으면 `nil`.
const function Find<K, V>(root: KeyNodeRead<K, V>?, key: K, compare: Comparator<K>): KeyNodeRead<K, V>?
	local cursor = root
	while cursor ~= nil do
		const order = compare(key, cursor.key)
		if order == 0 then
			return cursor
		end
		cursor = if order < 0 then cursor[LEFT] else cursor[RIGHT]
	end
	return nil
end

-- 키가 `key` **이상**인 첫 노드(중위 순서). 없으면 `nil`. `Ceiling` 이고, 구간 순회의 시작점입니다.
const function LowerBound<K, V>(root: KeyNodeRead<K, V>?, key: K, compare: Comparator<K>): KeyNodeRead<K, V>?
	local cursor, best: KeyNodeRead<K, V>? = root, nil
	while cursor ~= nil do
		if compare(key, cursor.key) <= 0 then
			best = cursor
			cursor = cursor[LEFT]
		else
			cursor = cursor[RIGHT]
		end
	end
	return best
end

-- 키가 `key` **초과**인 첫 노드. 없으면 `nil`.
const function UpperBound<K, V>(root: KeyNodeRead<K, V>?, key: K, compare: Comparator<K>): KeyNodeRead<K, V>?
	local cursor, best: KeyNodeRead<K, V>? = root, nil
	while cursor ~= nil do
		if compare(key, cursor.key) < 0 then
			best = cursor
			cursor = cursor[LEFT]
		else
			cursor = cursor[RIGHT]
		end
	end
	return best
end

-- 구조째 베낍니다(노드는 새로, 키·값과 **균형 정보까지 그대로** — 노드의 필드를 통째로 베끼니 어느 균형
-- 방식의 트리든 됩니다). O(n).
const function Clone<K, V>(root: KeyNodeRead<K, V>?): KeyNodeRead<K, V>?
	const function copy(node: any, parent: any): any
		if node == nil then
			return nil
		end
		const fresh = table.clone(node)
		fresh[PARENT] = parent
		fresh[LEFT] = copy(node[LEFT], fresh)
		fresh[RIGHT] = copy(node[RIGHT], fresh)
		return fresh
	end
	return copy(root, nil)
end

-- stylua: ignore
return {
	Find = Find, LowerBound = LowerBound, UpperBound = UpperBound, Clone = Clone,
}

--!strict
--[[
	Search — 이진 탐색 트리의 **균형 방식과 무관한** 조각(2층 트리부의 공유 구현, 2026-10-13).

	## 탐색 트리 노드의 칸 배치 (계약)

	이진 노드(`Node.Binary` — `1` = 값, `2` = 왼쪽, `3` = 오른쪽, `4` = 부모) 뒤에 두 칸을 더합니다:

	`{ [1] = 값, [2] = 왼쪽, [3] = 오른쪽, [4] = 부모, [5] = 키, [6] = 균형 정보 }` — `KEY = 5`, `BALANCE = 6`.

	균형 정보는 방식의 것입니다(레드블랙은 빨강 여부, AVL 은 높이). 그래서 `Node.Binary` 의 도구(회전·중위
	다음/이전)가 이 노드에 그대로 먹습니다.

	## 무엇이 여기 있는가

	키 순서로 놓인 노드를 **읽는** 일은 균형을 어떻게 맞췄든 같습니다 — 키·값 읽기, 순서대로 따라가기, 찾기,
	경계 찾기, 구조째 베끼기. `RedBlack`·`Avl` 은 넣기·지우기(구조를 고치는 쪽)만 자기 것으로 가집니다.
	자가 균형의 계약(`Balance`)도 여기 있습니다.

	⚠️ 트리 노드를 따라갈 땐 **여기의 `First`·`Last`·`Next`·`Prev`** 를 쓰세요(`Node.Binary` 의 같은 함수에
	키 타입을 입힌 것). `Node.Binary.Next(트리노드)` 도 동작은 같지만 타입이 `NodeRead<K | V>` 로 넓어집니다 —
	타입 인자가 둘인 별칭을 하나짜리 제네릭에 넘기면 새 솔버가 둘을 합쳐 풉니다(최소 재현으로 확인,
	2026-10-13. 교집합으로 적으면 풀리지만 다른 추론이 깨졌습니다).
]]
local Types = require("../Types")
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Binary = require("../Node/Binary")

type Comparator<T> = Types.Comparator<T>

-- 키를 가진 이진 노드(읽기 — 불투명 핸들). 균형 방식의 노드(`RbNodeRead`·`AvlNodeRead`)는 팬텀이 더 있을 뿐
-- 이 자리에 들어갑니다.
export type KeyNodeRead<K, V> = { read __links: "binary", read __value: V, read __key: K }

-- ⭐ **자가 균형의 계약**(2026-10-13 사용자: *"자가균형 같은 경우는 Insert, Remove 를 계약으로 하나의 추상화를 둘 수
-- 있을법 … 트리 쓰는 곳에서 자가균형을 뭘로 할 지 default 가 있고, 직접 선택도 가능한 구조"*). `RedBlack`·`Avl`
-- 모듈이 그대로 이 모양입니다 — 트리를 조립하는 쪽은 이것 하나를 받아 쓰고(기본은 레드블랙), 바깥에서 만든 균형
-- 방식도 같은 모양이면 들어갑니다. 노드 타입은 방식마다 달라 여기서는 `any` 입니다 — 조립하는 쪽이 뿌리를
-- "그 방식의 노드" 로만 다루면 됩니다(읽을 때는 `KeyNodeRead`).
-- - `Insert(root, key, value, compare)` → `(새 뿌리, 그 키의 노드, 새로 만들었나)`. 있던 키면 값만 바꿈.
-- - `Remove(root, node)` → 새 뿌리(비면 `nil`). `node` 는 그 트리의 노드, 떼어 낸 뒤 연결이 끊김.
-- - `FromSorted(keys, values, count)` → 정렬된 목록에서 O(n) 으로 지은 뿌리. `Clone(root)` → 구조째 베낀 뿌리.
-- 바깥에서 만드는 방식의 노드는 위 **칸 배치**를 따라야 합니다(조립하는 쪽이 `1`·`2`·`3`·`5` 번 칸을 직접 읽음).
export type Balance = {
	read Insert: (root: any, key: any, value: any, compare: Comparator<any>) -> (any, any, boolean),
	read Remove: (root: any, node: any) -> any,
	read FromSorted: (keys: { any }, values: { any }, count: number) -> any,
	read Clone: (root: any) -> any,
}

const VALUE, LEFT, RIGHT, PARENT, KEY, BALANCE = 1, 2, 3, 4, 5, 6

-- 노드의 키.
const function Key<K, V>(node: KeyNodeRead<K, V>): K
	return (node :: any)[KEY]
end

-- 노드의 값.
const function Value<K, V>(node: KeyNodeRead<K, V>): V
	return (node :: any)[VALUE]
end

-- 순서대로 따라가기 — `Node.Binary` 의 것에 키 타입을 입힌 것(머리 주석).
type StepFn = <K, V>(node: KeyNodeRead<K, V>) -> KeyNodeRead<K, V>?
type EdgeFn = <K, V>(root: KeyNodeRead<K, V>) -> KeyNodeRead<K, V>
const binary: any = Binary
-- 중위 순서로 다음 / 이전 노드(끝이면 `nil`).
const Next: StepFn = binary.Next
const Prev: StepFn = binary.Prev
-- 부분 트리에서 키가 가장 작은 / 큰 노드.
const First: EdgeFn = binary.First
const Last: EdgeFn = binary.Last

-- 키가 같은 노드. 없으면 `nil`.
const function Find<K, V>(root: KeyNodeRead<K, V>?, key: K, compare: Comparator<K>): KeyNodeRead<K, V>?
	local cursor: any = root
	while cursor ~= nil do
		const order = compare(key, cursor[KEY])
		if order == 0 then
			return cursor
		end
		cursor = if order < 0 then cursor[LEFT] else cursor[RIGHT]
	end
	return nil
end

-- 키가 `key` **이상**인 첫 노드(중위 순서). 없으면 `nil`. `Ceiling` 이고, 구간 순회의 시작점입니다.
const function LowerBound<K, V>(root: KeyNodeRead<K, V>?, key: K, compare: Comparator<K>): KeyNodeRead<K, V>?
	local cursor: any, best: any = root, nil
	while cursor ~= nil do
		if compare(key, cursor[KEY]) <= 0 then
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
	local cursor: any, best: any = root, nil
	while cursor ~= nil do
		if compare(key, cursor[KEY]) < 0 then
			best = cursor
			cursor = cursor[LEFT]
		else
			cursor = cursor[RIGHT]
		end
	end
	return best
end

-- 구조째 베낍니다(노드는 새로, 키·값과 **균형 정보까지 그대로** — 노드를 통째로 베끼니 어느 균형 방식의
-- 트리든 됩니다). O(n).
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
	-- 칸 배치(계약) — 앞의 넷은 `Node.Binary` 의 것
	VALUE = VALUE, LEFT = LEFT, RIGHT = RIGHT, PARENT = PARENT, KEY = KEY, BALANCE = BALANCE,
	Key = Key, Value = Value, Next = Next, Prev = Prev, First = First, Last = Last,
	Find = Find, LowerBound = LowerBound, UpperBound = UpperBound, Clone = Clone,
}

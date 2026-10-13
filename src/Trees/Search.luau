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
	자가 균형의 계약(넣기·지우기를 맡는 쪽의 모양)은 `Trees/Balance` 에 있습니다.

	찾기·따라가기는 **받은 노드의 타입 그대로** 돌려줍니다(`RbNodeRead` 를 넣으면 `RbNodeRead?` — 그대로 그 방식의
	`Remove` 에 넘길 수 있음). `Next`·`Prev`·`First`·`Last` 는 `Node.Binary` 의 것 그대로입니다(트리 노드도 이진 노드).
]]
local Types = require("../Types")
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Binary = require("../Node/Binary")

type Comparator<T> = Types.Comparator<T>

-- 키를 가진 이진 노드(읽기 — 불투명 핸들). 균형 방식의 노드(`RbNodeRead`·`AvlNodeRead`)는 팬텀이 더 있을 뿐
-- 이 자리에 들어갑니다.
export type KeyNodeRead<K, V> = { read __links: "binary", read __value: V, read __key: K }

const VALUE, LEFT, RIGHT, PARENT, KEY, BALANCE = 1, 2, 3, 4, 5, 6

-- 노드의 키.
const function Key<K, V>(node: KeyNodeRead<K, V>): K
	return (node :: any)[KEY]
end

-- 노드의 값.
const function Value<K, V>(node: KeyNodeRead<K, V>): V
	return (node :: any)[VALUE]
end

-- 순서대로 따라가기 — `Node.Binary` 의 것 그대로(받은 노드의 타입을 그대로 돌려줌).
-- 중위 순서로 다음 / 이전 노드(끝이면 `nil`), 부분 트리에서 키가 가장 작은 / 큰 노드.
const Next, Prev, First, Last = Binary.Next, Binary.Prev, Binary.First, Binary.Last

-- 찾기는 키를 가진 이진 노드면 무엇이든 받고 **그 타입 그대로** 돌려줍니다(`KeyNodeRead<K, V>?` 로 받던 때는
-- 균형 방식의 노드(`RbNode` …)를 넘기면 값 타입이 `unknown` 이 됐습니다, 리뷰).
type Keyed<K> = { read __links: "binary", read __key: K }

-- 키가 같은 노드. 없으면 `nil`.
const function Find<N, K>(root: (N & Keyed<K>)?, key: K, compare: Comparator<K>): N?
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
-- ⚠️ 이름은 C++ 의 `lower_bound`(이상)입니다 — 컨테이너의 `TreeMap.LowerKey`(Java 어휘: **미만** 중 가장 큰 것)와
-- `Lower` 가 반대 뜻이니 헷갈리지 마세요. 짝: `LowerBound` = `CeilingKey`, `UpperBound` = `HigherKey`.
const function LowerBound<N, K>(root: (N & Keyed<K>)?, key: K, compare: Comparator<K>): N?
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
const function UpperBound<N, K>(root: (N & Keyed<K>)?, key: K, compare: Comparator<K>): N?
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
const function Clone<N>(root: (N & { read __links: "binary" })?): N?
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

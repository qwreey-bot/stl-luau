--!strict
--[[
	Node — 컨테이너 **바깥의** 노드 조각. 연결 리스트·트리가 이것을 조립해 씁니다.

	⭐ **노드는 하나의 일반 노드이고, 연결은 번호 칸에 둡니다**(2026-10-13 사용자 결정 — `papers/07` 6절):
	*"노드는 다수의 연결이 있어도 된다 봐. 루아우니까, 그냥 arr 로써 링크하면 될것 같은 느낌. 더블릭 링크의
	경우 … 1번과 2번을 쓰는것, 트리에서는 일반 노드에 1,2,3,4 를 써도 되고, 바이너리면 왼 오를 1 2 할당"*.

	```lua
	{ value: T, [1]: Node<T>?, [2]: Node<T>?, … }
	```

	- 양방향 리스트: `1` = 앞 노드, `2` = 뒤 노드. 이진 트리: `1` = 왼쪽, `2` = 오른쪽.
	- 칸의 뜻은 **쓰는 쪽이 정합니다** — 각 모듈이 `const PREV, NEXT = 1, 2` 처럼 이름을 붙여 쓰세요(지역
	  상수는 접혀 비용이 없습니다. 이 모듈의 값을 받아 쓰면 접히지 않습니다).
	- 실측(perf 34절): 이름 필드만 쓰는 노드(`{ value, prev, next }`)보다 순회 0.55~0.67배, 메모리 0.64배.
	  ⚠️ **번호 칸은 만들 때 테이블 생성자에 같이 적으세요**(`{ prev, nil, value = v }`) — 나중에 대입하면
	  배열 부분을 다시 잡아 만들기가 3배였습니다. 그래서 뜨거운 자리는 `Node.New` 를 거치지 않고 생성자를
	  직접 씁니다(이 모듈의 타입만 가져다).

	## 읽기 노드와 고칠 수 있는 노드

	타입이 둘입니다(예전 과제의 읽기/쓰기 노드 층과 같은 결, `Arr` 의 `ArrRead`/`ArrData` 와 같은 규칙):
	- `NodeRead<T>` — 값과 연결을 **읽기만**. `read` 필드라 원소에 공변입니다. 순회·조회 함수의 인자,
	  컨테이너가 밖으로 내주는 위치(받은 쪽이 연결을 고쳐 컨테이너를 깨뜨리지 못하게).
	- `Node<T>` — 값과 연결을 고칠 수 있음. 그 노드를 가진 컨테이너의 구현이 씁니다.

	노드에는 타입 토큰이 없습니다 — 값(엔티티)의 종류는 그것을 든 컨테이너가 가집니다.

	## 층 (2026-10-13 사용자 결정 — `papers/07` 9-4)

	이 폴더가 **1층(노드단 도구)**입니다: 일반 노드(이 파일 — 타입은 `Types.luau`)와 연결 방식별 도구 파일 셋 —
	`Single.luau`(단방향), `Double.luau`(양방향), `Binary.luau`(이진 — 회전·중위 다음/이전). 밖에서는
	`Node.Single.InsertNext(…)` 처럼 이 모듈 하나로 받습니다(사용자: *"Trees 처럼, Node 폴더 만들고 분리해두는게
	코드베이스 관리성에 … 더 나을듯"*). 그 위에 2층 `src/Trees/`(이 도구로
	짠 균형 방식 — AVL·레드블랙), 3층 `src/Collections/`(그 조각들로 조립한 자료형)가 섭니다.
	도구는 **노드끼리의 연결만** 고칩니다 — 머리·꼬리·뿌리·크기는 그것을 가진 쪽이 돌려받은 것을 보고 고칩니다.
]]
local Common = require("./Common")
Common.registerSource(debug.info(1, "s"))
local Types = require("@self/Types")
local Single = require("@self/Single")
local Double = require("@self/Double")
local Binary = require("@self/Binary")

export type Node<T> = Types.Node<T>
export type NodeRead<T> = Types.NodeRead<T>

-- 연결이 없는 새 노드. `links` 는 미리 잡아 둘 연결 칸 수(양방향·이진이면 2) — 배열 부분을 한 번에
-- 잡습니다. 뜨거운 자리에서는 생성자를 직접 쓰세요(머리 주석).
-- `links` 는 숫자 인자 정책을 따릅니다(conventions): 소수는 0 쪽으로 자르고, NaN·음수·`2^26` 초과는 에러.
const MAX_LINKS = 2 ^ 26

const function New<T>(value: T, links: number?): Node<T>
	local count = 2
	if links ~= nil then
		if type(links) ~= "number" or not (links >= 0) or links > MAX_LINKS then
			Common.raise(`Node: New links must be a number in [0, {MAX_LINKS}] (got {tostring(links)})`)
		end
		count = math.floor(links)
	end
	const node = table.create(count) :: any
	node.value = value
	return node
end

-- `slot` 번 칸을 따라가며 노드를 하나씩 냅니다: `for node in Node.Walk(head, 2) do`. `start` 가 `nil` 이면
-- 한 번도 돌지 않습니다. 도는 동안 **지금 노드의 그 칸**을 고쳐도 됩니다(다음 노드는 내기 전에 읽어 둠) —
-- 순회하며 떼어 내는 코드가 이것에 기댑니다.
const function Walk<T>(start: NodeRead<T>?, slot: number): () -> NodeRead<T>?
	local cursor = start
	return function(): NodeRead<T>?
		const node = cursor
		if node ~= nil then
			cursor = node[slot]
		end
		return node
	end
end

-- `slot` 번 칸을 따라 닿는 노드 수(`start` 포함). `nil` 이면 0.
const function Count<T>(start: NodeRead<T>?, slot: number): number
	local total, cursor = 0, start
	while cursor ~= nil do
		total += 1
		cursor = cursor[slot]
	end
	return total
end

-- stylua: ignore
return {
	New = New, Walk = Walk, Count = Count,
	-- 연결 방식별 도구
	Single = Single, Double = Double, Binary = Binary,
}

--!strict
--[[
	SortedArray — **정렬 배열로 된 탐색 구조**의 도구(2층 트리부, 2026-10-14 사용자: *"insert remove … 배열로 구현된
	(트리)는 중간삽입이 가능하고(밀어낸다 가정할때) n + log n 걸리잖아 … 노드 연산이 컬랙션에 정의인게 걸린점"*).

	## 모양 (계약)

	평범한 배열 `list` 의 `1..count` 가 **키 순서**로 놓여 있습니다(같은 키는 없음). 가운데를 짚어 가며 찾으니 암묵적인
	균형 이진 탐색 트리입니다 — 노드도 균형 정보도 없고, 균형은 "배열이 빈틈없이 차 있음" 이 대신합니다. 길이는
	쓰는 쪽이 듭니다(`count` 를 인자로 — `BSearch`·`CompleteArray` 와 같은 모양). 키를 원소에서 어떻게 꺼내 견줄지는
	`probe(원소, 키) -> 음수 | 0 | 양수` 가 정합니다(`BSearch.Probe` — 맵은 레코드의 키를, 셋은 원소 자체를).

	## 무엇이 여기 있는가

	레드블랙·AVL(노드로 된 탐색 트리)의 짝입니다 — 저쪽이 `Insert`·`Remove` 를 회전으로 한다면 여기는 **밀고 당겨서**
	합니다:

	- 찾기: `Find`·`LowerBound`·`UpperBound`·`Locate` — O(log n)(`Algorithms/BSearch` 그대로).
	- 가르기 `SplitOff`(한 자리부터 끝까지를 새 배열로), 잇기 `Append` — 블록 이동.
	- 끼워 넣기 `InsertAt`, 빼기 `RemoveAt` — 뒤를 한 칸 밀거나 당깁니다. O(n) 이지만 `table.move` 라 C 안에서 돌아
	  원소 루프의 14배 빠릅니다(perf 3절). 그래서 넣기 하나가 **O(log n + n)**.

	`FlatMap`·`FlatSet`(3층)이 이것의 조립입니다 — 크기·타입 토큰·키 검사는 거기에.

	## ⚠️ 인자를 검사하지 않습니다

	위치는 정수(`InsertAt` 은 `1..count + 1`, `RemoveAt` 은 `1..count`), `count` 는 실제로 든 개수, 배열은 `probe` 의
	순서로 정렬돼 있어야 합니다. 조립하는 쪽이 준 값만 받는 자리입니다(규약의 "계약 함수" 예외).
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local BSearch = require("../Algorithms/BSearch")

type Probe<E, K> = BSearch.Probe<E, K>

-- 찾기는 `BSearch` 의 것 그대로입니다: 그 키의 자리(없으면 `nil`) / 키가 `key` 이상인 첫 자리 / 초과인 첫 자리
-- (뒤의 둘은 **삽입 위치**라 `1..count + 1`).
const Find, LowerBound, UpperBound = BSearch.Find, BSearch.LowerBound, BSearch.UpperBound

-- 키가 **있는 자리, 없으면 들어갈 자리**와 "이미 있는가" 를 같이 돌려줍니다. 넣기의 첫 걸음입니다 —
-- 있으면 그 자리의 원소를 고치고, 없으면 그 자리에 `InsertAt`.
const function Locate<E, K>(list: { E }, count: number, key: K, probe: Probe<E, K>): (number, boolean)
	const pos = LowerBound(list, count, key, probe)
	return pos, pos <= count and probe(list[pos], key) == 0
end

-- `pos` 자리에 `item` 을 끼워 넣습니다(그 자리부터 뒤를 한 칸씩 밂). 맨 뒤(`count + 1`)면 밀 것이 없습니다.
-- 길이는 쓰는 쪽이 올립니다(`count + 1`).
const function InsertAt<E>(list: { E }, count: number, pos: number, item: E)
	if pos <= count then
		table.move(list, pos, count, pos + 1)
	end
	list[pos] = item
end

-- `pos` 자리의 원소를 빼서 돌려줍니다(뒤를 한 칸씩 당기고 맨 끝 칸을 비움). 길이는 쓰는 쪽이 내립니다.
const function RemoveAt<E>(list: { E }, count: number, pos: number): E
	const removed = list[pos]
	if pos < count then
		table.move(list, pos + 1, count, pos)
	end
	list[count] = nil :: any
	return removed
end

-- **`pos` 부터 끝까지를 떼어 새 배열로** 돌려줍니다(원래 배열에는 `1..pos - 1` 만 남고 뒤 칸은 비움). `pos` 는
-- `1..count + 1`(`count + 1` 이면 빈 배열). 떼어 낸 개수는 `count - pos + 1`. 블록 이동이라 O(떼어 낸 개수).
const function SplitOff<E>(list: { E }, count: number, pos: number): { E }
	const moved = count - pos + 1
	const high: { E } = table.create(moved)
	if moved > 0 then
		table.move(list, pos, count, 1, high)
		-- 뒤 칸을 비웁니다(남기면 `count` 밖에 값이 남아 나중에 다시 보임)
		for idx = pos, count do
			list[idx] = nil :: any
		end
	end
	return high
end

-- `other` 의 `1..otherCount` 를 **뒤에 이어 붙입니다**(`other` 는 그대로 — 비우는 것은 쓰는 쪽이). 순서는 검사하지
-- 않습니다: `other` 의 모든 키가 `list` 의 모든 키보다 커야 정렬이 유지됩니다(호출자 책임). O(otherCount).
const function Append<E>(list: { E }, count: number, other: { E }, otherCount: number)
	table.move(other, 1, otherCount, count + 1, list)
end

-- stylua: ignore
return {
	Find = Find, LowerBound = LowerBound, UpperBound = UpperBound, Locate = Locate,
	InsertAt = InsertAt, RemoveAt = RemoveAt, SplitOff = SplitOff, Append = Append,
}

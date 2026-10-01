--!strict
--[[
	Algorithm — 계약만 알고 구현은 모르는 공용 알고리즘.

	여기 있는 것은 소스에 **한 번만** 존재하고 배열/연결/트리 구현이 전부
	공짜로 씁니다. `Types` 와 `Common`(리스트 길이 규약)만 require 합니다(말단
	바로 위 층).

	⚠️ **여기 있는 것들은 느린 게 정상입니다.** 위치 계약을 경유하므로 원소
	하나마다 간접 호출이 붙습니다. 컨테이너가 자기 표현을 아는 경우(배열의
	`self.n`, `self[i]`)에는 그 컨테이너 안에서 직접 구현한 빠른 판을 쓰고,
	여기 있는 것은 **구현을 모르는 코드가 쓰는 판**입니다.

	⚠️ 그래서 새 함수를 여기 추가하기 전에 물어보세요: "구현을 모르는 호출자가
	실제로 있는가?" 예전 과제에서 맵 순회를 만들어 뒀다가 끝까지 아무도 안
	쓴 전례가 있습니다(.claude/base/container-design-notes.md 10절).
]]
local Types = require("./Types")
local Common = require("./Common")
Common.registerSource(debug.info(1, "s"))

type ListOps<C, E, I> = Types.ListOps<C, E, I>
type MapOps<C, K, V> = Types.MapOps<C, K, V>
type Record<K, V> = Types.Record<K, V>

-- ⭐ 첫 인자는 **구현 함수 묶음**, 둘째가 컨테이너입니다(질문 AB). 모듈 테이블이
-- 그대로 구현체라 `Algorithm.IndexOf(Arr, a, x)`, `Algorithm.Keys(TreeMap, m)`.

local exports = {}

-- 같은 원소가 처음 나오는 위치. 없으면 nil.
-- 비교는 `==` 입니다 — 값 동등성이 필요하면 호출자가 다른 걸 써야 합니다.
function exports.IndexOf<C, E, I>(ops: ListOps<C, E, I>, list: C, item: E): I?
	local idx = ops.FirstIndex(list)
	while idx ~= nil do
		if ops.Get(list, idx) == item then
			return idx
		end
		idx = ops.NextIndex(list, idx)
	end
	return nil
end

-- 원소 개수. 배열처럼 길이를 들고 있는 구현은 자기 것을 쓰세요 — 이건
-- 길이를 모르는 구현(연결 리스트 등)을 위한 O(n) 판입니다.
function exports.Count<C, E, I>(ops: ListOps<C, E, I>, list: C): number
	local total, idx = 0, ops.FirstIndex(list)
	while idx ~= nil do
		total += 1
		idx = ops.NextIndex(list, idx)
	end
	return total
end

-- ⚠️ 맵 계약을 거치는 둘은 **타입 인자를 셋 다 알려줘야** 합니다:
--     Algorithm.Keys<<HashMap<string, number>, string, number>>(HashMap, m)
-- `K`/`V` 를 끌어낼 재료가 함수 묶음(제네릭 함수들)뿐이고 컨테이너 `C` 는 그걸
-- 드러내지 않아 추론이 `unknown` 으로 샙니다. `K`/`V` 만 주고 `C` 를 추론에
-- 맡기는 순서(`<K, V, C>`)도 재봤는데 솔버 내부 오류("invalid path")였습니다
-- (2026-10-01 실측). 순차 계약(`IndexOf`/`Count`)은 추론으로 됩니다.
-- `ops.Records` 의 결과는 `Common.denseList`(`n` 우선, 구멍은 건너뜀)로 읽습니다 —
-- 사용자 `MapOps` 가 `Arr`·`table.pack` 결과를 돌려주면 `pairs` 로 돌던 예전 판이
-- `n`·태그 키를 레코드로 읽어 터졌습니다(M0 7라운드).
function exports.Keys<C, K, V>(ops: MapOps<C, K, V>, map: C): { K }
	const records, count = Common.denseList(ops.Records(map))
	const out: { K } = table.create(count)
	for i = 1, count do
		out[i] = records[i].key
	end
	return out
end

function exports.Values<C, K, V>(ops: MapOps<C, K, V>, map: C): { V }
	const records, count = Common.denseList(ops.Records(map))
	const out: { V } = table.create(count)
	for i = 1, count do
		out[i] = records[i].value
	end
	return out
end

return exports

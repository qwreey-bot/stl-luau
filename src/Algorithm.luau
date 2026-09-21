--!strict
--[[
	Algorithm — 계약만 알고 구현은 모르는 공용 알고리즘.

	여기 있는 것은 소스에 **한 번만** 존재하고 배열/연결/트리 구현이 전부
	공짜로 씁니다. `Types` 만 require 합니다(말단 바로 위 층).

	⚠️ **여기 있는 것들은 느린 게 정상입니다.** 위치 계약을 경유하므로 원소
	하나마다 간접 호출이 붙습니다. 컨테이너가 자기 표현을 아는 경우(배열의
	`self.n`, `self[i]`)에는 그 컨테이너 안에서 직접 구현한 빠른 판을 쓰고,
	여기 있는 것은 **구현을 모르는 코드가 쓰는 판**입니다.

	⚠️ 그래서 새 함수를 여기 추가하기 전에 물어보세요: "구현을 모르는 호출자가
	실제로 있는가?" 예전 과제에서 맵 순회를 만들어 뒀다가 끝까지 아무도 안
	쓴 전례가 있습니다(.claude/base/container-design-notes.md 10절).
]]
local Types = require("./Types")

type ListCore<E, I> = Types.ListCore<E, I>
type MapCore<K, V> = Types.MapCore<K, V>
type Record<K, V> = Types.Record<K, V>

local exports = {}

-- 같은 원소가 처음 나오는 위치. 없으면 nil.
-- 비교는 `==` 입니다 — 값 동등성이 필요하면 호출자가 다른 걸 써야 합니다.
function exports.IndexOf<E, I>(list: ListCore<E, I>, item: E): I?
	local idx = list:FirstIndex()
	while idx ~= nil do
		if list:Get(idx) == item then
			return idx
		end
		idx = list:NextIndex(idx)
	end
	return nil
end

-- 원소 개수. 배열처럼 길이를 들고 있는 구현은 자기 것을 쓰세요 — 이건
-- 길이를 모르는 구현(연결 리스트 등)을 위한 O(n) 판입니다.
function exports.Count<E, I>(list: ListCore<E, I>): number
	local total, idx = 0, list:FirstIndex()
	while idx ~= nil do
		total += 1
		idx = list:NextIndex(idx)
	end
	return total
end

function exports.Keys<K, V>(map: MapCore<K, V>): { K }
	local records: { Record<K, V> } = map:Records()
	local out: { K } = table.create(#records)
	for i, rec in records do
		out[i] = rec.key
	end
	return out
end

function exports.Values<K, V>(map: MapCore<K, V>): { V }
	local records: { Record<K, V> } = map:Records()
	local out: { V } = table.create(#records)
	for i, rec in records do
		out[i] = rec.value
	end
	return out
end

return exports

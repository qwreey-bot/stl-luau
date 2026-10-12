--!strict
--[[
	Algorithm — 트레이트만 알고 구현은 모르는 공용 알고리즘.

	여기 있는 것은 소스에 **한 번만** 존재하고 배열/연결/트리 구현이 전부
	공짜로 씁니다.

	⭐ **구현을 손으로 넘기지 않습니다**(2026-10-06, `Trait.luau`). 값의 타입 토큰으로
	트레이트에서 구현을 찾습니다 — `Algorithm.IndexOf(a, x)`, `Algorithm.Keys(m)`.
	예전엔 `Algorithm.IndexOf(Arr, a, x)` 처럼 모듈을 같이 넘겼고, 맵은 타입 인자를 셋 다
	적어야 했습니다(`Algorithm.Keys<<HashMap<string, number>, string, number>>(HashMap, m)`).
	지금은 트레이트 마커(`Types.ListMarker` 등, 타입에만 있는 필드)에서 원소·키·값 타입을
	추론합니다. 사용자 컨테이너도 `Trait.Impl(Trait.List, 자기 토큰, 자기 구현)` 한 줄로
	들어옵니다.

	⚠️ **여기 있는 것들은 느린 게 정상입니다.** 위치 계약을 경유하므로 원소
	하나마다 간접 호출이 붙습니다. 컨테이너가 자기 표현을 아는 경우(배열의
	`self.n`, `self[i]`)에는 그 컨테이너 안에서 직접 구현한 빠른 판을 쓰고,
	여기 있는 것은 **구현을 모르는 코드가 쓰는 판**입니다. 구현 찾기는 호출당 한 번
	(테이블 조회 둘)이라 원소 수와 무관합니다.

	⚠️ 그래서 새 함수를 여기 추가하기 전에 물어보세요: "구현을 모르는 호출자가
	실제로 있는가?" 예전 과제에서 맵 순회를 만들어 뒀다가 끝까지 아무도 안
	쓴 전례가 있습니다(.claude/base/container-design-notes.md 10절).
]]
local Types = require("./Types")
local Common = require("./Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("./Trait")

type ListMarker<E, I> = Types.ListMarker<E, I>
type MapMarker<K, V> = Types.MapMarker<K, V>

local exports = {}

-- 값이 구현하는 트레이트의 구현 테이블. 없으면 사용자 줄 에러. 조회를 펼쳐 둡니다 —
-- `Trait.ImplOf` 를 거치면 짧은 리스트에서 호출 비용이 16% 붙었습니다(perf 21절).
const function implOf(trait: any, value: any, who: string): any
	const impl = if type(value) == "table" then trait.impls[rawget(value, "__type")] else nil
	if impl == nil then
		-- 셋으로 가릅니다(리뷰 2라운드 — 반대로 안내했음): 이 사본의 토큰인데 구현이 없음 /
		-- 이름 있는 토큰 모양이지만 이 사본이 모름(다른 사본의 라이브러리, 되읽은 테이블) / 토큰 없음.
		const token = Trait.TokenOf(value)
		const raw = if type(value) == "table" then rawget(value, "__type") else nil
		const rawName = if type(raw) == "table" then rawget(raw :: any, "name") else nil
		if token then
			return Common.raise(
				`Algorithm: {who} needs a {trait.name} — {token.name} does not implement {trait.name}`
			)
		elseif type(rawName) == "string" then
			return Common.raise(
				`Algorithm: {who} needs a {trait.name} — got a {rawName} this library does not know (from another copy of the library, or a deserialized table?)`
			)
		end
		const got = `{typeof(value)} without a type token`
		return Common.raise(`Algorithm: {who} needs a {trait.name} (got {got})`)
	end
	return impl
end

-- 같은 원소가 처음 나오는 위치. 없으면 nil.
-- 비교는 `==` 입니다 — 값 동등성이 필요하면 호출자가 다른 걸 써야 합니다.
-- (원소 타입이 다른 `item` 은 타입 에러가 아닙니다 — `E` 가 둘의 합으로 넓어집니다.
-- 건전하고(그냥 nil), 예전 판도 같았습니다.)
function exports.IndexOf<E, I>(list: ListMarker<E, I>, item: E): I?
	const ops = implOf(Trait.List, list, "IndexOf")
	local idx = ops.FirstIndex(list)
	while idx ~= nil do
		if ops.Get(list, idx) == item then
			return idx
		end
		idx = ops.NextIndex(list, idx)
	end
	return nil
end

-- 세어서 구한 개수(AE, 2026-10-06 — `Len` 은 알고 있는 크기, `Count` 는 셈). 술어가
-- 있으면 참인 원소만. 위치를 끝까지 걷는 O(n) 판입니다 — 길이를 아는 컨테이너는
-- 자기 `Len`/`Count` 가 빠릅니다.
function exports.Count<E, I>(list: ListMarker<E, I>, pred: ((element: E) -> boolean)?): number
	const ops = implOf(Trait.List, list, "Count")
	local total, idx = 0, ops.FirstIndex(list)
	if pred == nil then
		while idx ~= nil do
			total += 1
			idx = ops.NextIndex(list, idx)
		end
	else
		while idx ~= nil do
			if pred(ops.Get(list, idx)) then
				total += 1
			end
			idx = ops.NextIndex(list, idx)
		end
	end
	return total
end

-- `ops.Records` 의 결과는 리스트 길이 규약(`Common.listLength` — `n` 우선)으로 읽고 구멍은
-- 건너뜁니다 — 사용자 구현이 `Arr`·`table.pack` 결과를 돌려주면 `pairs` 로 돌던 예전 판이
-- `n`·태그 키를 레코드로 읽어 터졌습니다(M0 7라운드).
-- 한 번에 돕니다(2026-10-12, 사용자 지적): 예전엔 `Common.denseList` 로 조밀한 사본을 만든 뒤 다시
-- 돌며 새 테이블에 옮겨, 테이블 하나와 순회 한 번이 더 들었습니다(0.75~0.88배 — perf 25절).
function exports.Keys<K, V>(map: MapMarker<K, V>): { K }
	const ops = implOf(Trait.Map, map, "Keys")
	const records: { Types.Record<K, V> } = ops.Records(map)
	const len = Common.listLength(records)
	const out: { K } = table.create(len)
	local count = 0
	for idx = 1, len do
		const rec = records[idx]
		if rec ~= nil then
			count += 1
			out[count] = rec.key
		end
	end
	return out
end

function exports.Values<K, V>(map: MapMarker<K, V>): { V }
	const ops = implOf(Trait.Map, map, "Values")
	const records: { Types.Record<K, V> } = ops.Records(map)
	const len = Common.listLength(records)
	const out: { V } = table.create(len)
	local count = 0
	for idx = 1, len do
		const rec = records[idx]
		if rec ~= nil then
			count += 1
			out[count] = rec.value
		end
	end
	return out
end

return exports

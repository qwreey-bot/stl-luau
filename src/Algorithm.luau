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
type CollectionMarker = Types.CollectionMarker
type CollectionMarkerMut = Types.CollectionMarkerMut

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

-- 맵의 키들·값들. 순서는 구현의 순회 순서(`HashMap` 은 약속 없음, `TreeMap` 은 키 순서)이고 두 함수의
-- 순서는 서로 맞습니다(맵을 그 사이에 안 바꿨다면).
--
-- `ops.Iter` 로 돕니다(2026-10-12, 질문 AO). 예전엔 `ops.Records` 가 만든 레코드 N 개를 거쳐 뽑았습니다 —
-- 순회로 옮기니 레코드 할당이 사라졌습니다(perf 28절). 결과 테이블은 크기를 알면(`Trait.Collection` 도
-- 구현하면) 미리 잡습니다 — 작은 맵에서 다시 늘리는 비용이 컸습니다.
-- `Iter` 가 **테이블**을 돌려주는 구현(`HashMap`)에서는 Luau 가 직접 돌아 자기 `HashMap.Keys` 와 비슷하고
-- (1000개 이상에서 같음, 10개에서는 구현 찾기 때문에 1.5배쯤),
-- **순회 함수**를 돌려주는 구현(`TreeMap`)에서는 원소마다 호출이 붙어 자기 `Keys` 의 4배쯤입니다.
const function sizedList(map: any): { any }
	const sized = Trait.Collection.impls[rawget(map, "__type")]
	if sized then
		-- 사용자 구현의 `Len` 은 힌트로만 — 음수·NaN·너무 큰 값·숫자 아닌 값이면 `table.create` 가
		-- 라이브러리 줄에서 죽었습니다(리뷰). 그럴 땐 미리 잡지 않습니다.
		const len = sized.Len(map)
		if type(len) == "number" and len >= 0 and len <= 2 ^ 26 then
			return table.create(len)
		end
	end
	return {}
end

function exports.Keys<K, V>(map: MapMarker<K, V>): { K }
	const ops = implOf(Trait.Map, map, "Keys")
	const out: { K } = sizedList(map)
	local count = 0
	for key in ops.Iter(map) do
		count += 1
		out[count] = key
	end
	return out
end

function exports.Values<K, V>(map: MapMarker<K, V>): { V }
	const ops = implOf(Trait.Map, map, "Values")
	const out: { V } = sizedList(map)
	local count = 0
	for _, value in ops.Iter(map) do
		count += 1
		out[count] = value
	end
	return out
end

-- 알고 있는 크기(O(1)). 리스트·맵·셋·힙 어느 것이든 — `Trait.Collection` 을 구현하는 종류면 됩니다.
-- 읽기라 빌린 참조(`ArrRead`·`DequeRead`)도 받습니다. 세어서 구하는 것은 `Count`.
function exports.Len(collection: CollectionMarker): number
	return implOf(Trait.Collection, collection, "Len").Len(collection)
end

-- 비우고 **같은 컨테이너를 그 타입 그대로** 돌려줍니다(`HashMap<string, number>` 를 넣으면 그 타입).
-- 맵 종류를 모르고 "비우고 다시 채우기" 를 쓸 때. 읽기 전용으로 빌린 참조는 못 넣습니다
-- (`Types.CollectionMarkerMut`).
function exports.Clear<C>(collection: C & CollectionMarkerMut): C
	implOf(Trait.Collection, collection, "Clear").Clear(collection)
	return collection
end

return exports

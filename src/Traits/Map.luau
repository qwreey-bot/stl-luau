--!strict
--[[
	Map — 키로 값을 찾는 컨테이너의 트레이트. `HashMap`/`TreeMap`/`FlatMap` 이 구현합니다.

	이 파일이 트레이트의 전부입니다: 계약(`Core`), 타입 마커, 종류를 모르는 코드의 진입점
	(`Map.Keys(m)`·`Map.Values(m)`·`Map.Records(m)`). 크기와 비우기는 맵만의 것이 아니라 `Collection` 에
	있습니다.
]]
local Types = require("../Types")
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Trait = require("../Trait")
local Collection = require("./Collection")

--[[ 계약 ]]

-- ⭐ 2026-10-12 에 `Has`·`Remove`·`Iter` 를 더했습니다(질문 AM 다 → AO, 사용자: *"hash 인지 tree 인지
-- 몰라도 만질 수 있게"*). 예전의 셋(`Get`·`Set`·`Records`)만으로는 구현을 모르는 코드가 지울 수도,
-- 할당 없이 돌 수도 없었습니다.
-- `Records` 는 **2026-10-13 에 계약에서 뺐습니다**(사용자 결정, 질문 AO) — `Iter` 가 있으면 유도되고
-- (아래 `Records` 진입점) 사용자 맵이 구현할 것을 하나 줄였습니다. 모듈의 `HashMap.Records`·
-- `FlatMap.Records` 는 그대로 있습니다.
-- - `Remove` 는 지운 값을 돌려줍니다(없었으면 `nil`).
-- - `Iter` 는 `for key, value in ops.Iter(map) do` 에 넣는 **값 하나**입니다: 키-값이 그대로 든 **테이블**
--   (Luau 가 직접 돎 — 가장 빠름, `HashMap`) 또는 **인자 없는 순회 함수**(상태는 클로저에, `FlatMap`).
--   ⚠️ 테이블을 돌려준다면 **키-값만 든 테이블**이어야 합니다 — `Arr`·`table.pack` 결과처럼 `n`·`__type`
--   같은 다른 필드가 섞인 테이블도 타입은 받지만(폭 서브타이핑) `Keys` 가 그것까지 키로 냅니다.
--   함수·상태·처음 값 삼중항은 이 타입에 안 들어갑니다 — 클로저로 감싸세요(유니온에 `(...any) -> (K, V)` 를
--   넣으면 새 솔버가 `() -> (K, V)` 를 못 받았습니다, 실측). 순서는 구현의 것입니다(해시는 약속 없음, 정렬
--   맵은 키 순서). 도는 동안 맵을 바꾸면 정의되지 않은 동작입니다(conventions).
export type Core<C, K, V> = {
	read Get: (map: C, key: K) -> V?,
	read Set: (map: C, key: K, value: V) -> (),
	read Has: (map: C, key: K) -> boolean,
	read Remove: (map: C, key: K) -> V?,
	read Iter: (map: C) -> { read [K]: V } | (() -> (K, V)),
}

--[[ 마커 — 타입에만 있는 필드(읽으면 nil — 읽는 코드를 쓰지 마세요) ]]

-- 읽기 마커(공변). `K` 는 키, `V` 는 값. 컨테이너에서 **꺼내기만 하는** 알고리즘용입니다(`Keys`).
export type Marker<K, V> = { read __type: Trait.Token<any>, read __mapKey: K, read __mapValue: V }
-- ⭐ **키·값을 입력으로 받는 제네릭을 위한 불변 마커**(2026-10-12, 질문 AM). 위 읽기 마커는 `read` 라
-- **공변**입니다 — 마커와 함께 **값·키를 받아 넘기는** 제네릭에서는 그 타입이 조용히 넓어집니다: `Set` 으로
-- 쓰면 `HashMap<string, number>` 에 문자열이 들어가고, 조회만 해도 `FlatMap<string, …>` 에 숫자 키를 넘겨
-- 비교자가 라이브러리 줄에서 터졌습니다(진단 0건, `spikes/61`). 그런 제네릭은 이쪽을 받으세요. 팬텀이
-- **함수 타입**이라(인자·반환 양쪽에 타입 변수) 불변이고, 읽기 마커의 필드도 다 있어 읽는 알고리즘에
-- 그대로 넘어갑니다. (팬텀을 읽기·쓰기 필드로 선언하는 길도 불변이 되지만 사용자가 팬텀에 쓰는 코드가
-- 통과했습니다.)
export type MarkerMut<K, V> = {
	read __type: Trait.Token<any>,
	read __mapKey: K,
	read __mapValue: V,
	read __mapMut: (K, V) -> (K, V),
}

const Map = Trait.New<<Core<any, any, any>>>("Map", { required = { "Get", "Set", "Has", "Remove", "Iter" } })
const expectImpl = Trait.ExpectImpl

--[[ 진입점 — 종류를 모르는 코드가 부릅니다 ]]
-- 맵의 키들·값들·레코드들. 순서는 구현의 순회 순서(`HashMap` 은 약속 없음, `FlatMap` 은 키 순서)이고 세
-- 함수의 순서는 서로 맞습니다(맵을 그 사이에 안 바꿨다면).
--
-- `ops.Iter` 로 돕니다(2026-10-12, 질문 AO). 예전엔 `ops.Records` 가 만든 레코드 N 개를 거쳐 뽑았습니다 —
-- 순회로 옮기니 레코드 할당이 사라졌습니다(perf 28절). `Iter` 가 **테이블**을 돌려주는 구현(`HashMap`)에서는
-- Luau 가 직접 돌아 자기 `HashMap.Keys` 와 비슷하고(1000개 이상에서 같음, 10개에서는 구현 찾기 때문에
-- 1.5배쯤), **순회 함수**를 돌려주는 구현(`FlatMap`)에서는 원소마다 호출이 붙어 자기 `Keys` 의 4배쯤입니다.

-- 결과 테이블은 크기를 알면(`Collection` 도 구현하면) 미리 잡습니다 — 작은 맵에서 다시 늘리는 비용이 컸습니다.
const function sizedList(map: any): { any }
	const sized = (Collection.impls :: any)[rawget(map, "__type")]
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

const function Keys<K, V>(map: Marker<K, V>): { K }
	const ops = expectImpl(Map, map, "Keys")
	const out: { K } = sizedList(map)
	local count = 0
	for key in ops.Iter(map) do
		count += 1
		out[count] = key
	end
	return out
end

const function Values<K, V>(map: Marker<K, V>): { V }
	const ops = expectImpl(Map, map, "Values")
	const out: { V } = sizedList(map)
	local count = 0
	for _, value in ops.Iter(map) do
		count += 1
		out[count] = value
	end
	return out
end

-- 키-값 레코드의 목록(`{ { key, value } }`). 레코드는 **새로 만든 것**이라 받은 쪽이 고쳐도 맵은
-- 그대로입니다. 종류를 아는 코드는 `HashMap.Records`/`FlatMap.Records` 를 직접 쓰세요.
const function Records<K, V>(map: Marker<K, V>): { Types.Record<K, V> }
	const ops = expectImpl(Map, map, "Records")
	const out: { Types.Record<K, V> } = sizedList(map)
	local count = 0
	for key, value in ops.Iter(map) do
		count += 1
		out[count] = { key = key, value = value }
	end
	return out
end

-- stylua: ignore
return Trait.Expose(Map, {
	Keys = Keys, Values = Values, Records = Records,
})

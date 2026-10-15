--!strict
--[[
	Map — 키로 값을 찾는 컨테이너의 트레이트. `HashMap`/`TreeMap`/`FlatMap` 이 구현합니다.

	이 파일이 트레이트의 전부입니다: 정의(필수 다섯), 타입 마커, 종류를 모르는 코드의 진입점
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
-- (함수 서명은 아래 정의 팩토리에 — 완성 표 타입은 `Map.Full<Self, K, V>`.)

--[[ 마커 — 타입에만 있는 필드(읽으면 nil — 읽는 코드를 쓰지 마세요) ]]

-- 연관 타입 레코드(질문 BA): 컨테이너가 `read __traits: { read Map: Map.Assoc<K, V> }`. 키·값은 공변 칸(`() -> K`)과 불변
-- 팬텀 `Mut` 을 같이 둡니다(`(K) -> K` 는 `() -> K` 의 서브타입이 아니라 하나로는 두 쓰임을 못 덮음). 트레이트의 조건(`of`)은 불변 —
-- 조회도 키가 입력이라(질문 AM). `ValueRead` 는 꺼내기만 하는 알고리즘(`Keys`)용으로 공변.
export type Assoc<K, V> = { read Key: () -> K, read Value: () -> V, read Mut: (K, V) -> (K, V) }
export type ValueRead<K, V> = {
	read __type: Trait.Token<any>,
	read __traits: { read Map: { read Key: () -> K, read Value: () -> V } },
}
export type Value<K, V> = { read __type: Trait.Token<any>, read __traits: { read Map: Assoc<K, V> } }
type AnyToken = Trait.AnyToken
const Fn, FnMut = Trait.Fn, Trait.FnMut

--[[ 정의 ]]
const MapBase = Trait.Trait("Map", function<Self, K, V>(of: (Self & Value<K, V>) | AnyToken)
	return table.freeze({
		Get = Fn<<(map: Self, key: K) -> V?>>(),
		Set = FnMut<<(map: Self, key: K, value: V) -> ()>>(),
		Has = Fn<<(map: Self, key: K) -> boolean>>(),
		Remove = FnMut<<(map: Self, key: K) -> V?>>(),
		Iter = Fn<<(map: Self) -> { read [K]: V } | (() -> (K, V))>>(),
	})
end)
-- 완성 표(= 등록 표 — 기본 구현이 없음)
export type Full<Self, K, V> = typeof(MapBase.OfMut<<Self, K, V>>(nil :: any))
export type ReadFull<Self, K, V> = typeof(MapBase.Of<<Self, K, V>>(nil :: any))
export type Provided<Self, K, V> = typeof(MapBase.ImplOf<<Self, K, V>>(nil :: any))
const expectImpl = Trait.ExpectImpl
-- 구현 찾기를 펼칠 표(키가 토큰뿐 — 트레이트 객체를 바로 읽으면 `__type = "Get"` 같은 문자열이 진입점을 꺼냄, 리뷰 1라운드)
const mapImpls = Trait.Impls(MapBase)
-- 진입점은 구현 찾기를 **안에 펼쳐** 둡니다 — `expectImpl(…)` 을 부르는 것만으로 호출당 9~10ns 였습니다(perf 51절).
-- 못 찾았을 때만 `expectImpl` 로 갑니다(에러 메시지).

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
	const sized = Trait.ImplOf(Collection, map)
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

const function Keys<K, V>(map: ValueRead<K, V>): { K }
	const ops: any = (if type(map) == "table" then mapImpls[rawget(map :: any, "__type")] else nil)
		or expectImpl(MapBase, map, "Keys")
	const out: { K } = sizedList(map)
	local count = 0
	for key in ops.Iter(map) do
		count += 1
		out[count] = key
	end
	return out
end

const function Values<K, V>(map: ValueRead<K, V>): { V }
	const ops: any = (if type(map) == "table" then mapImpls[rawget(map :: any, "__type")] else nil)
		or expectImpl(MapBase, map, "Values")
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
const function Records<K, V>(map: ValueRead<K, V>): { Types.Record<K, V> }
	const ops: any = (if type(map) == "table" then mapImpls[rawget(map :: any, "__type")] else nil)
		or expectImpl(MapBase, map, "Records")
	const out: { Types.Record<K, V> } = sizedList(map)
	local count = 0
	for key, value in ops.Iter(map) do
		count += 1
		out[count] = { key = key, value = value }
	end
	return out
end

-- stylua: ignore
-- 트레이트 함수의 진입점(`Map.Get` …)은 시스템이 만들지만 서명을 입히지 않습니다(아직 부르는 곳이 없음 — 넣을 땐 `Value` 로).
return Trait.Expose(MapBase, {
	Keys = Keys, Values = Values, Records = Records,
})

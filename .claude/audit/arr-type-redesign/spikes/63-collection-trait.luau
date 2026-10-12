--!strict
--[[
	컬렉션 트레이트와 넓힌 맵 계약 (2026-10-12, 질문 AO — AM 다를 앞당김).

	지키는 성질:
	- `Algorithm.Clear` 는 **넣은 타입 그대로** 돌려주고(`<C>(c: C & CollectionMarkerMut): C`),
	  **읽기 전용으로 빌린 참조**(`ArrRead`·`DequeRead`)는 못 받습니다 — 마커가 토큰만 요구하던 시제품에선
	  빌린 참조가 진단 0건으로 지워졌습니다(AC 의 "빌린 참조가 쓰기를 얻음" 과 같은 결).
	- `Algorithm.Len` 은 읽기라 빌린 참조도 받고, 토큰 없는 것(리터럴·숫자·`Optional`)은 막습니다.
	- 모듈 테이블이 `CollectionOps`·넓힌 `MapOps`(`Has`·`Remove`·`Iter`)를 만족하고, 함수가 빠진 구현·다른
	  종류의 모듈은 그 타입 자리에 못 들어갑니다(리터럴이든 모듈이든). **모듈의 `Iter` 를 직접** 돌면 루프
	  변수는 `K`, `V`.

	⚠️ 알려진 경계(맨 아래, 0건):
	- `Len` 의 마커는 토큰만 봐서 토큰은 있지만 컬렉션이 아닌 `Fut` 이 타입을 지납니다 — 런타임에
	  `Common.raise`(spec.contracts 10절).
	- **계약 타입(`MapOps`)을 거친 `ops.Iter(m)` 의 루프 변수는 타입이 없습니다**(`any`) — 계약의 `Iter` 가
	  "테이블 또는 함수" 유니온이 되면서(2026-10-12, 질문 AP 1) 새 솔버가 유니온을 `for … in` 에 넣으면 변수
	  타입을 잃습니다. 루프 변수에 주석을 달거나(`for key: K, value: V in ops.Iter(m)`) 모듈의 `Iter` 를 직접.

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 20 줄 · 21건 + CANARY 1 — `Optional` 은 유니온이라 두 건)
]]
local stl = require("../../../../src")
local Algorithm, Arr, Deque, HashMap, HashSet, TreeMap, TreeSet, Heap, Common =
	stl.Algorithm, stl.Arr, stl.Deque, stl.HashMap, stl.HashSet, stl.TreeMap, stl.TreeSet, stl.Heap, stl.Common
type Record<K, V> = stl.Record<K, V>

local arr = Arr.Of(1, 2)
local dq = Deque.Of(1, 2)
local hm = HashMap.New<<string, number>>()
local tm = TreeMap.New<<string, number>>(Common.compareString)
local hs = HashSet.Of(1, 2)
local ts = TreeSet.New<<number>>(Common.compareNumber)
local heap = Heap.New<<number>>(function(a: number, b: number): boolean
	return a < b
end)

--[[ POS ]]
local total: number = Algorithm.Len(arr)
	+ Algorithm.Len(dq)
	+ Algorithm.Len(hm)
	+ Algorithm.Len(tm)
	+ Algorithm.Len(hs)
	+ Algorithm.Len(ts)
	+ Algorithm.Len(heap)
local clearedArr: stl.Arr<number> = Algorithm.Clear(arr)
local clearedDq: stl.Deque<number> = Algorithm.Clear(dq)
local clearedHm: stl.HashMap<string, number> = Algorithm.Clear(hm)
local clearedTm: stl.TreeMap<string, number> = Algorithm.Clear(tm)
local clearedHs: stl.HashSet<number> = Algorithm.Clear(hs)
local clearedTs: stl.TreeSet<number> = Algorithm.Clear(ts)
local clearedHeap: stl.Heap<number> = Algorithm.Clear(heap)
-- 돌려받은 것을 그 종류의 함수에 바로
HashMap.Set(Algorithm.Clear(hm), "x", 1)
-- 읽기로 빌린 참조도 크기는 읽음
local function borrowedLen(list: stl.ArrRead<number?>, queue: stl.DequeRead<number?>): number
	return Algorithm.Len(list) + Algorithm.Len(queue)
end
-- 모듈 테이블이 계약을 만족
local colOps: stl.CollectionOps<stl.HashMap<string, number>> = HashMap
local mapOps: stl.MapOps<stl.TreeMap<string, number>, string, number> = TreeMap
local has: boolean = mapOps.Has(tm, "x")
local removed: number? = mapOps.Remove(tm, "x")
-- 모듈의 Iter 를 직접 돌면 루프 변수 타입이 섬(HashMap 은 테이블, TreeMap 은 함수)
for key, value in HashMap.Iter(hm) do
	local _key: string = key
	local _value: number = value
end
for key, value in TreeMap.Iter(tm) do
	local _key: string = key
	local _value: number = value
end
-- 계약을 거치면 주석으로
for key: string, value: number in mapOps.Iter(tm) do
	local _key: string = key
	local _value: number = value
end
-- 종류를 모르는 사용자 제네릭: 비우고 다시 채우기
local function refill<K, V>(m: stl.MapMarkerMut<K, V> & stl.CollectionMarkerMut, records: { Record<K, V> })
	Algorithm.Clear(m)
	const ops = stl.Trait.ImplOf(stl.Trait.Map, m)
	if ops then
		for _, rec in records do
			ops.Set(m, rec.key, rec.value)
		end
	end
end
refill(hm, { { key = "a", value = 1 } })
refill(tm, { { key = "a", value = 1 } })

--[[ NEG — Clear 는 넣은 타입 그대로 ]]
local negClearedHm: stl.HashMap<string, string> = Algorithm.Clear(hm)
local negClearedArr: stl.Deque<number> = Algorithm.Clear(arr)

--[[ NEG — 읽기 전용으로 빌린 참조는 못 비움 ]]
local function borrowedClear(list: stl.ArrRead<number>, queue: stl.DequeRead<number>)
	Algorithm.Clear(list)
	Algorithm.Clear(queue)
end

--[[ NEG — 컨테이너가 아닌 것 ]]
Algorithm.Clear({ n = 0 })
Algorithm.Clear(5)
-- 팬텀은 있고 **토큰만 없는** 꼴 — 이 줄만 토큰 때문에 에러(리뷰: 위 둘은 팬텀 때문에도 에러라
-- `CollectionMarkerMut` 에서 토큰을 빼도 통과했음 — spikes/60 의 같은 교훈)
Algorithm.Clear({ __collectionMut = true :: true })
local negLenLiteral = Algorithm.Len({ size = 0 })
local negLenOptional = Algorithm.Len(stl.Optional.Present(1))

--[[ NEG — 계약 ]]
local negColOps: stl.CollectionOps<stl.Arr<number>> = HashMap
-- 맵이 아닌 모듈·함수가 빠진 **모듈**(리터럴 아님)도 계약 자리에 못 들어감. 키·값 타입은 그 모듈에
-- 맞게 적어 "빠진 함수" 만 이유가 되게(리뷰: `Iter` 의 타입에 `(...any) -> …` 가 있던 때는 `Iter` 필드만
-- 있으면 **나머지가 없어도 0건**이었고, 예전 줄은 `Remove` 반환 타입이 우연히 어긋나서 에러였음)
local negMapOps: stl.MapOps<stl.HashSet<number>, number, boolean> = HashSet
local negMapOpsList: stl.MapOps<stl.Arr<number>, number, number> = Arr
local noRemove = {
	Get = HashMap.Get,
	Set = HashMap.Set,
	Has = HashMap.Has,
	Records = HashMap.Records,
	Iter = HashMap.Iter,
}
local negNoRemove: stl.MapOps<stl.HashMap<string, number>, string, number> = noRemove
local function putVia<C, K, V>(ops: stl.MapOps<C, K, V>, map: C, key: K, value: V)
	ops.Set(map, key, value)
end
putVia<<stl.HashSet<number>, number, boolean>>(HashSet, hs, 3, true)
local negPartial: stl.MapOps<stl.HashMap<string, number>, string, number> = {
	Get = HashMap.Get,
	Set = HashMap.Set,
	Records = HashMap.Records,
}
local negRemoved: number = mapOps.Remove(tm, "x")
for _, value in HashMap.Iter(hm) do
	local _negValue: string = value
end
for key in TreeMap.Iter(tm) do
	local _negKey: number = key
end
-- Iter 가 돌려준 테이블은 읽기 전용
HashMap.Iter(hm).x = 1
refill(hm, { { key = "a", value = "bad" } })

local canary: string = 42

--[[ 알려진 경계 — 토큰은 있지만 컬렉션이 아닌 것은 `Len` 의 타입을 지남(런타임 에러) ]]
local futLen = Algorithm.Len(stl.Fut.Resolved(1))
--[[ 알려진 경계 — 계약을 거친 Iter 의 루프 변수는 any(유니온 순회) ]]
for _, value in mapOps.Iter(tm) do
	local _untyped: string = value
end

return {
	total,
	clearedArr,
	clearedDq,
	clearedHm,
	clearedTm,
	clearedHs,
	clearedTs,
	clearedHeap,
	borrowedLen,
	colOps,
	has,
	removed,
	negClearedHm,
	negClearedArr,
	borrowedClear,
	negLenLiteral,
	negLenOptional,
	negColOps,
	negMapOps,
	negMapOpsList,
	negNoRemove,
	negPartial,
	negRemoved,
	canary,
	futLen,
}

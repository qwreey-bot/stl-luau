--!strict
--[[
	키·위치·값을 **입력으로 받는** 제네릭은 불변 마커로 (2026-10-12, 질문 AM).

	읽기 마커(`MapMarker` 등)는 `read` 라 공변입니다 — 읽는 알고리즘엔 맞지만(`Map.Keys`), 마커를
	받아 `Set`/`Add` 하는 사용자 제네릭 함수에서는 값 타입이 조용히 넓어져 `HashMap<string, number>` 에
	문자열이 들어갔습니다(진단 0건, 10-06 트레이트 설계부터). AC 에서 본 "공변으로 빌린 참조가 쓰기를
	얻음" 과 같은 메커니즘입니다. **그런 제네릭은 `MapMarkerMut`/`SetMarkerMut`/`ListMarkerMut`** 을
	받습니다 — 데이터 타입의 함수 타입 팬텀(`read __mapMut: (K, V) -> (K, V)`, 인자·반환 양쪽에 나와
	불변)을 요구합니다. 읽기 전용으로 빌린 `ArrRead` 에는 그 팬텀이 없어 쓰는 제네릭에 못 들어갑니다.

	⚠️ **읽기 마커로 쓰는 코드를 타입이 막아 주지는 않습니다**(트레이트 구현은 `any` 를 거침) — 맨
	아래 "알려진 구멍" 은 지금도 0건입니다. 규약으로 지킵니다(`conventions.md`).

	기대 진단: 줄 번호는 scripts/spike-expectations.tsv (NEG 11 + CANARY 1)
]]
local stl = require("../../../../src")
local Arr, Deque, HashMap, HashSet, TreeMap, TreeSet, Trait, Common =
	stl.Arr, stl.Deque, stl.HashMap, stl.HashSet, stl.TreeMap, stl.TreeSet, stl.Trait, stl.Common

local hm = HashMap.New<<string, number>>()
local tm = TreeMap.New<<string, number>>(Common.compareString)
local hs = HashSet.Of(1, 2)
local ts = TreeSet.New<<number>>(Common.compareNumber)
local arr = Arr.Of(1, 2)
local dq = Deque.Of(1, 2)

-- 쓰는 사용자 제네릭 — 불변 마커
local function put<K, V>(m: stl.MapMarkerMut<K, V>, k: K, v: V)
	const ops = Trait.ImplOf(stl.Map, m)
	if ops then
		ops.Set(m, k, v)
	end
end
local function add<T>(s: stl.SetMarkerMut<T>, item: T)
	const ops = Trait.ImplOf(stl.Set, s)
	if ops then
		ops.Add(s, item)
	end
end
local function touch<E>(_list: stl.ListMarkerMut<E, number>, _item: E) end
-- 위치도 받는 쓰기(1라운드 — 팬텀이 `(E) -> E` 뿐일 땐 위치 타입이 넓어져 `Arr` 에 문자열 키로 썼음)
local function setAt<E, I>(_list: stl.ListMarkerMut<E, I>, _idx: I, _item: E) end
-- 키를 **입력으로 받는 조회**도 불변 마커로(읽기 마커면 `TreeMap<string, …>` 에 숫자 키가 0건으로
-- 들어가 비교자가 라이브러리 줄에서 터짐 — 아래 "알려진 구멍")
local function lookup<K, V>(m: stl.MapMarkerMut<K, V>, k: K): V?
	const ops = Trait.ImplOf(stl.Map, m)
	return if ops then ops.Get(m, k) else nil
end

--[[ POS ]]
put(hm, "x", 1)
put(tm, "x", 1)
add(hs, 3)
add(ts, 3)
touch(arr, 3)
touch(dq, 3)
setAt(arr, 1, 3)
setAt(dq, 1, 3)
local looked: number? = lookup(tm, "x")
-- 불변 마커로 받은 값은 읽는 알고리즘에도 그대로 들어감(읽기 마커의 서브타입)
local function keysThenPut<K, V>(m: stl.MapMarkerMut<K, V>, k: K, v: V): { K }
	put(m, k, v)
	return stl.Map.Keys(m)
end
local keys: { string } = keysThenPut(hm, "y", 2)
-- 읽는 쪽 공변은 그대로(좁은 맵을 넓은 읽기 자리에)
local wideKeys: { string | number } = stl.Map.Keys<<string | number, number>>(hm)
local wideIndex: number? = stl.List.IndexOf<<number?, number>>(arr, nil)

--[[ NEG — 쓰기는 넓어지지 않음 ]]
put(hm, "x", "bad")
put(tm, 1, 1)
add(hs, "oops")
add(ts, "oops")
touch(arr, "oops")
touch(dq, "oops")
setAt(arr, "one", 3)
setAt(dq, "one", 3)
local negLookup = lookup(tm, 1)
local negKeys: { number } = keysThenPut(hm, "y", 2)

--[[ NEG — 읽기 전용으로 빌린 참조는 쓰는 제네릭에 못 들어감(AC 와 같은 결) ]]
local function borrow(list: stl.ArrRead<number>)
	touch(list, 3)
end

local canary: string = 42

--[[ 알려진 구멍 — 읽기 마커로 쓰면 지금도 0건(타입이 못 막음, 규약으로 지킴) ]]
local function unsoundPut<K, V>(m: stl.MapMarker<K, V>, k: K, v: V)
	const ops = Trait.ImplOf(stl.Map, m)
	if ops then
		ops.Set(m, k, v)
	end
end
unsoundPut(HashMap.New<<string, number>>(), "x", "bad")
-- 키를 넘기는 조회도(런타임: 비교자가 `attempt to compare string < number`)
local function unsoundLookup<K, V>(m: stl.MapMarker<K, V>, k: K): V?
	const ops = Trait.ImplOf(stl.Map, m)
	return if ops then ops.Get(m, k) else nil
end
local unsoundGot = unsoundLookup(tm, 1)

return { keys, wideKeys, wideIndex, looked, negKeys, negLookup, borrow, canary, unsoundGot }

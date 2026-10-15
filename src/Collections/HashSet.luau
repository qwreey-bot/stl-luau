--!strict
--[[
	HashSet — 원소의 존재만 다루는 컨테이너.

	## ⭐ HashMap 위에 **단방향으로** 얹혀 있습니다

	```lua
	{ map: HashMap<T, T> }   -- 원소 → 원소
	```

	원소를 키로 넣고 **값에도 그 원소**를 넣습니다. Rust 의 `BTreeSet` 이
	`BTreeMap<T, ()>` 을, Java 의 `HashSet` 이 `HashMap` + 더미 객체를 쓰는
	것과 같은 결입니다. 같은 저자의 예전 C++ 과제도 결국 같은 경로를 갔습니다
	(빈 구조체를 값으로, 셋 메소드는 전부 한 줄 위임).

	⭐ 더미 `true` 가 아니라 **원소 자신**을 값으로 두는 이유(2026-10-13 사용자 결정): 안쪽 테이블을
	`Iter` 가 그대로 돌려줘도 순회가 `(item, item)` 을 냅니다 — Luau 가 테이블을 직접 돌아 순회 함수보다
	10배 빠르고(perf 29절), `for item in`·`for _, item in`(`FlatSet` 과 같은 모양)·
	`Arr.FromIter(HashSet.Iter(s))` 가 전부 그대로 됩니다. `true` 였다면 둘째 값과 `FromIter` 가 `true` 를
	받았을 것입니다. 메모리는 같습니다(값 한 칸). **모든 쓰기 자리가 `out[item] = item`** 이어야 합니다
	(`spec.hashset` 이 생성·변형 경로 전수로 지킴 — 타입은 `out[item] = true` 를 못 잡습니다).

	⚠️ 그래서 **값이 `false` 일 수 있습니다**(`HashSet<boolean>` 의 `false` 원소). 있는지 볼 땐 반드시
	`data[item] ~= nil` — Lua 의 흔한 관용구 `if data[item] then` 은 `false` 원소를 없다고 봅니다(예전엔 값이
	늘 `true` 라 같은 뜻이었음). 그리고 `map` 을 밖에서 직접 쓰면(`HashMap.Set(s.map, k, 다른값)`) 타입이 통과하고
	순회가 틀어집니다 — 예전엔 값 타입이 `true` 뿐이라 막혔습니다. `map` 은 구현 세부입니다.

	**단방향입니다** — `HashSet` 이 `HashMap` 을 require 하고 그 반대는 없어
	순환이 원천적으로 불가능합니다.

	## 이름을 맵과 가릅니다

	**셋은 `Add`/`Has`/`Remove`, 맵은 `Set`/`Get`.** 안에 맵이 들어 있어도
	바깥 어휘는 완전히 분리합니다. `map` 필드는 구현 세부이고, 밖에서 쓰라고
	둔 것이 아닙니다.

	## 집합 연산이 맵을 거치는 대가에 대하여

	Set-on-Map 을 정할 때 걱정한 것이 "합집합·교집합이 맵을 한 겹 거친다"
	였습니다. **실제로는 거의 들지 않습니다** — 이 모듈이 자기 맵의 주인이라
	`other.map.data[item]` 로 **바로 읽을 수 있기** 때문입니다. 계층을 넘는
	것이 아니라 자기 것을 읽는 것입니다.

	남는 진짜 비용은 **원소마다 값 한 칸**(원소 자신)뿐입니다.
	수치는 `.claude/base/perf-measurements.md`.
]]
local HashMap = require("./HashMap")
local Common = require("../Common")
local Trait = require("../Trait")
type A = Trait.A
local Set = require("../Traits/Set")
local Collection = require("../Traits/Collection")
Common.registerSource(debug.info(1, "s"))

type HashMapType<K, V> = HashMap.HashMap<K, V>

-- `__setMut` 는 쓰는 제네릭용 불변 팬텀(`Set.MarkerMut`, 질문 AM) — 타입에만 있습니다.
export type HashSetData<T> = {
	map: HashMapType<T, T>,
	read __type: Trait.Token<"Stl.HashSet">,
	read __setItem: T,
	read __setMut: (T) -> T,
	-- 바꾸는 컬렉션 알고리즘용 팬텀(`Collection.MarkerMut`, 2026-10-12) — 타입에만 있습니다.
	read __collectionMut: true,
	-- 연관 타입(트레이트 `Set` 의 정의가 `of` 로 읽음 — 2026-10-15, 질문 AY): 원소. 불변 팬텀, 타입에만 있습니다.
	read __generics: { read Item: (T) -> T },
}

-- 인스턴스 판별용 태그. **메타테이블은 없습니다**(질문 AB) — 데이터는 평범한
-- 테이블(엔티티), 연산은 이 모듈의 네임스페이스 함수(서비스)입니다.
-- 리터럴로 둡니다 — `Trait.TYPE_KEY` 를 받아 쓰면 상수 접기가 안 돼 생성이 7~11% 느려졌습니다(perf 21절).
const TYPE_KEY = "__type"
const TOKEN = Trait.NewToken("Stl.HashSet") :: Trait.Token<"Stl.HashSet">

-- 날 테이블에 태그를 붙입니다. 생성자들이 공유합니다.
const function tagged(raw: any): any
	raw[TYPE_KEY] = TOKEN
	return raw
end

--#region ----------- 계약 구현 (Set.Core) -----------
-- 이 모듈 테이블이 그대로 `Set.Core` 구현체입니다(질문 AB).

-- 원소를 넣습니다. **새로 들어갔으면 `true`**, 이미 있었으면 `false`.
const function Add<T>(self: HashSetData<T>, item: T): boolean
	const data = self.map.data
	if data[item] ~= nil then
		return false
	end
	data[item] = item
	self.map.size += 1
	return true
end

const function Has<T>(self: HashSetData<T>, item: T): boolean
	return self.map.data[item] ~= nil
end

-- 원소를 뺍니다. **정말 있었으면 `true`**.
const function Remove<T>(self: HashSetData<T>, item: T): boolean
	const data = self.map.data
	if data[item] == nil then
		return false
	end
	data[item] = nil
	self.map.size -= 1
	return true
end

-- 원소를 모은 평범한 Lua 배열. **순서는 보장하지 않습니다.**
const function Items<T>(self: HashSetData<T>): { T }
	return HashMap.Keys(self.map)
end

--#endregion

--#region ----------- 조회 -----------

const function Len<T>(self: HashSetData<T>): number
	return self.map.size
end

const function Empty<T>(self: HashSetData<T>): boolean
	return self.map.size == 0
end

-- `for item in HashSet.Iter(set) do … end`  (또는 `for _, item in …` — `FlatSet.Iter` 와 같은 모양)
--
-- ⭐ **안쪽 테이블을 그대로 돌려줍니다**(2026-10-13 사용자 결정 — `HashMap.Iter` 와 같은 결). 안쪽이
-- `원소 → 원소` 라 순회가 `(item, item)` 을 내고, Luau 가 테이블을 직접 돌아 예전의 순회 함수(원소마다
-- Luau 호출)보다 10배 빠릅니다(perf 29절). 반환은 **함수가 아닙니다** — `Arr.FromIter(HashSet.Iter(s))`
-- 는 그대로 되고, 손으로 걸으려면 `next(HashSet.Iter(s) :: any, item)`.
-- 타입은 읽기 전용(`{ read [T]: T }`) — 받은 테이블에 인덱싱으로 쓰면 크기가 틀어지니 타입이 막습니다
-- (예전엔 돌려준 상태가 읽기·쓰기라 `state[30] = true` 가 0건이었음). `table.clear` 같은 내장은 못
-- 막습니다 — 읽기만 하세요. 도는 동안 넣는 것은 정의되지 않은 동작입니다.
const function Iter<T>(self: HashSetData<T>): { read [T]: T }
	return self.map.data
end

--#endregion

--#region ----------- 변형 -----------

-- 비우고 **자기 자신을 돌려줍니다**(2026-10-12 사용자 결정, 질문 AM — 일곱 컨테이너가 같게. 반환은 공짜였음).
const function Clear<T>(self: HashSetData<T>): HashSet<T>
	HashMap.Clear(self.map)
	return self
end

-- 조건을 만족하는 원소만 **남깁니다**(제자리). ⚠️ Java `retainAll`(다른 컬렉션을 받음)과 달리
-- 술어를 받습니다(질문 W) — 다른 셋과의 교집합은 `Intersect`. 콜백 안에서 이 셋을 바꾸면
-- 정의되지 않은 동작입니다(`HashMap.Retain` 과 같음, 질문 AL 1 — 지우기의 크기가 맞는 것은 관측).
const function Retain<T>(self: HashSetData<T>, fn: (item: T) -> boolean): HashSet<T>
	const map = self.map
	const data = map.data
	for item in data do
		if not fn(item) and data[item] ~= nil then
			data[item] = nil
			map.size -= 1
		end
	end
	return self
end

const function Clone<T>(self: HashSetData<T>): HashSet<T>
	return tagged({ map = HashMap.Clone(self.map) })
end

--#endregion

--#region ----------- 집합 연산 -----------
-- 상대 셋의 `map.data` 를 직접 읽습니다. 계층을 넘는 게 아니라 이 모듈이
-- 주인인 자기 표현을 읽는 것입니다 — 그래서 맵을 한 겹 거치는 비용이 없습니다.

const function newFrom<T>(data: { [T]: T }, size: number): HashSet<T>
	const map: HashMapType<T, T> = HashMap.Adopt(data, size)
	return tagged({ map = map })
end

-- 합집합. 양쪽에 있는 것 전부.
const function Union<T>(self: HashSetData<T>, other: HashSetData<T>): HashSet<T>
	const out: { [T]: T } = {}
	local count = 0
	for item in self.map.data do
		out[item] = item
		count += 1
	end
	for item in other.map.data do
		if out[item] == nil then
			out[item] = item
			count += 1
		end
	end
	return newFrom(out, count)
end

-- 교집합. 양쪽 모두에 있는 것.
-- **작은 쪽을 순회합니다** — 큰 쪽을 돌며 작은 쪽에 묻는 것보다 적게 묻습니다.
const function Intersect<T>(self: HashSetData<T>, other: HashSetData<T>): HashSet<T>
	const smaller = if self.map.size <= other.map.size then self else other
	const larger = if smaller == self then other else self
	const largerData = larger.map.data
	const out: { [T]: T } = {}
	local count = 0
	for item in smaller.map.data do
		if largerData[item] ~= nil then
			out[item] = item
			count += 1
		end
	end
	return newFrom(out, count)
end

-- 차집합. 이쪽에는 있고 저쪽에는 없는 것.
const function Difference<T>(self: HashSetData<T>, other: HashSetData<T>): HashSet<T>
	const otherData = other.map.data
	const out: { [T]: T } = {}
	local count = 0
	for item in self.map.data do
		if otherData[item] == nil then
			out[item] = item
			count += 1
		end
	end
	return newFrom(out, count)
end

-- 대칭차. 한쪽에만 있는 것.
const function SymmetricDifference<T>(self: HashSetData<T>, other: HashSetData<T>): HashSet<T>
	const selfData = self.map.data
	const otherData = other.map.data
	const out: { [T]: T } = {}
	local count = 0
	for item in selfData do
		if otherData[item] == nil then
			out[item] = item
			count += 1
		end
	end
	for item in otherData do
		if selfData[item] == nil then
			out[item] = item
			count += 1
		end
	end
	return newFrom(out, count)
end

-- 이쪽이 저쪽에 통째로 들어가는가. **크기를 먼저 보고 걸러냅니다.**
const function IsSubsetOf<T>(self: HashSetData<T>, other: HashSetData<T>): boolean
	if self.map.size > other.map.size then
		return false
	end
	const otherData = other.map.data
	for item in self.map.data do
		if otherData[item] == nil then
			return false
		end
	end
	return true
end

-- 겹치는 원소가 하나도 없는가.
const function IsDisjointFrom<T>(self: HashSetData<T>, other: HashSetData<T>): boolean
	const smaller = if self.map.size <= other.map.size then self else other
	const larger = if smaller == self then other else self
	const largerData = larger.map.data
	for item in smaller.map.data do
		if largerData[item] ~= nil then
			return false
		end
	end
	return true
end

-- 원소가 완전히 같은가.
const function Equal<T>(self: HashSetData<T>, other: HashSetData<T>): boolean
	if self.map.size ~= other.map.size then
		return false
	end
	const otherData = other.map.data
	for item in self.map.data do
		if otherData[item] == nil then
			return false
		end
	end
	return true
end

--#endregion

--#region ----------- 타입 -----------
-- 함수가 타입 바깥(네임스페이스)에 있으니 전체형은 데이터부 그 자체입니다(질문 AB).
export type HashSet<T> = HashSetData<T>

--#endregion

--#region ----------- 생성자 -----------

const function New<T>(): HashSet<T>
	return newFrom({} :: { [T]: T }, 0)
end

const function Of<T>(...: T): HashSet<T>
	const out: { [T]: T } = {}
	local count = 0
	for idx = 1, select("#", ...) do
		const item: T = select(idx, ...)
		if item ~= nil and out[item] == nil then
			out[item] = item
			count += 1
		end
	end
	return newFrom(out, count)
end

-- 평범한 Lua 배열의 원소로 만듭니다. 중복은 하나로 접힙니다.
const function FromList<T>(list: { T }): HashSet<T>
	const out: { [T]: T } = {}
	local count = 0
	-- 길이는 `Common.listLength` 규약(`n` 우선) — `pairs` 로 돌면 `Arr` 의 `n`·태그도
	-- 원소가 됐습니다(M0 3라운드). 구멍은 건너뜁니다.
	const items, itemCount = Common.denseList(list)
	for idx = 1, itemCount do
		const item = items[idx]
		if out[item] == nil then
			out[item] = item
			count += 1
		end
	end
	return newFrom(out, count)
end

const function isHashSet(value: any): boolean
	return type(value) == "table" and rawget(value, TYPE_KEY) == TOKEN
end

--#endregion

-- stylua: ignore
const HashSetModule = {
	New = New,
	Of = Of,
	FromList = FromList,
	isHashSet = isHashSet,
	-- 이 종류의 타입 토큰(값의 `__type`) — 바깥 트레이트를 이 종류에 붙일 때: `MyTrait.ImplFor(HashSet.Token, impl)`
	Token = TOKEN,

	-- ⭐ 모든 연산은 여기 네임스페이스 함수입니다(`HashSet.X(v, …)`) — 콜론 호출은
	-- 없습니다(질문 AB). `local` 로 받아 부르면 더 빠릅니다(perf 14·16절).
	Len = Len, Empty = Empty, Iter = Iter, Clear = Clear, Clone = Clone, Union = Union,
	Intersect = Intersect, Difference = Difference, SymmetricDifference = SymmetricDifference,
	IsSubsetOf = IsSubsetOf, IsDisjointFrom = IsDisjointFrom, Equal = Equal, Add = Add, Has = Has,
	Remove = Remove, Items = Items,
	Retain = Retain,
}

-- ⭐ **트레이트에는 넘길 것만 든 표를 등록합니다**(2026-10-13 사용자 결정, 질문 AS) — 모듈 테이블을 통째로 넘기지
-- 않습니다(같은 이름이 전부 그 트레이트의 구현이 되어, 뜻이 다른 같은 이름이 조용히 먹었음. 이제 모르는 이름은
-- `ImplFor` 가 에러로 알림). 표의 타입 주석(`X.Provided<…>` — 등록 표 타입, 기본 구현 칸은 선택)이 "구현이 계약을 만족하는가" 의
-- 정적 확인입니다 — **탐침 타입**(`Trait.A`·`Trait.B` — 서로 다른 불투명 타입)으로 적습니다: `any` 로 적으면 인자 수·인자 타입이
-- 검사되지 않았고(2라운드 리뷰), 구체 타입(`string`)으로 적으면 원소를 못박은 함수가 샙니다(2026-10-14 탐색 — 질문 AY).
-- 표는 이렇게 **주석 단 지역 변수**에 적어 넘깁니다 — `ImplFor(토큰, { … })` 처럼 표 리터럴을 바로 넘기면 검사가 안 됩니다.
const setImpl: Set.Provided<HashSet<A>, A> =
	{ Add = HashSetModule.Add, Has = HashSetModule.Has, Remove = HashSetModule.Remove, Items = HashSetModule.Items }
const collectionImpl: Collection.Provided<HashSet<A>> = { Len = HashSetModule.Len, Clear = HashSetModule.Clear }
Set.ImplFor(TOKEN, setImpl)
Collection.ImplFor(TOKEN, collectionImpl)

return HashSetModule

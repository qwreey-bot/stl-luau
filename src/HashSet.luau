--!strict
--[[
	HashSet — 원소의 존재만 다루는 컨테이너.

	## ⭐ HashMap 위에 **단방향으로** 얹혀 있습니다

	```lua
	{ map: HashMap<T, true> }
	```

	원소를 키로, 더미 값으로 `true` 를 넣습니다. Rust 의 `BTreeSet` 이
	`BTreeMap<T, ()>` 을, Java 의 `HashSet` 이 `HashMap` + 더미 객체를 쓰는
	것과 같습니다. 같은 저자의 예전 C++ 과제도 결국 같은 경로를 갔습니다
	(빈 구조체를 값으로, 셋 메소드는 전부 한 줄 위임).

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

	남는 진짜 비용은 **원소마다 더미 값 `true` 한 칸**뿐입니다.
	수치는 `.claude/base/perf-measurements.md`.
]]
local Types = require("./Types")
local HashMap = require("./HashMap")

type HashMapType<K, V> = HashMap.HashMap<K, V>

export type HashSetData<T> = { map: HashMapType<T, true> }

local Ifce: HashSetIfce & Types.SetCore<any>

--#region ----------- 계약 구현 (Types.SetCore) -----------
-- ⚠️ 이 넷은 `HashSetIfce` 에 **다시 쓰지 않습니다.** 계약이 이미 줍니다.

-- 원소를 넣습니다. **새로 들어갔으면 `true`**, 이미 있었으면 `false`.
const function Add<T>(self: HashSetData<T>, item: T): boolean
	const data = self.map.data
	if data[item] ~= nil then
		return false
	end
	data[item] = true
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
	return self.map:Keys()
end

--#endregion

--#region ----------- 조회 -----------

const function Len<T>(self: HashSetData<T>): number
	return self.map.size
end

const function Empty<T>(self: HashSetData<T>): boolean
	return self.map.size == 0
end

-- `for item in set:Iter() do … end`
-- 루프 변수가 하나입니다 — 값 자리엔 더미 `true` 가 올 뿐이라 뜻이 없습니다.
const function iterStep<T>(data: { [T]: true }, item: T?): (T, true)
	return (next :: any)(data, item)
end

const function Iter<T>(self: HashSetData<T>): (typeof(iterStep), { [T]: true }, T?)
	return iterStep, self.map.data, nil
end

--#endregion

--#region ----------- 변형 -----------

const function Clear<T>(self: HashSetData<T>): ()
	self.map:Clear()
end

const function Clone<T>(self: HashSetData<T>): HashSet<T>
	return setmetatable({ map = self.map:Clone() } :: any, Ifce :: any) :: any
end

--#endregion

--#region ----------- 집합 연산 -----------
-- 상대 셋의 `map.data` 를 직접 읽습니다. 계층을 넘는 게 아니라 이 모듈이
-- 주인인 자기 표현을 읽는 것입니다 — 그래서 맵을 한 겹 거치는 비용이 없습니다.

const function newFrom<T>(data: { [T]: true }, size: number): HashSet<T>
	const map: HashMapType<T, true> = HashMap.Adopt(data, size)
	return setmetatable({ map = map } :: any, Ifce :: any) :: any
end

-- 합집합. 양쪽에 있는 것 전부.
const function Union<T>(self: HashSetData<T>, other: HashSetData<T>): HashSet<T>
	const out: { [T]: true } = {}
	local count = 0
	for item in self.map.data do
		out[item] = true
		count += 1
	end
	for item in other.map.data do
		if out[item] == nil then
			out[item] = true
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
	const out: { [T]: true } = {}
	local count = 0
	for item in smaller.map.data do
		if largerData[item] ~= nil then
			out[item] = true
			count += 1
		end
	end
	return newFrom(out, count)
end

-- 차집합. 이쪽에는 있고 저쪽에는 없는 것.
const function Difference<T>(self: HashSetData<T>, other: HashSetData<T>): HashSet<T>
	const otherData = other.map.data
	const out: { [T]: true } = {}
	local count = 0
	for item in self.map.data do
		if otherData[item] == nil then
			out[item] = true
			count += 1
		end
	end
	return newFrom(out, count)
end

-- 대칭차. 한쪽에만 있는 것.
const function SymmetricDifference<T>(self: HashSetData<T>, other: HashSetData<T>): HashSet<T>
	const selfData = self.map.data
	const otherData = other.map.data
	const out: { [T]: true } = {}
	local count = 0
	for item in selfData do
		if otherData[item] == nil then
			out[item] = true
			count += 1
		end
	end
	for item in otherData do
		if selfData[item] == nil then
			out[item] = true
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

--#region ----------- 타입 조립 -----------
-- ⭐ `Add`/`Has`/`Remove`/`Items` 는 **여기 없습니다.** `Types.SetCore` 가 줍니다.

type HashSetIfce = {
	Len: typeof(Len),
	Empty: typeof(Empty),
	Iter: typeof(Iter),
	Clear: typeof(Clear),
	Clone: typeof(Clone),
	Union: typeof(Union),
	Intersect: typeof(Intersect),
	Difference: typeof(Difference),
	SymmetricDifference: typeof(SymmetricDifference),
	IsSubsetOf: typeof(IsSubsetOf),
	IsDisjointFrom: typeof(IsDisjointFrom),
	Equal: typeof(Equal),
}

export type HashSet<T> = HashSetData<T> & HashSetIfce & Types.SetCore<T>

Ifce = {
	Len = Len, Empty = Empty, Iter = Iter, Clear = Clear, Clone = Clone,
	Union = Union, Intersect = Intersect, Difference = Difference,
	SymmetricDifference = SymmetricDifference,
	IsSubsetOf = IsSubsetOf, IsDisjointFrom = IsDisjointFrom, Equal = Equal,
	-- 계약이 주는 것들.
	Add = Add, Has = Has, Remove = Remove, Items = Items,
} :: any
;(Ifce :: any).__index = Ifce

--#endregion

--#region ----------- 생성자 -----------

const function New<T>(): HashSet<T>
	return newFrom({} :: { [T]: true }, 0)
end

const function Of<T>(...: T): HashSet<T>
	const out: { [T]: true } = {}
	local count = 0
	for idx = 1, select("#", ...) do
		const item: T = select(idx, ...)
		if item ~= nil and out[item] == nil then
			out[item] = true
			count += 1
		end
	end
	return newFrom(out, count)
end

-- 평범한 Lua 배열의 원소로 만듭니다. 중복은 하나로 접힙니다.
const function FromList<T>(list: { T }): HashSet<T>
	const out: { [T]: true } = {}
	local count = 0
	for _, item in list do
		if out[item] == nil then
			out[item] = true
			count += 1
		end
	end
	return newFrom(out, count)
end

const function isHashSet(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Ifce
end

--#endregion

return {
	New = New,
	Of = Of,
	FromList = FromList,
	isHashSet = isHashSet,
}

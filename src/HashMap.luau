--!strict
--[[
	HashMap — 키로 값을 찾는 컨테이너.

	## 표현 — 왜 래퍼인가

	```lua
	{ data: { [K]: V }, size: number }
	```

	**Luau 테이블 자체가 이미 해시맵입니다.** 그래서 버킷·체인·해시 함수 주입·
	리해싱 같은 계층이 통째로 필요 없습니다. 이 모듈이 실제로 더하는 것은
	**크기 추적**과 **계약(`Types.MapCore`) 만족** 둘뿐입니다.

	⭐ **키와 값을 `self` 에 바로 넣지 않고 `data` 안에 넣습니다.** 인스턴스에
	길이 필드를 두면 `HashMap<string, …>` 에서 `Set("size", v)` 가 길이를
	덮어씁니다. 래퍼가 그 사고를 원천적으로 막습니다(사용자 결정 2026-08-22).

	## 크기를 왜 따로 세는가

	Lua 에는 해시 부분의 개수를 O(1) 로 알려주는 게 없습니다(`#` 는 배열
	부분만 봅니다). 매번 세면 O(n) 이므로 `Set`/`Remove` 에서 갱신합니다.
	**그래서 `data` 를 밖에서 직접 건드리면 `size` 가 틀어집니다** — 읽기만
	하세요.

	## 해시 함수를 주입받지 않는 이유

	문자열·숫자·불리언 키는 Luau 가 알아서 합니다. 해시 주입이 값지는 경우는
	**테이블을 값으로 비교해 키로 쓸 때**(`{1,2}` 와 `{1,2}` 를 같은 키로)
	뿐인데, 그건 지금 만들 이유가 없어 `Types.Hasher` 에 자리만 남겨뒀습니다.
	(`.claude/question.md` M)

	## 이름을 셋과 가릅니다

	**맵은 `Set`/`Get`, 셋은 `Add`/`Has`/`Remove`.** `HashSet` 이 이 모듈 위에
	얹혀 있어도 바깥 어휘는 완전히 분리합니다.
]]
local Types = require("./Types")

type Record<K, V> = Types.Record<K, V>

export type HashMapData<K, V> = { data: { [K]: V }, size: number }

-- 런타임 메소드 테이블. 아래에서 채웁니다.
local Ifce: HashMapIfce & Types.MapCore<any, any>

--#region ----------- 계약 구현 (Types.MapCore) -----------
-- ⚠️ 이 셋은 `HashMapIfce` 에 **다시 쓰지 않습니다.** 계약이 이미 줍니다.

const function Get<K, V>(self: HashMapData<K, V>, key: K): V?
	return self.data[key]
end

-- 값을 넣습니다. 이미 있으면 덮어씁니다.
-- 반환이 없는 것은 계약이 그렇게 정해서입니다 — 체이닝은 못 합니다.
const function Set<K, V>(self: HashMapData<K, V>, key: K, value: V): ()
	const data = self.data
	if data[key] == nil then
		self.size += 1
	end
	data[key] = value
end

-- 키-값 쌍의 목록. **순서는 보장하지 않습니다**(해시 순서).
-- 순서가 필요하면 `TreeMap` 을 쓰세요.
const function Records<K, V>(self: HashMapData<K, V>): { Record<K, V> }
	const out = table.create(self.size) :: { Record<K, V> }
	local count = 0
	for key, value in self.data do
		count += 1
		out[count] = { key = key, value = value }
	end
	return out
end

--#endregion

--#region ----------- 조회 -----------

const function Has<K, V>(self: HashMapData<K, V>, key: K): boolean
	return self.data[key] ~= nil
end

-- 없으면 `fallback` 을 돌려줍니다. `Get` 과 달리 옵셔널이 아닙니다.
const function GetOr<K, V>(self: HashMapData<K, V>, key: K, fallback: V): V
	const found = self.data[key]
	if found == nil then
		return fallback
	end
	return found
end

const function Len<K, V>(self: HashMapData<K, V>): number
	return self.size
end

const function Empty<K, V>(self: HashMapData<K, V>): boolean
	return self.size == 0
end

-- 키만 모은 평범한 Lua 배열. **순서는 보장하지 않습니다.**
-- `Arr` 로 받고 싶으면 `Arr.FromTable(map:Keys())` 하세요 — 이 모듈이 `Arr`
-- 을 require 하지 않게 하려는 것입니다(의존을 한 방향으로 유지).
const function Keys<K, V>(self: HashMapData<K, V>): { K }
	const out: { K } = table.create(self.size)
	local count = 0
	for key in self.data do
		count += 1
		out[count] = key
	end
	return out
end

const function Values<K, V>(self: HashMapData<K, V>): { V }
	const out: { V } = table.create(self.size)
	local count = 0
	for _, value in self.data do
		count += 1
		out[count] = value
	end
	return out
end

-- `for key, value in map:Iter() do … end`
-- ⭐ `(K, V)` 로 **비옵셔널로** 선언합니다 — 끝에서 `nil` 을 돌려주지만 타입엔
-- 드러내지 않습니다. 드러내면 루프 변수가 옵셔널이 되어 바로 못 씁니다.
-- Luau 자신의 `next`/`ipairs` 도 같은 방식입니다.
const function iterStep<K, V>(data: { [K]: V }, key: K?): (K, V)
	return (next :: any)(data, key)
end

const function Iter<K, V>(self: HashMapData<K, V>): (typeof(iterStep), { [K]: V }, K?)
	return iterStep, self.data, nil
end

--#endregion

--#region ----------- 변형 -----------

-- 키를 지우고 **지워진 값**을 돌려줍니다. 없었으면 `nil`.
-- Lua 테이블은 `nil` 값을 저장할 수 없으므로 "있었는가" 와 구분이 모호하지
-- 않습니다.
const function Remove<K, V>(self: HashMapData<K, V>, key: K): V?
	const data = self.data
	const found = data[key]
	if found == nil then
		return nil
	end
	data[key] = nil
	self.size -= 1
	return found
end

const function Clear<K, V>(self: HashMapData<K, V>): ()
	table.clear(self.data)
	self.size = 0
end

-- 얕은 복사. 키와 값 자체는 공유합니다.
const function Clone<K, V>(self: HashMapData<K, V>): HashMap<K, V>
	const copy: { [K]: V } = {}
	for key, value in self.data do
		copy[key] = value
	end
	return setmetatable({ data = copy, size = self.size } :: any, Ifce :: any) :: any
end

--#endregion

--#region ----------- 타입 조립 -----------
-- ⭐ `Get`/`Set`/`Records` 는 **여기 없습니다.** `Types.MapCore` 가 줍니다.
-- 여기 다시 쓰면 self 타입이 달라 교집합이 충돌하고 메소드 타입이 통째로
-- 죽습니다(진단 0건으로).

type HashMapIfce = {
	Has: typeof(Has),
	GetOr: typeof(GetOr),
	Len: typeof(Len),
	Empty: typeof(Empty),
	Keys: typeof(Keys),
	Values: typeof(Values),
	Iter: typeof(Iter),
	Remove: typeof(Remove),
	Clear: typeof(Clear),
	Clone: typeof(Clone),
}

export type HashMap<K, V> = HashMapData<K, V> & HashMapIfce & Types.MapCore<K, V>

-- 범주별로 묶어 두는 편이 읽기 좋은 디스패치 테이블입니다. 한 줄에 하나씩
-- 펼치면 배로 길어지고 그룹 주석과의 대응이 흩어집니다.
-- stylua: ignore
Ifce = {
	Has = Has, GetOr = GetOr, Len = Len, Empty = Empty,
	Keys = Keys, Values = Values, Iter = Iter,
	Remove = Remove, Clear = Clear, Clone = Clone,
	-- 계약이 주는 것들. 타입 선언엔 없지만 런타임 테이블엔 있어야 합니다.
	Get = Get, Set = Set, Records = Records,
} :: any
(Ifce :: any).__index = Ifce

--#endregion

--#region ----------- 생성자 -----------

-- ⚠️ **빈 맵은 타입을 캐스트로 적어야 합니다** — 인자가 없어 `K`/`V` 를
-- 추론할 방법이 없고, Luau 는 기대 타입을 제네릭 호출 안으로 전파하지
-- 않습니다(선언 주석 `local m: HashMap<string, number> = HashMap.New()` 는
-- 안 됩니다).
--
--     local m = HashMap.New() :: HashMap<string, number>
--
-- `Arr.Of()` 로 빈 배열을 만들 때와 같은 한계입니다.
const function New<K, V>(): HashMap<K, V>
	return setmetatable({ data = {} :: { [K]: V }, size = 0 } :: any, Ifce :: any) :: any
end

-- 평범한 Lua 테이블에서 만듭니다. **복사합니다** — 넘긴 테이블을 나중에
-- 건드려도 `size` 가 틀어지지 않게 하려는 것입니다.
--
-- ⚠️ **테이블 리터럴을 바로 넘기면 타입이 안 잡힙니다.** `{ a = 1 }` 은
-- `{ [string]: number }` 가 아니라 **이름 붙은 속성을 가진 레코드**
-- `{ a: number }` 라서, `{ [K]: V }` 에 맞출 `K`/`V` 가 없습니다. 결과가
-- 조용히 `HashMap<unknown, unknown>` 이 됩니다. 둘 중 하나를 하세요:
--
--     local src: { [string]: number } = { a = 1 }
--     local m = HashMap.FromTable(src)
--     -- 또는
--     local m = HashMap.FromTable({ a = 1 }) :: HashMap<string, number>
const function FromTable<K, V>(tbl: { [K]: V }): HashMap<K, V>
	const copy: { [K]: V } = {}
	local count = 0
	for key, value in tbl do
		copy[key] = value
		count += 1
	end
	return setmetatable({ data = copy, size = count } :: any, Ifce :: any) :: any
end

-- 키-값 쌍 목록에서 만듭니다. `Records()` 의 역연산입니다.
const function FromRecords<K, V>(records: { Record<K, V> }): HashMap<K, V>
	const copy: { [K]: V } = {}
	local count = 0
	for _, rec in records do
		if copy[rec.key] == nil then
			count += 1
		end
		copy[rec.key] = rec.value
	end
	return setmetatable({ data = copy, size = count } :: any, Ifce :: any) :: any
end

-- ⚠️ **입양**: 이미 만들어 둔 테이블과 크기를 그대로 감쌉니다. 복사하지
-- 않고 `size` 가 맞는지도 검사하지 않습니다 — **호출자 책임**입니다.
-- `HashSet` 처럼 이 모듈 위에 얹히는 구현이 중간 테이블을 한 번 더 만들지
-- 않게 하려고 둔 문입니다. 일반 사용자는 `FromTable` 을 쓰세요.
const function Adopt<K, V>(data: { [K]: V }, size: number): HashMap<K, V>
	return setmetatable({ data = data, size = size } :: any, Ifce :: any) :: any
end

const function isHashMap(value: any): boolean
	return type(value) == "table" and getmetatable(value) == Ifce
end

--#endregion

return {
	New = New,
	FromTable = FromTable,
	FromRecords = FromRecords,
	Adopt = Adopt,
	isHashMap = isHashMap,
}

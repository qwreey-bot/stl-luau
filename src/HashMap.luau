--!strict
--[[
	HashMap — 키로 값을 찾는 컨테이너.

	## 표현 — 왜 래퍼인가

	```lua
	{ data: { [K]: V }, size: number }
	```

	**Luau 테이블 자체가 이미 해시맵입니다.** 그래서 버킷·체인·해시 함수 주입·
	리해싱 같은 계층이 통째로 필요 없습니다. 이 모듈이 실제로 더하는 것은
	**크기 추적**과 **계약(`Types.MapOps`) 만족** 둘뿐입니다.

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
local Common = require("./Common")
local Trait = require("./Trait")
Common.registerSource(debug.info(1, "s"))

type Record<K, V> = Types.Record<K, V>

-- `read __type` 은 타입 토큰(생성자가 붙이는 실제 필드, `Trait.luau`) —
-- 리터럴이 맵 자리에 들어가는 것을 막습니다(M0 리뷰).
export type HashMapData<K, V> = {
	data: { [K]: V },
	size: number,
	read __type: Trait.Token<"HashMap">,
	read __mapKey: K,
	read __mapValue: V,
	-- 쓰는 제네릭용 불변 팬텀(`Types.MapMarkerMut`, 질문 AM) — 타입에만 있습니다.
	read __mapMut: (K, V) -> (K, V),
	-- 바꾸는 컬렉션 알고리즘용 팬텀(`Types.CollectionMarkerMut`, 2026-10-12) — 타입에만 있습니다.
	read __collectionMut: true,
}

-- 인스턴스 판별용 태그. **메타테이블은 없습니다**(질문 AB) — 데이터는 평범한
-- 테이블(엔티티), 연산은 이 모듈의 네임스페이스 함수(서비스)입니다.
-- 리터럴로 둡니다 — `Trait.TYPE_KEY` 를 받아 쓰면 상수 접기가 안 돼 생성이 7~11% 느려졌습니다(perf 21절).
const TYPE_KEY = "__type"
const TOKEN = Trait.Types.HashMap

-- 날 테이블에 태그를 붙입니다. 생성자들이 공유합니다.
const function tagged(raw: any): any
	raw[TYPE_KEY] = TOKEN
	return raw
end

--#region ----------- 계약 구현 (Types.MapOps) -----------
-- 이 모듈 테이블이 그대로 `Types.MapOps` 구현체입니다(질문 AB).

const function Get<K, V>(self: HashMapData<K, V>, key: K): V?
	return self.data[key]
end

-- 값을 넣습니다. 이미 있으면 덮어씁니다.
-- 반환이 없는 것은 계약(`Types.MapOps`)이 그렇게 정해서입니다.
--
-- ⭐ **값이 `nil` 이면 삭제입니다** — Lua 의 `t[k] = nil` 과 같습니다. 예전엔
-- 크기만 올리고 실제로는 아무것도 안 들어가 `size` 가 틀어졌습니다
-- (2026-09-30 리뷰). `TreeMap` 도 같은 규칙입니다.
--
-- **먼저 쓰고 나서 셉니다.** 키가 NaN 이나 `nil` 이면 Lua 가 쓰기에서
-- 에러를 내는데, 세는 게 먼저면 실패한 쓰기가 크기만 올렸습니다.
const function Set<K, V>(self: HashMapData<K, V>, key: K, value: V): ()
	const data = self.data
	const had = data[key] ~= nil
	data[key] = value
	if value == nil then
		if had then
			self.size -= 1
		end
	elseif not had then
		self.size += 1
	end
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
-- `Arr` 로 받고 싶으면 `Arr.FromTable(HashMap.Keys(map))` 하세요 — 이 모듈이 `Arr`
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

-- `for key, value in HashMap.Iter(map) do … end`
--
-- ⭐ **안쪽 테이블을 그대로 돌려줍니다**(2026-10-12 사용자 결정, 질문 AP 1). Luau 는 테이블을 `for … in` 에
-- 바로 넣으면 순회 함수 호출 없이 직접 돕니다(일반화 순회) — 함수 삼중항(`next, data`)을 돌려주던 때보다
-- 5배, 그 전의 Luau 래퍼보다 9배 빠릅니다(perf 27절). 그래서 반환은 **함수가 아닙니다**:
-- - `Arr.FromIter(HashMap.Iter(m))` 는 그대로 됩니다(`FromIter` 가 테이블을 받음).
-- - 타입은 **읽기 전용** `{ read [K]: V }` — 받은 테이블에 쓰면 `size` 가 틀어지니 타입이 막습니다.
--   도는 동안 있는 키의 값을 바꾸려면 `HashMap.Set(m, key, v)`(새 키를 넣는 것은 정의되지 않은 동작).
-- - 손으로 한 걸음씩 걷거나(`next`) 삼중항이 필요하면(`pairs`) **캐스트가 듭니다**:
--   `next(HashMap.Iter(m) :: any, key)`. 내장 `next`/`pairs` 의 타입이 읽기·쓰기 테이블을 요구해서입니다
--   (읽기·쓰기로 돌려주면 캐스트는 없어지지만 `HashMap.Iter(m).x = 1` 이 통과해 크기가 틀어집니다 — 드문
--   쪽에 캐스트를 두었습니다).
const function Iter<K, V>(self: HashMapData<K, V>): { read [K]: V }
	return self.data
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

-- 비우고 **자기 자신을 돌려줍니다**(2026-10-12 사용자 결정, 질문 AM — 일곱 컨테이너가 같게. 반환은 공짜였음).
const function Clear<K, V>(self: HashMapData<K, V>): HashMap<K, V>
	table.clear(self.data)
	self.size = 0
	return self
end

-- 얕은 복사. 키와 값 자체는 공유합니다.
const function Clone<K, V>(self: HashMapData<K, V>): HashMap<K, V>
	const copy: { [K]: V } = {}
	for key, value in self.data do
		copy[key] = value
	end
	return tagged({ data = copy, size = self.size })
end

-- 조건을 만족하는 쌍만 **남깁니다**(제자리, Rust `retain`). 콜백은 `(key, value)` 를 받습니다.
-- ⚠️ Java `retainAll`(다른 컬렉션을 받음)과 달리 **술어**를 받습니다(질문 W). 순서는 해시 순서.
-- ⚠️ 콜백 안에서 이 컨테이너를 바꾸면(넣기·지우기 — 캡처한 변수로) **정의되지 않은 동작**입니다
-- (2026-10-12 사용자 결정, 질문 AL 1). 관측(계약 아님): 지금 판은 콜백이 `Remove` 로 지운 키를
-- 다시 세지 않아 지우기는 크기가 맞습니다 — 셈을 맞추는 읽기 하나일 뿐 약속이 아닙니다.
const function Retain<K, V>(self: HashMapData<K, V>, fn: (key: K, value: V) -> boolean): HashMap<K, V>
	const data = self.data
	for key, value in data do
		if not fn(key, value) and data[key] ~= nil then
			data[key] = nil
			self.size -= 1
		end
	end
	return self
end

--#endregion

--#region ----------- 넣거나 합치기 (M4, 2026-10-07) -----------

-- 있으면 그 값, 없으면 `default` 를 넣고 그것을 돌려줍니다(Rust `entry(k).or_insert(v)`).
-- `default` 가 `nil` 이면 아무것도 넣지 않고 `nil` — `Set` 의 "값이 nil 이면 삭제" 와 같은 규칙.
const function GetOrInsert<K, V>(self: HashMapData<K, V>, key: K, default: V): V
	const data = self.data
	const found = data[key]
	if found ~= nil then
		return found
	end
	if default ~= nil then
		-- 먼저 쓰고 셉니다(`Set` 과 같은 이유 — NaN·nil 키는 쓰기에서 터짐).
		data[key] = default
		self.size += 1
	end
	return default
end

-- `GetOrInsert` 인데 기본값을 **없을 때만** 만듭니다(Rust `or_insert_with`). 비싼 기본값
-- (새 테이블·새 `Arr`)을 매번 만들지 않으려는 것 — 묶기를 손으로 짤 때의 재료(`Arr.GroupBy` 는 안을 직접 씀).
-- `make` 는 키를 받습니다. `make` 가 `nil` 을 돌려주면 아무것도 넣지 않고 그때 맵에 있는 값(보통
-- `nil`, `make` 가 그 키를 직접 넣었으면 그 값)을 돌려줍니다.
const function GetOrInsertWith<K, V>(self: HashMapData<K, V>, key: K, make: (key: K) -> V): V
	const data = self.data
	const found = data[key]
	if found ~= nil then
		return found
	end
	const value = make(key)
	if value ~= nil then
		-- `make` 가 같은 키를 넣었을 수 있어(재귀 메모이즈) 다시 봅니다 — 안 보면 크기를 두 번
		-- 셌습니다. 값은 `make` 가 돌려준 것이 이깁니다.
		const had = data[key] ~= nil
		data[key] = value
		if not had then
			self.size += 1
		end
		return value
	end
	return data[key] :: any
end

-- 키에 값을 **누적**합니다(Java `Map.merge`): 없으면 `value` 를 넣고, 있으면
-- `combine(old, value)` 로 바꿉니다. 바뀐 값을 돌려줍니다. `combine` 이 `nil` 을 돌려주면
-- 키를 지웁니다(`Set` 규칙). 예: 단어 세기 `HashMap.Accumulate(m, w, 1, add)`.
-- (이름: `Update` 는 Python `dict.update`(덮어 합치기)와 겹쳐서 — 질문 W.)
const function Accumulate<K, V>(self: HashMapData<K, V>, key: K, value: V, combine: (old: V, value: V) -> V): V?
	const old = self.data[key]
	if old == nil then
		Set(self, key, value)
		return value
	end
	const combined = combine(old, value)
	Set(self, key, combined)
	return combined
end

-- `other` 의 쌍을 **덮어 합친** 새 맵(같은 키는 `other` 가 이김 — Sift·Llama `Dictionary.merge`,
-- Python `dict | other`). 두 맵은 그대로입니다. 누적하려면 `Accumulate`.
const function Merge<K, V>(self: HashMapData<K, V>, other: HashMapData<K, V>): HashMap<K, V>
	const copy: { [K]: V } = {}
	local count = 0
	for key, value in self.data do
		copy[key] = value
		count += 1
	end
	for key, value in other.data do
		if copy[key] == nil then
			count += 1
		end
		copy[key] = value
	end
	return tagged({ data = copy, size = count })
end

-- `Merge` 의 제자리 판 — `self` 에 `other` 를 덮어쓰고 자기 자신을 돌려줍니다(Python `dict.update`).
const function MergeInplace<K, V>(self: HashMapData<K, V>, other: HashMapData<K, V>): HashMap<K, V>
	const data = self.data
	local count = self.size
	for key, value in other.data do
		if data[key] == nil then
			count += 1
		end
		data[key] = value
	end
	self.size = count
	return self
end

--#endregion

--#region ----------- 타입 -----------
-- 함수가 타입 바깥(네임스페이스)에 있으니 전체형은 데이터부 그 자체입니다(질문 AB).
export type HashMap<K, V> = HashMapData<K, V>

--#endregion

--#region ----------- 생성자 -----------

-- ⚠️ **빈 맵은 타입을 직접 알려줘야 합니다** — 인자가 없어 `K`/`V` 를 추론할
-- 방법이 없습니다. 선언 주석(`local m: HashMap<string, number> = …`)은
-- **안 됩니다**.
--
--     local m = HashMap.New<<string, number>>()          -- 권장
--     local m = HashMap.New() :: HashMap<string, number> -- 차선
--
-- `Arr.Of()` 로 빈 배열을 만들 때와 같은 한계입니다.
const function New<K, V>(): HashMap<K, V>
	return tagged({ data = {} :: { [K]: V }, size = 0 })
end

-- 평범한 Lua 테이블에서 만듭니다. **복사합니다** — 넘긴 테이블을 나중에
-- 건드려도 `size` 가 틀어지지 않게 하려는 것입니다.
--
-- ⚠️ **테이블 리터럴을 바로 넘기면 타입이 안 잡힙니다.** `{ a = 1 }` 은
-- `{ [string]: number }` 가 아니라 **이름 붙은 속성을 가진 레코드**
-- `{ a: number }` 라서, `{ [K]: V }` 에 맞출 `K`/`V` 가 없습니다. 결과가
-- 조용히 `HashMap<unknown, unknown>` 이 되고, **그 뒤로는 키 타입이 틀려도
-- 값 타입이 틀려도 전부 조용합니다.**
--
--     local m = HashMap.FromTable<<string, number>>({ a = 1 })  -- 권장
--     local src: { [string]: number } = { a = 1 }               -- 차선
--     local m = HashMap.FromTable(src)
-- **사전을 받는 진입점**입니다 — `Arr` 만 "위치 → 값" 으로 따로 읽고, 그 밖의 테이블은
-- 키 전부를 담습니다. `table.pack(…)` 결과를 넘기면 `"n"` 도 키가 됩니다(그 테이블의 정당한
-- 키 — 2026-10-02 Gemini 지적, 그대로 둠). 리스트에서 만들려면 `Arr.FromTable`·`Arr.CloneFromTable` 을 거치세요(`HashMap.FromTable(Arr.FromTable(t))`).
const function FromTable<K, V>(tbl: { [K]: V }): HashMap<K, V>
	const copy: { [K]: V } = {}
	local count = 0
	-- `__type` 이 있으면(등록 여부와 무관 — 다른 사본의 컨테이너, 되읽은 테이블도) 이 사본의
	-- Arr 말고는 사전이 아닙니다: 내부 필드(`data`·`size`·`__type`…)가 키로 쏟아졌습니다(2026-10-06
	-- Gemini 트레이트 검토). ⚠️ 리스트 진입점(`Common.listLength`)과 **일부러 다릅니다** — 그쪽은
	-- 유효한 `n` 이 있으면 다른 사본의 Arr 도 위치로 받지만, 사전으로 읽는 이쪽은 어떤 칸이
	-- 데이터인지 모르니 거절합니다(리뷰 3라운드).
	const rawToken = rawget(tbl :: any, "__type")
	if rawToken ~= nil and rawToken ~= Trait.Types.Arr then
		const name = if type(rawToken) == "table" then rawget(rawToken, "name") else nil
		const what = if Trait.TokenOf(tbl) ~= nil
			then `a {name} container`
			elseif type(name) == "string" then `a {name} from another copy of the library (or a deserialized table)`
			else `a table with a reserved __type field ({tostring(rawToken)})`
		Common.raise(`HashMap: FromTable takes a plain table or an Arr, got {what}`)
	end
	if rawToken == Trait.Types.Arr then
		-- `Arr` 는 "위치 → 값" 으로 읽습니다 — `pairs` 로 돌면 `n` 과 태그 키까지
		-- 키가 됐습니다(M0 3라운드). 구멍은 키가 아닙니다.
		const list = tbl :: any
		for idx = 1, Common.listLength(list) do
			const value = list[idx]
			if value ~= nil then
				copy[idx :: any] = value
				count += 1
			end
		end
		return tagged({ data = copy, size = count })
	end
	for key, value in tbl do
		copy[key] = value
		count += 1
	end
	return tagged({ data = copy, size = count })
end

-- 키-값 쌍 목록에서 만듭니다. `Records()` 의 역연산입니다.
const function FromRecords<K, V>(source: { Record<K, V> }): HashMap<K, V>
	const copy: { [K]: V } = {}
	local count = 0
	-- 길이는 `Common.listLength` 규약(`n` 우선, 구멍은 건너뜀, M0 3라운드) —
	-- `pairs` 로 돌면 `Arr` 의 `n`(숫자)·태그(불리언)를 레코드로 읽어 터졌습니다.
	const records, recordCount = Common.denseList(source)
	for idx = 1, recordCount do
		const rec = records[idx]
		-- Set 과 같은 규칙: 뒤엣것이 이기고, 값이 nil 이면 삭제입니다.
		const had = copy[rec.key] ~= nil
		copy[rec.key] = rec.value
		if rec.value == nil then
			if had then
				count -= 1
			end
		elseif not had then
			count += 1
		end
	end
	return tagged({ data = copy, size = count })
end

-- ⚠️ **입양**: 이미 만들어 둔 테이블과 크기를 그대로 감쌉니다. 복사하지
-- 않고 `size` 가 맞는지도 검사하지 않습니다 — **호출자 책임**입니다.
-- `HashSet` 처럼 이 모듈 위에 얹히는 구현이 중간 테이블을 한 번 더 만들지
-- 않게 하려고 둔 문입니다. 일반 사용자는 `FromTable` 을 쓰세요.
const function Adopt<K, V>(data: { [K]: V }, size: number): HashMap<K, V>
	return tagged({ data = data, size = size })
end

const function isHashMap(value: any): boolean
	return type(value) == "table" and rawget(value, TYPE_KEY) == TOKEN
end

--#endregion

-- stylua: ignore
const HashMapModule = {
	New = New,
	FromTable = FromTable,
	FromRecords = FromRecords,
	Adopt = Adopt,
	isHashMap = isHashMap,

	-- ⭐ 모든 연산은 여기 네임스페이스 함수입니다(`HashMap.X(v, …)`) — 콜론 호출은
	-- 없습니다(질문 AB). `local` 로 받아 부르면 더 빠릅니다(perf 14·16절).
	Has = Has, GetOr = GetOr, Len = Len, Empty = Empty, Keys = Keys, Values = Values, Iter = Iter,
	Remove = Remove, Clear = Clear, Clone = Clone, Get = Get, Set = Set, Records = Records,
	Retain = Retain, GetOrInsert = GetOrInsert, GetOrInsertWith = GetOrInsertWith, Accumulate = Accumulate,
	Merge = Merge, MergeInplace = MergeInplace,
}

-- 모듈 테이블이 그대로 map 트레이트의 구현체입니다.
Trait.Impl(Trait.Map, TOKEN, HashMapModule)
Trait.Impl(Trait.Collection, TOKEN, HashMapModule)

return HashMapModule

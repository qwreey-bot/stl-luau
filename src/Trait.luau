--!strict
--[[
	Trait — 타입 토큰과 트레이트(인터페이스) 레지스트리.

	⭐ **값에는 타입 토큰 하나**(`__type` 필드), **구현은 트레이트가 듭니다**(2026-10-06,
	사용자와 설계 — quad 의 Brand 를 "값 단위" 가 아니라 "타입 단위" 로).
	- **타입 토큰**: 컨테이너 종류마다 하나인 공유 테이블(`Trait.Types.Arr`). 값은
	  `__type = Trait.Types.Arr` 로 자기 종류를 가리킵니다 — 생성 비용은 예전 문자열
	  태그(`__arr__ = true`)와 같은 필드 하나.
	- **트레이트**: 공유 테이블 하나가 `[타입 토큰] = 구현 테이블` 을 듭니다(quad Brand 의
	  `[값] = true` 자리에 구현이 들어간 모양). 모듈 테이블이 그대로 구현체입니다 —
	  함수가 바깥(서비스)에 있으니 값(엔티티)이 아니라 타입이 구현을 찾는 열쇠입니다.
	- 한 타입이 **여러 트레이트**를 구현할 수 있고(문자열 태그 하나로는 하드코딩이 필요했음),
	  **바깥에서** 자기 트레이트를 만들어 우리 타입에 붙이거나, 자기 타입을 우리 트레이트에
	  넣을 수 있습니다 — 이름(문자열)이 아니라 정체성(테이블)으로 구분하니 충돌이 없습니다.
	- 조회는 숫자·nil·userdata 를 넣어도 안전합니다(`t[nil]` 읽기는 에러가 아님).

	위조는 막지 않습니다(사용자: *"유저가 막 의도적으로 배껴간다는 솔찍히 막을 이유
	모르겠음"*). 토큰을 베껴 넣으면 그 종류로 취급됩니다. 대신 **우연한 충돌은 없습니다** —
	문자열 태그와 달리 직렬화했다 되읽은 테이블은 토큰의 정체성을 잃어 그 종류가 아닙니다.
	대가: 라이브러리 사본이 둘이면(다른 버전) 서로의 값을 그 종류로 보지 않습니다.

	## 타입 쪽 — 팬텀 마커

	런타임 조회는 토큰으로 하지만 정적 타입은 그걸 따라가지 못하니, 트레이트마다
	**타입에만 있는 필드**를 둡니다(`Types.ListMarker<E, I>` = `{ read __type: Token<any>, read __list: E,
	read __listIndex: I }` — 마커는 토큰도 요구합니다). 런타임엔
	없습니다(quad 의 `StateMarker` 와 같은 결). 덕분에 `Algorithm.Keys(m)` 가 타입 인자
	없이 `{ K }` 를 추론합니다 — 예전 `Algorithm.Keys<<HashMap<…>, K, V>>(HashMap, m)`.
]]
local Common = require("./Common")
Common.registerSource(debug.info(1, "s"))
local Types = require("./Types")

-- 타입 토큰. `N` 은 이름의 리터럴 타입 — 종류마다 구조가 달라 정적으로도 갈립니다(정의는
-- `Types` — 마커가 토큰을 요구하려고 말단에 둠).
export type Token<N> = Types.Token<N>
-- 트레이트. `I` 는 **완성 표**(구현이 준 것 + 기본 구현)의 타입 — `ImplOf` 가 돌려주는 것. `C` 는
-- 구현이 `Impl` 에 넘기는 표의 타입(필수 함수 + 재정의하고 싶은 것)이고, 기본 구현이 없는 트레이트는
-- `I` 와 같습니다. 둘이 다른 트레이트는 만든 자리에서 캐스트합니다:
-- `Trait.New<<Full>>(name, spec) :: Trait<Full, Core>`.
export type Trait<I, C = I> = {
	read name: string,
	read impls: { [any]: I },
	read required: { string }?,
	read requires: { any }?, -- 의존 트레이트들(자기 자신을 다른 인자로 가리키는 재귀 타입은 Luau 가 받지 않음)
	read defaults: Defaults?,
	read derived: { [any]: true },
	-- 타입에만 있는 필드(구현 표의 타입). **함수 타입**이라 `C` 에 불변입니다 — `read __impl: C` 로 두었더니
	-- `Impl` 에 엉뚱한 표를 넘겨도 `C` 가 조용히 넓어져 통과했습니다(읽기 마커와 같은 함정, `spikes/55`).
	read __impl: (C) -> C,
}
-- 기본 구현을 만드는 함수. `ops` 는 그 종류의 **완성 표**(살아 있는 표 — 나중에 재정의가 등록되면
-- 같은 표가 바뀜), `deps` 는 `[의존 트레이트] = 그 종류의 완성 표`. 돌려준 함수들이 완성 표의 빈
-- 자리를 채웁니다. ⚠️ 그 함수들은 필수 함수·다른 기본 구현·의존의 함수를 **부를 때 `ops`·`deps` 에서
-- 꺼내야** 합니다(여기서 지역 변수로 붙잡아 두면 나중의 재정의를 못 봅니다).
export type Defaults = (ops: any, deps: { [any]: any }) -> { [string]: any }
-- `Trait.New` 의 둘째 인자.
export type TraitSpec = {
	read required: { string }?,
	read requires: { any }?,
	read defaults: Defaults?,
}

-- 값에 타입 토큰을 싣는 필드 이름. **라이브러리 예약어**입니다. 해시 칸 배치는 이름에 따라
-- 모양마다 ±5% 엇갈렸고(`__t` 와 `__type` 을 컨테이너 여섯 모양에서 재 봄 — 어느 쪽도 고르게
-- 낫지 않음) 그래서 읽기 좋은 이름을 씁니다(사용자 결정, 2026-10-06). 모듈들은 이 문자열을
-- **리터럴로** 다시 적습니다 — 이 값을 받아 쓰면 상수 접기가 안 돼 생성이 7~11% 느렸습니다.
const TYPE_KEY = "__type"

-- `NewType`·`New` 가 만든 것만 토큰·트레이트로 칩니다(약한 키 — 버려진 사용자 토큰은
-- 수거됨). 얼린 아무 테이블, 토큰 모음 테이블, 숫자·문자열 `__type` 이 토큰 행세를 하면
-- 에러 메시지가 라이브러리 줄에서 터졌습니다(리뷰 1라운드). 만드는 일이 드물어 비용 없음.
const tokens: { [any]: true } = setmetatable({}, { __mode = "k" }) :: any
const traits: { [any]: true } = setmetatable({}, { __mode = "k" }) :: any

-- 새 타입 토큰. 사용자 컨테이너도 이걸로 만듭니다.
const function NewType(name: string): Token<string>
	if type(name) ~= "string" then
		Common.raise(`Trait: NewType needs a name string, got {typeof(name)}`)
	end
	const token = table.freeze({ name = name })
	tokens[token] = true
	return token :: any
end

-- 새 트레이트. 완성 표의 타입을 알려 주면 `ImplOf` 가 그 타입을 돌려줍니다:
--     local Show = Trait.New<<{ read Show: (any) -> string }>>("Show", { required = { "Show" } })
--
-- ⭐ `spec`(선택 — 2026-10-13, `papers/07`. Rust 의 트레이트와 같은 세 가지):
-- - **`required`** — 구현이 꼭 줘야 하는 함수 이름들. `Impl` 이 등록할 때 확인합니다(2026-10-12). 타입을
--   안 쓰는 코드가 하나를 빠뜨리면 알고리즘 안(라이브러리 줄)에서 `attempt to call a nil value` 였습니다.
-- - **`defaults`** — 기본 구현(provided method). 구현이 필수 함수만 주면 나머지는 이것이 채우고, 구현이
--   같은 이름을 주면 그것이 이깁니다(재정의). **등록할 때 한 번** 합쳐 완성 표를 만들어 두므로 호출
--   비용은 조회 하나 그대로입니다.
-- - **`requires`** — 의존 트레이트(supertrait / `where`). 그것들을 구현한 종류만 이 트레이트를 구현할 수
--   있고, 기본 구현은 의존의 완성 표를 받아 씁니다.
--
-- ⭐ **저절로 따라오는 구현**: 필수 함수가 없는 트레이트는 **등록이 필요 없습니다** — 의존을 다 갖춘
-- 종류면 처음 쓸 때 기본 구현으로 완성 표를 만들어 둡니다(Rust 의 `impl<T: A + B> C for T`). 사용자:
-- *"A가 된다면 이게 된다가 자연히 따라오는 방식 … 인터페이스 자신이 필요한건 자신이 아니까."* 컨테이너를
-- 만드는 쪽은 자기가 아는 트레이트만 등록하고, 나중에 누가 새 트레이트를 더해도 컨테이너를 고치지 않습니다.
const function New<I>(name: string, spec: TraitSpec?): Trait<I, I>
	if type(name) ~= "string" then
		Common.raise(`Trait: New needs a name string, got {typeof(name)}`)
	end
	if spec ~= nil and type(spec) ~= "table" then
		Common.raise(`Trait: New needs a spec table (required / requires / defaults), got {typeof(spec)}`)
	end
	local required: { string }? = nil
	local requires: { any }? = nil
	local defaults: Defaults? = nil
	if spec ~= nil then
		const givenRequired: any = rawget(spec :: any, "required")
		if givenRequired ~= nil then
			if type(givenRequired) ~= "table" then
				Common.raise(`Trait: New needs a list of required function names, got {typeof(givenRequired)}`)
			end
			-- 사본을 손으로 만듭니다 — 넘긴 목록을 나중에 바꿔도 트레이트는 그대로이고, `table.clone` 은
			-- 보호된 메타테이블을 단 목록에서 라이브러리 줄 에러였습니다(리뷰).
			const names: { string } = {}
			for _, fnName in givenRequired do
				if type(fnName) ~= "string" then
					Common.raise(`Trait: New needs a list of required function names, got a {typeof(fnName)} in it`)
				end
				table.insert(names, fnName)
			end
			required = table.freeze(names)
		end
		const givenRequires: any = rawget(spec :: any, "requires")
		if givenRequires ~= nil then
			if type(givenRequires) ~= "table" then
				Common.raise(`Trait: New needs a list of traits in requires, got {typeof(givenRequires)}`)
			end
			-- 이미 만들어진 트레이트만 요구할 수 있으니 의존이 돌아 물릴 수 없습니다.
			const list: { any } = {}
			for _, dep in givenRequires do
				if not traits[dep] then
					Common.raise(`Trait: New needs a list of traits in requires, got a {typeof(dep)} in it`)
				end
				table.insert(list, dep)
			end
			requires = table.freeze(list)
		end
		const givenDefaults: any = rawget(spec :: any, "defaults")
		if givenDefaults ~= nil then
			if type(givenDefaults) ~= "function" then
				Common.raise(`Trait: New needs a function for defaults, got {typeof(givenDefaults)}`)
			end
			defaults = givenDefaults
		end
	end
	-- `impls` 는 **약한 키** — 버린 사용자 토큰은 등록했어도 수거됩니다(아무도 그 토큰을 쥐지
	-- 않으면 조회될 일도 없음). 내장 토큰은 `Trait.Types` 가 붙잡습니다. ⚠️ Luau 의 약한 키는
	-- ephemeron 이 아니라 구현 테이블이 토큰을 참조하면 남습니다(리뷰 2라운드 실측).
	-- `derived` 는 "등록 없이 저절로 만들어진" 종류의 표시입니다(그 위에는 재정의를 등록할 수 있음).
	const trait = {
		name = name,
		impls = setmetatable({}, { __mode = "k" }),
		required = required,
		requires = requires,
		defaults = defaults,
		derived = setmetatable({}, { __mode = "k" }),
	}
	traits[trait] = true
	return trait :: any
end

-- 그 종류의 의존 표들(`[의존 트레이트] = 완성 표`). 하나라도 없으면 nil 과 그 트레이트.
local resolve: (trait: any, token: any) -> any
const function depsOf(trait: any, token: any): ({ [any]: any }?, any)
	const deps: { [any]: any } = {}
	const requires = trait.requires
	if requires then
		for _, dep in requires do
			const depImpl = resolve(dep, token)
			if depImpl == nil then
				return nil, dep
			end
			deps[dep] = depImpl
		end
	end
	return deps, nil
end

-- 완성 표의 빈 자리를 기본 구현으로 채웁니다(기본 구현이 없는 트레이트면 아무 일도 안 함).
const function fillDefaults(defaults: Defaults?, full: { [string]: any }, deps: { [any]: any })
	if defaults == nil then
		return
	end
	for fnName, fn in defaults(full, deps) do
		if full[fnName] == nil then
			full[fnName] = fn
		end
	end
end

-- 그 종류의 완성 표. 등록된 것이 없어도 **필수 함수가 없는** 트레이트면 의존만으로 만들어 둡니다
-- (저절로 따라오는 구현). 의존도 기본 구현도 없는 트레이트는 그럴 것이 없으니 nil.
function resolve(trait: any, token: any): any
	const found = trait.impls[token]
	if found ~= nil then
		return found
	end
	if not tokens[token] or trait.required ~= nil and #trait.required > 0 then
		return nil
	end
	if trait.requires == nil and trait.defaults == nil then
		return nil
	end
	const deps = depsOf(trait, token)
	if deps == nil then
		return nil
	end
	const full: { [string]: any } = {}
	fillDefaults(trait.defaults, full, deps)
	trait.impls[token] = full
	trait.derived[token] = true
	return full
end

-- `token` 종류가 `trait` 를 구현한다고 등록합니다. 보통 모듈을 불러올 때 한 번.
-- **같은 (트레이트, 토큰) 을 두 번 등록하면 에러**입니다(2026-10-06, 제가 정함 — 되돌리기
-- 쉬움): 덮어쓰기를 허용하면 내장 구현도 조용히 바뀌어 다른 모듈의 `Algorithm` 이 전역으로
-- 달라집니다. 바꾸고 싶으면 자기 트레이트를 만드세요.
-- ⭐ 단 **저절로 따라온 구현 위에는 등록할 수 있습니다**(2026-10-13 사용자 결정 — 빠른 판을 나중에
-- 얹는 길). 그때는 완성 표를 새로 만들지 않고 **같은 표를 제자리에서** 고칩니다 — 그 표를 이미 들고
-- 있는 쪽(의존으로 받은 다른 트레이트의 기본 구현 포함)도 새 함수를 보게 됩니다.
--
-- 저장되는 것: 기본 구현도 의존도 없는 트레이트는 **넘긴 표 그대로**(모듈 테이블이 곧 구현체), 그 밖에는
-- "넘긴 것 + 기본 구현" 을 합친 새 표입니다.
const function Impl<I, C>(trait: Trait<I, C>, token: Token<any>, impl: C)
	if not traits[trait] then
		Common.raise(`Trait: Impl needs a trait (from Trait.New), got {typeof(trait)}`)
	end
	if not tokens[token] then
		Common.raise(`Trait: Impl needs a type token (from Trait.NewType), got {typeof(token)}`)
	end
	if impl == nil then
		Common.raise(`Trait: Impl needs an implementation for {trait.name}`)
	end
	const impls = trait.impls :: any
	const derived = trait.derived :: any
	const existing = impls[token]
	if existing ~= nil and not derived[token] then
		Common.raise(`Trait: {token.name} already implements {trait.name}`)
	end
	const required = trait.required
	const merges = trait.defaults ~= nil or trait.requires ~= nil
	if required or merges then
		if type(impl) ~= "table" then
			Common.raise(`Trait: Impl needs a table of functions for {trait.name}, got {typeof(impl)}`)
		end
	end
	if required then
		for _, fnName in required do
			if type((impl :: any)[fnName]) ~= "function" then
				Common.raise(`Trait: {token.name} is missing {fnName} for {trait.name}`)
			end
		end
	end
	if not merges then
		impls[token] = impl
		return
	end
	const deps, missing = depsOf(trait, token)
	if deps == nil then
		Common.raise(`Trait: {token.name} must implement {missing.name} to implement {trait.name}`)
	end
	if existing ~= nil then
		-- 저절로 따라온 표 위에 재정의 — 같은 표를 고칩니다.
		for fnName, fn in impl :: any do
			existing[fnName] = fn
		end
		derived[token] = nil
		return
	end
	const full: { [string]: any } = {}
	for fnName, fn in impl :: any do
		full[fnName] = fn
	end
	fillDefaults((trait :: any).defaults, full, deps :: any)
	impls[token] = full
end

-- 값의 타입 토큰. 테이블이 아니거나, `__type` 이 없거나 토큰이 아니면 nil.
const function TokenOf(value: any): Token<any>?
	if type(value) ~= "table" then
		return nil
	end
	const token = rawget(value, TYPE_KEY)
	return if tokens[token] then token :: any else nil
end

-- 값의 종류가 `trait` 를 구현하면 그 구현 테이블, 아니면 nil.
const function ImplOf<I, C>(trait: Trait<I, C>, value: any): I?
	if not traits[trait] then
		Common.raise(`Trait: ImplOf needs a trait (from Trait.New), got {typeof(trait)}`)
	end
	-- `impls[nil]` 읽기는 에러가 아닙니다 — 토큰이 없으면 그대로 nil. 등록된 것이 없으면 저절로
	-- 따라오는 구현을 찾습니다(있으면 만들어 둠 — 그 뒤로는 첫 줄의 조회 하나).
	const token: any = TokenOf(value)
	return (trait.impls :: any)[token] or resolve(trait, token)
end

const function Implements<I, C>(trait: Trait<I, C>, value: any): boolean
	if not traits[trait] then
		Common.raise(`Trait: Implements needs a trait (from Trait.New), got {typeof(trait)}`)
	end
	const token: any = TokenOf(value)
	return ((trait.impls :: any)[token] or resolve(trait, token)) ~= nil
end

-- 값에 타입 토큰을 붙입니다. 사용자 컨테이너의 생성자가 씁니다(라이브러리 모듈은 상수
-- 접기를 받으려고 `"__type"` 리터럴로 직접 붙입니다).
const function Stamp<T>(value: T, token: Token<any>): T
	if not tokens[token] then
		Common.raise(`Trait: Stamp needs a type token (from Trait.NewType), got {typeof(token)}`)
	end
	if type(value) ~= "table" or table.isfrozen(value :: any) then
		Common.raise(`Trait: Stamp needs a table that is not frozen, got {typeof(value)}`)
	end
	(value :: any)[TYPE_KEY] = token
	return value
end

--[[ 라이브러리의 트레이트와 타입 토큰 ]]

-- ⭐ 리스트의 기본 구현(2026-10-13, `papers/07` 2단계): 위치 프리미티브 다섯만 구현하면 읽기 알고리즘이
-- 따라옵니다 — `Deque` 와 사용자 리스트(위치가 노드여도)가 이것을 받습니다. 원소마다 프리미티브를
-- 간접 호출하므로 직접 구현의 1.1~3.8배입니다(`papers/07` 4절) — 빨라야 하는 종류는 같은 이름의 함수로
-- 재정의합니다(`Arr` 는 모듈을 그대로 등록해 전부 재정의).
-- 프리미티브는 **부를 때** `ops` 에서 꺼냅니다(나중에 재정의가 등록돼도 그것을 씀).
const function listDefaults(ops: any): { [string]: any }
	return {
		Fold = function(self: any, init: any, fn: (any, any, any) -> any): any
			const get, nextIndex = ops.Get, ops.NextIndex
			local acc, idx = init, ops.FirstIndex(self)
			while idx ~= nil do
				acc = fn(acc, get(self, idx), idx)
				idx = nextIndex(self, idx)
			end
			return acc
		end,
		Find = function(self: any, pred: (any, any) -> boolean): (any, any)
			const get, nextIndex = ops.Get, ops.NextIndex
			local idx = ops.FirstIndex(self)
			while idx ~= nil do
				const item = get(self, idx)
				if pred(item, idx) then
					return item, idx
				end
				idx = nextIndex(self, idx)
			end
			return nil, nil
		end,
		IndexOf = function(self: any, item: any): any
			const get, nextIndex = ops.Get, ops.NextIndex
			local idx = ops.FirstIndex(self)
			while idx ~= nil do
				if get(self, idx) == item then
					return idx
				end
				idx = nextIndex(self, idx)
			end
			return nil
		end,
		-- 다른 기본 구현을 부르는 것도 `ops` 로 — 구현이 `IndexOf` 를 재정의했으면 그 판을 씁니다.
		Contains = function(self: any, item: any): boolean
			return ops.IndexOf(self, item) ~= nil
		end,
		Count = function(self: any, pred: ((any, any) -> boolean)?): number
			const get, nextIndex = ops.Get, ops.NextIndex
			local total, idx = 0, ops.FirstIndex(self)
			if pred == nil then
				while idx ~= nil do
					total += 1
					idx = nextIndex(self, idx)
				end
			else
				while idx ~= nil do
					if pred(get(self, idx), idx) then
						total += 1
					end
					idx = nextIndex(self, idx)
				end
			end
			return total
		end,
		Some = function(self: any, pred: (any, any) -> boolean): boolean
			const get, nextIndex = ops.Get, ops.NextIndex
			local idx = ops.FirstIndex(self)
			while idx ~= nil do
				if pred(get(self, idx), idx) then
					return true
				end
				idx = nextIndex(self, idx)
			end
			return false
		end,
		Every = function(self: any, pred: (any, any) -> boolean): boolean
			const get, nextIndex = ops.Get, ops.NextIndex
			local idx = ops.FirstIndex(self)
			while idx ~= nil do
				if not pred(get(self, idx), idx) then
					return false
				end
				idx = nextIndex(self, idx)
			end
			return true
		end,
	}
end

const List = New<<Types.ListFull<any, any, any>>>("List", {
	required = { "Get", "FirstIndex", "LastIndex", "NextIndex", "PrevIndex" },
	defaults = listDefaults,
}) :: Trait<Types.ListFull<any, any, any>, Types.ListOps<any, any, any>>
const Map = New<<Types.MapOps<any, any, any>>>("Map", { required = { "Get", "Set", "Has", "Remove", "Iter" } })
const Set = New<<Types.SetOps<any, any>>>("Set", { required = { "Add", "Has", "Remove", "Items" } })
-- 원소를 담는 것 전부(리스트·맵·셋·힙) — 크기와 비우기(2026-10-12). 한 종류가 `List` 와 `Collection` 처럼
-- 여러 트레이트를 구현합니다.
const Collection = New<<Types.CollectionOps<any>>>("Collection", { required = { "Len", "Clear" } })

const BuiltinTypes = table.freeze({
	Arr = NewType("Arr") :: Token<"Arr">,
	HashMap = NewType("HashMap") :: Token<"HashMap">,
	HashSet = NewType("HashSet") :: Token<"HashSet">,
	TreeMap = NewType("TreeMap") :: Token<"TreeMap">,
	TreeSet = NewType("TreeSet") :: Token<"TreeSet">,
	Heap = NewType("Heap") :: Token<"Heap">,
	Fut = NewType("Fut") :: Token<"Fut">,
	Deque = NewType("Deque") :: Token<"Deque">,
})

-- stylua: ignore
return {
	TYPE_KEY = TYPE_KEY,
	NewType = NewType, New = New, Impl = Impl,
	TokenOf = TokenOf, ImplOf = ImplOf, Implements = Implements, Stamp = Stamp,
	List = List, Map = Map, Set = Set, Collection = Collection,
	Types = BuiltinTypes,
}

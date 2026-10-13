--!strict
--[[
	Trait — 타입 토큰과 트레이트 **시스템**.

	여기에는 장치만 있습니다: 토큰(`NewType`·`TokenOf`·`Stamp`), 트레이트 만들기(`New`), 구현 등록·조회
	(`Impl`·`ImplOf`·`Implements`), 트레이트 모듈을 짜는 도구(`Dispatch`·`Module`). **트레이트 하나하나**
	(`List`·`Map`·`Set`·`Collection` — 계약 타입, 마커, 기본 구현, 종류를 모르는 코드의 진입점)는
	`src/Traits/` 에 파일 하나씩 있습니다(2026-10-13 사용자: *"trait 은 trait 시스템만 담고 … 인터페이스
	파일처럼"*).

	⭐ **값에는 타입 토큰 하나**(`__type` 필드), **구현은 트레이트가 듭니다**(2026-10-06,
	사용자와 설계 — quad 의 Brand 를 "값 단위" 가 아니라 "타입 단위" 로).
	- **타입 토큰**: 컨테이너 종류마다 하나인 공유 테이블 — **그 종류의 모듈이 만들어 듭니다**
	  (`const TOKEN = Trait.NewType("Arr")`, 밖에서는 `Arr.Token`). 값은 `__type = 토큰` 으로 자기 종류를
	  가리킵니다 — 생성 비용은 예전 문자열 태그(`__arr__ = true`)와 같은 필드 하나.
	- **트레이트**: 공유 테이블 하나가 `[타입 토큰] = 구현 테이블` 을 듭니다(quad Brand 의
	  `[값] = true` 자리에 구현이 들어간 모양). 함수가 바깥(서비스)에 있으니 값(엔티티)이 아니라
	  타입이 구현을 찾는 열쇠입니다.
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
	**타입에만 있는 필드**를 둡니다(`List.Marker<E, I>` = `{ read __type: Token<any>, read __list: E,
	read __listIndex: I }` — 마커는 토큰도 요구합니다). 런타임엔 없습니다(quad 의 `StateMarker` 와
	같은 결). 덕분에 `Map.Keys(m)` 가 타입 인자 없이 `{ K }` 를 추론합니다.
]]
local Common = require("./Common")
Common.registerSource(debug.info(1, "s"))

-- 타입 토큰(`NewType` 이 만듦). `N` 은 이름의 리터럴 타입 — 종류마다 구조가 달라 정적으로도 갈립니다.
-- 트레이트 마커가 이것을 요구합니다 — 토큰 없는 평범한 테이블이 마커만 흉내 내면 타입은 통과하고
-- 런타임에 터졌습니다(2026-10-06 Gemini 트레이트 검토).
export type Token<N> = { read name: N }
-- 트레이트. `I` 는 **완성 표**(구현이 준 것 + 기본 구현)의 타입 — `ImplOf` 가 돌려주는 것. `C` 는
-- 구현이 `Impl` 에 넘기는 표의 타입이고, 기본 구현이 없는 트레이트는 `I` 와 같습니다. 둘이 다른 트레이트는
-- 만든 자리에서 캐스트합니다: `Trait.New<<Full>>(name, spec) :: Trait<Full, Core>`.
-- ⚠️ **`Core` 는 "필수 함수 + 재정의할 수 있는 함수는 선택 필드(`?`)"** 로 적으세요(`Traits/List` 의 `Impl` 이 그 모양).
-- 필수만 적으면 재정의 자리는 검사되지 않습니다(폭 서브타이핑 — `Describe = "문자열"` 이 0건이고 런타임에
-- `attempt to call a string value`, 리뷰). ⚠️ 그 캐스트 자체는 검사되지 않습니다(새 솔버는 테이블 → 테이블
-- 캐스트를 안 봄): `Full` 이 "필수 + 기본 구현이 채우는 것" 과 맞는지는 테스트로 지키세요.
-- 트레이트를 인자로 받는 제네릭은 `<I, C>(t: Trait<I, C>)` 로 — `Trait<I>` 하나로 적으면 기본 구현 달린
-- 트레이트를 못 받습니다.
export type Trait<I, C = I> = {
	read name: string,
	read impls: { [any]: I },
	read required: { string }?,
	read dependencies: { any }?, -- 의존 트레이트들(자기 자신을 다른 인자로 가리키는 재귀 타입은 Luau 가 받지 않음)
	read defaults: Defaults?,
	read derived: { [any]: true },
	read derivable: boolean, -- 등록 없이 저절로 따라올 수 있는 트레이트인가(`New` 가 한 번 계산)
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
	read dependencies: { any }?,
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
-- 약한 키 + **줄어들 수 있음**(`s`) — `k` 만이면 항목이 수거돼도 칸 수가 안 줄어, 종류를 많이 만들었다 버리는
-- 쓰임에서 메모리가 남았습니다(리뷰 실측: 40만 종에 +8~32MB → `ks` 로 0).
const WEAK_KEYS = table.freeze({ __mode = "ks" })
const tokens: { [any]: true } = setmetatable({}, WEAK_KEYS) :: any
const traits: { [any]: true } = setmetatable({}, WEAK_KEYS) :: any

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
-- - **`dependencies`** — 의존 트레이트(supertrait / `where`). 그것들을 구현한 종류만 이 트레이트를 구현할 수
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
		Common.raise(`Trait: New needs a spec table (required / dependencies / defaults), got {typeof(spec)}`)
	end
	local required: { string }? = nil
	local dependencies: { any }? = nil
	local defaults: Defaults? = nil
	if spec ~= nil then
		-- 모르는 필드는 거절합니다 — 한 글자 오타(`require = …`)나 옛 호출 모양(이름 목록을 그대로)이 조용히
		-- 통과해 필수 검사·의존이 사라졌습니다(오타 난 의존은 "의존 없음" 으로 읽혀 아무 값에나 따라옴, 리뷰).
		for field in spec :: any do
			if field ~= "required" and field ~= "dependencies" and field ~= "defaults" then
				Common.raise(
					`Trait: New got an unknown spec field {tostring(field)} (expected required, dependencies or defaults)`
				)
			end
		end
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
		const givenDependencies: any = rawget(spec :: any, "dependencies")
		if givenDependencies ~= nil then
			if type(givenDependencies) ~= "table" then
				Common.raise(`Trait: New needs a list of traits in dependencies, got {typeof(givenDependencies)}`)
			end
			-- 이미 만들어진 트레이트만 요구할 수 있으니 의존이 돌아 물릴 수 없습니다.
			-- 숫자 루프로 읽고 **빈 칸·빈 목록을 거절**합니다 — 오타 난 이름(`{ Lisst }`)은 `nil` 이라 빈 목록과
			-- 구별이 안 되고, 그러면 "의존 없음" 으로 읽혀 아무 종류에나 따라왔습니다(2라운드 리뷰).
			const list: { any } = {}
			const count = rawlen(givenDependencies)
			if count == 0 then
				Common.raise(
					"Trait: New got an empty dependencies list (a misspelled trait name reads as nil) — leave the field out for no dependencies"
				)
			end
			for at = 1, count do
				const dep = rawget(givenDependencies, at)
				if not traits[dep] then
					Common.raise(`Trait: New needs a list of traits in dependencies, got a {typeof(dep)} at {at}`)
				end
				list[at] = dep
			end
			dependencies = table.freeze(list)
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
	-- 않으면 조회될 일도 없음). 내장 토큰은 각 컨테이너 모듈이 붙잡습니다(`Arr.Token`). ⚠️ Luau 의 약한 키는
	-- ephemeron 이 아니라 구현 테이블이 토큰을 참조하면 남습니다(리뷰 2라운드 실측).
	-- `derived` 는 "등록 없이 저절로 만들어진" 종류의 표시입니다(그 위에는 재정의를 등록할 수 있음).
	-- 저절로 따라올 수 있는가: 필수 함수가 없고, 따라올 것(의존이나 기본 구현)이 있을 때.
	const derivable = (required == nil or #required == 0) and (dependencies ~= nil or defaults ~= nil)
	const trait = {
		name = name,
		impls = setmetatable({}, WEAK_KEYS),
		required = required,
		dependencies = dependencies,
		defaults = defaults,
		derived = setmetatable({}, WEAK_KEYS),
		derivable = derivable,
	}
	traits[trait] = true
	return trait :: any
end

-- 그 종류의 의존 표들(`[의존 트레이트] = 완성 표`). 하나라도 없으면 nil 과 그 트레이트.
local resolve: (trait: any, token: any) -> any
const function depsOf(trait: any, token: any): ({ [any]: any }?, any)
	const deps: { [any]: any } = {}
	const dependencies = trait.dependencies
	if dependencies then
		for _, dep in dependencies do
			const depImpl = resolve(dep, token)
			if depImpl == nil then
				return nil, dep
			end
			deps[dep] = depImpl
		end
	end
	return deps, nil
end

-- 구현 표에서 이름 하나를 찾습니다: 자기 키, 없으면 **`__index` 가 테이블인 사슬**을 따라(클래스처럼 물려받은
-- 모듈). `impl[name]` 으로 읽지 않습니다 — `__index` 가 **함수**인 표에서, 없는 멤버를 읽으면 에러를 내는
-- 엄격한 모듈은 기본 구현 이름을 묻는 순간 라이브러리 줄에서 죽었고(프리미티브만 구현한 모듈이 등록 불가),
-- 값을 지어내는 프록시는 기본 구현을 전부 갈아치웠습니다(2라운드 리뷰). 그런 표는 자기 키만 봅니다.
const function lookup(impl: any, name: string): any
	local cursor = impl
	for _ = 1, 100 do -- Lua 의 `__index` 사슬 한도와 같음(돌아 물린 사슬 방지)
		const own = rawget(cursor, name)
		if own ~= nil then
			return own
		end
		const meta = getmetatable(cursor)
		const parent = if type(meta) == "table" then rawget(meta, "__index") else nil
		if type(parent) ~= "table" then
			return nil
		end
		cursor = parent
	end
	return nil
end

-- 완성 표의 빈 자리를 기본 구현으로 채웁니다(기본 구현이 없는 트레이트면 아무 일도 안 함).
-- `impl` 은 구현이 넘긴 표(저절로 만들 땐 nil) — 기본 구현과 같은 이름을 **물려받고** 있으면(`lookup`)
-- 그것이 재정의입니다(자기 키만 옮기면 물려받은 것이 조용히 기본 구현에 졌습니다, 리뷰).
const function fillDefaults(trait: any, impl: any, full: { [string]: any }, deps: { [any]: any })
	const defaults: Defaults? = trait.defaults
	if defaults == nil then
		return
	end
	const provided: any = defaults(full, deps)
	if type(provided) ~= "table" then
		-- `return` 을 빠뜨린 기본 구현 — 라이브러리 줄의 `attempt to iterate over a nil value` 였습니다(리뷰)
		Common.raise(`Trait: defaults of {trait.name} must return a table of functions, got {typeof(provided)}`)
	end
	for fnName, fn in provided do
		if full[fnName] == nil then
			const inherited = if impl ~= nil then lookup(impl, fnName) else nil
			full[fnName] = if inherited ~= nil then inherited else fn
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
	if not trait.derivable or not tokens[token] then
		return nil
	end
	const deps = depsOf(trait, token)
	if deps == nil then
		return nil
	end
	const full: { [string]: any } = {}
	fillDefaults(trait, nil, full, deps)
	trait.impls[token] = full
	trait.derived[token] = true
	return full
end

-- `token` 종류가 `trait` 를 구현한다고 등록합니다. 보통 모듈을 불러올 때 한 번.
-- **같은 (트레이트, 토큰) 을 두 번 등록하면 에러**입니다(2026-10-06, 제가 정함 — 되돌리기
-- 쉬움): 덮어쓰기를 허용하면 내장 구현도 조용히 바뀌어 다른 모듈의 `List.IndexOf(…)` 가 전역으로
-- 달라집니다. 바꾸고 싶으면 자기 트레이트를 만드세요.
-- ⭐ 단 **저절로 따라온 구현 위에는 등록할 수 있습니다**(2026-10-13 사용자 결정 — 빠른 판을 나중에
-- 얹는 길). 그때는 완성 표를 새로 만들지 않고 **같은 표를 제자리에서** 고칩니다 — 그 표를 이미 들고
-- 있는 쪽(의존으로 받은 다른 트레이트의 기본 구현 포함)도 새 함수를 보게 됩니다.
--
-- 저장되는 것: 기본 구현도 의존도 없는 트레이트는 **넘긴 표 그대로**(모듈 테이블이 곧 구현체), 그 밖에는
-- 새 표입니다: 넘긴 표의 **자기 키 전부** + 필수·기본 구현 이름 중 물려받은 것(`__index` 가 테이블인 사슬) +
-- 기본 구현. (그 밖의 이름으로 물려받은 함수는 옮기지 않습니다 — 완성 표는 트레이트의 함수를 부르는 곳.)
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
	const merges = trait.defaults ~= nil or trait.dependencies ~= nil
	if required or merges then
		if type(impl) ~= "table" then
			Common.raise(`Trait: Impl needs a table of functions for {trait.name}, got {typeof(impl)}`)
		end
	end
	if required then
		for _, fnName in required do
			if type(lookup(impl, fnName)) ~= "function" then
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
		-- 저절로 따라온 표 위에 재정의 — 같은 표를 고칩니다. 구현이 `__index` 로 물려받은 것도 재정의이니,
		-- 자기 키를 옮긴 뒤 표에 이미 있는 이름들을 구현에서 한 번 더 찾습니다.
		for fnName, fn in impl :: any do
			existing[fnName] = fn
		end
		for fnName in existing do
			const inherited = lookup(impl, fnName)
			if inherited ~= nil then
				existing[fnName] = inherited
			end
		end
		derived[token] = nil
		return
	end
	-- 넘긴 표는 고치지 않습니다(모듈 테이블을 그대로 넘겨도 모듈에 기본 구현이 써지지 않고, 얼린 표도 됨).
	const full: { [string]: any } = {}
	for fnName, fn in impl :: any do
		full[fnName] = fn
	end
	if required then
		-- 필수 함수는 `lookup` 으로 — 위의 검사가 물려받은 것도 인정했으니 완성 표에도 그렇게 넣습니다
		-- (자기 키만 옮겼더니 물려받은 필수 함수가 완성 표에 없었습니다, 리뷰).
		for _, fnName in required do
			if full[fnName] == nil then
				full[fnName] = lookup(impl, fnName)
			end
		end
	end
	fillDefaults(trait, impl, full, deps :: any)
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
	const found = (trait.impls :: any)[token]
	-- 저절로 따라올 수 없는 트레이트는 여기서 끝(빗나갈 때마다 만들기 경로를 타 1.6~1.9배였습니다, 리뷰)
	if found ~= nil or not (trait :: any).derivable then
		return found
	end
	return resolve(trait, token)
end

const function Implements<I, C>(trait: Trait<I, C>, value: any): boolean
	if not traits[trait] then
		Common.raise(`Trait: Implements needs a trait (from Trait.New), got {typeof(trait)}`)
	end
	const token: any = TokenOf(value)
	if (trait.impls :: any)[token] ~= nil then
		return true
	end
	return (trait :: any).derivable and resolve(trait, token) ~= nil
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

--[[ 트레이트 모듈을 짜는 도구 — `src/Traits/*` 와 사용자 트레이트가 씁니다 ]]

-- 구현을 못 찾았을 때. 저절로 따라오는 트레이트면 여기서 만들어지고, 아니면 사용자 줄 에러.
const function dispatchMiss(trait: any, value: any, who: string): any
	const derived = if trait.derivable then resolve(trait, TokenOf(value)) else nil
	if derived ~= nil then
		return derived
	end
	-- 셋으로 가릅니다(리뷰 2라운드 — 반대로 안내했음): 이 사본의 토큰인데 구현이 없음 /
	-- 이름 있는 토큰 모양이지만 이 사본이 모름(다른 사본의 라이브러리, 되읽은 테이블) / 토큰 없음.
	const token = TokenOf(value)
	const raw = if type(value) == "table" then rawget(value, TYPE_KEY) else nil
	const rawName = if type(raw) == "table" then rawget(raw :: any, "name") else nil
	const traitName: string = trait.name
	if token then
		return Common.raise(`{traitName}: {who} needs a {traitName} — {token.name} does not implement {traitName}`)
	elseif type(rawName) == "string" then
		return Common.raise(
			`{traitName}: {who} needs a {traitName} — got a {rawName} this library does not know (from another copy of the library, or a deserialized table?)`
		)
	end
	return Common.raise(`{traitName}: {who} needs a {traitName} (got {typeof(value)} without a type token)`)
end

-- 값의 종류가 구현한 `trait` 의 완성 표. 없으면 **사용자 줄 에러**(`"List: IndexOf needs a List — …"`) —
-- 종류를 모르는 코드의 진입점이 씁니다: `Dispatch(List, list, "IndexOf").IndexOf(list, item)`.
-- `who` 는 에러 메시지에 적을 진입점 이름. `ImplOf` 와 달리 트레이트 인자를 검사하지 않습니다(진입점이
-- 자기 트레이트를 넘기는 자리 — 원소 수와 무관하게 호출당 조회 하나, perf 21절).
const function Dispatch<I, C>(trait: Trait<I, C>, value: any, who: string): I
	const impl = if type(value) == "table" then (trait.impls :: any)[rawget(value, TYPE_KEY)] else nil
	if impl == nil then
		return dispatchMiss(trait, value, who)
	end
	return impl
end

-- 트레이트 객체에 **진입점 함수들**을 얹어 돌려줍니다 — 트레이트 파일이 내보내는 모듈이 곧 트레이트라
-- `Trait.Impl(List, 토큰, 구현)` 과 `List.IndexOf(값, x)` 가 같은 이름으로 됩니다(Rust 의 `List::index_of`).
-- 트레이트의 자기 필드(`name`·`impls` …)와 겹치는 이름은 에러.
const function Module<T, E>(trait: T, entries: E): T & E
	if not traits[trait] then
		Common.raise(`Trait: Module needs a trait (from Trait.New), got {typeof(trait)}`)
	end
	if type(entries) ~= "table" then
		Common.raise(`Trait: Module needs a table of entry functions, got {typeof(entries)}`)
	end
	for entryName, fn in entries :: any do
		if rawget(trait :: any, entryName) ~= nil then
			Common.raise(`Trait: Module got an entry named {tostring(entryName)}, which the trait already has`)
		end
		(trait :: any)[entryName] = fn
	end
	return trait :: any
end

-- stylua: ignore
return {
	TYPE_KEY = TYPE_KEY,
	NewType = NewType, New = New, Impl = Impl,
	TokenOf = TokenOf, ImplOf = ImplOf, Implements = Implements, Stamp = Stamp,
	Dispatch = Dispatch, Module = Module,
}

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
-- 트레이트. `I` 는 구현 테이블의 타입(팬텀 — `impls` 의 값 타입).
export type Trait<I> = { read name: string, read impls: { [any]: I }, read required: { string }? }

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

-- 새 트레이트. 구현 테이블의 타입을 알려 주면 `ImplOf` 가 그 타입을 돌려줍니다:
--     local Show = Trait.New<<{ read Show: (any) -> string }>>("Show", { "Show" })
--
-- `required`(선택)는 구현이 꼭 가져야 하는 함수 이름들입니다 — `Impl` 이 등록할 때 확인합니다
-- (2026-10-12). 타입을 안 쓰는 코드가 함수 하나를 빠뜨리면 알고리즘 안(라이브러리 줄)에서
-- `attempt to call a nil value` 로 죽었습니다 — `MapOps` 를 넓히자 예전 구현들이 그렇게 됐습니다.
const function New<I>(name: string, required: { string }?): Trait<I>
	if type(name) ~= "string" then
		Common.raise(`Trait: New needs a name string, got {typeof(name)}`)
	end
	if required ~= nil then
		if type(required) ~= "table" then
			Common.raise(`Trait: New needs a list of required function names, got {typeof(required)}`)
		end
		-- 사본을 손으로 만듭니다 — 넘긴 목록을 나중에 바꿔도 트레이트는 그대로이고, `table.clone` 은
		-- 보호된 메타테이블을 단 목록에서 라이브러리 줄 에러였습니다(리뷰).
		const names: { string } = {}
		for _, fnName in required do
			if type(fnName) ~= "string" then
				Common.raise(`Trait: New needs a list of required function names, got a {typeof(fnName)} in it`)
			end
			table.insert(names, fnName)
		end
		required = table.freeze(names)
	end
	-- `impls` 는 **약한 키** — 버린 사용자 토큰은 등록했어도 수거됩니다(아무도 그 토큰을 쥐지
	-- 않으면 조회될 일도 없음). 내장 토큰은 `Trait.Types` 가 붙잡습니다. ⚠️ Luau 의 약한 키는
	-- ephemeron 이 아니라 구현 테이블이 토큰을 참조하면 남습니다(리뷰 2라운드 실측).
	const trait = { name = name, impls = setmetatable({}, { __mode = "k" }), required = required }
	traits[trait] = true
	return trait :: any
end

-- `token` 종류가 `trait` 를 구현한다고 등록합니다. 보통 모듈을 불러올 때 한 번.
-- **같은 (트레이트, 토큰) 을 두 번 등록하면 에러**입니다(2026-10-06, 제가 정함 — 되돌리기
-- 쉬움): 덮어쓰기를 허용하면 내장 구현도 조용히 바뀌어 다른 모듈의 `Algorithm` 이 전역으로
-- 달라집니다. 바꾸고 싶으면 자기 트레이트를 만드세요.
const function Impl<I>(trait: Trait<I>, token: Token<any>, impl: I)
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
	if impls[token] ~= nil then
		Common.raise(`Trait: {token.name} already implements {trait.name}`)
	end
	const required = trait.required
	if required then
		if type(impl) ~= "table" then
			Common.raise(`Trait: Impl needs a table of functions for {trait.name}, got {typeof(impl)}`)
		end
		for _, fnName in required do
			if type((impl :: any)[fnName]) ~= "function" then
				Common.raise(`Trait: {token.name} is missing {fnName} for {trait.name}`)
			end
		end
	end
	impls[token] = impl
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
const function ImplOf<I>(trait: Trait<I>, value: any): I?
	if not traits[trait] then
		Common.raise(`Trait: ImplOf needs a trait (from Trait.New), got {typeof(trait)}`)
	end
	-- `impls[nil]` 읽기는 에러가 아닙니다 — 토큰이 없으면 그대로 nil.
	return trait.impls[TokenOf(value) :: any]
end

const function Implements<I>(trait: Trait<I>, value: any): boolean
	if not traits[trait] then
		Common.raise(`Trait: Implements needs a trait (from Trait.New), got {typeof(trait)}`)
	end
	return trait.impls[TokenOf(value) :: any] ~= nil
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

const List = New<<Types.ListOps<any, any, any>>>("List", { "Get", "FirstIndex", "LastIndex", "NextIndex", "PrevIndex" })
const Map = New<<Types.MapOps<any, any, any>>>("Map", { "Get", "Set", "Has", "Remove", "Records", "Iter" })
const Set = New<<Types.SetOps<any, any>>>("Set", { "Add", "Has", "Remove", "Items" })
-- 원소를 담는 것 전부(리스트·맵·셋·힙) — 크기와 비우기(2026-10-12). 한 종류가 `List` 와 `Collection` 처럼
-- 여러 트레이트를 구현합니다.
const Collection = New<<Types.CollectionOps<any>>>("Collection", { "Len", "Clear" })

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

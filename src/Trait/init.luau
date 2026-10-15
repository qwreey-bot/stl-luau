--!strict
--[[
	Trait — 타입 토큰과 트레이트 **시스템**(2026-10-15 들임 — 질문 AY, 정본 설계·실험은 `.claude/research/trait-v9`·`trait-debate`,
	같은 날 정의를 한 번만 넘기는 레코드 안으로 — `.claude/research/trait-udtf`).
	트레이트 하나하나(계약 타입·기본 구현·진입점 서명)는 `src/Traits/` 에 파일 하나씩.

	⚠️ **이 시스템은 계속 바뀔 수 있습니다**(사용자: *"trait 시스템 자체는 계속 변화할 수 있는걸로 둬야겠어. 타입 시스템이
	변경됨에 따라서 영향을 받는지라"*) — 타입 모양이 Luau 새 솔버의 동작(사용자 타입 함수 `View`, 명시적 타입 인자)에 기댑니다.

	## 값과 토큰
	값에는 **타입 토큰 하나**(`__type` 필드 — 컨테이너 모듈이 `Trait.NewToken("Stl.Arr")` 로 만든 얼린 테이블). 토큰 이름은
	**유일**합니다(라이브러리 것은 `Stl.` 접두). 직렬화했다 되읽은 값은 토큰의 정체성을 잃으니 `Trait.Restore(값)` 이 이름으로
	이 사본의 진짜 토큰을 되찾아 줍니다. 위조는 막지 않습니다(토큰을 베껴 넣으면 그 종류).

	## 트레이트 = 정의(팩토리)
	```lua
	const List = Trait.Trait("List", function<Self, E, I>(of: (Self & Trait.ItemIndexRead<E, I>) | Trait.AnyToken)
		return table.freeze({
			Get = Trait.Fn<<(list: Self, index: I) -> E>>(),                         -- 필수
			IndexOf = Trait.Default(function(ops: any): (list: Self, item: E) -> I? -- 기본 구현(빌더)
				return function(list, item) … end
			end),
		})
	end)
	export type Full<Self, E, I> = typeof(List.Of<<Self, E, I>>(nil :: any))         -- 완성 표
	export type Provided<Self, E, I> = typeof(List.ImplOf<<Self, E, I>>(nil :: any)) -- 등록 표(기본 구현 칸은 선택)
	```
	- 정의는 **한 번** 넘깁니다. 칸은 타입으로 레코드(`Fn` = `{ required: true, fn: F }`, `Default` = `{ required: false, fn: F }`)이고,
	  타입 함수 `View` 가 정의 함수의 타입을 받아 두 보기(완성 = 칸마다 `fn`, 등록 = 기본 구현 칸만 `fn?`)로 **다시 지어** `Of`·`ImplOf`
	  의 타입으로 줍니다 — 매개변수와 제네릭 목록은 정의의 것 그대로. (D3 의 `def(FULL), def(IMPL)` 두 번 넘기기와 모드 값, 덜
	  줄어든 `index<>` 의 `never` 함정이 없어졌습니다 — 정의자가 모드를 틀릴 자리 자체가 없음.)
	- ⚠️ 같은 파일에서 정의하고 등록하려면 정의를 `do … end` 안에 — 파일 꼭대기에서 정의하면 그 파일의 등록 표에서 칸 자체가 제네릭인
	  함수(`Fold<U>`)의 실수가 0건입니다(다시 지은 `<U>` 가 모듈 스코프를 받음 — 상류 `Subtyping.cpp:830`, 질문 AZ, `spikes/70`).
	- 팩토리는 런타임에 **한 번**(of = nil) 불려 이름(`Fn` = 필수, `Default` = 기본 구현 빌더)을 줍니다. `table.freeze` 로 돌려주면
	  트레이트 타입의 필드가 `read` 가 됩니다. 정의가 함수가 아니거나 표를 돌려주지 않거나 칸이 `Fn`/`Default` 가 아니면 `View` 가
	  타입 에러로 알립니다(`'View' type function errored at runtime: Trait.Trait: …`).
	- `of` 가 연관 타입을 고릅니다: 쓰는 함수가 있는 트레이트는 `Item<T>`(불변 — 읽기 전용으로 빌린 참조는 그 트레이트를 아예
	  못 얻음), 읽기만 하는 트레이트는 `ItemRead<T>`/`ItemIndexRead<E, I>`(공변 — 빌린 참조도 얻음). 컨테이너는 자기 타입에
	  `__generics`(불변)·`__readGenerics`(공변) 팬텀을 적습니다.
	- `Default(build)` 의 `build(ops)` 는 그 종류의 완성 표를 받아 함수를 돌려줍니다(형제를 지역으로 붙잡아도 됨 — 다시
	  지어질 때 다시 불림). ⚠️ 계약: 던지지 않고 부작용 없이 함수만 돌려줌. 기본 구현 타입에 오버로드(`&`)를 쓰지 마세요(등록
	  보기의 `(A & B)?` 에 한쪽 갈래만 든 재정의가 0건 — 상류 결함).

	## 등록·조회
	- `X.ImplFor(토큰, 표)` — 표는 **그 트레이트의 함수만**(모르는 이름은 에러), `X.Provided<종류<A>, A>` 주석을 단 **지역 변수**에 적어
	  넘깁니다(타입 검사 — 표 리터럴을 바로 넘기면 검사가 안 됨). 기본 구현 칸은 안 적으면 기본 구현, 적으면 재정의.
	  `__index` 가 테이블인 사슬로 물려받은 함수도 칩니다(등록 때 한 번 읽어 사본으로).
	- `X.ImplWhere({ 의존 트레이트 }, function(deps) return { … } end)` — 뭉텅이 구현(의존을 다 구현한 모든 종류에. `Trait.Every` 면 모든
	  종류). 명시 구현(`ImplFor`)이 덮고, 뭉텅이끼리 겹치면 에러. 몸통은 탐침 타입(`Trait.A`·`Trait.B`)으로 짜면 원소까지 검사됨.
	- 표는 **미리** 지어 둡니다(토큰·트레이트·등록이 생길 때) — 조회는 짓지 않습니다. 의존 표가 다시 지어지면 위로 번짐.
	- `X.Of(값 또는 토큰)` — 완성 표(없으면 사용자 줄 에러). `Trait.ImplOf(X, 값)` 은 없으면 nil, `Trait.Implements(X, 값)` 은 불리언.
	- 진입점(`X.이름(값, …)`)은 **시스템이 만듭니다** — 트레이트 파일이 서명을 타입으로만 입힙니다(교집합 — 객체 타입에 인덱서가
	  없어야 `X.Of<<…>>` 가 됨).
]]
-- 폴더 모듈의 init 은 `./`·`../` 가 폴더의 부모(src) 기준, 형제 조각은 `@self/`
local Common = require("./Common")
Common.registerSource(debug.info(1, "s"))
local Registry = require("@self/Registry")
local Build = require("@self/Build")
local Entry = require("@self/Entry")
local Errors = require("@self/Errors")

-- 타입 토큰. `N` 은 이름의 리터럴 타입.
export type Token<N> = { read name: N }
-- ⚠️ `name` 은 `string` 으로 — `any`·`unknown` 이면 그 필드가 **없는** 테이블도 만족해(빠진 읽기 필드를 `nil` 로 봄 — 상류의
-- 의도된 동작), 팩토리의 `(Self & Item<T>) | AnyToken` 의 토큰 갈래가 아무 값이나 받았음.
export type AnyToken = Token<string>
-- "모든 종류" 표식(`X.ImplWhere(Trait.Every, …)`)의 타입 — 빈 목록 `{}` 은 에러입니다(아래 `Every`).
export type EveryKind = { read __everyKind: true }
-- 연관 타입(트레이트 팩토리의 `of` 가 씀). 컨테이너는 자기 타입에 같은 필드를 글자 그대로 적음. 함수 팬텀(`(T) -> T`)이라 불변 —
-- 맨 필드(`read Item: T`)는 `Self &` 와 섞이면 앞선 호출의 타입이 합으로 섞였음(`trait-typing-probes/assocfields.luau`).
export type Item<T> = { read __generics: { read Item: (T) -> T } }
export type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
-- 읽기 연관 타입(공변 — `() -> T` 꼴): 전체 타입과 읽기 타입(`ArrRead` 등) 둘 다에 적혀 있어 빌린 참조도 받음.
-- ⚠️ 쓰는 함수가 있는 트레이트에 쓰면 넓혀 빌린 참조로 쓰기가 열림 — 그런 트레이트는 `Item`.
export type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }
export type ItemIndexRead<E, I> = { read __readGenerics: { read Item: () -> E, read Index: () -> I } }
-- 탐침 타입: 등록 표의 타입 주석과 뭉텅이 몸통에 — "모든 T 에 대해" 를 서로 다른 불투명 타입으로 흉내 냄. 구체 타입(`string`)으로
-- 적으면 원소를 못박은 함수가 샙니다. 제네릭 함수의 **몸통 안**은 상류 결함(`Subtyping.cpp:830`)으로 검사가 거의 안 돼서, 몸통도
-- 탐침 타입으로 짜는 것이 원리상 맞는 우회입니다(`.claude/research/luau-source/README.md`).
export type A = { read __probeA: true }
export type B = { read __probeB: true }
export type C = { read __probeC: true }
-- 트레이트 객체. `Of` 의 타입이 팩토리 그 자체(트레이트마다 손으로 적지 않음). ⚠️ 인덱서를 두지 않습니다 — `[string]: any` 와
-- 교집합이면 `X.Of<<…>>` 가 함수가 아니게 돼(`T & any` → `T | error`) 진입점 서명을 교집합으로 입힐 수 없었습니다.
export type Object<F, G> = {
	read Of: F, -- 완성 표 꺼내기(값이나 토큰으로)
	read ImplOf: G, -- 타입 전용: `typeof(X.ImplOf<<…>>(nil :: any))` 로 등록 표 타입을 얻음(런타임은 `Of` 와 같은 함수)
	read ImplFor: (token: AnyToken, impl: any) -> (),
	read ImplWhere: (deps: { any } | EveryKind, build: (deps: { [any]: any }) -> any) -> (),
	read FnTok: { [string]: number },
}

-- 트레이트의 두 보기. `def` 는 정의 함수의 타입(`<Self, T>(of: …) -> { 이름: { required, fn } }`), `mode` 는 `"full"`(완성 표 — 칸마다
-- `fn`) 또는 `"impl"`(등록 표 — 기본 구현 칸은 `fn?`). 반환 표만 다시 짓고 매개변수와 **제네릭 목록은 정의의 것 그대로** 되넘깁니다 —
-- 그래서 `Of<<Self, T>>` 가 되고, 정의할 때 바로 줄어듭니다(제네릭이 함수 타입 안에 묶여 있어 바깥 제네릭이 정해지길 기다리지
-- 않음 — 별칭에 걸면 `outer_generics_irreducible` 로 안 줄어듦, `.claude/research/trait-udtf`).
-- - 정의의 가변 꼬리(`...any`)는 떼어 냅니다 — 남기면 `X.Of(d, 1, 2)` 가 0건이었습니다.
-- - ⚠️ 다시 지은 제네릭은 적용한 자리의 스코프를 받고 제네릭 기본값·바운드는 사라집니다(지금 정의엔 없음).
-- - 실수는 `error` 로 — 타입 에러 `'View' type function errored at runtime: …` 로 정의 줄에 뜹니다. 정의나 그 반환이 `any` 면
--   보기도 `any`(검사를 끄는 관용구).
export type function View(def, mode)
	-- `any` 는 검사를 끄는 관용구 그대로(런타임만 보는 테스트·동적 정의) — 정의나 그 반환이 `any` 면 보기도 `any`.
	if def:is("any") then
		return types.any
	end
	local full = mode:value() == "full"
	if not def:is("function") then
		error(
			"Trait.Trait: the definition must be a function `function<Self, …>(of) return table.freeze({ … }) end`"
		)
	end
	local returns = def:returns().head
	local fns = if returns == nil then nil else returns[1]
	if fns ~= nil and fns:is("any") then
		return types.any
	end
	if fns == nil or not fns:is("table") then
		error("Trait.Trait: the definition must return a table of Trait.Fn / Trait.Default slots")
	end
	local REQUIRED, FN = types.singleton("required"), types.singleton("fn")
	local out: { [type]: { read: type?, write: type? } } = {}
	for key, prop in fns:properties() do
		local slot = prop.read
		local fnType = if slot ~= nil and slot:is("table") then slot:readproperty(FN) else nil
		local required = if slot ~= nil and slot:is("table") then slot:readproperty(REQUIRED) else nil
		if fnType == nil or required == nil then
			local value = if key:is("singleton") then key:value() else nil
			local name = if type(value) == "string" then value else "?"
			error(`Trait.Trait: '{name}' must be Trait.Fn<<…>>() or Trait.Default(…)`)
		end
		local isRequired = required:is("singleton") and required:value() == true
		out[key] = { read = if full or isRequired then fnType else types.optional(fnType) }
	end
	return types.newfunction({ head = def:parameters().head }, { head = { types.newtable(out) } }, def:generics())
end

-- 값에 타입 토큰을 싣는 필드 이름. 모듈들은 이 문자열을 **리터럴로** 다시 적습니다 — 이 값을 받아 쓰면 상수 접기가 안 돼
-- 생성이 7~11% 느렸습니다(perf 21절).
const TYPE_KEY = "__type"

const records = Registry.records
const isToken = Registry.isToken
const RESERVED: { [string]: boolean } =
	table.freeze({ Of = true, ImplOf = true, ImplFor = true, ImplWhere = true, FnTok = true } :: { [string]: boolean })
const FN_MARK = table.freeze({})
const DEFAULT_MARK = table.freeze({})

--[[ 토큰 ]]

-- 새 타입 토큰. 이름은 유일 — 라이브러리 것은 `Stl.`, 바깥 것은 자기 이름공간(`MyLib.Thing`).
const function NewToken<N>(name: N & string): Token<N>
	if type(name) ~= "string" then
		Errors.tokenName(name)
	end
	if Registry.byName[name] ~= nil then
		Errors.tokenTaken(name)
	end
	const token = table.freeze({ name = name })
	Registry.byName[name] = token
	isToken[token] = true
	table.insert(Registry.tokens, token)
	Build.onToken(token)
	return token :: any
end

-- 값의 타입 토큰. 테이블이 아니거나, `__type` 이 없거나 이 사본의 토큰이 아니면 nil.
const function TokenOf(value: any): Token<string>?
	if type(value) ~= "table" then
		return nil
	end
	const token = rawget(value, TYPE_KEY)
	return if isToken[token] then token :: any else nil
end

-- 값에 타입 토큰을 붙입니다(사용자 컨테이너의 생성자용 — 라이브러리 모듈은 `"__type"` 리터럴로 직접).
const function Stamp<T>(value: T, token: AnyToken): T
	if not isToken[token] then
		Errors.notToken("Stamp", token)
	end
	if type(value) ~= "table" or table.isfrozen(value :: any) then
		Errors.stampBad(value)
	end
	(value :: any)[TYPE_KEY] = token
	return value
end

-- 직렬화로 복사된 값(과 그 안의 테이블들)의 `__type` 을 **이름으로** 이 사본의 진짜 토큰으로 되돌립니다. 이름이 이 사본에 없는
-- 것은 그대로 둡니다. 돌아 물린 테이블도 됩니다.
-- 걷기는 명시적 스택으로 — 재귀로 걸었더니 되읽은 LinkedDeque 5만 개(노드가 사슬)에서 stack overflow 였습니다(리뷰 1라운드).
const function Restore<T>(value: T): T
	const seen: { [any]: true } = {}
	const stack: { any } = { value }
	local top = 1
	while top > 0 do
		const node = stack[top]
		stack[top] = nil
		top -= 1
		if type(node) == "table" and not seen[node] then
			seen[node] = true
			const raw = rawget(node, TYPE_KEY)
			if type(raw) == "table" and not isToken[raw] then
				const tokenName = rawget(raw :: any, "name")
				const real = if type(tokenName) == "string" then Registry.byName[tokenName] else nil
				if real ~= nil and not table.isfrozen(node) then
					rawset(node, TYPE_KEY, real)
				end
			end
			-- raw 로 걸음(`rawget` 으로 읽는 `__type` 과 같게 — 사용자 `__iter` 를 부르지 않음, 2라운드 참고)
			for key, child in next, node do
				if key ~= TYPE_KEY and type(child) == "table" and not seen[child] then
					top += 1
					stack[top] = child
				end
			end
		end
	end
	return value
end

--[[ 트레이트 ]]

-- 필수 함수의 칸: 런타임엔 표식, 타입은 레코드(`View` 가 두 보기 모두 `fn` 으로).
const function Fn<F>(): { required: true, fn: F }
	return FN_MARK :: any
end
-- 기본 구현의 칸: 빌더(그 종류의 완성 표 `ops` 를 받아 함수를 돌려줌). 타입은 레코드 — `View` 가 완성 보기에서는 빌더가 돌려주는
-- 함수, 등록 보기에서는 그 함수의 선택 칸으로.
const function Default<F>(build: (ops: any) -> F): { required: false, fn: F }
	return table.freeze({ [DEFAULT_MARK] = build }) :: any
end

-- "모든 종류" 의 뭉텅이 구현을 밝혀 적는 표식. 빈 목록(`{}`)을 그 뜻으로 받았더니 의존 이름의 오타(`{ traits.Dequ }` = `{ nil }`, 길이 0)가
-- 조용히 모든 종류가 됐습니다(2026-10-15 리뷰 1라운드 참고 7 → 사용자: *"런타임 검사로 두는거 확인"*). 이제 빈 목록은 에러.
const Every: EveryKind = table.freeze({}) :: any

-- 등록(아래 `Trait` 가 트레이트 객체의 `ImplFor`·`ImplWhere` 로 붙임)
local implFor: (trait: any, token: any, impl: any) -> ()
local implWhere: (trait: any, deps: any, build: any) -> ()

-- 트레이트 `Trait.Trait(이름, 정의)`. 런타임은 정의를 한 번(of = nil) 불러 칸 이름을 얻습니다.
const function newTrait(name: string, def: any): any
	if type(name) ~= "string" then
		Errors.traitName(name)
	end
	local fns: any = def
	if type(fns) == "function" then
		const make = fns :: (any) -> any
		fns = make(nil)
	end
	if type(fns) ~= "table" then
		Errors.badFns(name)
	end
	const fnNames: { string } = {}
	const required: { [string]: true } = {}
	const builders: { [string]: (ops: any) -> any } = {}
	for fnName, mark in fns :: any do
		if type(fnName) ~= "string" then
			Errors.badFns(name)
		end
		if RESERVED[fnName] then
			Errors.reserved(name, fnName)
		end
		if mark == FN_MARK then
			required[fnName] = true
		elseif type(mark) == "table" and type(rawget(mark, DEFAULT_MARK)) == "function" then
			builders[fnName] = rawget(mark, DEFAULT_MARK) :: any
		else
			Errors.badFns(name)
		end
		table.insert(fnNames, fnName)
	end
	table.sort(fnNames)
	const fnTok: { [string]: number } = {}
	for at, fnName in fnNames do
		fnTok[fnName] = at
	end
	const trait: any = { FnTok = table.freeze(fnTok) }
	const impls: { [any]: any } = {}
	for at, fnName in fnNames do
		trait[fnName] = Entry.make(impls, name, fnName, at)
	end
	trait.Of = function(x: any): any
		const full = if isToken[x] then impls[x] elseif type(x) == "table" then impls[rawget(x, TYPE_KEY)] else nil
		if full == nil then
			return if isToken[x] then Errors.notImplemented(name, x) else Errors.entryMiss(name, "Of", x)
		end
		return full
	end
	trait.ImplOf = trait.Of
	trait.ImplFor = function(token: any, impl: any)
		implFor(trait, token, impl)
	end
	trait.ImplWhere = function(deps: any, build: any)
		implWhere(trait, deps, build)
	end
	records[trait] = {
		name = name,
		fnNames = fnNames,
		fnTok = fnTok,
		impls = impls,
		required = required,
		builders = builders,
		explicit = {},
		blankets = {},
		dependents = {},
		dependentSet = {},
	}
	table.insert(Registry.traits, trait)
	return trait
end

-- 종류 하나의 구현. 같은 (트레이트, 토큰) 을 두 번 명시 등록하면 에러(덮어쓰기를 허용하면 내장 구현이 전역으로 조용히 바뀜).
-- 뭉텅이 구현으로 따라온 것 위에는 등록할 수 있습니다(빠른 판을 나중에 얹는 길 — 같은 표를 다시 짓고 위로 번짐).
function implFor(trait: any, token: any, impl: any)
	const rec = records[trait]
	if not isToken[token] then
		Errors.notToken(`{rec.name}.ImplFor`, token)
	end
	if type(impl) ~= "table" then
		Errors.implNotTable(rec.name, impl)
	end
	Build.onFor(trait, token, impl)
end

function implWhere(trait: any, deps: any, build: any)
	const rec = records[trait]
	if deps ~= Every and (type(deps) ~= "table" or rawlen(deps) == 0) then
		Errors.emptyWhere(rec.name)
	end
	if type(build) ~= "function" then
		Errors.builderNotFunction(rec.name, build)
	end
	-- 숫자 루프로 읽어 사본으로(넘긴 목록을 나중에 고쳐도 그대로). 빈 칸(오타 난 이름 = nil)은 길이 안이면 에러. ⚠️ **끝의** 오타
	-- (`{ Deque, Typo }` = `{ Deque }`)는 길이에 안 잡혀 런타임이 못 봅니다(조건이 넓어짐) — `--!strict` 의 타입이 잡음.
	const list: { any } = {}
	for at = 1, if deps == Every then 0 else rawlen(deps) do
		const dep = rawget(deps, at)
		if records[dep] == nil then
			Errors.notTrait(`{rec.name}.ImplWhere`, dep)
		end
		list[at] = dep
	end
	-- 의존 고리는 등록 줄에서 거절: 의존 중 하나가 뭉텅이 구현을 따라 이 트레이트에 닿으면(자기 자신 포함) 명시 구현이 뭉텅이를
	-- 덮을 때마다 다시 짓기가 서로를 끝없이 불러 라이브러리 줄의 stack overflow 였습니다(2026-10-15 리뷰 1라운드).
	const seen: { [any]: true } = {}
	local function reaches(from: any): boolean
		if from == trait then
			return true
		end
		if seen[from] then
			return false
		end
		seen[from] = true
		const blankets = records[from].blankets
		for b = 1, #blankets do
			const bdeps = blankets[b].deps
			for at = 1, #bdeps do
				if reaches(bdeps[at]) then
					return true
				end
			end
		end
		return false
	end
	for at = 1, #list do
		if reaches(list[at]) then
			Errors.whereCycle(rec.name, records[list[at]].name)
		end
	end
	Build.onWhere(trait, { deps = list, build = build })
end

type TraitFn = <F>(name: string, def: F) -> Object<View<F, "full">, View<F, "impl">>
const Trait: TraitFn = newTrait :: any

--[[ 조회 — 종류를 모르는 코드, 트레이트 파일이 씀 ]]

-- 값의 종류가 `trait` 를 구현하면 그 완성 표, 아니면 nil.
const function ImplOf(trait: any, value: any): any
	if records[trait] == nil then
		Errors.notTrait("ImplOf", trait)
	end
	const token = TokenOf(value)
	return if token == nil then nil else records[trait].impls[token]
end

const function Implements(trait: any, value: any): boolean
	if records[trait] == nil then
		Errors.notTrait("Implements", trait)
	end
	const token = TokenOf(value)
	return token ~= nil and records[trait].impls[token] ~= nil
end

-- 값의 종류가 구현한 `trait` 의 완성 표. 없으면 **사용자 줄 에러**(`"Map: Arr.GroupBy needs a Map — …"`). 트레이트 인자를 검사하지
-- 않습니다(라이브러리 안에서 자기 트레이트를 넘기는 자리 — 호출당 조회 하나).
const function ExpectImpl(trait: any, value: any, who: string): any
	const rec = records[trait]
	const impl = if type(value) == "table" then rec.impls[rawget(value, TYPE_KEY)] else nil
	if impl == nil then
		return Errors.entryMiss(rec.name, who, value)
	end
	return impl
end

-- 그 트레이트의 `[토큰] = 완성 표` 표 — 트레이트 파일의 알고리즘 진입점이 구현 찾기를 펼칠 때(`impls[rawget(v, "__type")] or
-- ExpectImpl(…)` — perf 51절). 키는 토큰뿐이라 문자열 `__type` 은 "없음". ⚠️ 읽기만 — 고치면 시스템이 지은 표가 어긋납니다.
const function Impls(trait: any): { [any]: { [any]: any } }
	const rec = records[trait]
	if rec == nil then
		Errors.notTrait("Impls", trait)
	end
	return rec.impls
end

-- 트레이트 객체에 **알고리즘 진입점**(트레이트 함수가 아닌 것 — `Map.Keys` 처럼 구현을 써서 도는 함수)을 얹어 돌려줍니다.
-- 트레이트 함수·시스템 필드와 겹치는 이름은 에러(먼저 전부 검사하고 얹음 — 도중에 걸려 반쯤 얹힌 채 남지 않게).
const function Expose<T, E>(trait: T, entries: E): T & E
	const rec = records[trait]
	if rec == nil then
		Errors.notTrait("Expose", trait)
	end
	if type(entries) ~= "table" then
		Errors.exposeNotTable(entries)
	end
	for entryName in entries :: any do
		if type(entryName) ~= "string" or RESERVED[entryName] or rawget(trait :: any, entryName) ~= nil then
			Errors.exposeTaken(rec.name, entryName)
		end
	end
	for entryName, fn in entries :: any do
		(trait :: any)[entryName] = fn
	end
	return trait :: any
end

-- stylua: ignore
return {
	TYPE_KEY = TYPE_KEY,
	NewToken = NewToken, TokenOf = TokenOf, Stamp = Stamp, Restore = Restore,
	Trait = Trait, Fn = Fn, Default = Default, Every = Every,
	ImplOf = ImplOf, Implements = Implements, ExpectImpl = ExpectImpl, Expose = Expose, Impls = Impls,
}

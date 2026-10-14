--!strict
--[[
	Trait (시제품 v3 — 2026-10-14) — 트레이트가 **제네릭 타입**을 가집니다(자바의 `List<T>`, Rust 의 `trait Stack<T>`).

	```lua
	local function stackDef<Self, T>()                         -- 정의는 팩토리 한 곳
		return { Push = Trait.Fn<<(stack: Self, item: T) -> Self>>(), Pop = Trait.Fn<<(stack: Self) -> T?>>() }
	end
	export type Stack<Self, T> = typeof(stackDef<<Self, T>>())  -- 트레이트의 제네릭 타입
	const Stack = Trait.Trait("Stack", stackDef)                -- 런타임은 팩토리를 한 번 불러 이름 목록을 얻음

	const impl: Stack<CircularDeque<string>, string> = { … }   -- 등록 검사(구체 타입)
	Trait.Impl(Stack):For(TOKEN)(impl)
	Trait.Impl(Stack):Where({ Deque })(function(deps) return stackFromDeque(deps[Deque]) end)  -- 제네릭 함수로 검사

	local s = Stack.Of<<CircularDeque<number>, number>>(d)    -- 동적 경로: 받는 쪽이 T 를 밝힘(주장 — 검사 안 됨)
	Stack.Push(d, 1)                                           -- 편한 진입점(원소 검사 없음 — any)
	```

	v2(연관 타입 — 값의 타입에서 원소를 캐냄)와 다른 것은 타입 층뿐이고 런타임은 같습니다. 원소 타입을 값에서 캐내지 않으니
	표식·`__generics`·시그니처를 바꿔 끼우는 타입 함수가 없습니다. 타입 함수는 등록 표의 선택 필드(`Provided`) 하나뿐.
]]
-- 폴더 모듈의 init 은 `./`·`../` 가 폴더의 부모 기준(형제 조각은 `@self/`)
local Common = require("../../../src/Common")
Common.registerSource(debug.info(1, "s"))
local Registry = require("@self/Registry")
local Build = require("@self/Build")
local Entry = require("@self/Entry")
local Errors = require("@self/Errors")

export type Token<N> = { read name: N }
-- 트레이트 객체의 타입: 진입점(시그니처 그대로) + 종류별 완성 표 + 함수 번호
-- 트레이트 객체(런타임): 진입점(이름마다 — 원소 검사 없는 any 경로) + `Of`·`For` + `FnTok`. `Trait` 은 `any` 를 돌려주고
-- 트레이트 파일이 자기 제네릭 별칭으로 타입을 적습니다(`Stack<any, any> & { Of, For, FnTok }` — 하나의 함수가 트레이트마다
-- 다른 별칭을 돌려줄 수 없음, 고차 타입이 없음).
export type Object = { read FnTok: { [string]: number }, read [string]: any }

const records = Registry.records
const FN_MARK = table.freeze({}) -- 필수 함수
const DEFAULT_MARK = table.freeze({}) -- 기본 구현이 있는 함수
export type DefaultTag = { read __default: true }

-- 토큰. 이름은 한 사본 안에서 유일합니다(직렬화된 값을 이름으로 되찾으니까).
const function Token<N>(name: N & string): Token<N>
	if type(name) ~= "string" then
		Errors.tokenName(name)
	end
	if Registry.byName[name] ~= nil then
		Errors.tokenTaken(name)
	end
	const token = table.freeze({ name = name })
	Registry.byName[name] = token
	Registry.isToken[token] = true
	table.insert(Registry.tokens, token)
	Build.onToken(token)
	return token :: any
end

-- 함수 목록의 한 칸: 런타임엔 표식, 타입은 그 시그니처. `Fn` 은 **필수**, `Default` 는 **기본 구현이 채움**(등록 표에
-- 없어도 됨 — `For<…>` 별칭에서 선택 필드가 됨). 필수 여부를 시그니처에 적는 것은 타입이 따라오게 하려고입니다(기본 구현을
-- 불러 봐서 아는 것은 런타임뿐이라 등록 표의 타입이 모든 함수를 요구했음).
const function Fn<T>(): T
	return FN_MARK :: any
end
const function Default<T>(): T & DefaultTag
	return DEFAULT_MARK :: any
end

-- 등록 표의 타입: 완성 타입(`Stack<S, T>`)에서 `Default` 칸(꼬리표 `__default`)을 선택 필드로. **구체 타입에만** 씌웁니다
-- (`Provided<List<Arr<string>, string, number>>`) — 제네릭이 든 채로 거치면 추론이 끊겼습니다(v2 실험).
export type function Provided(full: type): type
	const out: any = {}
	for key, v in full:properties() do
		local t = v.read :: type
		local optional = false
		if t.tag == "intersection" then
			const rest = {}
			for _, c in t:components() do
				if c.tag == "table" and c:readproperty(types.singleton("__default")) then
					optional = true
				else
					table.insert(rest, c)
				end
			end
			t = if #rest == 1 then rest[1] else types.intersectionof(table.unpack(rest))
		end
		out[key] = { read = if optional then types.optional(t) else t }
	end
	return types.newtable(out)
end

-- 트레이트. `fns` 의 키가 함수 이름(정렬해 번호를 매김 — 표의 키 순서는 실행마다 다를 수 있음), `defaults(ops)` 는 기본
-- 구현을 돌려줌(그것이 채우지 않는 이름이 필수). 진입점은 이름마다 시스템이 만들어 트레이트 객체에 둠.
-- `def` 는 시그니처 표를 돌려주는 **팩토리**(`function<Self, T>() return { … } end` — 타입의 제네릭을 쥐는 자리) 또는 그 표.
const function Trait(name: string, def: any, defaults: ((ops: any) -> { [string]: any })?): any
	local fns: any = def
	if type(def) == "function" then
		const factory = def :: () -> any
		fns = factory()
	end
	if type(fns) ~= "table" then
		Errors.badFns(name)
	end
	const fnNames: { string } = {}
	const marked: { [string]: true } = {} -- Default 로 적은 이름
	for fnName, mark in fns :: any do
		if type(fnName) ~= "string" or (mark ~= FN_MARK and mark ~= DEFAULT_MARK) then
			Errors.badFns(name)
		end
		if mark == DEFAULT_MARK then
			marked[fnName] = true
		end
		table.insert(fnNames, fnName)
	end
	table.sort(fnNames)
	const fnTok: { [string]: number } = {}
	for at, fnName in fnNames do
		fnTok[fnName] = at
	end
	-- 기본 구현이 `Default` 로 적은 이름을 **정확히** 채우는지 한 번 불러 봄(계약: 표만 돌려주고 부작용 없음)
	const required: { [string]: true } = {}
	const provided: { [string]: true } = {}
	if defaults then
		const probe = defaults({})
		if type(probe) ~= "table" then
			Errors.defaultsNotTable(name, probe)
		end
		for fnName in probe do
			if not marked[fnName] then
				Errors.defaultsUnknown(name, fnName)
			end
			provided[fnName] = true
		end
	end
	for _, fnName in fnNames do
		if marked[fnName] and not provided[fnName] then
			Errors.defaultMissing(name, fnName)
		elseif not marked[fnName] then
			required[fnName] = true
		end
	end
	const trait: any = { FnTok = table.freeze(fnTok) }
	for at, fnName in fnNames do
		trait[fnName] = Entry.make(trait, name, fnName, at)
	end
	-- 동적 경로로 완성 표를 꺼냄: 값으로(`Of`) / 토큰으로(`For`). 없으면 사용자 줄 에러. 타입은 트레이트 파일이 자기 별칭으로.
	if fnTok.Of == nil then
		trait.Of = function(value: any): any
			const full = if type(value) == "table" then trait[rawget(value, "__type")] else nil
			if full == nil then
				return Errors.entryMiss(name, "Of", value)
			end
			return full
		end
	end
	if fnTok.For == nil then
		trait.For = function(token: any): any
			const full = trait[token]
			if full == nil then
				return Errors.notImplemented(name, token)
			end
			return full
		end
	end
	records[trait] = {
		name = name,
		fnNames = fnNames,
		fnTok = fnTok,
		required = required,
		defaults = defaults,
		explicit = {},
		blankets = {},
		dependents = {},
		dependentSet = {},
	}
	table.insert(Registry.traits, trait)
	return trait
end

-- 등록: `Impl(트레이트):For(토큰)(표)` / `Impl(트레이트):Where({ 트레이트… })(function(deps) … end)`.
type Implementer = {
	For: (self: Implementer, token: Token<any>) -> <I>(impl: I) -> (),
	Where: (self: Implementer, deps: { any }) -> (build: (deps: { [any]: any }) -> any) -> (),
}
const function Impl(trait: any): Implementer
	if records[trait] == nil then
		Errors.notTrait("Impl", trait)
	end
	return {
		For = function(_self: Implementer, token: Token<any>): <I>(impl: I) -> ()
			if not Registry.isToken[token] then
				Errors.notToken("Impl(...):For", token)
			end
			return function<I>(impl: I)
				if type(impl) ~= "table" then
					Errors.badFns(records[trait].name)
				end
				Build.onFor(trait, token, impl :: any)
			end
		end,
		Where = function(_self: Implementer, deps: { any }): (build: (deps: { [any]: any }) -> any) -> ()
			if type(deps) ~= "table" then
				Errors.emptyWhere(records[trait].name)
			end
			const list = table.clone(deps)
			for _, dep in list do
				if records[dep] == nil then
					Errors.notTrait("Impl(...):Where", dep)
				end
			end
			return function(build)
				Build.onWhere(trait, { deps = list, build = build })
			end
		end,
	}
end

-- 값의 종류가 구현한 그 트레이트의 완성 표(없으면 nil).
const function ImplOf(trait: any, value: any): any
	if type(value) ~= "table" then
		return nil
	end
	return (trait :: any)[rawget(value, "__type")]
end

-- 직렬화로 복사된 값(과 그 안의 컨테이너들)의 `__type` 을 이름으로 이 사본의 진짜 토큰으로 바꿈. 모르는 이름은 그대로.
const function Restore<T>(value: T): T
	const seen: { [any]: true } = {}
	local function walk(node: any)
		if type(node) ~= "table" or seen[node] then
			return
		end
		seen[node] = true
		const raw = rawget(node, "__type")
		if type(raw) == "table" and not Registry.isToken[raw] then
			const name = rawget(raw :: any, "name")
			const real = if type(name) == "string" then Registry.byName[name] else nil
			if real ~= nil then
				rawset(node, "__type", real)
			end
		end
		for key, child in node do
			if key ~= "__type" then
				walk(child)
			end
		end
	end
	walk(value)
	return value
end

-- stylua: ignore
return {
	Token = Token, Fn = Fn, Default = Default, Trait = Trait, Impl = Impl, ImplOf = ImplOf, Restore = Restore,
}

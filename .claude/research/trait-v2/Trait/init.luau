--!strict
--[[
	Trait (시제품 v2) — 2026-10-14 사용자와 정한 모양.

	```lua
	const TOKEN = Trait.Token("Stl.CircularDeque")              -- 이름은 한 사본 안에서 유일(우리 것은 `Stl.`)

	const Stack = Trait.Trait("Stack", {                       -- 함수 목록 = 런타임 이름 + 타입(시그니처)
		Push = Trait.Fn<<<Self, T>(stack: Self & MarkerMut<T>, item: T) -> Self>>(),
		Pop = Trait.Fn<<<Self, T>(stack: Self & MarkerMut<T>) -> T?>>(),
	}, function(ops) return { … 기본 구현 … } end)             -- 기본 구현이 채우지 않는 이름이 필수
	export type For<Self, T> = Fill.FillGenerics<typeof(fns), { Self: Self, T: T }>

	Trait.Impl(Stack):For(TOKEN)(stackImpl)                    -- stackImpl: Stack.For<CircularDeque<string>, string>
	Trait.Impl(Stack):Where({ Deque })(function(deps) … end)   -- 뭉텅이 구현(Deque 인 모든 종류)

	Stack.Push(d, 1)            -- 종류를 모를 때(시스템이 만든 진입점 — vtable 을 거치는 dyn 경로)
	Stack[TOKEN].Push(d, 1)     -- 종류를 알 때(이름이 상수라 빠름)
	Trait.Restore(value)        -- 직렬화로 복사된 값의 `__type` 을 이름으로 진짜 토큰으로 바꿈
	```

	조각: `Registry`(강한 배열 — 기억하는 것 전부) / `Build`(짓기·놓기·사건 셋) / `Entry`(진입점) / `Errors` / `Fill`(타입 함수).
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
export type Trait<F> = F & { read FnTok: { [string]: number } }

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

-- 트레이트. `fns` 의 키가 함수 이름(정렬해 번호를 매김 — 표의 키 순서는 실행마다 다를 수 있음), `defaults(ops)` 는 기본
-- 구현을 돌려줌(그것이 채우지 않는 이름이 필수). 진입점은 이름마다 시스템이 만들어 트레이트 객체에 둠.
const function Trait<F>(name: string, fns: F, defaults: ((ops: any) -> { [string]: any })?): Trait<F>
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
	Where: (self: Implementer, deps: { any }) -> (build: (deps: { [any]: any }) -> { [string]: any }) -> (),
}
const function Impl<F>(trait: Trait<F>): Implementer
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
		Where = function(_self: Implementer, deps: { any }): (build: (deps: { [any]: any }) -> { [string]: any }) -> ()
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
const function ImplOf<F>(trait: Trait<F>, value: any): F?
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

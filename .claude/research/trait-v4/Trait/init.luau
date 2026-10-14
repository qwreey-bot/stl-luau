--!strict
--[[
	Trait (시제품 v4 — 2026-10-14, 다시각 탐색 1회차가 모인 뼈대). 런타임은 v3(=v2)과 같고, 정의·등록의 모양과 타입이 다릅니다.

	```lua
	-- 트레이트 = 팩토리 하나. 팩토리가 이름 목록(런타임)이자 트레이트의 제네릭 타입이자 `Of` 의 타입
	const Stack = Trait.Trait("Stack", function<Self, T>(of: (Self & Trait.Item<T>) | Trait.AnyToken)
		return {
			Push = Trait.Fn<<(stack: Self, item: T) -> Self>>(),
			Pop = Trait.Fn<<(stack: Self) -> T?>>(),
			Peek = Trait.Default(function(ops: Stack<Self, T>)   -- 기본 구현: 빌더가 그 종류의 완성 표를 받음
				const pop, push = ops.Pop, ops.Push
				return function(stack: Self): T? … end
			end),
		}
	end)
	export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))

	const arrStack: Stack<Arr<Trait.A>, Trait.A> = { Push = Arr.PushBack, Pop = Arr.PopBack, Peek = Trait.Inherit }  -- 탐침으로 검사
	Trait.Impl(Stack, ARR, arrStack)
	Trait.Blanket(Stack, { Deque }, function(deps) return stackFromDeque(deps[Deque]) end)   -- 제네릭 함수로 검사

	local s = Stack.Of(d)          -- 값에서 Self·T (컨테이너의 `__generics`), 토큰이면 `Stack.Of<<C, T>>(TOKEN)`(주장)
	Stack.Push(d, x)               -- 편한 진입점(원소 검사 없음 — any)
	```

	조각: `Registry`(강한 배열) / `Build`(짓기 — 기본 구현 빌더·`Inherit` — 놓기·사건 셋) / `Entry`(진입점) / `Errors`.
	타입 함수 없음. 연관 타입은 컨테이너의 `read __generics: { read Item: (T) -> T, … }`(불변 팬텀 — 글자 그대로).
]]
-- 폴더 모듈의 init 은 `./`·`../` 가 폴더의 부모 기준(형제 조각은 `@self/`)
local Common = require("../../../src/Common")
Common.registerSource(debug.info(1, "s"))
local Registry = require("@self/Registry")
local Build = require("@self/Build")
local Entry = require("@self/Entry")
local Errors = require("@self/Errors")

export type Token<N> = { read name: N }
-- ⚠️ `name` 은 `string` 으로(`any`·`unknown` 이면 그 필드가 **없는** 테이블도 만족해, 팩토리의 `(Self & Item<T>) | AnyToken`
-- 에서 토큰 갈래가 아무 값이나 받아 "값으로 밝힌 T 가 어긋남" 이 새었음 — `trait-typing-probes/factoryof.luau` 변형)
export type AnyToken = Token<string>
-- 연관 타입(받는 쪽이 쓰는 모양). 컨테이너는 자기 타입 **안에** 같은 필드를 글자 그대로 적음
export type Item<T> = { read __generics: { read Item: (T) -> T } }
export type ItemIndex<E, I> = { read __generics: { read Item: (E) -> E, read Index: (I) -> I } }
-- 탐침 타입: 등록 검사를 "모든 T 에 대해" 로(어떤 실제 타입과도 다른 불투명 타입). 구체 타입(`string`)으로 검사하면
-- 원소를 못박은 함수가 샙니다(`trait-typing-probes/probetype.luau`).
export type A = { read __probeA: true }
export type B = { read __probeB: true }
-- 트레이트 객체: `Of` 의 타입이 팩토리 그 자체(트레이트마다 손으로 적지 않음 — 고차 타입 없이)
export type Object<F> = { read Of: F, read FnTok: { [string]: number }, read [string]: any }

const records = Registry.records
const FN_MARK = table.freeze({})
const DEFAULT_MARK = table.freeze({})

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

-- 필수 함수의 칸: 런타임엔 표식, 타입은 그 시그니처
const function Fn<F>(): F
	return FN_MARK :: any
end
-- 기본 구현의 칸: 빌더(그 종류의 완성 표 `ops` 를 받아 함수를 돌려줌). 타입은 빌더가 돌려주는 함수의 타입
const function Default<F>(build: (ops: any) -> F): F
	return table.freeze({ [DEFAULT_MARK] = build }) :: any
end
-- 등록 표에서 "이 칸은 기본 구현에 맡김"(전체 타입으로 적을 때)
const Inherit: any = Registry.INHERIT

-- 트레이트. `factory` 는 `function<Self, T…>(of: …) return { 이름 = Fn<<…>>() | Default(…) } end` — 런타임은 한 번
-- 불러 이름과 빌더를 얻습니다(`of` 는 nil). 진입점은 이름마다 시스템이 만들고, `Of` 는 값이나 토큰으로 완성 표를 꺼냄.
const function Trait<F>(name: string, factory: F): Object<F>
	local fns: any = factory
	if type(factory) == "function" then
		const make = factory :: (any) -> any
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
		if fnName == "Of" or fnName == "FnTok" then
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
	for at, fnName in fnNames do
		trait[fnName] = Entry.make(trait, name, fnName, at)
	end
	trait.Of = function(x: any): any
		const full = if Registry.isToken[x]
			then trait[x]
			elseif type(x) == "table" then trait[rawget(x, "__type")]
			else nil
		if full == nil then
			return if Registry.isToken[x] then Errors.notImplemented(name, x) else Errors.entryMiss(name, "Of", x)
		end
		return full
	end
	records[trait] = {
		name = name,
		fnNames = fnNames,
		fnTok = fnTok,
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

-- 종류 하나의 구현(그 트레이트의 함수만 든 표 — 탐침 타입 주석을 단 지역 변수로 적어 넘기세요)
const function Impl(trait: any, token: AnyToken, impl: any)
	if records[trait] == nil then
		Errors.notTrait("Impl", trait)
	end
	if not Registry.isToken[token] then
		Errors.notToken("Impl", token)
	end
	if type(impl) ~= "table" then
		Errors.badFns(records[trait].name)
	end
	Build.onFor(trait, token, impl)
end

-- 뭉텅이 구현: `deps` 를 다 구현한 모든 종류에. 몸통은 제네릭 함수로 짜서 넘기면 타입 검사를 받음
const function Blanket(trait: any, deps: { any }, build: (deps: { [any]: any }) -> any)
	if records[trait] == nil then
		Errors.notTrait("Blanket", trait)
	end
	if type(deps) ~= "table" then
		Errors.emptyWhere(records[trait].name)
	end
	const list = table.clone(deps)
	for _, dep in list do
		if records[dep] == nil then
			Errors.notTrait("Blanket", dep)
		end
	end
	Build.onWhere(trait, { deps = list, build = build })
end

-- 직렬화로 복사된 값(과 그 안의 컨테이너들)의 `__type` 을 이름으로 이 사본의 진짜 토큰으로
const function Restore<T>(value: T): T
	const seen: { [any]: true } = {}
	local function walk(node: any)
		if type(node) ~= "table" or seen[node] then
			return
		end
		seen[node] = true
		const raw = rawget(node, "__type")
		if type(raw) == "table" and not Registry.isToken[raw] then
			const tokenName = rawget(raw :: any, "name")
			const real = if type(tokenName) == "string" then Registry.byName[tokenName] else nil
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
	Token = Token, Fn = Fn, Default = Default, Inherit = Inherit, Trait = Trait, Impl = Impl, Blanket = Blanket,
	Restore = Restore,
}

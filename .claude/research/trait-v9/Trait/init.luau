--!strict
--[[
	Trait (시제품 v9 — 2026-10-14, 토론이 모은 모양: 기본 구현이 없으면 한 겹, 있으면 정의 함수를 모드 값으로 두 번. v8 에서 `Trait` 의 머리만 다름). 런타임은 v4 그대로이고, 정의의 모양과 타입이 다릅니다. v4 에서 바뀐 것 셋:

	1. **두 보기**: 정의를 모드 `M` 을 받는 한 겹으로 감쌉니다. 같은 정의에서 완성 표 타입(`Of`)과 등록 표 타입(`ImplOf`)이
	   나오고, 기본 구현 칸은 등록 보기에서 선택 칸입니다 — **`Trait.Inherit` 가 없어졌습니다.** 칸 하나의 두 모양은 내장 타입
	   함수 `index<{ full: …, impl: … }, M>` 로 고릅니다(이 시제품의 유일한 타입 함수).
	2. **빌린 읽기 참조**: 팩토리가 공변 팬텀(`ItemRead`)으로 원소를 얻고, 쓰는 함수의 self 는 `Mut<Self, T, M>`(완성 보기에선
	   불변 팬텀 `Item<T>` 를 요구 — 빌린 참조는 못 들어감).
	3. **등록은 트레이트 객체에서**: `Stack.ImplFor(토큰, 표)`, `Stack.ImplWhere({ Deque }, 만드는 함수)`.

	```lua
	local function stackDef<M>(mode: M)
		return function<Self, T>(of: (Self & Trait.ItemRead<T>) | Trait.AnyToken)
			return {
				Push = Trait.Fn<<(stack: Trait.Mut<Self, T, M>, item: T) -> Self>>(),   -- 쓰는 함수
				Pop = Trait.Fn<<(stack: Trait.Mut<Self, T, M>) -> T?>>(),
				Peek = Trait.Fn<<(stack: Self) -> T?>>(),                               -- 읽는 함수
				IsEmpty = Trait.Default(mode, function(ops: Stack<Self, T>) … end),     -- 기본 구현
			}
		end
	end
	const Stack = Trait.Trait("Stack", stackDef, stackDef)   -- 같은 정의를 두 번: 받는 자리가 모드를 "full"·"impl" 로 정함
	export type Stack<Self, T> = typeof(Stack.Of<<Self, T>>(nil :: any))          -- 완성 표
	export type StackImpl<Self, T> = typeof(Stack.ImplOf<<Self, T>>(nil :: any))  -- 등록 표(기본 구현 칸은 선택)

	const arrStack: StackImpl<Arr<Trait.A>, Trait.A> = { Push = Arr.PushBack, Pop = Arr.PopBack, Peek = arrPeek }
	Stack.ImplFor(ARR, arrStack)
	Stack.ImplWhere({ Deque }, function(deps) return stackFromDeque(deps[Deque]) end)
	```
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
-- 읽기 연관 타입(공변 — `() -> T` 꼴). 컨테이너는 전체 타입과 읽기 타입(`ArrRead` 등) 둘 다에 적음. 팩토리는 이것으로 받아
-- 빌린 참조도 `Of` 로 꺼냄. ⚠️ 맨 `read Item: T` 는 `Self &` 와 섞이면 합이 섞임(`trait-typing-probes/assocfields.luau`)
export type ItemRead<T> = { read __readGenerics: { read Item: () -> T } }
export type ItemIndexRead<E, I> = { read __readGenerics: { read Item: () -> E, read Index: () -> I } }
-- 쓰는 함수의 self: 완성 보기에선 불변 팬텀을 요구(빌린 참조·넓혀 빌린 것이 못 들어감), 등록 보기에선 `Self` 그대로
-- (`Self & Item<T>` 로 두면 `<T>(CircularDeque<T>, T)` 같은 제네릭 구현이 교집합 인자에 안 맞춰짐 — Opus 실측)
export type Mut<Self, T, M> = index<{ full: Self & Item<T>, impl: Self }, M>
export type MutIndex<Self, E, I, M> = index<{ full: Self & ItemIndex<E, I>, impl: Self }, M>
-- 탐침 타입: 등록 검사를 "모든 T 에 대해" 로(어떤 실제 타입과도 다른 불투명 타입). 구체 타입(`string`)으로 검사하면
-- 원소를 못박은 함수가 샙니다(`trait-typing-probes/probetype.luau`).
export type A = { read __probeA: true }
export type B = { read __probeB: true }
-- 트레이트 객체: `Of` 의 타입이 팩토리 그 자체(트레이트마다 손으로 적지 않음 — 고차 타입 없이)
export type Object<F, G> = {
	read Of: F, -- 완성 표 꺼내기(값이나 토큰으로)
	read ImplOf: G, -- 타입 전용: `typeof(X.ImplOf<<…>>(nil :: any))` 로 등록 표 타입을 얻음(런타임은 `Of` 와 같은 함수)
	read ImplFor: (token: AnyToken, impl: any) -> (),
	read ImplWhere: (deps: { any }, build: (deps: { [any]: any }) -> any) -> (),
	read FnTok: { [string]: number },
	read [string]: any,
}

const records = Registry.records
const RESERVED: { [string]: boolean } = table.freeze({ Of = true, ImplOf = true, ImplFor = true, ImplWhere = true, FnTok = true } :: { [string]: boolean })
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
-- 기본 구현의 칸: 빌더(그 종류의 완성 표 `ops` 를 받아 함수를 돌려줌). 타입은 완성 보기에서 빌더가 돌려주는 함수,
-- 등록 보기에서 그 함수의 선택 칸(구현이 재정의할 수 있음 — 빼면 기본 구현). `mode` 는 정의의 모드를 그대로 넘김(런타임은 안 봄)
const function Default<F, M>(mode: M, build: (ops: any) -> F): index<{ full: F, impl: F? }, M>
	return table.freeze({ [DEFAULT_MARK] = build }) :: any
end

-- 등록(아래 `Trait` 가 트레이트 객체의 `ImplFor`·`ImplWhere` 로 붙임)
local Impl: (trait: any, token: AnyToken, impl: any) -> ()
local Blanket: (trait: any, deps: { any }, build: (deps: { [any]: any }) -> any) -> ()

-- 트레이트. 두 모양(인자 수로 가름 — 같은 인자 수의 오버로드는 제네릭 앞에서 모호해서):
--   `Trait.Trait(이름, 팩토리)`                         기본 구현 없음: 완성 표 = 등록 표
--   `Trait.Trait(이름, def(Trait.FULL), def(Trait.IMPL))` 기본 구현 있음: 정의 함수 `def<M>(mode: M)` 를 모드 값으로 두 번
-- 런타임은 팩토리를 한 번 불러(of = nil) 이름과 빌더를 얻습니다(셋째 인자는 타입만 위한 것). 진입점은 이름마다 시스템이
-- 만들고, `Of` 는 값이나 토큰으로 완성 표를 꺼냄.
const function TraitAny(name: string, def: any, _implDef: any?): any
	local fns: any = def
	for _ = 1, 2 do
		if type(fns) == "function" then
			const make = fns :: (any) -> any
			fns = make(nil)
		end
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
	trait.ImplOf = trait.Of
	trait.ImplFor = function(token: AnyToken, impl: any)
		Impl(trait, token, impl)
	end
	trait.ImplWhere = function(deps: { any }, build: (deps: { [any]: any }) -> any)
		Blanket(trait, deps, build)
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

-- 종류 하나의 구현(그 트레이트의 함수만 든 표 — 탐침 타입 주석을 단 지역 변수로 적어 넘기세요). 기본 구현 칸은 빼면 기본 구현
function Impl(trait: any, token: AnyToken, impl: any)
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
function Blanket(trait: any, deps: { any }, build: (deps: { [any]: any }) -> any)
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

-- 모드 값(정의 함수에 넘김 — 글자 그대로의 타입이라 부르는 자리에서 모드가 정해짐)
const FULL: "full" = "full"
const IMPL: "impl" = "impl"
type TraitFn = (<F>(name: string, factory: F) -> Object<F, F>) & (<F, G>(name: string, full: F, impl: G) -> Object<F, G>)
const Trait: TraitFn = TraitAny :: any

-- stylua: ignore
return {
	Token = Token, Fn = Fn, Default = Default, Trait = Trait, FULL = FULL, IMPL = IMPL, Restore = Restore,
}

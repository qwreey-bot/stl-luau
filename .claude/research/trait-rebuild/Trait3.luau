--!strict
--[[
	Trait3 — **시제품**: 구현을 "다시 만들 수 있는 것" 으로(2026-10-14 사용자 제안, 질문 AW).

	`src/Trait.luau` 와 무엇이 다른가:

	1. **의존하는 쪽의 표식이 의존 트레이트에 박혀 있습니다**(`trait.dependents` — 거꾸로 가는 색인). `Stack` 을
	   만들 때 `Deque.dependents[Stack] = true`.
	2. **어떤 종류의 한 트레이트 표가 (다시) 만들어지면, 그것에 의존하는 트레이트의 그 종류 표를 다시 만듭니다**
	   (`commit` → `rebuild` — 연쇄). 표는 **같은 테이블을 비우고 다시 채웁니다**(표를 쥔 쪽은 새 함수를 봄).
	3. 그래서 기본 구현을 만드는 함수(`defaults(ops, deps)`)와 구현을 만드는 함수(`Impl(trait, token, function(deps) … end)`)
	   가 의존·필수의 함수를 **만들 때 붙잡거나 그대로 돌려줘도** 됩니다 — 바뀌면 다시 불립니다.
	4. 구현의 "출처"(넘긴 표 / 만드는 함수 / 저절로 따라옴)를 기억합니다(`trait.sources`) — 다시 만들 때 씁니다.
	5. 함수별 표(`FnTable(trait, "Push")` = `[토큰] = 함수`)를 같이 맞춰 둡니다 — 진입점이 조회 하나로 함수에 닿는 변형.

	시제품이라 뺀 것: 에러 규약(`Common.raise` — 여기는 `error`), 토큰·트레이트 인자 검증, `__index` 로 물려받은 구현,
	`spec` 의 모르는 필드, `Expose`. 토큰은 `src` 의 것(`CircularDeque.Token`)을 그대로 받습니다(이름 있는 테이블이면 됨).
]]

export type Defaults = (ops: any, deps: { [any]: any }) -> { [string]: any }
export type Spec = {
	read required: { string }?,
	read dependencies: { any }?,
	read defaults: Defaults?,
}

const WEAK_KEYS = table.freeze({ __mode = "ks" })

-- 재는 용도: 표를 몇 번 만들었나(첫 만들기 + 다시 만들기)
local builds = 0

const function New(name: string, spec: Spec?): any
	const required = if spec then spec.required else nil
	const dependencies = if spec then spec.dependencies else nil
	const defaults = if spec then spec.defaults else nil
	const trait = {
		name = name,
		required = required,
		dependencies = dependencies,
		defaults = defaults,
		derivable = (required == nil or #required == 0) and (dependencies ~= nil or defaults ~= nil),
		-- [토큰] = 완성 표(정체성이 유지됨 — 다시 만들 때 같은 테이블을 고침)
		impls = setmetatable({}, WEAK_KEYS),
		-- [토큰] = 출처: 넘긴 표 / 만드는 함수 / false(저절로 따라옴)
		sources = setmetatable({}, WEAK_KEYS),
		-- ⭐ 표식: 나를 의존으로 적은 트레이트들(약한 키 — 버린 트레이트는 수거)
		dependents = setmetatable({}, WEAK_KEYS),
		-- [함수 이름] = { [토큰] = 함수 } — `FnTable` 이 처음 물을 때 만듦
		fns = {},
	}
	if dependencies then
		for _, dep in dependencies do
			dep.dependents[trait] = true
		end
	end
	return trait
end

local resolve: (trait: any, token: any) -> any

-- 그 종류의 의존 표들. 하나라도 없으면 nil 과 그 트레이트.
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

-- 출처에서 **새 표**를 짓습니다(아무것도 고치지 않음 — 실패하면 그 트레이트의 예전 표가 그대로).
-- `source`: 넘긴 표 / 만드는 함수(`deps` 를 받아 표를 돌려줌) / nil(저절로 따라옴).
const function assemble(trait: any, token: any, source: any, deps: { [any]: any }): { [string]: any }
	builds += 1
	local given: any = source
	if type(source) == "function" then
		const build = source :: (deps: { [any]: any }) -> any
		given = build(deps)
	end
	if source ~= nil and type(given) ~= "table" then
		error(`Trait3: {token.name} gave a {typeof(given)} as its implementation of {trait.name}`, 0)
	end
	const fresh: { [string]: any } = {}
	if given ~= nil then
		for fnName, fn in given do
			if type(fn) ~= "function" then
				error(`Trait3: {token.name} gave a {typeof(fn)} as {fnName} for {trait.name}`, 0)
			end
			fresh[fnName] = fn
		end
	end
	const required: { string }? = trait.required
	if required then
		for _, fnName in required do
			if fresh[fnName] == nil then
				error(`Trait3: {token.name} is missing {fnName} for {trait.name}`, 0)
			end
		end
	end
	-- 기본 구현. `ops` 로 넘기는 것은 **이번에 짓는 표**입니다 — 필수 함수와 재정의가 이미 들어 있어
	-- 만드는 함수가 붙잡을 수 있습니다(같은 트레이트의 다른 기본 구현은 `ops.X or 내것` 으로).
	local filled: { [string]: any }? = nil
	const defaults: Defaults? = trait.defaults
	if defaults then
		filled = defaults(fresh, deps)
		if type(filled) ~= "table" then
			error(`Trait3: defaults of {trait.name} must return a table of functions`, 0)
		end
	end
	-- 모르는 이름(필수도 기본 구현도 아닌 것) — 채우기 전에 봅니다
	if given ~= nil then
		for fnName in given do
			if not (required and table.find(required, fnName)) and not (filled and filled[fnName] ~= nil) then
				error(`Trait3: {token.name} gave {fnName} to {trait.name}, which {trait.name} does not have`, 0)
			end
		end
	end
	if filled then
		for fnName, fn in filled do
			if fresh[fnName] == nil then
				fresh[fnName] = fn
			end
		end
	end
	return fresh
end

local rebuild: (trait: any, token: any) -> ()

-- 지은 표를 자리에 놓고(처음이면 그 표가 곧 완성 표, 아니면 **같은 테이블을 비우고 다시 채움**),
-- 함수별 표를 맞추고, ⭐ 이 트레이트에 의존하는 트레이트의 그 종류 표를 다시 만듭니다.
const function commit(trait: any, token: any, fresh: { [string]: any }, source: any)
	local full = trait.impls[token]
	const first = full == nil
	if first then
		full = fresh
		trait.impls[token] = full
	else
		table.clear(full)
		for fnName, fn in fresh do
			full[fnName] = fn
		end
	end
	trait.sources[token] = if source == nil then false else source
	for fnName, byToken in trait.fns do
		byToken[token] = full[fnName]
	end
	if not first then
		for dependent in trait.dependents do
			if dependent.impls[token] ~= nil then
				rebuild(dependent, token)
			end
		end
	end
end

function rebuild(trait: any, token: any)
	const source = trait.sources[token]
	const deps, missing = depsOf(trait, token)
	if deps == nil then
		error(`Trait3: {token.name} lost {missing.name} while rebuilding {trait.name}`, 0)
	end
	commit(trait, token, assemble(trait, token, if source == false then nil else source, deps), source or nil)
end

function resolve(trait: any, token: any): any
	const found = trait.impls[token]
	if found ~= nil then
		return found
	end
	if not trait.derivable or type(token) ~= "table" then
		return nil
	end
	const deps = depsOf(trait, token)
	if deps == nil then
		return nil
	end
	commit(trait, token, assemble(trait, token, nil, deps), nil)
	return trait.impls[token]
end

-- `source` 는 **표**이거나 **만드는 함수** `function(deps) return { … } end`(의존이 바뀌면 다시 불림).
-- 의존을 갖추지 못했으면 "먼저 구현하라" 에러. 명시 등록의 재등록은 에러, 저절로 따라온 것 위에는 됨(→ 다시 만듦).
const function Impl(trait: any, token: any, source: any)
	if trait.impls[token] ~= nil and trait.sources[token] ~= false then
		error(`Trait3: {token.name} already implements {trait.name}`, 0)
	end
	const deps, missing = depsOf(trait, token)
	if deps == nil then
		error(`Trait3: {token.name} must implement {missing.name} first to implement {trait.name}`, 0)
	end
	commit(trait, token, assemble(trait, token, source, deps), source)
end

const function ImplOf(trait: any, value: any): any
	const token = if type(value) == "table" then rawget(value, "__type") else nil
	const found = trait.impls[token]
	if found ~= nil or not trait.derivable then
		return found
	end
	return resolve(trait, token)
end

const function expectImplMiss(trait: any, value: any, who: string): any
	const token = if type(value) == "table" then rawget(value, "__type") else nil
	const derived = if trait.derivable then resolve(trait, token) else nil
	if derived ~= nil then
		return derived
	end
	return error(`{trait.name}: {who} needs a {trait.name}`, 0)
end

-- `src` 의 `ExpectImpl` 과 같은 몸통(견주기 위해).
const function ExpectImpl(trait: any, value: any, who: string): any
	const impl = if type(value) == "table" then trait.impls[rawget(value, "__type")] else nil
	if impl == nil then
		return expectImplMiss(trait, value, who)
	end
	return impl
end

-- 함수별 표: `[토큰] = 그 종류의 그 함수`. 정체성이 유지되고 다시 만들기가 맞춰 둡니다.
const function FnTable(trait: any, fnName: string): { [any]: any }
	local byToken = trait.fns[fnName]
	if byToken == nil then
		byToken = setmetatable({}, WEAK_KEYS) :: any
		for token, full in trait.impls do
			byToken[token] = full[fnName]
		end
		trait.fns[fnName] = byToken
	end
	return byToken
end

-- 함수별 표가 빗나갔을 때(저절로 따라오는 트레이트면 여기서 만들어짐).
const function FnMiss(trait: any, value: any, fnName: string): any
	return ExpectImpl(trait, value, fnName)[fnName]
end

const function Builds(): number
	return builds
end

-- stylua: ignore
return {
	New = New, Impl = Impl, ImplOf = ImplOf, ExpectImpl = ExpectImpl,
	FnTable = FnTable, FnMiss = FnMiss, Builds = Builds,
}

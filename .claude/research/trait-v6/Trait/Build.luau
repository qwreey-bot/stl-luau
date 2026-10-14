--!strict
--[[
	Build — 완성 표를 짓고, 놓고, 사건마다 다시 짓습니다.

	**사건은 셋**이고 각각 함수 하나입니다:
	- `onToken(token)`       토큰이 생김 → 의존이 없는 뭉텅이 구현(`Where = {}`)이 있는 트레이트를 그 종류에 지음.
	- `onFor(trait, token)`  그 종류의 명시 구현이 들어옴 → 그 표를 (다시) 지음.
	- `onWhere(trait)`       뭉텅이 구현이 들어옴 → 조건을 갖춘 종류마다 지음.
	셋 다 결국 `refresh(trait, token)` 하나로 모이고, 표가 놓이면(`commit`) 그 트레이트를 `Where` 에 적은 트레이트들
	(`dependents`)을 그 종류에 대해 다시 `refresh` 합니다(위로 번짐).

	**어느 구현을 쓰나**(`sourceOf`): 그 종류의 명시 구현(`For`)이 있으면 그것, 없으면 조건을 갖춘 뭉텅이 구현 — 둘 이상이면
	에러(Rust 처럼 겹침 금지). 아무것도 없으면 표가 없습니다.

	**짓기**(`assemble`)는 아무것도 고치지 않습니다 — 검사에 걸리면 에러이고 그때까지 바뀐 것이 없습니다.
	완성 표는 `{ [함수번호] = f, 이름 = f }`(진입점은 번호로, 종류를 아는 코드는 이름으로).
	⚠️ 계약: 만드는 함수(기본 구현, 뭉텅이의 builder)는 던지지 않고 표만 돌려줌 — 여러 번 불립니다.
]]
local Common = require("../../../../src/Common")
Common.registerSource(debug.info(1, "s"))
local Registry = require("./Registry")
local Errors = require("./Errors")

type Record = Registry.Record

const records = Registry.records

const Build = {}

-- 그 종류가 `deps` 를 다 갖췄으면 `[트레이트] = 완성 표`, 아니면 nil.
const function depsOf(deps: { any }, token: any): { [any]: any }?
	const out: { [any]: any } = {}
	for at = 1, #deps do
		const dep = deps[at]
		const full = dep[token]
		if full == nil then
			return nil
		end
		out[dep] = full
	end
	return out
end

-- 그 종류에 쓸 구현의 출처: 명시 구현의 사본 / 뭉텅이 builder 가 만든 표 / nil.
const function sourceOf(trait: any, rec: Record, token: any): { [string]: any }?
	const explicit = rec.explicit[token]
	if explicit ~= nil then
		return explicit
	end
	local found: Registry.Blanket? = nil
	local foundDeps: { [any]: any }? = nil
	for at = 1, #rec.blankets do
		const blanket = rec.blankets[at]
		const deps = depsOf(blanket.deps, token)
		if deps ~= nil then
			if found ~= nil then
				Errors.overlap(rec.name, token.name)
			end
			found, foundDeps = blanket, deps
		end
	end
	if found == nil then
		return nil
	end
	const given = found.build(foundDeps :: any)
	if type(given) ~= "table" then
		Errors.builderNotTable(rec.name, given)
	end
	return given
end
Build.sourceOf = sourceOf

-- 넘긴 표(+ 기본 구현)로 완성 표를 새로 지음. 아무것도 고치지 않음(검사에 걸리면 에러, 그때까지 바뀐 것 없음).
-- 기본 구현은 이름마다 **빌더**(`(ops) -> 함수`)이고, 넘긴 표에 없는(또는 `Trait.Inherit` 인) 이름만 짓습니다. 빌더가
-- `ops`(지금 짓는 표)에서 아직 안 지은 형제 기본 구현을 읽으면 그 자리에서 먼저 짓습니다 — 그래서 형제를 지역으로
-- 붙잡아도 순서와 무관합니다. 그동안만 `fresh` 에 메타테이블을 걸고 끝나면 뗍니다(완성 표는 평범한 테이블).
const function assemble(rec: Record, token: any, given: { [string]: any }): { [any]: any }
	const fresh: { [any]: any } = {}
	const builders = rec.builders
	for fnName, fn in given do
		if rec.fnTok[fnName] == nil then
			Errors.unknownName(rec.name, token.name, fnName)
		elseif fn == Registry.INHERIT then
			if builders[fnName] == nil then
				Errors.inheritRequired(rec.name, token.name, fnName)
			end
			continue
		elseif type(fn) ~= "function" then
			Errors.notFunction(rec.name, token.name, fnName, fn)
		end
		fresh[fnName] = fn
	end
	if next(builders) ~= nil then
		const building: { [string]: true } = {}
		local buildOne: (fnName: string) -> ()
		setmetatable(fresh, {
			__index = function(_: any, fnName: any): any
				if type(fnName) == "string" and builders[fnName] ~= nil then
					buildOne(fnName)
					return rawget(fresh, fnName)
				end
				return nil
			end,
		})
		function buildOne(fnName: string)
			if building[fnName] then
				Errors.defaultCycle(rec.name, fnName)
			end
			building[fnName] = true
			const fn = builders[fnName](fresh)
			if type(fn) ~= "function" then
				Errors.defaultNotFunction(rec.name, fnName, fn)
			end
			rawset(fresh, fnName, fn)
		end
		for fnName in builders do
			if rawget(fresh, fnName) == nil then
				buildOne(fnName)
			end
		end
		setmetatable(fresh, nil)
	end
	const fnNames = rec.fnNames
	for at = 1, #fnNames do
		const fnName = fnNames[at]
		const fn = fresh[fnName]
		if fn == nil then
			Errors.missing(rec.name, token.name, fnName)
		end
		fresh[at] = fn
	end
	return fresh
end
Build.assemble = assemble

-- 지은 표를 놓고(처음이면 그 표, 아니면 **같은 테이블을 비우고 다시 채움**) 위로 번짐.
local refresh: (trait: any, token: any) -> ()
const function commit(trait: any, rec: Record, token: any, full: { [any]: any })
	const existing = rawget(trait, token)
	if existing ~= nil then
		table.clear(existing)
		for key, fn in full do
			existing[key] = fn
		end
	else
		rawset(trait, token, full)
	end
	const dependents = rec.dependents
	for at = 1, #dependents do
		refresh(dependents[at], token)
	end
end
Build.commit = commit

function refresh(trait: any, token: any)
	const rec = records[trait]
	const given = sourceOf(trait, rec, token)
	if given == nil then
		return
	end
	commit(trait, rec, token, assemble(rec, token, given))
end
Build.refresh = refresh

--[[ 사건 셋 ]]

function Build.onToken(token: any)
	const traits = Registry.traits
	for at = 1, #traits do
		const trait = traits[at]
		const blankets = records[trait].blankets
		for b = 1, #blankets do
			if #blankets[b].deps == 0 then
				refresh(trait, token)
				break
			end
		end
	end
end

function Build.onFor(trait: any, token: any, given: { [string]: any })
	const rec = records[trait]
	if rec.explicit[token] ~= nil then
		Errors.already(rec.name, token.name)
	end
	-- 먼저 지어 보고(검사), 통과하면 기록하고 놓음 — 실패하면 아무것도 남지 않음
	const copy = table.clone(given)
	const full = assemble(rec, token, copy)
	rec.explicit[token] = copy
	commit(trait, rec, token, full)
end

function Build.onWhere(trait: any, blanket: Registry.Blanket)
	const rec = records[trait]
	const tokens = Registry.tokens
	-- 겹침을 먼저 다 봄(아무것도 바꾸기 전에): 명시 구현이 없는 종류에서 이미 다른 뭉텅이가 맞으면 에러
	for at = 1, #tokens do
		const token = tokens[at]
		if rec.explicit[token] == nil and depsOf(blanket.deps, token) ~= nil then
			for b = 1, #rec.blankets do
				if depsOf(rec.blankets[b].deps, token) ~= nil then
					Errors.overlap(rec.name, token.name)
				end
			end
		end
	end
	table.insert(rec.blankets, blanket)
	for _, dep in blanket.deps do
		const depRec = records[dep]
		if not depRec.dependentSet[trait] then
			depRec.dependentSet[trait] = true
			table.insert(depRec.dependents, trait)
		end
	end
	for at = 1, #tokens do
		const token = tokens[at]
		if rec.explicit[token] == nil and depsOf(blanket.deps, token) ~= nil then
			refresh(trait, token)
		end
	end
end

return Build

--!strict
--[[
	Build — 완성 표를 짓고, 놓고, 사건마다 다시 짓습니다.

	**사건은 셋**이고 각각 함수 하나입니다:
	- `onToken(token)`       토큰이 생김 → "모든 종류" 뭉텅이 구현(`ImplWhere(Trait.Any, …)`)이 있는 트레이트를 그 종류에 지음.
	- `onFor(trait, token)`  그 종류의 명시 구현이 들어옴 → 그 표를 (다시) 지음.
	- `onWhere(trait)`       뭉텅이 구현이 들어옴 → 조건을 갖춘 종류마다 지음.
	셋 다 결국 `refresh(trait, token)` 하나로 모이고, 표가 놓이면(`commit`) 그 트레이트를 `Where` 에 적은 트레이트들
	(`dependents`)을 그 종류에 대해 다시 `refresh` 합니다(위로 번짐).

	**어느 구현을 쓰나**(`sourceOf`): 그 종류의 명시 구현(`For`)이 있으면 그것, 없으면 조건을 갖춘 뭉텅이 구현 — 둘 이상이면
	에러(Rust 처럼 겹침 금지). 아무것도 없으면 표가 없습니다.

	**짓기**(`assemble`)는 아무것도 고치지 않습니다 — 검사에 걸리면 에러이고 그때까지 바뀐 것이 없습니다. 등록(`onFor`)과 뭉텅이
	등록(`onWhere`)은 **먼저 지어 보고** 통과하면 기록하고 놓습니다.
	⭐ **등록 하나는 묶음입니다**(`transact` — `NewToken`·`ImplFor`·`ImplWhere` 셋 다): 그동안 바꾼 것(놓은 표 — 같은 테이블의 옛 내용,
	기록, 토큰)을 일지(`note`)에 적어 두고, 위로 번지는 다시 짓기에서 무엇이 던지든(다른 트레이트의 뭉텅이 둘이 그 종류에서 처음 겹침,
	뭉텅이가 준 표의 빠짐이 조건을 갖춘 첫 종류에서야 드러남, 만드는 함수가 던짐) **전부 되돌리고** 다시 던집니다. 라이브러리 에러는
	사용자의 등록 줄, 사용자 코드의 에러는 그 줄 그대로(`Common.transact`). 예전엔 계기가 된 등록이 남아, 실패한 "모든 종류" 뭉텅이가
	그 뒤 무관한 `NewToken` 마다 던졌습니다(2026-10-15 리뷰 2~4라운드 — 같은 뿌리가 라운드마다 한 겹씩 깊어져 뿌리를 막음).
	완성 표는 `{ [함수번호] = f, 이름 = f }`(진입점은 번호로, 종류를 아는 코드는 이름으로).
	⚠️ 계약: 만드는 함수(기본 구현, 뭉텅이의 builder)는 던지지 않고 표만 돌려줌 — 여러 번 불립니다.
]]
local Common = require("../Common")
Common.registerSource(debug.info(1, "s"))
local Registry = require("./Registry")
local Errors = require("./Errors")

type Record = Registry.Record

const records = Registry.records

const Build = {}

-- 되돌리기 일지: 등록 하나(`transact`)가 도는 동안 바꾼 것마다 되돌리는 함수를 적고, 던지면 거꾸로 부릅니다. **스레드마다**
-- 하나(약한 키 — 만드는 함수가 양보한 채 버려진 스레드가 다른 스레드의 등록을 막거나 묶지 못하게 하지 않음, 트레이트 리뷰 5라운드).
-- ⚠️ 계약: 만드는 함수는 양보하지 않음(양보한 사이 다른 스레드가 등록하면 서로의 되돌리기가 엇갈림 — 정의되지 않은 동작).
const journals: { [thread]: { () -> () } } = setmetatable({}, { __mode = "k" }) :: any
const function note(undo: () -> ())
	const journal = journals[coroutine.running()]
	if journal ~= nil then
		table.insert(journal, undo)
	end
end
Build.note = note

-- 등록 하나를 묶음으로: 던지면 그동안 바꾼 것(놓은 표·기록·토큰)을 전부 되돌리고 다시 던짐(`Common.transact` — 사용자 줄 유지).
-- ⚠️ 만드는 함수 안에서 또 등록하는 것은 **정의되지 않은 동작**(2026-10-15 사용자: *"정의하지 말자"* — 계약: 부작용 없이 표만
-- 돌려줌). 지금은 같은 스레드면 바깥 묶음에 섞입니다(관측 — 안쪽 실패를 잡으면 반쯤 남거나, 바깥 실패가 안쪽 등록까지 되돌림).
-- `require` 는 모듈을 다른 스레드에서 돌리므로 builder 안에서 처음 require 된 모듈(이나 builder 가 띄운 코루틴)의 등록은 별개의
-- 묶음으로 따로 커밋됩니다(6라운드 관측).
function Build.transact(fn: () -> ())
	const thread = coroutine.running()
	if journals[thread] ~= nil then
		fn() -- 만드는 함수 안의 등록(정의되지 않은 동작): 바깥 묶음에 섞임
		return
	end
	journals[thread] = {}
	Common.transact(fn, function()
		const undo = journals[thread]
		journals[thread] = nil
		for at = #undo, 1, -1 do
			undo[at]()
		end
	end)
	journals[thread] = nil
end

const function removeValue(list: { any }, value: any)
	const at = table.find(list, value)
	if at ~= nil then
		table.remove(list, at)
	end
end

-- 그 종류가 `deps` 를 다 갖췄으면 `[트레이트] = 완성 표`, 아니면 nil.
const function depsOf(deps: { any }, token: any): { [any]: any }?
	const out: { [any]: any } = {}
	for at = 1, #deps do
		const dep = deps[at]
		const full = records[dep].impls[token]
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
-- 기본 구현은 이름마다 **빌더**(`(ops) -> 함수`)이고, 넘긴 표에 없는 이름만 짓습니다. 빌더가
-- `ops`(지금 짓는 표)에서 아직 안 지은 형제 기본 구현을 읽으면 그 자리에서 먼저 짓습니다 — 그래서 형제를 지역으로
-- 붙잡아도 순서와 무관합니다. 그동안만 `fresh` 에 메타테이블을 걸고 끝나면 뗍니다(완성 표는 평범한 테이블).
const function assemble(rec: Record, token: any, given: { [string]: any }, blanket: boolean?): { [any]: any }
	const fresh: { [any]: any } = {}
	const builders = rec.builders
	for fnName, fn in given do
		if rec.fnTok[fnName] == nil then
			Errors.unknownName(rec.name, token.name, fnName, blanket)
		elseif type(fn) ~= "function" then
			Errors.notFunction(rec.name, token.name, fnName, fn, blanket)
		end
		fresh[fnName] = fn
	end
	if next(builders) ~= nil then
		const building: { [string]: true } = {}
		local buildOne: (fnName: string) -> ()
		-- `:: any`: Luau 0.740(luau-lsp 1.70.1 — 편집기·Studio)은 `setmetatable` 뒤 `fresh` 를 메타테이블 타입으로 바꿔 아래 반환이 31건
		-- 에러였습니다(게이트의 0.742 는 0건).
		setmetatable(fresh :: any, {
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
			Errors.missing(rec.name, token.name, fnName, blanket)
		end
		fresh[at] = fn
	end
	return fresh
end
Build.assemble = assemble

-- 지은 표를 놓고(처음이면 그 표, 아니면 **같은 테이블을 비우고 다시 채움**) 위로 번짐.
local refresh: (trait: any, token: any) -> ()
const function commit(trait: any, rec: Record, token: any, full: { [any]: any })
	const existing = rec.impls[token]
	if existing ~= nil then
		const saved = table.clone(existing)
		note(function()
			table.clear(existing)
			for key, fn in saved do
				existing[key] = fn
			end
		end)
		table.clear(existing)
		for key, fn in full do
			existing[key] = fn
		end
	else
		rec.impls[token] = full
		note(function()
			rec.impls[token] = nil
		end)
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
	commit(trait, rec, token, assemble(rec, token, given, rec.explicit[token] == nil))
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

-- 구현 표에서 이름 하나를 찾습니다: 자기 키, 없으면 **`__index` 가 테이블인 사슬**을 따라(클래스처럼 물려받은 모듈).
-- `impl[name]` 으로 읽지 않습니다 — `__index` 가 **함수**인 표에서, 없는 멤버를 읽으면 에러를 내는 엄격한 모듈은 기본 구현
-- 이름을 묻는 순간 라이브러리 줄에서 죽었고(프리미티브만 구현한 모듈이 등록 불가), 값을 지어내는 프록시는 기본 구현을
-- 전부 갈아치웠습니다(옛 시스템 2라운드 리뷰). 그런 표는 자기 키만 봅니다.
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

-- 넘긴 표를 **등록 때 한 번** 읽어 평범한 사본으로: 자기 키 전부(모르는 이름은 `assemble` 이 에러) + 트레이트 함수 이름 중
-- 물려받은 것(`__index` 가 테이블인 사슬). 다시 지을 때는 이 사본만 씁니다 — 넘긴 표를 다시 읽으면 같은 틀 표를 고쳐 가며
-- 여러 종류에 등록한 쓰임에서 앞 종류가 뒤 종류의 함수를 얻었습니다(옛 시스템 1라운드 리뷰). 사본이라 넘긴 표를 붙잡지 않고,
-- 얼린 표·보호된 메타테이블도 됩니다(`table.clone` 은 보호된 메타테이블에서 라이브러리 줄 에러였음).
const function snapshot(rec: Record, token: any, given: any): { [string]: any }
	const copy: { [string]: any } = {}
	for fnName, fn in given do
		copy[fnName] = fn
	end
	const fnNames = rec.fnNames
	for at = 1, #fnNames do
		const fnName = fnNames[at]
		if copy[fnName] == nil then
			const inherited = lookup(given, fnName)
			if inherited ~= nil then
				if type(inherited) ~= "function" then
					Errors.notFunction(rec.name, token.name, fnName, inherited)
				end
				copy[fnName] = inherited
			end
		end
	end
	return copy
end

function Build.onFor(trait: any, token: any, given: { [string]: any })
	const rec = records[trait]
	if rec.explicit[token] ~= nil then
		Errors.already(rec.name, token.name)
	end
	-- 먼저 지어 보고(검사), 통과하면 기록하고 놓음 — 실패하면 아무것도 남지 않음
	const copy = snapshot(rec, token, given)
	const full = assemble(rec, token, copy)
	rec.explicit[token] = copy
	note(function()
		rec.explicit[token] = nil
	end)
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
	-- 지금 조건을 갖춘 종류마다 **먼저 지어 봄**(검사만 — 아무것도 놓지 않음): 만드는 함수가 표를 안 돌려주거나 빠진 필수 함수가
	-- 있으면 여기서 에러이고 아무것도 기록되지 않습니다. 예전엔 기록부터 하고 지어서, 실패한 뭉텅이 구현이 남아 그 뒤 조건을 채우는
	-- 무관한 등록마다 엉뚱한 줄에서 던졌고 `{}` 는 앞쪽 종류에만 적용된 채 멈췄습니다(이관 중 재현).
	for at = 1, #tokens do
		const token = tokens[at]
		if rec.explicit[token] == nil then
			const deps = depsOf(blanket.deps, token)
			if deps ~= nil then
				const given = blanket.build(deps)
				if type(given) ~= "table" then
					Errors.builderNotTable(rec.name, given)
				end
				assemble(rec, token, given, true)
			end
		end
	end
	table.insert(rec.blankets, blanket)
	note(function()
		removeValue(rec.blankets, blanket)
	end)
	for _, dep in blanket.deps do
		const depRec = records[dep]
		if not depRec.dependentSet[trait] then
			depRec.dependentSet[trait] = true
			table.insert(depRec.dependents, trait)
			note(function()
				depRec.dependentSet[trait] = nil
				removeValue(depRec.dependents, trait)
			end)
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

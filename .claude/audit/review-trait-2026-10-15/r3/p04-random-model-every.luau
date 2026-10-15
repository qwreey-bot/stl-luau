--!nocheck
-- 프로브 07: 무작위 등록 순서(토큰·트레이트·명시·뭉텅이)를 처음부터 다시 계산하는 모델과 대조.
-- 뭉텅이 몸통은 의존 함수를 **지을 때 붙잡음**(Stack 과 같은 모양 — 위로 번짐이 없으면 낡음).
-- 의존은 먼저 만든 트레이트만(고리 없음 — 고리는 p03). 겹침이 전파 중에 생기면 그 시행을 끝냄(문서상 부분 상태).
local stl = require("../../../../src")
local Trait = stl.Trait
-- 시행 하나가 겹침으로 끝나면 전역 등록부에 겹친 뭉텅이가 남아 다음 시행의 NewToken 을 깨므로, 시드 하나 = 프로세스 하나.
local SEED = tonumber(({...})[1]) or 1
local STEPS = 150
local totalChecks, totalSteps, trialsEndedByOverlap = 0, 0, 0
local uid = 0
for seed = SEED, SEED do
	math.randomseed(seed)
	local traits = {} -- { obj, i, blankets = { {bid, deps = {i...}, overrideD} }, explicit = { [tokI] = {overrideD} } }
	local tokens = {}
	local held = {} -- { traitI, tokI, table }
	local function R(i) return "R" .. i end
	local function D(i) return "D" .. i end
	local value -- (i, k, name) -> string | nil
	local function sourceOf(i, k)
		local t = traits[i]
		if t.explicit[k] then return "E", t.explicit[k] end
		local found, count = nil, 0
		for _, b in t.blankets do
			local okAll = true
			for _, dj in b.deps do
				if sourceOf(dj, k) == nil then okAll = false; break end
			end
			if okAll then found = b; count += 1 end
		end
		if count > 1 then return "OVERLAP" end
		if found then return "B", found end
		return nil
	end
	function value(i, k, name)
		local kind, src = sourceOf(i, k)
		if name == R(i) then
			if kind == "E" then return "E" .. i .. "." .. k end
			local parts = {}
			for _, dj in src.deps do
				table.insert(parts, value(dj, k, R(dj)) .. "," .. value(dj, k, D(dj)))
			end
			return "B" .. src.bid .. "(" .. table.concat(parts, ";") .. ")"
		else
			if kind == "E" and src.overrideD then return "O" .. i .. "." .. k end
			if kind == "B" and src.overrideD then return "BO" .. src.bid end
			return "D(" .. value(i, k, R(i)) .. ")"
		end
	end
	local function anyOverlap(exceptI)
		for i in traits do
			if i ~= exceptI then
				if sourceOf(i, 0) == "OVERLAP" then return true end -- 0 = 바깥 토큰(라이브러리·앞 시행) — 명시 구현 없음
				for k in tokens do
					if sourceOf(i, k) == "OVERLAP" then return true end
				end
			end
		end
		return false
	end
	local function verify(where)
		for i, t in traits do
			for k, tok in tokens do
				local kind = sourceOf(i, k)
				local v = Trait.Stamp({}, tok)
				local impl = Trait.Implements(t.obj, v)
				totalChecks += 1
				if impl ~= (kind ~= nil) then
					error(`seed {seed} {where}: Implements trait {i} token {k}: got {impl}, model {kind}`)
				end
				if kind then
					local gotR = t.obj[R(i)](v)
					local gotD = t.obj[D(i)](v)
					local wantR, wantD = value(i, k, R(i)), value(i, k, D(i))
					if gotR ~= wantR or gotD ~= wantD then
						error(`seed {seed} {where}: trait {i} token {k}: R {gotR} vs {wantR}, D {gotD} vs {wantD}`)
					end
				end
			end
		end
		for _, h in held do
			local now = traits[h[1]].obj.Of(tokens[h[2]])
			if not rawequal(now, h[3]) then error(`seed {seed}: held table replaced`) end
		end
	end
	local ended = false
	for step = 1, STEPS do
		if ended then break end
		totalSteps += 1
		local r = math.random()
		if r < 0.15 and #tokens < 7 then
			uid += 1
			local tok = Trait.NewToken("P07.Tok" .. uid)
			table.insert(tokens, tok)
			if anyOverlap(nil) then -- {} 뭉텅이 둘 — onWhere 가 막았어야
				error("unexpected overlap after token")
			end
		elseif r < 0.3 and #traits < 7 then
			local i = #traits + 1
			uid += 1
			local fns = {}
			fns[R(i)] = Trait.Fn()
			fns[D(i)] = Trait.Default(function(ops)
				local rf = ops[R(i)]
				return function(v) return "D(" .. rf(v) .. ")" end
			end)
			local obj = Trait.Trait("P07.T" .. uid, function(of) return table.freeze(fns) end)
			traits[i] = { obj = obj, blankets = {}, explicit = {} }
		elseif r < 0.6 and #traits > 0 and #tokens > 0 then
			local i = math.random(#traits)
			local k = math.random(#tokens)
			local t = traits[i]
			local overrideD = math.random() < 0.3
			local give = {}
			local ii, kk = i, k
			give[R(i)] = function(v) return "E" .. ii .. "." .. kk end
			if overrideD then give[D(i)] = function(v) return "O" .. ii .. "." .. kk end end
			local ok, err = pcall(t.obj.ImplFor, tokens[k], give)
			if t.explicit[k] then
				if ok then error("double explicit accepted") end
			else
				t.explicit[k] = { overrideD = overrideD }
				if anyOverlap(nil) then
					trialsEndedByOverlap += 1
					ended = true
				elseif not ok then
					error(`seed {seed}: ImplFor failed: {err}`)
				end
			end
		elseif r < 0.85 and #traits > 0 then
			local i = math.random(#traits)
			local t = traits[i]
			if #t.blankets < 2 then
				local deps, depObjs = {}, {}
				for j = 1, i - 1 do
					if math.random() < 0.35 then table.insert(deps, j); table.insert(depObjs, traits[j].obj) end
				end
				uid += 1
				local bid = uid
				local overrideD = math.random() < 0.25
				local b = { bid = bid, deps = deps, overrideD = overrideD }
				local function build(depTables)
					-- 지을 때 붙잡음
					local captured = {}
					for _, dj in deps do
						local full = depTables[traits[dj].obj]
						table.insert(captured, { full[R(dj)], full[D(dj)] })
					end
					local out = {}
					out[R(i)] = function(v)
						local parts = {}
						for _, c in captured do table.insert(parts, c[1](v) .. "," .. c[2](v)) end
						return "B" .. bid .. "(" .. table.concat(parts, ";") .. ")"
					end
					if overrideD then out[D(i)] = function() return "BO" .. bid end end
					return out
				end
				table.insert(t.blankets, b)
				local overlapHere = sourceOf(i, 0) == "OVERLAP"
				for k in tokens do if sourceOf(i, k) == "OVERLAP" then overlapHere = true end end
				local ok, err = pcall(t.obj.ImplWhere, if #depObjs == 0 then Trait.Every else depObjs, build)
				if overlapHere then
					table.remove(t.blankets)
					if ok then error(`seed {seed}: overlapping blanket accepted`) end
				elseif anyOverlap(i) then
					trialsEndedByOverlap += 1
					ended = true
				elseif not ok then
					error(`seed {seed}: ImplWhere failed: {err}`)
				end
			end
		elseif #traits > 0 and #tokens > 0 then
			local i, k = math.random(#traits), math.random(#tokens)
			local t = traits[i].obj
			if Trait.Implements(t, Trait.Stamp({}, tokens[k])) then
				table.insert(held, { i, k, t.Of(tokens[k]) })
			end
		end
		if not ended then verify("step " .. step) end
	end
end
print("seed", SEED, "steps", totalSteps, "checks", totalChecks, "ended-by-overlap", trialsEndedByOverlap)

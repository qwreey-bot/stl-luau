--!nocheck
-- 프로브 05: 다이아몬드를 층층이 쌓으면 다시 짓기 횟수가 2^층 — 아래층이 **이미 표가 있는 종류**에서 다시 지어질 때(명시 구현이 뭉텅이를 덮음)
-- L0 ← {P1, Q1} ← L1 ← {P2, Q2} ← L2 … (Pi·Qi 는 L(i-1) 의 뭉텅이, Li 는 {Pi, Qi} 의 뭉텅이)
local stl = require("../../../../src")
local T = stl.Trait
local function tr(name)
	return T.Trait(name, function()
		return table.freeze({ f = T.Fn() })
	end)
end
for _, depth in { 4, 8, 12, 16 } do
	local builds = 0
	local L0 = tr(`P05.{depth}.L0`)
	L0.ImplWhere({}, function()
		return { f = print }
	end)
	local prev = L0
	for i = 1, depth do
		local P, Q, L = tr(`P05.{depth}.P{i}`), tr(`P05.{depth}.Q{i}`), tr(`P05.{depth}.L{i}`)
		local below = prev
		P.ImplWhere({ below }, function(deps) builds += 1 return { f = deps[below].f } end)
		Q.ImplWhere({ below }, function(deps) builds += 1 return { f = deps[below].f } end)
		L.ImplWhere({ P, Q }, function(deps) builds += 1 return { f = deps[P].f } end)
		prev = L
	end
	local tok = T.NewToken(`P05.{depth}.Kind`)
	builds = 0
	local t0 = os.clock()
	L0.ImplFor(tok, { f = tostring }) -- 명시 구현이 {} 뭉텅이를 덮음 → 위로 번짐
	print(`층 {depth}: 명시 등록 하나가 부른 builder {builds}회, {string.format("%.3f", os.clock() - t0)}s, 꼭대기 표가 새 함수 {T.Impls(prev)[tok].f == tostring}`)
end

--!nocheck
-- 프로브 04: 한 묶음 안에서 같은 완성 표가 두 번 다시 지어진 뒤 실패 — 되돌리기가 **가장 옛 내용**으로 돌리는지(일지 역순).
-- 마름모: A → B, A → C, {B, C} → D. A 의 명시 구현이 뭉텅이를 덮으면 B 다시 짓기 → D(1), C 다시 짓기 → D(2), 그다음 E 가 실패.
local stl = require("../../../../src")
local T = stl.Trait
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end
local Z = tr("P04.Z", { z = T.Fn() })
local A = tr("P04.A", { a = T.Fn() })
local B = tr("P04.B", { b = T.Fn() })
local C = tr("P04.C", { c = T.Fn() })
local D = tr("P04.D", { d = T.Fn() })
local E = tr("P04.E", { e = T.Fn() })
local function tag(s) return function() return s end end
A.ImplWhere({ Z }, function() return { a = tag("a-blanket") } end)
B.ImplWhere({ A }, function(deps) local x = deps[A].a() return { b = tag("b<" .. x) } end)
C.ImplWhere({ A }, function(deps) local x = deps[A].a() return { c = tag("c<" .. x) } end)
D.ImplWhere({ B, C }, function(deps) return { d = tag("d<" .. deps[B].b() .. "," .. deps[C].c()) } end)
-- E 는 A 가 뭉텅이일 때만 성공 — A 의 dependents 순서상 B, C 다음(D 는 B·C 의 dependents)
E.ImplWhere({ A }, function(deps)
	return if deps[A].a() == "a-blanket" then { e = tag("e") } else {}
end)
local kind = T.NewToken("P04.Kind")
Z.ImplFor(kind, { z = print })
local heldD = D.Of(kind)
local before = heldD.d()
local heldB, heldC = B.Of(kind), C.Of(kind)
local bBefore, cBefore = heldB.b(), heldC.c()
print("전:", before, bBefore, cBefore)
local ok, err = pcall(function()
	A.ImplFor(kind, { a = tag("a-explicit") })
end)
print("실패:", ok, err)
print("후:", heldD.d(), heldB.b(), heldC.c(), "/ 같은 테이블:", D.Of(kind) == heldD)
print("D 가 가장 옛 내용?", heldD.d() == before)
print("D 진입점:", D.d(T.Stamp({}, kind)))

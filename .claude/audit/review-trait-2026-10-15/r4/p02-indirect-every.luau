--!nocheck
-- 프로브 02: 구조 검사가 보지 않는 "사실상 Every" — 목록 뭉텅이의 의존이 전부 Every 트레이트이면 그 뭉텅이도 모든 종류에 맞음.
-- 같은 트레이트의 목록 뭉텅이 둘이 각자 Every 트레이트에 기대면 3라운드 p03 과 같은 꼴(번짐에서 겹침 → 그 뒤 NewToken 이 던짐)이 남는지
local stl = require("../../../../src")
local T = stl.Trait
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end
local function try(label, fn)
	local ok, err = pcall(fn)
	print(label, ok, if ok then "" else tostring(err))
end
local A = tr("P02.A", { a = T.Fn() })
local B = tr("P02.B", { b = T.Fn() })
local Show = tr("P02.Show", { show = T.Fn() })
A.ImplWhere(T.Every, function() return { a = function() return "a" end } end)
Show.ImplWhere({ A }, function(d) return { show = d[A].a } end) -- 사실상 Every
try("(1) Show.ImplWhere({ B }) — B 종류 아직 없음", function()
	Show.ImplWhere({ B }, function(d) return { show = d[B].b } end)
end)
try("(2) B.ImplWhere(T.Every)", function()
	B.ImplWhere(T.Every, function() return { b = function() return "b" end } end)
end)
try("(3) 무관한 NewToken", function() T.NewToken("P02.Unrelated") end)
try("(4) 또 다른 NewToken", function() T.NewToken("P02.Other") end)
-- 비교: B 를 Every 가 아니라 한 종류에만 ImplFor 하면 그 줄에서 겹침(p02 r3 꼴, 독이 아님)
local C = tr("P02.C", { c = T.Fn() })
local Show2 = tr("P02.Show2", { show = T.Fn() })
Show2.ImplWhere({ A }, function(d) return { show = d[A].a } end)
Show2.ImplWhere({ C }, function(d) return { show = d[C].c } end)
try("(5) NewToken 도 여기서 던짐(독)", function() T.NewToken("P02.K") end)

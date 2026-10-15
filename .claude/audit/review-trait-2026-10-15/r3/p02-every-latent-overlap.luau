--!nocheck
-- 프로브 02: Every 뭉텅이와 다른 뭉텅이가 **같은 트레이트**에 있으면 겹침이 구조적으로 정해짐(다른 뭉텅이의 조건을 갖춘 모든 종류에서) —
-- 등록 때 그 조건을 갖춘 종류가 아직 없으면 통과하고, 나중의 무관한 등록 줄에서 겹침 에러 + 반쯤 반영(2라운드 참고 6 의 꼴)
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
-- 사용자 라이브러리의 흔한 순서: 트레이트를 정의하고 "기본은 모두에게" + "Printable 이면 이것" 을 걸고, 종류 등록은 나중
local Printable = tr("P02.Printable", { text = T.Fn() })
local Show = tr("P02.Show", { show = T.Fn() })
local Loud = tr("P02.Loud", { loud = T.Fn() }) -- Show 에 기대는 트레이트(번짐 확인)
Show.ImplWhere(T.Every, function()
	return { show = function() return "default" end }
end)
try("(1) Show.ImplWhere({ Printable }) — Printable 종류가 아직 없음", function()
	Show.ImplWhere({ Printable }, function(deps) return { show = deps[Printable].text } end)
end)
Loud.ImplWhere({ Show }, function(deps) return { loud = function(v) return deps[Show].show(v) .. "!" end } end)
local tok = T.NewToken("P02.Doc")
local v = T.Stamp({}, tok)
print("(2) 등록 전 Show/Loud", Show.show(v), Loud.loud(v))
try("(3) Printable.ImplFor(tok) — 무관해 보이는 줄", function()
	Printable.ImplFor(tok, { text = function() return "printable" end })
end)
print("(4) 뒤: Printable?", T.Implements(Printable, v), "Show.show", Show.show(v), "Loud.loud", Loud.loud(v))
try("(5) 다시 Printable.ImplFor", function()
	Printable.ImplFor(tok, { text = function() return "printable" end })
end)
-- 같은 상황을 Rust 처럼 등록 줄에서 잡는다면: Every 와 다른 뭉텅이는 같은 트레이트에 함께 둘 수 없음(순서 무관)

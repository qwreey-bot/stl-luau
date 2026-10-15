--!nocheck
-- 프로브 01: Trait.Every 의 런타임 경로 전부 — 목록과 헷갈릴 수 있는 값, 겹침, 고리, 나중 토큰, 명시 구현이 덮기, 사용자 줄
local stl = require("../../../../src")
local T = stl.Trait
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end
local function try(label, fn)
	local where = debug.info(1, "l") -- 이 줄(try 안) 이 아니라 아래 fn 의 줄이 맞는지는 출력의 파일:줄 로 봄
	local ok, err = pcall(fn)
	print(label, ok, if ok then "" else tostring(err))
end

local Base = tr("P01.Base", { a = T.Fn() })
local Show = tr("P01.Show", { name = T.Fn() })

-- (a) 목록과 헷갈릴 수 있는 값들
try("(a1) table.freeze({})", function()
	Show.ImplWhere(table.freeze({}), function() return { name = print } end)
end)
try("(a2) table.clone(T.Every)", function()
	Show.ImplWhere(table.clone(T.Every), function() return { name = print } end)
end)
try("(a3) 트레이트 객체를 목록 없이(흔한 실수)", function()
	Show.ImplWhere(Base, function() return { name = print } end)
end)
try("(a4) { T.Every }", function()
	Show.ImplWhere({ T.Every }, function() return { name = print } end)
end)
try("(a5) setmetatable({}, {__len = 1})", function()
	Show.ImplWhere(setmetatable({}, { __len = function() return 1 end, __index = function() return Base end }), function() return { name = print } end)
end)
try("(a6) 문자열", function()
	Show.ImplWhere("Base", function() return { name = print } end)
end)
try("(a7) {[2]=Base} (구멍 뒤 하나)", function()
	Show.ImplWhere({ [2] = Base }, function() return { name = print } end)
end)
print("(a) 뒤 Show 가 붙었나?", T.Implements(Show, stl.Arr.Of(1)))

-- (b) Every 정상: 이미 있던 종류 + 나중 토큰
Show.ImplWhere(T.Every, function()
	return { name = function(v) return T.TokenOf(v).name end }
end)
print("(b1) Arr", Show.name(stl.Arr.Of(1)))
local late = T.NewToken("P01.Late")
print("(b2) 나중 토큰", Show.name(T.Stamp({}, late)))

-- (c) 같은 트레이트에 Every 뭉텅이 둘 / Every 위에 {Base} 뭉텅이 / 반대 순서
try("(c1) 두 번째 Every", function()
	Show.ImplWhere(T.Every, function() return { name = print } end)
end)
try("(c2) Every 위에 {Base}", function()
	Show.ImplWhere({ Base }, function() return { name = print } end)
end)
local Show2 = tr("P01.Show2", { name = T.Fn() })
-- Base 를 구현한 종류가 없으면 {Base} 는 아무 종류와도 안 겹침 → 통과. 그 뒤 Every 는?
Show2.ImplWhere({ Base }, function() return { name = print } end)
print("(c3) {Base} 먼저 — 통과")
try("(c3) 그 뒤 Every(Base 종류 없음 — 겹침 없음)", function()
	Show2.ImplWhere(T.Every, function() return { name = function() return "every" end } end)
end)
local kb = T.NewToken("P01.KB")
try("(c4) 그 뒤 Base 를 구현하는 종류 — 이 종류에서 두 뭉텅이가 겹침", function()
	Base.ImplFor(kb, { a = print })
end)
print("(c4) 뒤: Base?", T.Implements(Base, T.Stamp({}, kb)), "Show2?", T.Implements(Show2, T.Stamp({}, kb)))

-- (d) 고리: Every 뭉텅이를 가진 트레이트를 거쳐
local X = tr("P01.X", { x = T.Fn() })
local Y = tr("P01.Y", { y = T.Fn() })
X.ImplWhere(T.Every, function() return { x = print } end)
Y.ImplWhere({ X }, function(deps) return { y = deps[X].x } end)
print("(d1) Y 는 모든 종류?", T.Implements(Y, stl.Arr.Of(1)), T.Implements(Y, T.Stamp({}, T.NewToken("P01.L2"))))
try("(d2) X.ImplWhere({ Y }) — 고리", function()
	X.ImplWhere({ Y }, function() return { x = print } end)
end)
try("(d3) Y.ImplWhere(T.Every) — 겹침", function()
	Y.ImplWhere(T.Every, function() return { y = print } end)
end)

-- (e) 명시 구현이 Every 를 덮고, 그 위로 번짐
local tok = T.NewToken("P01.Explicit")
X.ImplFor(tok, { x = function() return "explicit-x" end })
print("(e1) 덮음", X.x(T.Stamp({}, tok)), "번짐", Y.y(T.Stamp({}, tok)))

-- (f) Every 뭉텅이가 표를 잘못 줌 — 등록 줄(기존 종류에서)
local Z = tr("P01.Z", { z = T.Fn() })
try("(f1) 빠짐", function()
	Z.ImplWhere(T.Every, function() return {} end)
end)
try("(f2) 모르는 이름", function()
	Z.ImplWhere(T.Every, function() return { z = print, zz = print } end)
end)
print("(f) 뒤 Z?", T.Implements(Z, stl.Arr.Of(1)))

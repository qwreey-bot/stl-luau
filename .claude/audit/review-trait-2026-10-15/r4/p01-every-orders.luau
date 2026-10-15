--!nocheck
-- 프로브 01: Every 검사의 순서·조합 전수 — 등록 줄, 메시지, 거절 뒤 아무것도 안 남는지, NewToken 이 멀쩡한지
local stl = require("../../../../src")
local T = stl.Trait
local n = 0
local function tr(name, fns)
	n += 1
	return T.Trait(`P01.{n}.{name}`, function()
		return table.freeze(fns)
	end)
end
local function try(label, where, fn)
	local ok, err = pcall(fn)
	local msg = tostring(err)
	local lineOk = if ok then "-" else tostring(string.find(msg, `p01-every-orders.luau:{where}:`, 1, true) ~= nil)
	print(label, "ok=" .. tostring(ok), "userLine=" .. lineOk, if ok then "" else msg)
end
local function every(v)
	return function()
		return { show = function() return v end }
	end
end
local where

-- A. Every 먼저 → 목록 뭉텅이
local P = tr("Printable", { text = T.Fn() })
local S = tr("Show", { show = T.Fn() })
S.ImplWhere(T.Every, every("default"))
try("A Every→list", (function() where = debug.info(1, "l") + 1 return where end)(), function() S.ImplWhere({ P }, function(d) return { show = d[P].text } end) end)
local a = T.NewToken(`P01.A.{n}`)
P.ImplFor(a, { text = function() return "p" end })
print("A after: show", S.show(T.Stamp({}, a)), "blankets survive?", "-")

-- B. 목록 → Every
local P2 = tr("Printable", { text = T.Fn() })
local S2 = tr("Show", { show = T.Fn() })
S2.ImplWhere({ P2 }, function(d) return { show = d[P2].text } end)
try("B list→Every", (function() return debug.info(1, "l") end)(), function() S2.ImplWhere(T.Every, every("x")) end)
local b = T.NewToken(`P01.B.{n}`)
print("B after NewToken: S2 implemented on fresh kind?", T.Implements(S2, T.Stamp({}, b)), "Arr?", T.Implements(S2, stl.Arr.Of(1)))
P2.ImplFor(b, { text = function() return "p2" end })
print("B list blanket still works:", S2.show(T.Stamp({}, b)))

-- C. Every 둘
local S3 = tr("Show", { show = T.Fn() })
S3.ImplWhere(T.Every, every("first"))
try("C Every→Every", (function() return debug.info(1, "l") end)(), function() S3.ImplWhere(T.Every, every("second")) end)
local c = T.NewToken(`P01.C.{n}`)
print("C after: show", S3.show(T.Stamp({}, c)), S3.show(stl.Arr.Of(1)))

-- D. 명시 구현이 있는 트레이트 + Every + 목록 (명시 구현이 있어도 거절)
local P4 = tr("Printable", { text = T.Fn() })
local S4 = tr("Show", { show = T.Fn() })
local d1 = T.NewToken(`P01.D1.{n}`)
P4.ImplFor(d1, { text = function() return "p4" end })
S4.ImplFor(d1, { show = function() return "explicit" end })
S4.ImplWhere(T.Every, every("default4"))
try("D explicit+Every→list", (function() return debug.info(1, "l") end)(), function() S4.ImplWhere({ P4 }, function(d) return { show = d[P4].text } end) end)
print("D d1 explicit wins", S4.show(T.Stamp({}, d1)), "Arr default", S4.show(stl.Arr.Of(1)))
local S4b = tr("Show", { show = T.Fn() })
S4b.ImplFor(d1, { show = function() return "explicit" end })
S4b.ImplWhere({ P4 }, function(d) return { show = d[P4].text } end) -- d1 만 P4 인데 명시가 이김
try("D explicit+list→Every", (function() return debug.info(1, "l") end)(), function() S4b.ImplWhere(T.Every, every("x")) end)

-- E. Every 뒤 명시 구현(합법 — 여전히 됨)
local S5 = tr("Show", { show = T.Fn() })
S5.ImplWhere(T.Every, every("def5"))
local e = T.NewToken(`P01.E.{n}`)
S5.ImplFor(e, { show = function() return "fast" end })
print("E explicit over Every", S5.show(T.Stamp({}, e)), S5.show(stl.Arr.Of(1)))

-- F. 다른 트레이트의 뭉텅이가 이 트레이트에 기댐(합법): Loud.ImplWhere({ Show(Every) }), 그리고 Loud 에 Every 를 더하면?
local S6 = tr("Show", { show = T.Fn() })
local L6 = tr("Loud", { loud = T.Fn() })
S6.ImplWhere(T.Every, every("s6"))
L6.ImplWhere({ S6 }, function(d) return { loud = function(v) return d[S6].show(v) .. "!" end } end)
local f = T.NewToken(`P01.F.{n}`)
print("F Loud via Show(Every)", L6.loud(T.Stamp({}, f)))
try("F Loud list→Every", (function() return debug.info(1, "l") end)(), function() L6.ImplWhere(T.Every, function() return { loud = function() return "?" end } end) end)
-- 다른 트레이트에 Every 를 거는 것은 여전히 됨
local P6 = tr("Printable", { text = T.Fn() })
P6.ImplWhere(T.Every, function() return { text = function() return "pt" end } end)
L6 .ImplFor(T.NewToken(`P01.F2.{n}`), { loud = function() return "explicit" end })
print("F ok")

-- G. 자기 자신 의존 + Every 가 있음: 어떤 에러가 먼저?
local S7 = tr("Show", { show = T.Fn() })
S7.ImplWhere(T.Every, every("s7"))
try("G Every then {self}", (function() return debug.info(1, "l") end)(), function() S7.ImplWhere({ S7 }, function() return {} end) end)

-- H. 거절 뒤 아무것도 안 남는지(blankets/dependents) — 기록을 직접 봄
local Registry = require("../../../../src/Trait/Registry")
local P8 = tr("Printable", { text = T.Fn() })
local S8 = tr("Show", { show = T.Fn() })
S8.ImplWhere(T.Every, every("s8"))
pcall(S8.ImplWhere, { P8 }, function() return {} end)
print("H blankets", #Registry.records[S8].blankets, "P8 dependents", #Registry.records[P8].dependents)
local S9 = tr("Show", { show = T.Fn() })
S9.ImplWhere({ P8 }, function(d) return { show = d[P8].text } end)
pcall(S9.ImplWhere, T.Every, every("s9"))
print("H blankets S9", #Registry.records[S9].blankets, "P8 dependents", #Registry.records[P8].dependents)
for i = 1, 3 do T.NewToken(`P01.H.{i}`) end
print("H NewToken x3 ok")

--!nocheck
-- 프로브 03: 두 트레이트가 서로를 뭉텅이 의존으로 — 두 라이브러리의 같은 뜻 트레이트를 잇는 어댑터 모양
-- (A 를 구현하면 B, B 를 구현하면 A). 한 종류가 A 를 명시 구현하면?
local stl = require("../../../../src")
local Trait = stl.Trait
local LibA = Trait.Trait("P03.LibA.Sized", function(of)
	return table.freeze({ Size = Trait.Fn() })
end)
local LibB = Trait.Trait("P03.LibB.Sized", function(of)
	return table.freeze({ Count = Trait.Fn() })
end)
LibB.ImplWhere({ LibA }, function(deps) return { Count = deps[LibA].Size } end)
print("B where A ok")
local ok, err = pcall(function()
	LibA.ImplWhere({ LibB }, function(deps) return { Size = deps[LibB].Count } end)
end)
print("A where B", ok, err)
local T = Trait.NewToken("P03.Thing")
local ok2, err2 = pcall(function()
	LibA.ImplFor(T, { Size = function() return 3 end })
end)
print("A for T", ok2, err2 and string.sub(tostring(err2), 1, 200))
print("B.Count", pcall(LibB.Count, Trait.Stamp({}, T)))

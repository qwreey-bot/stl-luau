--!nocheck
-- 프로브 10: (가) 자기 자신을 의존으로 둔 뭉텅이, (나) 뭉텅이 builder 가 모르는 이름을 돌려줄 때의 메시지.
local stl = require("../../../../src")
local Trait = stl.Trait
local X = Trait.Trait("P10.X", function(of) return table.freeze({ F = Trait.Fn() }) end)
print("self where", pcall(X.ImplWhere, { X }, function(deps) return { F = deps[X].F } end))
local t = Trait.NewToken("P10.T")
local ok, err = pcall(X.ImplFor, t, { F = function() end })
print("explicit after self-blanket", ok, err and string.sub(tostring(err), 1, 120))
local Y = Trait.Trait("P10.Y", function(of) return table.freeze({ G = Trait.Fn() }) end)
local ok2, err2 = pcall(Y.ImplWhere, {}, function() return { G = function() end, Extra = function() end } end)
print("blanket unknown name", ok2, err2)

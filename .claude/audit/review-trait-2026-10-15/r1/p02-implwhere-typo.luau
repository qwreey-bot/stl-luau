--!nocheck
-- 프로브 02: ImplWhere 의 의존 목록에 오타(= nil) 하나만 — `{}`(모든 종류)와 구별이 안 됨.
local stl = require("../../../../src")
local Trait = stl.Trait
local Named = Trait.Trait("P02.Named", function(of)
	return table.freeze({ Name = Trait.Fn() })
end)
local traits = { Deque = stl.Deque }
-- 의도: 덱이면 이름을 줌. 오타: traits.Dequ (nil)
local ok, err = pcall(function()
	Named.ImplWhere({ traits.Dequ }, function(deps)
		return { Name = function(_v) return "deque" end }
	end)
end)
print("register", ok, err)
print("Arr has Named?", Trait.Implements(Named, stl.Arr.Of(1)))
print("HashMap has Named?", Trait.Implements(Named, stl.HashMap.New()))
print("Named.Name(HashMap)", pcall(Named.Name, stl.HashMap.New()))
-- 몸통이 deps[Deque] 를 읽는 흔한 모양이면?
local Named2 = Trait.Trait("P02.Named2", function(of)
	return table.freeze({ Back2 = Trait.Fn() })
end)
local ok2, err2 = pcall(function()
	Named2.ImplWhere({ traits.Dequ }, function(deps)
		local d = deps[stl.Deque]
		return { Back2 = d.Back }
	end)
end)
print("register2", ok2, err2)

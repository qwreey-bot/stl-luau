--!nonstrict
-- 타입 프로브 t03: ImplWhere 의존 목록의 오타가 타입에서 잡히는가(런타임에선 `{}` 와 같음 — p02).
local stl = require("../../../../src")
local Trait = stl.Trait
local Named = Trait.Trait("T03.Named", function<Self>(of: Self | stl.TraitToken<string>)
	return table.freeze({ Name = Trait.Fn<<(v: Self) -> string>>() })
end)
Named.ImplWhere({ stl.Dequ }, function(deps) -- NEG? 오타
	return { Name = function(_v: any): string return "deque" end }
end)
local traits = { Deque = stl.Deque }
Named.ImplWhere({ traits.Dequ }, function(deps) -- NEG? 오타(지역 표)
	return { Name = function(_v: any): string return "deque" end }
end)
local canary: string = 1
return canary

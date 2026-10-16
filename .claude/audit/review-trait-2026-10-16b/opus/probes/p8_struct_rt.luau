local stl = require("../src")
local T = stl.Trait
-- (a) 닫힌 트레이트를 뭉텅이 의존으로
local Shout = T.Trait("P8.Shout", function() return table.freeze({ Shout = T.Fn() }) end)
print("a", pcall(Shout.ImplWhere, { stl.Arr }, function(deps)
	local arr = deps[stl.Arr]
	return { Shout = function(a) return "n=" .. arr.Len(a) end }
end))
print("a2", pcall(function() return Shout.Shout(stl.Arr.Of(1, 2)) end))
print("a3 implements(Shout, HashMap)", T.Implements(Shout, stl.HashMap.New()))
-- (b) Any 뭉텅이가 특정 이름에서 던지면 Struct 도 되돌려짐
local Named = T.Trait("P8.Named", function() return table.freeze({ Name = T.Fn() }) end)
local boom = false
Named.ImplWhere(T.Any, function()
	if boom then
		boom = false
		error("builder boom")
	end
	return { Name = function() return "x" end }
end)
boom = true
local ok, err = pcall(T.Struct, "P8.Kind")
print("b1", ok, err)
local ok2, k2 = pcall(T.Struct, "P8.Kind")
print("b2 retry", ok2, ok2 and T.TokenOf(k2.Seal({})) ~= nil)
-- (c) Seal 에 토큰을 넘기면?
local KA = T.Struct("P8.KA")
local KB = T.Struct("P8.KB")
print("c seal token", pcall(KA.Seal, KB.Token))
print("c TokenOf(KB.Token).name", (T.TokenOf(KB.Token) or {}).name)
-- (d) Seal 에 다른 종류의 값을 넘기면?
local KC = T.Struct("P8.KC")
local arrv = stl.Arr.Of(1)
print("d seal value", pcall(KC.Seal, arrv))
print("d TokenOf(arr value)", (T.TokenOf(arrv) or {}).name, "isArr", stl.isArr(arrv), "List.Of ok", pcall(stl.List.Of, arrv))

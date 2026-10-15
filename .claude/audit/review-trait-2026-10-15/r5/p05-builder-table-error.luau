--!nocheck
-- 프로브 05: 묶음 안의 사용자 builder 가 **테이블** 에러(사용자 정의 에러 객체)를 던지면 그 값이 그대로(정체성 유지) 나와야 함.
local stl = require("../../../../src")
local T = stl.Trait
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end
local MyError = { code = "E_BUILDER" }
local Flaky = tr("P05.Flaky", { Run = T.Fn() })
local boom = false
Flaky.ImplWhere(T.Every, function()
	if boom then
		error(MyError)
	end
	return { Run = function() end }
end)
boom = true
local ok, err = pcall(function()
	T.NewToken("P05.Kind")
end)
print("ok:", ok, "같은 값:", err == MyError, "type:", type(err), tostring(err))
boom = false
print("다시 만들기:", pcall(function() return T.NewToken("P05.Kind") ~= nil end))

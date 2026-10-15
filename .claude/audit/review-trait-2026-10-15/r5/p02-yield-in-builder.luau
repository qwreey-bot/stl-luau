--!nocheck
-- 프로브 02: 묶음 안에서 builder 가 양보(yield)하면 `deferring`·`journal` 이 **전역으로** 켜진 채 다른 스레드가 돎.
-- (Luau 의 pcall 은 양보를 통과시킴 — Roblox 에선 builder 안의 require·WaitForChild 등)
local stl = require("../../../../src")
local T = stl.Trait
local Arr = stl.Arr
local function tr(name, fns)
	return T.Trait(name, function()
		return table.freeze(fns)
	end)
end
local a = Arr.Of(10, 20, 30)
local yieldNow = false
local Lazy = tr("P02.Lazy", { Run = T.Fn() })
Lazy.ImplWhere(T.Every, function(_deps)
	if yieldNow then
		coroutine.yield() -- 양보
	end
	return { Run = function() return "lazy" end }
end)
yieldNow = true
local co = coroutine.create(function()
	return T.NewToken("P02.Suspended")
end)
print("resume:", coroutine.resume(co))
print("status:", coroutine.status(co))
yieldNow = false

-- (1) 다른 스레드(여기선 메인)의 평범한 pcall(lib.fn) 이 표식 테이블을 받음
local ok1, err1 = pcall(Arr.At, a, 0 / 0)
print("(1) 메인의 pcall(Arr.At, NaN):", ok1, type(err1), tostring(err1))

-- (2) 메인의 등록이 실패해도 되돌려지지 않음(journal 이 남아 '중첩' 으로 취급 → pcall 없이 바로 돎)
local Q = tr("P02.Q", { Get = T.Fn() })
local P = tr("P02.P", { Name = T.Fn() })
local X = tr("P02.X", { Run = T.Fn() })
local function blanketName() return "blanket" end
P.ImplWhere({ Q }, function() return { Name = blanketName } end)
X.ImplWhere({ P }, function(deps)
	return if deps[P].Name == blanketName then { Run = blanketName } else {}
end)
local kind = T.NewToken("P02.Kind")
Q.ImplFor(kind, { Get = print })
local held = P.Of(kind)
local ok2, err2 = pcall(function()
	P.ImplFor(kind, { Name = function() return "explicit" end })
end)
print("(2) 번지다 실패:", ok2, tostring(err2))
print("    놓인 표가 옛 내용?", held.Name == blanketName, " (false 면 되돌려지지 않음)")
local ok3, err3 = pcall(function()
	P.ImplFor(kind, { Name = function() return "explicit" end })
end)
print("    다시 시도:", ok3, tostring(err3))

-- (3) 매달린 스레드를 버리면(Roblox: task.cancel / 스크립트 파괴) 영원히 켜진 채
coroutine.close(co)
print("closed:", coroutine.status(co))
local ok4, err4 = pcall(Arr.At, a, 0 / 0)
print("(3) 버린 뒤 pcall(Arr.At, NaN):", ok4, type(err4), tostring(err4))
local ok5, err5 = pcall(T.NewToken, "P02.Suspended")
print("    매달렸던 토큰 이름으로 다시:", ok5, tostring(err5))

--!nocheck
-- 양보한 채 버린 스레드가 수거되는가(약한 키의 주장 확인). collectgarbage("collect") 가 되는지도.
local stl = require("../../../../src")
local T = stl.Trait
local Slow = T.Trait("Q01.Slow", function() return table.freeze({ Run = T.Fn() }) end)
local yieldNow = false
Slow.ImplWhere(T.Every, function()
	if yieldNow then coroutine.yield() end
	return { Run = function() end }
end)
yieldNow = true
local probe = setmetatable({}, { __mode = "k" })
for i = 1, 200 do
	local co = coroutine.create(function() T.NewToken("Q01.Hung" .. i) end)
	coroutine.resume(co)
	probe[co] = true
end
local before = 0
for _ in probe do before += 1 end
print("ok collect:", pcall(collectgarbage, "collect"))
local after = 0
for _ in probe do after += 1 end
print("매달린 스레드 수 before/after GC:", before, after)
yieldNow = false
print("메인 스레드 등록:", pcall(T.NewToken, "Q01.Main"))
